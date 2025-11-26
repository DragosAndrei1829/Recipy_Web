#!/bin/bash

# Script pentru restore al storage-ului din backup

BACKUP_DIR="backups/storage"
STORAGE_DIR="backend/storage"

if [ -z "$1" ]; then
    echo "Usage: $0 <backup_file>"
    echo "Available backups:"
    ls -lh "$BACKUP_DIR"/storage_backup_*.tar.gz 2>/dev/null | awk '{print $9, "(" $5 ")"}'
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "⚠️  This will replace the current storage directory!"
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Restore cancelled."
    exit 0
fi

# Backup current storage before restore
if [ -d "$STORAGE_DIR" ]; then
    CURRENT_BACKUP="${BACKUP_DIR}/storage_before_restore_$(date +%Y%m%d_%H%M%S).tar.gz"
    echo "Creating backup of current storage..."
    tar -czf "$CURRENT_BACKUP" -C "$(dirname $STORAGE_DIR)" "$(basename $STORAGE_DIR)" 2>/dev/null
fi

# Restore
echo "Restoring from backup..."
tar -xzf "$BACKUP_FILE" -C "$(dirname $STORAGE_DIR)" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Storage restored successfully from: $BACKUP_FILE"
else
    echo "❌ Restore failed!"
    exit 1
fi



