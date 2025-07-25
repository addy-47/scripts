#!/bin/bash

# Helper script for VM to StatefulSet MongoDB migration
# Usage: vm-ss.sh <config-file>

set -euo pipefail  # Exit on error, undefined vars, pipe failures

CONFIG_FILE="$1"
if [ -z "$CONFIG_FILE" ] || [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not provided or does not exist" | tee -a migration.log
    exit 1
fi

# Source the config file
source "$CONFIG_FILE"

# Validate required variables
required_vars=("SOURCE_MONGO_URI" "TARGET_MONGO_URI" "BACKUP_DIR" "SOURCE_VM_IP" "SOURCE_VM_USER" "TARGET_K8S_CONTEXT" "TARGET_K8S_NAMESPACE" "TARGET_K8S_POD")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: Required variable '$var' is not set" | tee -a migration.log
        exit 1
    fi
done

# Check prerequisites
command -v kubectx >/dev/null 2>&1 || { echo "Error: kubectx not found"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "Error: kubectl not found"; exit 1; }

# Step 0: Perform source VM operations
echo "Connecting to source VM at ${SOURCE_VM_IP} as user ${SOURCE_VM_USER}..." | tee -a migration.log

# Create remote script with proper variable substitution
cat > /tmp/remote_backup.sh << EOF
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
    curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
        sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg
    
    echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/ubuntu \${OS_CODENAME}/mongodb-org/8.0 multiverse" | \
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

ls -lh "\${BACKUP_DIR}"

# Compress backup
echo "Compressing backup..."
tar -czf "\${BACKUP_DIR}.tar.gz" "\${BACKUP_DIR}"

echo "Backup completed successfully"
EOF

# Transfer and execute script on remote VM
scp /tmp/remote_backup.sh "${SOURCE_VM_USER}@${SOURCE_VM_IP}:/tmp/"
ssh "${SOURCE_VM_USER}@${SOURCE_VM_IP}" "chmod +x /tmp/remote_backup.sh && /tmp/remote_backup.sh"

if [ $? -ne 0 ]; then
    echo "Error: Source VM operations failed" | tee -a migration.log
    exit 1
fi

# Clean up local temp script
rm /tmp/remote_backup.sh

# Step 1: Transfer backup to local machine with retries
echo "Transferring backup to local machine..." | tee -a migration.log
BACKUP_FILE="$(basename "${BACKUP_DIR}").tar.gz"

for i in {1..3}; do
    if scp "${SOURCE_VM_USER}@${SOURCE_VM_IP}:${BACKUP_DIR}.tar.gz" "./${BACKUP_FILE}"; then
        break
    fi
    echo "Transfer attempt $i failed, retrying..." | tee -a migration.log
    sleep 5
done

if [ ! -f "./${BACKUP_FILE}" ]; then
    echo "Error: Failed to transfer backup from source VM" | tee -a migration.log
    exit 1
fi

echo "Backup transferred successfully, size: $(ls -lh "${BACKUP_FILE}" | awk '{print $5}')"

# Step 2: Switch to target Kubernetes context
echo "Switching to target Kubernetes context..." | tee -a migration.log
if ! kubectx "$TARGET_K8S_CONTEXT"; then
    echo "Error: Failed to switch to target Kubernetes context '$TARGET_K8S_CONTEXT'" | tee -a migration.log
    exit 1
fi

# Step 3: Check target pod status
echo "Checking target pod status..." | tee -a migration.log
POD_STATUS=$(kubectl get pod -n "$TARGET_K8S_NAMESPACE" "$TARGET_K8S_POD" -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")

if [ "$POD_STATUS" != "Running" ]; then
    echo "Error: Target pod is not running (status: $POD_STATUS)" | tee -a migration.log
    exit 1
fi

# Step 4: Transfer backup to target pod with retries
echo "Transferring backup to target pod..." | tee -a migration.log
for i in {1..3}; do
    if kubectl cp "./${BACKUP_FILE}" "${TARGET_K8S_NAMESPACE}/${TARGET_K8S_POD}:/${BACKUP_FILE}"; then
        break
    fi
    echo "Transfer to pod attempt $i failed, retrying..." | tee -a migration.log
    sleep 5
done

# Verify transfer to pod
if ! kubectl exec -n "${TARGET_K8S_NAMESPACE}" "${TARGET_K8S_POD}" -- ls -la "/${BACKUP_FILE}" >/dev/null 2>&1; then
    echo "Error: Failed to transfer backup to target pod" | tee -a migration.log
    exit 1
fi

# Step 5: Create and execute restore script in target pod
echo "Performing restore operations in target pod..." | tee -a migration.log

# Create restore script content
RESTORE_SCRIPT="
set -euo pipefail
cd /

# Extract backup
echo 'Extracting backup...'
tar -xzf /${BACKUP_FILE}

# Check if backup directory exists
BACKUP_DIR_NAME=\$(basename '${BACKUP_DIR}')
if [ ! -d \"/\${BACKUP_DIR_NAME}\" ]; then
    echo 'Error: Extracted backup directory not found'
    exit 1
fi

# Test target MongoDB connection
echo 'Testing target MongoDB connection...'
if ! mongosh '${TARGET_MONGO_URI}' --eval 'db.adminCommand(\"ping\")' --quiet; then
    echo 'Error: Cannot connect to target MongoDB'
    exit 1
fi

# Drop existing databases (except system ones)
echo 'Dropping existing user databases...'
mongosh '${TARGET_MONGO_URI}' --eval \"
db.adminCommand('listDatabases').databases.forEach(function(d) { 
    if (d.name !== 'admin' && d.name !== 'local' && d.name !== 'config') { 
        print('Dropping database: ' + d.name);
        db.getMongo().getDB(d.name).dropDatabase(); 
    } 
})\"

# Restore data
echo 'Restoring data...'
if ! mongorestore --uri='${TARGET_MONGO_URI}' --drop \"/\${BACKUP_DIR_NAME}\" --verbose; then
    echo 'Error: Restore failed'
    exit 1
fi

# Verify restore
echo 'Verifying restore...'
mongosh '${TARGET_MONGO_URI}' --eval "
db.getMongo().getDBNames().forEach(function(dbName) {
    if (dbName !== 'admin' && dbName !== 'local' && dbName !== 'config') {
        print('Verifying database: ' + dbName);
        let db = db.getMongo().getDB(dbName);
        db.getCollectionNames().forEach(function(collectionName) {
            let count = db.getCollection(collectionName).countDocuments();
            print(`  - ${collectionName}: ${count} documents`);
        });
    }
});
"

# Cleanup
echo 'Cleaning up...'
rm -rf \"/\${BACKUP_DIR_NAME}\" \"/${BACKUP_FILE}\"

echo 'Restore completed successfully'
"

# Execute restore script in pod (non-interactive)
kubectl exec -n "${TARGET_K8S_NAMESPACE}" "${TARGET_K8S_POD}" -- bash -c "$RESTORE_SCRIPT" | tee -a migration.log

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "Error: Target pod operations failed" | tee -a migration.log
    exit 1
fi

# Step 6: Cleanup
echo "Cleaning up..." | tee -a migration.log
rm -f "./${BACKUP_FILE}"

# Cleanup on source VM
ssh "${SOURCE_VM_USER}@${SOURCE_VM_IP}" "rm -rf ${BACKUP_DIR} ${BACKUP_DIR}.tar.gz /tmp/remote_backup.sh" 2>/dev/null || true

echo "VM to StatefulSet migration completed successfully at $(date)" | tee -a migration.log
echo "Migration log saved to: migration.log"