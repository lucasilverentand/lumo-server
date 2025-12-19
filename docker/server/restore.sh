#!/usr/bin/env bash
#
# Minecraft Server Restore Script
# Restores server data from a backup archive
#

set -e

BACKUP_FILE="${1}"
DATA_DIR="${DATA_DIR:-/data}"
BACKUP_DIR="${BACKUP_DIR:-/backups}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[RESTORE]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if backup file is provided
if [ -z "${BACKUP_FILE}" ]; then
    error "Usage: $0 <backup-file>"
fi

# Check if backup file exists
if [ ! -f "${BACKUP_FILE}" ]; then
    # Try looking in backup directory
    if [ -f "${BACKUP_DIR}/${BACKUP_FILE}" ]; then
        BACKUP_FILE="${BACKUP_DIR}/${BACKUP_FILE}"
    else
        error "Backup file not found: ${BACKUP_FILE}"
    fi
fi

log "Backup file: ${BACKUP_FILE}"
log "Data directory: ${DATA_DIR}"

# Confirm restore
warn "This will REPLACE all data in ${DATA_DIR}"
warn "Make sure the server is STOPPED before restoring!"
read -p "Continue? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    log "Restore cancelled"
    exit 0
fi

# Create backup of current data
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
CURRENT_BACKUP="${BACKUP_DIR}/pre-restore-${TIMESTAMP}.tar.gz"

if [ -d "${DATA_DIR}" ]; then
    log "Creating safety backup of current data..."
    mkdir -p "${BACKUP_DIR}"
    tar -czf "${CURRENT_BACKUP}" -C "$(dirname ${DATA_DIR})" "$(basename ${DATA_DIR})"
    log "Current data backed up to: ${CURRENT_BACKUP}"
fi

# Clear data directory
log "Clearing data directory..."
rm -rf "${DATA_DIR}"/*

# Extract backup
log "Extracting backup..."
tar -xf "${BACKUP_FILE}" -C "/"

# Move data from archive structure
if [ -d "/data" ]; then
    log "Backup extracted successfully"
else
    error "Backup extraction failed - data directory not found"
fi

# Fix permissions
log "Fixing permissions..."
chown -R minecraft:minecraft "${DATA_DIR}" 2>/dev/null || true

log "Restore complete!"
log ""
log "Next steps:"
log "  1. Start the server"
log "  2. Verify worlds loaded correctly"
log "  3. Check player data"
log ""
log "If restore failed, original data is at: ${CURRENT_BACKUP}"
