#!/bin/bash

# Helper script for VM to VM MongoDB migration
# Usage: vm-vm.sh <config-file>

set -euo pipefail

CONFIG_FILE="$1"
if [ -z "$CONFIG_FILE" ] || [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not provided or does not exist" | tee -a migration.log
    exit 1
fi

# Source the config file
source "$CONFIG_FILE"

# Validate required variables for VM-to-VM migration
required_vars=("SOURCE_MONGO_URI" "TARGET_MONGO_URI" "BACKUP_DIR" "SOURCE_VM_IP" "SOURCE_VM_USER" "TARGET_VM_IP" "TARGET_VM_USER" "TARGET_DOCKER_CONTAINER")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: Required variable '$var' is not set" | tee -a migration.log
        exit 1
    fi
done

# Global variables for cleanup
BACKUP_FILE=""

# Cleanup function
cleanup() {
    echo "Performing cleanup..." | tee -a migration.log
    
    # Clean up local backup file
    if [ -n "$BACKUP_FILE" ] && [ -f "$BACKUP_FILE" ]; then
        rm -f "$BACKUP_FILE"
    fi
    
    # Clean up source VM (ignore errors)
    ssh "${SOURCE_VM_USER}@${SOURCE_VM_IP}" "rm -rf ${BACKUP_DIR} ${BACKUP_DIR}.tar.gz /tmp/source_backup.sh" 2>/dev/null || true
    
    # Clean up target VM (ignore errors)
    ssh "${TARGET_VM_USER}@${TARGET_VM_IP}" "rm -rf ${BACKUP_DIR} ${BACKUP_DIR}.tar.gz /tmp/target_restore.sh" 2>/dev/null || true
}

# Set trap for cleanup on exit
trap cleanup EXIT INT TERM

echo "Starting VM to VM migration at $(date)" | tee -a migration.log

# Step 1: Create and execute backup script on source VM
echo "Setting up backup on source VM..." | tee -a migration.log

# Create backup script with proper variable substitution
cat > /tmp/source_backup.sh << EOF
#!/bin/bash
set -euo pipefail

SOURCE_MONGO_URI='${SOURCE_MONGO_URI}'
BACKUP_DIR='${BACKUP_DIR}'

# Check MongoDB connectivity
echo "Checking MongoDB connectivity..."
if ! mongosh "\${SOURCE_MONGO_URI}" --eval 'db.adminCommand("ping")' --quiet; then
    echo "Error: Cannot connect to source MongoDB"
    exit 1
fi

# Check if MongoDB tools are installed
if ! command -v mongodump >/dev/null 2>&1; then
    echo "Installing MongoDB tools..."
    
    # Detect OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_CODENAME=\${VERSION_CODENAME:-focal}
    else
        OS_CODENAME="focal"
    fi
    
    # Remove old tools and install new ones
    sudo apt remove mongo-tools -y 2>/dev/null || true
    
    # Use modern keyring method instead of deprecated apt-key
    curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \\
        sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg
    
    echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/ubuntu \${OS_CODENAME}/mongodb-org/8.0 multiverse" | \\
        sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
    
    sudo apt update
    sudo apt install -y mongodb-database-tools
fi

# Verify tools are working
mongodump --version

# Clean up old backup if exists
[ -d "\${BACKUP_DIR}" ] && rm -rf "\${BACKUP_DIR}"
[ -f "\${BACKUP_DIR}.tar.gz" ] && rm -f "\${BACKUP_DIR}.tar.gz"

# Take backup
echo "Taking MongoDB backup..."
if ! mongodump --uri="\${SOURCE_MONGO_URI}" --out="\${BACKUP_DIR}" --verbose; then
    echo "Error: Backup failed"
    exit 1
fi

# Verify backup has content
echo "Verifying backup contents..."
if [ ! -d "\${BACKUP_DIR}" ] || [ -z "\$(ls -A "\${BACKUP_DIR}")" ]; then
    echo "Error: Backup directory is empty or does not exist"
    exit 1
fi

echo "Backup contents:"
ls -lh "\${BACKUP_DIR}"

# Compress backup
echo "Compressing backup..."
tar -czf "\${BACKUP_DIR}.tar.gz" "\${BACKUP_DIR}"

echo "Backup size: \$(ls -lh "\${BACKUP_DIR}.tar.gz" | awk '{print \$5}')"
echo "Backup completed successfully"
EOF

# Transfer and execute backup script on source VM
scp /tmp/source_backup.sh "${SOURCE_VM_USER}@${SOURCE_VM_IP}:/tmp/"
ssh "${SOURCE_VM_USER}@${SOURCE_VM_IP}" "chmod +x /tmp/source_backup.sh && /tmp/source_backup.sh" | tee -a migration.log

if [ ${PIPESTATUS[1]} -ne 0 ]; then
    echo "Error: Backup failed on source VM" | tee -a migration.log
    exit 1
fi

# Step 2: Transfer backup to local machine with retries
echo "Transferring backup to local machine..." | tee -a migration.log
BACKUP_FILE="$(basename "${BACKUP_DIR}")_$(date +%Y%m%d_%H%M%S).tar.gz"

for i in {1..3}; do
    if scp "${SOURCE_VM_USER}@${SOURCE_VM_IP}:${BACKUP_DIR}.tar.gz" "./${BACKUP_FILE}"; then
        break
    fi
    echo "Transfer from source attempt $i failed, retrying..." | tee -a migration.log
    sleep 5
done

if [ ! -f "./${BACKUP_FILE}" ]; then
    echo "Error: Failed to transfer backup from source VM" | tee -a migration.log
    exit 1
fi

echo "Backup transferred to local machine, size: $(ls -lh "${BACKUP_FILE}" | awk '{print $5}')"

# Step 3: Transfer backup to target VM with retries
echo "Transferring backup to target VM..." | tee -a migration.log

for i in {1..3}; do
    if scp "./${BACKUP_FILE}" "${TARGET_VM_USER}@${TARGET_VM_IP}:${BACKUP_DIR}.tar.gz"; then
        break
    fi
    echo "Transfer to target attempt $i failed, retrying..." | tee -a migration.log
    sleep 5
done

# Verify transfer to target VM
if ! ssh "${TARGET_VM_USER}@${TARGET_VM_IP}" "ls -la ${BACKUP_DIR}.tar.gz" >/dev/null 2>&1; then
    echo "Error: Failed to transfer backup to target VM" | tee -a migration.log
    exit 1
fi

# Step 4: Create and execute restore script on target VM
echo "Setting up restore on target VM..." | tee -a migration.log

# Create restore script with proper variable substitution
cat > /tmp/target_restore.sh << EOF
#!/bin/bash
set -euo pipefail

TARGET_MONGO_URI='${TARGET_MONGO_URI}'
BACKUP_DIR='${BACKUP_DIR}'
TARGET_DOCKER_CONTAINER='${TARGET_DOCKER_CONTAINER}'

# Check if Docker container exists and is running
echo "Checking Docker container status..."
if ! docker ps --format "table {{.Names}}" | grep -q "^\${TARGET_DOCKER_CONTAINER}$"; then
    echo "Error: Docker container '\${TARGET_DOCKER_CONTAINER}' is not running"
    echo "Available containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}"
    exit 1
fi

# Extract backup
echo "Extracting backup..."
tar -xzf \${BACKUP_DIR}.tar.gz

if [ ! -d "\${BACKUP_DIR}" ]; then
    echo "Error: Extracted backup directory not found"
    exit 1
fi

echo "Extracted backup contents:"
ls -la "\${BACKUP_DIR}"

# Copy backup to Docker container
echo "Copying backup to Docker container..."
if ! docker cp "\${BACKUP_DIR}" "\${TARGET_DOCKER_CONTAINER}:/\${BACKUP_DIR}"; then
    echo "Error: Failed to copy backup to Docker container"
    exit 1
fi

# Test MongoDB connection in container
echo "Testing MongoDB connection in container..."
if ! docker exec "\${TARGET_DOCKER_CONTAINER}" mongosh "\${TARGET_MONGO_URI}" --eval 'db.adminCommand("ping")' --quiet; then
    echo "Error: Cannot connect to target MongoDB in container"
    exit 1
fi

# Drop existing databases (except system ones)
echo "Dropping existing user databases..."
docker exec "\${TARGET_DOCKER_CONTAINER}" mongosh "\${TARGET_MONGO_URI}" --eval "
db.adminCommand('listDatabases').databases.forEach(function(d) { 
    if (d.name !== 'admin' && d.name !== 'local' && d.name !== 'config') { 
        print('Dropping database: ' + d.name);
        db.getMongo().getDB(d.name).dropDatabase(); 
    } 
})"

# Restore data
echo "Restoring data..."
if ! docker exec "\${TARGET_DOCKER_CONTAINER}" mongorestore --uri="\${TARGET_MONGO_URI}" --drop "/\${BACKUP_DIR}" --verbose; then
    echo "Error: Restore failed"
    exit 1
fi

# Verify restoration
echo "Verifying restoration..."docker exec "\${TARGET_DOCKER_CONTAINER}" mongosh "\${TARGET_MONGO_URI}" --eval "db.getMongo().getDBNames().forEach(function(dbName) {    if (dbName !== 'admin' && dbName !== 'local' && dbName !== 'config') {        print('Verifying database: ' + dbName);        let db = db.getMongo().getDB(dbName);        db.getCollectionNames().forEach(function(collectionName) {            let count = db.getCollection(collectionName).countDocuments();            print(`  -${collectionName}: ${count} documents`);        });    }});"

# Clean up backup in container
echo "Cleaning up backup in container..."
docker exec "\${TARGET_DOCKER_CONTAINER}" rm -rf "/\${BACKUP_DIR}"

echo "Restore completed successfully"
EOF

# Transfer and execute restore script on target VM
scp /tmp/target_restore.sh "${TARGET_VM_USER}@${TARGET_VM_IP}:/tmp/"
ssh "${TARGET_VM_USER}@${TARGET_VM_IP}" "chmod +x /tmp/target_restore.sh && /tmp/target_restore.sh" | tee -a migration.log

if [ ${PIPESTATUS[1]} -ne 0 ]; then
    echo "Error: Restore failed on target VM" | tee -a migration.log
    exit 1
fi

# Clean up temp scripts
rm -f /tmp/source_backup.sh /tmp/target_restore.sh

echo "VM to VM migration completed successfully at $(date)" | tee -a migration.log
echo "Migration log saved to: migration.log"