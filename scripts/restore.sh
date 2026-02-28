#!/bin/bash
# ==============================================================================
# AWS Secure S3 to EC2 Restore Automation
# Description: Downloads a specific backup from S3 and extracts it locally.
# Usage: ./restore.sh s3://bucket/backups/YYYY-MM-DD/backup_XYZ.tar.gz /target/dir
# ==============================================================================

set -e

# Ensure minimum arguments are passed
if [ -z "$1" ]; then
    echo "Usage: $0 <s3-backup-uri> [target-directory]"
    echo "Example: $0 s3://your-secure-backup-bucket-name/backups/2023-10-25/backup_XYZ.tar.gz /var/www/html_restored"
    exit 1
fi

S3_BACKUP_URI="$1"
TARGET_DIR="${2:-/var/www/html_restored}"
TEMP_DIR="/tmp/restores"
RESTORE_FILENAME=$(basename "$S3_BACKUP_URI")
LOG_FILE="/var/log/s3_restore.log"

# Validate user privileges for logging
if [ "$EUID" -ne 0 ] && [ ! -w /var/log ]; then
  LOG_FILE="/tmp/s3_restore.log"
  echo "Warning: Not running as root. Logging to $LOG_FILE"
fi

log_message() {
    local message="$1"
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $message" | tee -a "$LOG_FILE"
}

log_message "=========================================="
log_message "Starting Restore Process..."
log_message "Source S3 URI: $S3_BACKUP_URI"
log_message "Target Directory: $TARGET_DIR"

mkdir -p "$TEMP_DIR"

# 1. Download Backup from S3
log_message "Downloading from S3: $S3_BACKUP_URI to $TEMP_DIR/$RESTORE_FILENAME"
if aws s3 cp "$S3_BACKUP_URI" "$TEMP_DIR/$RESTORE_FILENAME"; then
    log_message "Download completed successfully."
else
    log_message "ERROR: Failed to download from S3. Verify the URI and IAM permissions."
    exit 1
fi

# 2. Extract Archive
mkdir -p "$TARGET_DIR"
log_message "Extracting $RESTORE_FILENAME to $TARGET_DIR..."

if tar -xzf "$TEMP_DIR/$RESTORE_FILENAME" -C "$TARGET_DIR"; then
    log_message "Extraction completed successfully."
    
    # Keep directory structure clean
    rm -f "$TEMP_DIR/$RESTORE_FILENAME"
    log_message "Cleaned up temporary downloaded archive."
else
    log_message "ERROR: Extraction failed!"
    exit 1
fi

log_message "Restore Process Finished Successfully!"
log_message "=========================================="
