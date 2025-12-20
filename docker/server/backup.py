#!/usr/bin/env python3
"""
Minecraft Server Backup System
Automated backups with compression, rotation, and multiple destination support.
"""

import os
import sys
import time
import json
import signal
import logging
import subprocess
import tarfile
import shutil
from pathlib import Path
from datetime import datetime, timedelta
from typing import List, Optional
from glob import glob

# Configuration from environment variables
BACKUP_ENABLED = os.getenv("BACKUP_ENABLED", "true").lower() == "true"
BACKUP_INTERVAL = int(os.getenv("BACKUP_INTERVAL", "86400"))  # 24 hours
BACKUP_DIR = os.getenv("BACKUP_DIR", "/backups")
DATA_DIR = os.getenv("DATA_DIR", "/data")
BACKUP_RETENTION_DAYS = int(os.getenv("BACKUP_RETENTION_DAYS", "7"))
BACKUP_RETENTION_WEEKS = int(os.getenv("BACKUP_RETENTION_WEEKS", "4"))
BACKUP_COMPRESSION = os.getenv("BACKUP_COMPRESSION", "gz")  # gz, bz2, xz
RCON_HOST = os.getenv("RCON_HOST", "localhost")
RCON_PORT = os.getenv("RCON_PORT", "25575")
RCON_PASSWORD = os.getenv("RCON_PASSWORD", "minecraft")

# S3 configuration (optional)
S3_ENABLED = os.getenv("S3_ENABLED", "false").lower() == "true"
S3_BUCKET = os.getenv("S3_BUCKET", "")
S3_PREFIX = os.getenv("S3_PREFIX", "minecraft-backups")
S3_ENDPOINT = os.getenv("S3_ENDPOINT", "")  # For S3-compatible services

# Rclone configuration (optional)
RCLONE_ENABLED = os.getenv("RCLONE_ENABLED", "false").lower() == "true"
RCLONE_DEST = os.getenv("RCLONE_DEST", "")  # e.g., "remote:bucket/path"

# Discord webhook for backup notifications (optional)
DISCORD_WEBHOOK_URL = os.getenv("DISCORD_WEBHOOK_URL", "")

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [BACKUP] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)
logger = logging.getLogger(__name__)

shutdown_flag = False


def rcon_command(command: str) -> Optional[str]:
    """Execute RCON command and return output."""
    try:
        result = subprocess.run(
            ["mcrcon", "-H", RCON_HOST, "-P", RCON_PORT, "-p", RCON_PASSWORD, command],
            capture_output=True,
            text=True,
            timeout=10
        )
        if result.returncode == 0:
            return result.stdout.strip()
        return None
    except Exception as e:
        logger.error(f"RCON error: {e}")
        return None


def send_discord_notification(message: str, color: int = 0x00ff00):
    """Send backup notification to Discord webhook."""
    if not DISCORD_WEBHOOK_URL:
        return

    try:
        import urllib.request
        import json

        data = {
            "embeds": [{
                "title": "Backup Notification",
                "description": message,
                "color": color,
                "timestamp": datetime.utcnow().isoformat() + "Z"
            }]
        }

        req = urllib.request.Request(
            DISCORD_WEBHOOK_URL,
            data=json.dumps(data).encode("utf-8"),
            headers={"Content-Type": "application/json"}
        )
        urllib.request.urlopen(req, timeout=10)
    except Exception as e:
        logger.error(f"Failed to send Discord notification: {e}")


def create_backup() -> Optional[str]:
    """Create a compressed backup of the data directory."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_name = f"minecraft-backup-{timestamp}"

    # Determine compression mode
    if BACKUP_COMPRESSION == "bz2":
        ext = "tar.bz2"
        mode = "w:bz2"
    elif BACKUP_COMPRESSION == "xz":
        ext = "tar.xz"
        mode = "w:xz"
    else:
        ext = "tar.gz"
        mode = "w:gz"

    backup_file = os.path.join(BACKUP_DIR, f"{backup_name}.{ext}")

    try:
        logger.info(f"Creating backup: {backup_name}")

        # Disable world saving (optional - prevents corruption)
        logger.info("Disabling auto-save...")
        rcon_command("save-off")
        rcon_command("save-all flush")
        time.sleep(2)  # Wait for save to complete

        # Create backup directory if it doesn't exist
        os.makedirs(BACKUP_DIR, exist_ok=True)

        # Create compressed archive
        logger.info(f"Compressing {DATA_DIR}...")
        with tarfile.open(backup_file, mode) as tar:
            # Exclude certain files/dirs that don't need backing up
            excludes = [
                "cache",
                "logs",
                "*.tmp",
                "*.log",
                "session.lock"
            ]

            def filter_func(tarinfo):
                # Skip excluded files
                for pattern in excludes:
                    if pattern in tarinfo.name:
                        return None
                return tarinfo

            tar.add(DATA_DIR, arcname="data", filter=filter_func)

        # Re-enable world saving
        logger.info("Re-enabling auto-save...")
        rcon_command("save-on")

        # Get backup size
        size_mb = os.path.getsize(backup_file) / (1024 * 1024)
        logger.info(f"Backup created: {backup_file} ({size_mb:.2f} MB)")

        # Send notification
        send_discord_notification(
            f"✅ Backup completed successfully\n"
            f"**File**: {backup_name}.{ext}\n"
            f"**Size**: {size_mb:.2f} MB",
            color=0x00ff00
        )

        return backup_file

    except Exception as e:
        logger.error(f"Backup failed: {e}")
        rcon_command("save-on")  # Ensure save is re-enabled
        send_discord_notification(
            f"❌ Backup failed\n**Error**: {str(e)}",
            color=0xff0000
        )
        return None


def upload_to_s3(backup_file: str) -> bool:
    """Upload backup to S3-compatible storage."""
    if not S3_ENABLED or not S3_BUCKET:
        return True  # Skip if not configured

    try:
        logger.info(f"Uploading to S3: {S3_BUCKET}/{S3_PREFIX}/")

        cmd = [
            "aws", "s3", "cp",
            backup_file,
            f"s3://{S3_BUCKET}/{S3_PREFIX}/{os.path.basename(backup_file)}"
        ]

        if S3_ENDPOINT:
            cmd.extend(["--endpoint-url", S3_ENDPOINT])

        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)

        if result.returncode == 0:
            logger.info("S3 upload successful")
            return True
        else:
            logger.error(f"S3 upload failed: {result.stderr}")
            return False

    except Exception as e:
        logger.error(f"S3 upload error: {e}")
        return False


def upload_to_rclone(backup_file: str) -> bool:
    """Upload backup using rclone."""
    if not RCLONE_ENABLED or not RCLONE_DEST:
        return True  # Skip if not configured

    try:
        logger.info(f"Uploading to rclone: {RCLONE_DEST}")

        result = subprocess.run(
            ["rclone", "copy", backup_file, RCLONE_DEST],
            capture_output=True,
            text=True,
            timeout=300
        )

        if result.returncode == 0:
            logger.info("Rclone upload successful")
            return True
        else:
            logger.error(f"Rclone upload failed: {result.stderr}")
            return False

    except Exception as e:
        logger.error(f"Rclone upload error: {e}")
        return False


def cleanup_old_backups():
    """Remove old backups based on retention policy."""
    try:
        logger.info("Cleaning up old backups...")

        # Get all backups sorted by creation time
        backups = []
        for ext in ["tar.gz", "tar.bz2", "tar.xz"]:
            pattern = os.path.join(BACKUP_DIR, f"minecraft-backup-*.{ext}")
            backups.extend(glob(pattern))

        backups.sort(key=os.path.getmtime, reverse=True)

        if not backups:
            logger.info("No backups found for cleanup")
            return

        # Keep daily backups
        daily_cutoff = datetime.now() - timedelta(days=BACKUP_RETENTION_DAYS)
        weekly_cutoff = datetime.now() - timedelta(weeks=BACKUP_RETENTION_WEEKS)

        kept_daily = []
        kept_weekly = []
        removed = []

        for backup_file in backups:
            mtime = datetime.fromtimestamp(os.path.getmtime(backup_file))

            # Keep all recent daily backups
            if mtime > daily_cutoff:
                kept_daily.append(backup_file)
                continue

            # Keep weekly backups (one per week)
            if mtime > weekly_cutoff:
                week = mtime.isocalendar()[1]
                if week not in [datetime.fromtimestamp(os.path.getmtime(f)).isocalendar()[1] for f in kept_weekly]:
                    kept_weekly.append(backup_file)
                    continue

            # Remove old backups
            logger.info(f"Removing old backup: {os.path.basename(backup_file)}")
            os.remove(backup_file)
            removed.append(backup_file)

        logger.info(f"Cleanup complete. Daily: {len(kept_daily)}, Weekly: {len(kept_weekly)}, Removed: {len(removed)}")

    except Exception as e:
        logger.error(f"Cleanup failed: {e}")


def backup_loop():
    """Main backup loop."""
    global shutdown_flag

    logger.info(f"Backup system started (interval: {BACKUP_INTERVAL}s)")
    logger.info(f"Backup directory: {BACKUP_DIR}")
    logger.info(f"Retention: {BACKUP_RETENTION_DAYS} days, {BACKUP_RETENTION_WEEKS} weeks")
    logger.info(f"S3: {'enabled' if S3_ENABLED else 'disabled'}")
    logger.info(f"Rclone: {'enabled' if RCLONE_ENABLED else 'disabled'}")

    # Run first backup after short delay
    time.sleep(60)

    while not shutdown_flag:
        try:
            # Create backup
            backup_file = create_backup()

            if backup_file:
                # Upload to remote destinations
                if S3_ENABLED:
                    upload_to_s3(backup_file)

                if RCLONE_ENABLED:
                    upload_to_rclone(backup_file)

                # Cleanup old backups
                cleanup_old_backups()

        except Exception as e:
            logger.error(f"Backup loop error: {e}")

        # Wait for next backup
        time.sleep(BACKUP_INTERVAL)


def signal_handler(signum, frame):
    """Handle shutdown signals."""
    global shutdown_flag
    logger.info("Shutting down backup system...")
    shutdown_flag = True
    sys.exit(0)


def main():
    """Main entry point."""
    if not BACKUP_ENABLED:
        logger.info("Backups are disabled (BACKUP_ENABLED=false)")
        sys.exit(0)

    logger.info("Starting backup system...")

    # Setup signal handlers
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)

    # Run backup loop
    backup_loop()


if __name__ == "__main__":
    main()
