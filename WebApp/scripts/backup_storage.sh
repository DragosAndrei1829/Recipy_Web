#!/bin/bash

# Script pentru backup al storage-ului local
# Folosește-l dacă vrei să rămâi cu storage local dar să faci backup-uri

STORAGE_DIR="backend/storage"
BACKUP_DIR="backups/storage"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/storage_backup_${DATE}.tar.gz"

# Creează directorul de backup dacă nu există
mkdir -p "$BACKUP_DIR"

# Face backup
echo "Creating backup of storage directory..."
tar -czf "$BACKUP_FILE" -C "$(dirname $STORAGE_DIR)" "$(basename $STORAGE_DIR)" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Backup created successfully: $BACKUP_FILE"
    echo "📦 Size: $(du -h "$BACKUP_FILE" | cut -f1)"
    
    # Șterge backup-urile mai vechi de 7 zile
    find "$BACKUP_DIR" -name "storage_backup_*.tar.gz" -mtime +7 -delete
    echo "🧹 Old backups (older than 7 days) have been cleaned up"
else
    echo "❌ Backup failed!"
    exit 1
fi



