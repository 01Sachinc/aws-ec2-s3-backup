#!/bin/bash
# ==============================================================================
# AWS Secure EC2 to S3 Backup Automation
# Description: Compresses a specified directory and uploads it to an S3 bucket
#              with a timestamp-based folder structure.
# ==============================================================================

set -e

# Configuration Variables
SOURCE_DIR=${1:-"/var/www/html"}        # Directory to backup
S3_BUCKET="s3://your-secure-backup-bucket-name"
TEMP_DIR="/tmp/backups"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
DATE_FOLDER=$(date +"%Y-%m-%d")
BACKUP_FILENAME="backup_${TIMESTAMP}.tar.gz"
LOG_FILE="/var/log/s3_backup.log"

# Validate running as root or have sudo privileges for logging/backup
if [ "$EUID" -ne 0 ] && [ ! -w /var/log ]; then
  LOG_FILE="/tmp/s3_backup.log"
  echo "Warning: Not running as root or cannot write to /var/log. Logging to $LOG_FILE"
fi

# Setup Logging function
log_message() {
    local message="$1"
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $message" | tee -a "$LOG_FILE"
}

log_message "=========================================="
log_message "Starting Backup Process..."
log_message "Source Directory: $SOURCE_DIR"
log_message "Destination S3: $S3_BUCKET/backups/$DATE_FOLDER/"

# Validate Source Directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    log_message "ERROR: Source directory $SOURCE_DIR does not exist!"
    exit 1
fi

# Create Temp Directory if not exists
mkdir -p "$TEMP_DIR"

# 1. Compress Directory
log_message "Compressing $SOURCE_DIR into $TEMP_DIR/$BACKUP_FILENAME..."
if tar -czf "$TEMP_DIR/$BACKUP_FILENAME" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"; then
    log_message "Compression completed successfully."
else
    log_message "ERROR: Compression failed!"
    exit 1
fi

# 2. Upload to S3
S3_DESTINATION="${S3_BUCKET}/backups/${DATE_FOLDER}/${BACKUP_FILENAME}"
log_message "Uploading to S3: $S3_DESTINATION..."

# Note: Uses instance IAM role (no keys required) & Enables Server-Side Encryption (AES256)
if aws s3 cp "$TEMP_DIR/$BACKUP_FILENAME" "$S3_DESTINATION" --sse AES256; then
    log_message "Upload to S3 completed successfully."
    
    # Clean up local temp file
    rm -f "$TEMP_DIR/$BACKUP_FILENAME"
    log_message "Cleaned up temporary local backup file."
else
    log_message "ERROR: Failed to upload to S3!"
    exit 1
fi

log_message "Backup Process Finished Successfully!"
log_message "=========================================="
