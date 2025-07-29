#!/bin/bash

# Simple MySQL Backup Script for Beginners
# This script creates a MySQL backup, compresses it, uploads to S3, and keeps only 5 local copies

# =============================================================================
# CONFIGURATION - Change these values for your setup
# =============================================================================
DB_HOST="localhost"           # Database server address
DB_USER="backup_user"         # MySQL username
DB_PASSWORD="your_password"   # MySQL password (change this!)
DB_NAME="your_database"       # Database name to backup
BACKUP_DIR="/tmp/mysql_backups"  # Where to store backups locally
S3_BUCKET="your-backup-bucket"   # Your S3 bucket name
MAX_BACKUPS=5                 # How many backups to keep locally

# =============================================================================
# SCRIPT STARTS HERE - Don't change below unless you know what you're doing
# =============================================================================

# Create a timestamp for the backup file (format: 20240129_143022)
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${DB_NAME}_backup_${TIMESTAMP}.sql"
COMPRESSED_FILE="${BACKUP_FILE}.gz"

echo "=== MySQL Backup Script Started ==="
echo "Time: $(date)"
echo "Database: $DB_NAME"
echo ""

# Step 1: Create backup directory if it doesn't exist
echo "Step 1: Checking backup directory..."
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    if [ $? -ne 0 ]; then
        echo "ERROR: Could not create backup directory!"
        exit 1
    fi
else
    echo "Backup directory exists: $BACKUP_DIR"
fi

# Step 2: Check if we can connect to MySQL
echo ""
echo "Step 2: Testing MySQL connection..."
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1;" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "ERROR: Cannot connect to MySQL database!"
    echo "Please check your database credentials."
    exit 1
fi
echo "MySQL connection successful!"

# Step 3: Create the MySQL backup
echo ""
echo "Step 3: Creating MySQL backup..."
echo "This may take a few minutes for large databases..."

mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" > "$BACKUP_DIR/$BACKUP_FILE"

# Check if the backup was created successfully
if [ $? -ne 0 ]; then
    echo "ERROR: MySQL backup failed!"
    exit 2
fi

# Check if the backup file is not empty
if [ ! -s "$BACKUP_DIR/$BACKUP_FILE" ]; then
    echo "ERROR: Backup file is empty!"
    rm -f "$BACKUP_DIR/$BACKUP_FILE"
    exit 2
fi

echo "MySQL backup created: $BACKUP_FILE"
echo "File size: $(ls -lh "$BACKUP_DIR/$BACKUP_FILE" | awk '{print $5}')"

# Step 4: Compress the backup file
echo ""
echo "Step 4: Compressing backup file..."
gzip "$BACKUP_DIR/$BACKUP_FILE"

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to compress backup file!"
    rm -f "$BACKUP_DIR/$BACKUP_FILE"
    exit 3
fi

echo "Backup compressed: $COMPRESSED_FILE"
echo "Compressed size: $(ls -lh "$BACKUP_DIR/$COMPRESSED_FILE" | awk '{print $5}')"

# Step 5: Upload to Amazon S3
echo ""
echo "Step 5: Uploading to Amazon S3..."

# Check if AWS CLI is installed
if ! command -v aws > /dev/null 2>&1; then
    echo "ERROR: AWS CLI is not installed!"
    echo "Please install AWS CLI first."
    exit 4
fi

# Upload the file to S3
aws s3 cp "$BACKUP_DIR/$COMPRESSED_FILE" "s3://$S3_BUCKET/mysql-backups/$COMPRESSED_FILE"

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to upload backup to S3!"
    echo "Please check your AWS credentials and S3 bucket name."
    exit 4
fi

echo "Backup uploaded to S3 successfully!"

# Step 6: Clean up old local backups (keep only the last 5)
echo ""
echo "Step 6: Cleaning up old local backups..."

# Count how many backup files we have
BACKUP_COUNT=$(find "$BACKUP_DIR" -name "${DB_NAME}_backup_*.sql.gz" | wc -l)
echo "Current number of local backups: $BACKUP_COUNT"

if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
    echo "Removing old backups (keeping only $MAX_BACKUPS newest)..."
    
    # Find old backup files and remove them
    # This finds all backup files, sorts them by date (oldest first), 
    # and removes all except the newest MAX_BACKUPS files
    find "$BACKUP_DIR" -name "${DB_NAME}_backup_*.sql.gz" -type f | \
    sort | \
    head -n -"$MAX_BACKUPS" | \
    while read old_backup; do
        echo "Removing old backup: $(basename "$old_backup")"
        rm -f "$old_backup"
    done
else
    echo "No old backups to remove."
fi

# Final step: Show summary
echo ""
echo "=== BACKUP COMPLETED SUCCESSFULLY ==="
echo "Database: $DB_NAME"
echo "Backup file: $COMPRESSED_FILE"
echo "Local location: $BACKUP_DIR/$COMPRESSED_FILE"
echo "S3 location: s3://$S3_BUCKET/mysql-backups/$COMPRESSED_FILE"
echo "Completed: $(date)"
echo ""

# Exit with success code
exit 0