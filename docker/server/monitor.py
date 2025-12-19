#!/usr/bin/env python3
"""
Minecraft Server Monitor
Provides health check endpoint and optional Discord webhooks for server status.
"""

import os
import sys
import time
import json
import signal
import logging
import subprocess
from http.server import HTTPServer, BaseHTTPRequestHandler
from threading import Thread
from typing import Optional, Dict, Any
from datetime import datetime

# Configuration from environment variables
RCON_HOST = os.getenv("RCON_HOST", "localhost")
RCON_PORT = os.getenv("RCON_PORT", "25575")
RCON_PASSWORD = os.getenv("RCON_PASSWORD", "minecraft")
MONITOR_PORT = int(os.getenv("MONITOR_PORT", "8080"))
DISCORD_WEBHOOK_URL = os.getenv("DISCORD_WEBHOOK_URL", "")
CHECK_INTERVAL = int(os.getenv("MONITOR_CHECK_INTERVAL", "60"))
TPS_WARNING_THRESHOLD = float(os.getenv("TPS_WARNING_THRESHOLD", "15.0"))

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [MONITOR] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)
logger = logging.getLogger(__name__)

# Global state
server_status = {
    "online": False,
    "players": 0,
    "max_players": 0,
    "tps": 0.0,
    "memory_used": 0,
    "memory_max": 0,
    "uptime": 0,
    "last_check": None,
    "error": None
}

start_time = time.time()
shutdown_flag = False


def rcon_command(command: str) -> Optional[str]:
    """Execute RCON command and return output."""
    try:
        result = subprocess.run(
            ["mcrcon", "-H", RCON_HOST, "-P", RCON_PORT, "-p", RCON_PASSWORD, command],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0:
            return result.stdout.strip()
        else:
            logger.error(f"RCON command failed: {result.stderr}")
            return None
    except subprocess.TimeoutExpired:
        logger.error("RCON command timed out")
        return None
    except Exception as e:
        logger.error(f"RCON error: {e}")
        return None


def get_server_status() -> Dict[str, Any]:
    """Query server status via RCON."""
    global server_status

    try:
        # Check if server is online with list command
        list_output = rcon_command("list")
        if not list_output:
            server_status["online"] = False
            server_status["error"] = "Server not responding to RCON"
            return server_status

        server_status["online"] = True
        server_status["error"] = None

        # Parse player count from "There are X of Y players online"
        try:
            parts = list_output.split()
            if "are" in parts:
                idx = parts.index("are")
                server_status["players"] = int(parts[idx + 1])
                server_status["max_players"] = int(parts[idx + 3])
        except (ValueError, IndexError):
            logger.warning(f"Could not parse player count from: {list_output}")

        # Get TPS
        tps_output = rcon_command("tps")
        if tps_output:
            try:
                # Parse TPS from output like "TPS from last 1m, 5m, 15m: 20.0, 20.0, 20.0"
                if ":" in tps_output:
                    tps_values = tps_output.split(":")[1].strip()
                    tps_1m = float(tps_values.split(",")[0].strip())
                    server_status["tps"] = round(tps_1m, 2)
            except (ValueError, IndexError):
                logger.warning(f"Could not parse TPS from: {tps_output}")

        # Get memory usage
        mem_output = rcon_command("forge:tps")  # Try forge command first
        if not mem_output:
            # Fallback to checking via external commands
            # This is a placeholder - actual memory tracking would need plugin support
            server_status["memory_used"] = 0
            server_status["memory_max"] = 0

        # Calculate uptime
        server_status["uptime"] = int(time.time() - start_time)
        server_status["last_check"] = datetime.utcnow().isoformat() + "Z"

    except Exception as e:
        logger.error(f"Error getting server status: {e}")
        server_status["online"] = False
        server_status["error"] = str(e)

    return server_status


def send_discord_webhook(message: str, color: int = 0x00ff00):
    """Send notification to Discord webhook."""
    if not DISCORD_WEBHOOK_URL:
        return

    try:
        import urllib.request
        import json

        data = {
            "embeds": [{
                "title": "Minecraft Server Alert",
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
        logger.info(f"Discord notification sent: {message}")
    except Exception as e:
        logger.error(f"Failed to send Discord webhook: {e}")


class HealthCheckHandler(BaseHTTPRequestHandler):
    """HTTP handler for health check endpoint."""

    def log_message(self, format, *args):
        """Override to use custom logger."""
        pass  # Suppress default HTTP logging

    def do_GET(self):
        """Handle GET requests."""
        if self.path == "/health" or self.path == "/":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()

            # Refresh status
            status = get_server_status()

            response = {
                "status": "healthy" if status["online"] else "unhealthy",
                "timestamp": datetime.utcnow().isoformat() + "Z",
                "server": status
            }

            self.wfile.write(json.dumps(response, indent=2).encode("utf-8"))
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"Not found")


def monitor_loop():
    """Background monitoring loop."""
    global shutdown_flag
    last_online = None
    last_tps_warning = 0

    while not shutdown_flag:
        status = get_server_status()

        # Check for server down/up
        if last_online is not None and last_online != status["online"]:
            if status["online"]:
                send_discord_webhook(
                    "✅ Server is now **ONLINE**",
                    color=0x00ff00
                )
            else:
                send_discord_webhook(
                    "❌ Server is **DOWN** or not responding",
                    color=0xff0000
                )

        last_online = status["online"]

        # Check TPS
        if status["online"] and status["tps"] > 0:
            if status["tps"] < TPS_WARNING_THRESHOLD:
                # Only send warning once every 5 minutes
                if time.time() - last_tps_warning > 300:
                    send_discord_webhook(
                        f"⚠️ Server TPS is low: **{status['tps']}** (threshold: {TPS_WARNING_THRESHOLD})",
                        color=0xffaa00
                    )
                    last_tps_warning = time.time()

        time.sleep(CHECK_INTERVAL)


def signal_handler(signum, frame):
    """Handle shutdown signals."""
    global shutdown_flag
    logger.info("Shutting down monitor...")
    shutdown_flag = True
    sys.exit(0)


def main():
    """Main entry point."""
    logger.info(f"Starting Minecraft server monitor on port {MONITOR_PORT}")
    logger.info(f"RCON: {RCON_HOST}:{RCON_PORT}")
    logger.info(f"Check interval: {CHECK_INTERVAL}s")
    logger.info(f"Discord webhook: {'enabled' if DISCORD_WEBHOOK_URL else 'disabled'}")

    # Setup signal handlers
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)

    # Start background monitoring thread
    monitor_thread = Thread(target=monitor_loop, daemon=True)
    monitor_thread.start()

    # Start HTTP server
    try:
        server = HTTPServer(("0.0.0.0", MONITOR_PORT), HealthCheckHandler)
        logger.info(f"Health check endpoint available at http://0.0.0.0:{MONITOR_PORT}/health")
        server.serve_forever()
    except Exception as e:
        logger.error(f"Failed to start HTTP server: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
