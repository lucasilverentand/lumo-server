# Automated Backup System

The Lumo Server includes a comprehensive automated backup system with compression, retention policies, and multiple destination support.

## Features

- **Automated Daily Backups**: Runs on configurable schedule (default: every 24 hours)
- **Compression**: gzip, bzip2, or xz compression
- **Retention Policy**: Keep 7 daily + 4 weekly backups by default
- **Multiple Destinations**: Local storage, S3-compatible, rclone
- **Safe Backups**: Automatically disables world saving during backup
- **Discord Notifications**: Optional notifications for backup events
- **Easy Restore**: Simple restore script included

## Quick Start

### Enable Backups

Backups are enabled by default. Configure with volume mount:

```bash
docker run \
  -v minecraft_data:/data \
  -v minecraft_backups:/backups \
  lumo-server
```

Backups will be stored in the `/backups` volume.

### Manual Backup

Trigger a manual backup:

```bash
docker exec <container> python3 /backup.py
```

### Restore from Backup

1. Stop the server:
   ```bash
   docker stop <container>
   ```

2. List available backups:
   ```bash
   docker run --rm -v minecraft_backups:/backups lumo-server ls -lh /backups
   ```

3. Restore from backup:
   ```bash
   docker run --rm \
     -v minecraft_data:/data \
     -v minecraft_backups:/backups \
     lumo-server /restore.sh <backup-filename>
   ```

4. Start the server:
   ```bash
   docker start <container>
   ```

## Configuration

Configure backups via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `BACKUP_ENABLED` | `true` | Enable/disable automated backups |
| `BACKUP_INTERVAL` | `86400` | Backup interval in seconds (24h) |
| `BACKUP_DIR` | `/backups` | Directory to store backups |
| `BACKUP_RETENTION_DAYS` | `7` | Keep backups from last N days |
| `BACKUP_RETENTION_WEEKS` | `4` | Keep one weekly backup for N weeks |
| `BACKUP_COMPRESSION` | `gz` | Compression: `gz`, `bz2`, or `xz` |

### Compression Options

- **`gz` (gzip)**: Fast compression, moderate size (recommended)
- **`bz2` (bzip2)**: Slower compression, smaller size
- **`xz`**: Slowest compression, smallest size

### Example: 12-hour backups with 14-day retention

```bash
docker run \
  -e BACKUP_INTERVAL=43200 \
  -e BACKUP_RETENTION_DAYS=14 \
  -e BACKUP_RETENTION_WEEKS=8 \
  -v minecraft_backups:/backups \
  lumo-server
```

## S3-Compatible Storage

Upload backups to S3, MinIO, Backblaze B2, or other S3-compatible services.

### Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `S3_ENABLED` | `false` | Enable S3 uploads |
| `S3_BUCKET` | `""` | S3 bucket name |
| `S3_PREFIX` | `minecraft-backups` | S3 object prefix/folder |
| `S3_ENDPOINT` | `""` | Custom endpoint (for MinIO, B2, etc.) |

### AWS S3 Example

```bash
docker run \
  -e S3_ENABLED=true \
  -e S3_BUCKET=my-minecraft-backups \
  -e AWS_ACCESS_KEY_ID=AKIA... \
  -e AWS_SECRET_ACCESS_KEY=... \
  -e AWS_DEFAULT_REGION=us-east-1 \
  lumo-server
```

### MinIO Example

```bash
docker run \
  -e S3_ENABLED=true \
  -e S3_BUCKET=minecraft \
  -e S3_ENDPOINT=https://minio.example.com \
  -e AWS_ACCESS_KEY_ID=minioadmin \
  -e AWS_SECRET_ACCESS_KEY=minioadmin \
  lumo-server
```

### Backblaze B2 Example

```bash
docker run \
  -e S3_ENABLED=true \
  -e S3_BUCKET=my-bucket \
  -e S3_ENDPOINT=https://s3.us-west-002.backblazeb2.com \
  -e AWS_ACCESS_KEY_ID=<key_id> \
  -e AWS_SECRET_ACCESS_KEY=<application_key> \
  lumo-server
```

## Rclone Support

Use [rclone](https://rclone.org/) to backup to 50+ cloud storage providers.

### Setup

1. Configure rclone on your host:
   ```bash
   rclone config
   ```

2. Mount rclone config into container:
   ```bash
   docker run \
     -e RCLONE_ENABLED=true \
     -e RCLONE_DEST="remote:bucket/minecraft" \
     -v ~/.config/rclone:/root/.config/rclone:ro \
     lumo-server
   ```

### Supported Destinations

Rclone supports 50+ providers including:
- Google Drive
- Dropbox
- OneDrive
- SFTP
- FTP
- WebDAV
- And many more

See [rclone.org](https://rclone.org/) for full list.

## Discord Notifications

Receive backup status notifications in Discord.

### Setup

1. Create Discord webhook:
   - Server Settings → Integrations → Webhooks → New Webhook
   - Copy webhook URL

2. Configure:
   ```bash
   docker run \
     -e DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..." \
     lumo-server
   ```

### Notification Types

- ✅ **Backup Success**: Backup completed with filename and size
- ❌ **Backup Failed**: Backup failed with error message

## Backup Contents

The backup includes:
- All world data (overworld, nether, end)
- Player data (inventories, locations, stats)
- Plugin configurations
- Plugin data (economy, permissions, etc.)
- Server properties

The backup excludes:
- Log files
- Temporary files
- Cache directories
- Session locks

## Restore Process

### Full Restore

Complete server restoration from backup:

1. **Stop the server** (REQUIRED):
   ```bash
   docker stop minecraft-server
   ```

2. **Run restore script**:
   ```bash
   docker run --rm -it \
     -v minecraft_data:/data \
     -v minecraft_backups:/backups \
     lumo-server /restore.sh minecraft-backup-20251219_120000.tar.gz
   ```

3. **Confirm restore**:
   - Script will ask for confirmation
   - Creates safety backup of current data
   - Extracts backup archive
   - Fixes permissions

4. **Start server**:
   ```bash
   docker start minecraft-server
   ```

### Partial Restore

Restore specific files or worlds:

1. Extract backup to temporary location:
   ```bash
   mkdir /tmp/backup-extract
   tar -xzf minecraft-backup-20251219_120000.tar.gz -C /tmp/backup-extract
   ```

2. Copy specific files:
   ```bash
   # Restore just one world
   docker cp /tmp/backup-extract/data/world minecraft-server:/data/

   # Restore player data
   docker cp /tmp/backup-extract/data/world/playerdata minecraft-server:/data/world/
   ```

3. Fix permissions and restart:
   ```bash
   docker exec minecraft-server chown -R minecraft:minecraft /data
   docker restart minecraft-server
   ```

## Monitoring Backups

### Check Backup Logs

```bash
docker logs minecraft-server | grep BACKUP
```

### List Backups

```bash
docker run --rm -v minecraft_backups:/backups lumo-server ls -lh /backups
```

### Check Backup Size

```bash
docker run --rm -v minecraft_backups:/backups lumo-server du -sh /backups
```

### Verify Backup Contents

```bash
docker run --rm -v minecraft_backups:/backups lumo-server \
  tar -tzf /backups/minecraft-backup-20251219_120000.tar.gz | head -20
```

## Retention Policy

The backup system automatically manages old backups:

### Daily Backups
- Keeps all backups from the last `BACKUP_RETENTION_DAYS` days
- Default: 7 days

### Weekly Backups
- After daily retention expires, keeps one backup per week
- Keeps weekly backups for `BACKUP_RETENTION_WEEKS` weeks
- Default: 4 weeks

### Example Timeline

With defaults (7 days + 4 weeks):
- **Day 1-7**: All daily backups kept (7 backups)
- **Week 2-5**: One backup per week (4 backups)
- **Older**: Deleted automatically

Total: ~11 backups at any time

### Custom Retention

```bash
# Keep 14 days + 8 weeks
docker run \
  -e BACKUP_RETENTION_DAYS=14 \
  -e BACKUP_RETENTION_WEEKS=8 \
  lumo-server
```

## Troubleshooting

### Backups not running

Check logs:
```bash
docker logs minecraft-server | grep BACKUP
```

Verify backup is enabled:
```bash
docker inspect minecraft-server | grep BACKUP_ENABLED
```

### Backup failed - disk space

Check available space:
```bash
df -h /var/lib/docker/volumes/
```

Cleanup old backups manually:
```bash
docker run --rm -v minecraft_backups:/backups lumo-server \
  find /backups -name "*.tar.gz" -mtime +30 -delete
```

### Restore failed - permissions

Fix permissions:
```bash
docker exec minecraft-server chown -R minecraft:minecraft /data
```

### S3 upload failed

Verify credentials:
```bash
docker exec minecraft-server aws s3 ls s3://your-bucket
```

Check S3 endpoint:
```bash
docker logs minecraft-server | grep "S3 upload"
```

### Backup too large

Use better compression:
```bash
# Use xz instead of gz
docker run -e BACKUP_COMPRESSION=xz lumo-server
```

Exclude more files (edit `/backup.py` excludes list)

## Best Practices

### 1. Test Restores Regularly

Test restore process monthly to ensure backups are valid:
```bash
# Create test container
docker run -d --name mc-test \
  -v minecraft_test_data:/data \
  -v minecraft_backups:/backups \
  lumo-server /restore.sh latest-backup.tar.gz

# Verify it starts
docker logs mc-test

# Cleanup
docker rm -f mc-test
docker volume rm minecraft_test_data
```

### 2. Use Remote Backups

Always use S3 or rclone for off-site backups. Local-only backups don't protect against hardware failure.

### 3. Monitor Backup Size

Track backup sizes over time:
```bash
docker run --rm -v minecraft_backups:/backups lumo-server \
  find /backups -name "*.tar.gz" -printf "%TY-%Tm-%Td %p %s\n"
```

### 4. Backup Before Updates

Before updating Minecraft version or plugins:
```bash
# Force immediate backup
docker exec minecraft-server python3 /backup.py
```

### 5. Document Backup Strategy

Keep a note of:
- Where backups are stored
- S3/rclone credentials
- Retention policy
- Last successful restore test

## Advanced Usage

### Custom Backup Schedule

Use external cron to trigger backups:

```bash
# Disable internal backup daemon
docker run -e BACKUP_ENABLED=false lumo-server

# Add cron job on host
0 2 * * * docker exec minecraft-server python3 /backup.py
```

### Backup to Multiple Destinations

Enable both S3 and rclone:

```bash
docker run \
  -e S3_ENABLED=true \
  -e S3_BUCKET=primary-backups \
  -e RCLONE_ENABLED=true \
  -e RCLONE_DEST="secondary:backups" \
  lumo-server
```

### Backup Hooks

Run custom scripts before/after backups:

```bash
# Create pre-backup script
docker exec minecraft-server sh -c 'cat > /pre-backup.sh << EOF
#!/bin/bash
# Your custom pre-backup tasks
echo "Running pre-backup tasks..."
EOF'

# Modify backup.py to call hooks
```

## Security Considerations

### Backup Encryption

Backups are not encrypted by default. For sensitive data:

```bash
# Encrypt backups with GPG
docker run --rm -v minecraft_backups:/backups lumo-server \
  gpg --symmetric --cipher-algo AES256 /backups/minecraft-backup-*.tar.gz
```

### Access Control

- Use IAM roles for S3 (avoid hardcoded credentials)
- Restrict S3 bucket access with bucket policies
- Use rclone encryption for cloud storage

### Secure Deletion

When removing old backups:
```bash
# Secure deletion
docker run --rm -v minecraft_backups:/backups lumo-server \
  shred -u /backups/old-backup.tar.gz
```

---

Last Updated: 2025-12-19
