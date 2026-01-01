#!/bin/bash

# Helper script for StatefulSet to StatefulSet MongoDB migration
# Usage: ss-ss.sh <config-file>

set -euo pipefail

CONFIG_FILE="$1"
if [ -z "$CONFIG_FILE" ] || [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not provided or does not exist" | tee -a migration.log
    exit 1
fi

# Source the config file
source "$CONFIG_FILE"

# Validate required variables
required_vars=("SOURCE_MONGO_URI" "TARGET_MONGO_URI" "BACKUP_DIR" "SOURCE_K8S_CONTEXT" "SOURCE_K8S_NAMESPACE" "SOURCE_K8S_POD" "TARGET_K8S_CONTEXT" "TARGET_K8S_NAMESPACE" "TARGET_K8S_POD")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: Required variable '$var' is not set" | tee -a migration.log
        exit 1
    fi
done

# Additional required variables for StatefulSet names
if [ -z "${SOURCE_STATEFULSET:-}" ]; then
    echo "Error: SOURCE_STATEFULSET variable is required" | tee -a migration.log
    exit 1
fi

# Global variables for cleanup
PF_PID=""
BACKUP_FILE=""

# Cleanup function
cleanup() {
    echo "Performing cleanup..." | tee -a migration.log
    
    # Kill port-forward if running
    if [ -n "$PF_PID" ] && kill -0 "$PF_PID" 2>/dev/null; then
        echo "Stopping port-forward (PID: $PF_PID)..." | tee -a migration.log
        kill "$PF_PID" 2>/dev/null || true
        sleep 2
        # Force kill if still running
        kill -9 "$PF_PID" 2>/dev/null || true
    fi
    
    # Clean up backup files
    if [ -n "$BACKUP_FILE" ] && [ -f "$BACKUP_FILE" ]; then
        rm -f "$BACKUP_FILE"
    fi
    if [ -d "${BACKUP_DIR}" ]; then
        rm -rf "${BACKUP_DIR}"
    fi
}

# Set trap for cleanup on exit
trap cleanup EXIT INT TERM

# Check prerequisites
command -v kubectx >/dev/null 2>&1 || { echo "Error: kubectx not found"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "Error: kubectl not found"; exit 1; }
command -v mongodump >/dev/null 2>&1 || { echo "Error: mongodump not found"; exit 1; }
command -v mongorestore >/dev/null 2>&1 || { echo "Error: mongorestore not found"; exit 1; }

echo "Starting StatefulSet to StatefulSet migration at $(date)" | tee -a migration.log

# Step 1: Switch to source Kubernetes context
echo "Switching to source Kubernetes context..." | tee -a migration.log
if ! kubectx "$SOURCE_K8S_CONTEXT"; then
    echo "Error: Failed to switch to source Kubernetes context '$SOURCE_K8S_CONTEXT'" | tee -a migration.log
    exit 1
fi

# Step 2: Check source pod status
echo "Checking source pod status..." | tee -a migration.log
SOURCE_POD_STATUS=$(kubectl get pod -n "$SOURCE_K8S_NAMESPACE" "$SOURCE_K8S_POD" -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
if [ "$SOURCE_POD_STATUS" != "Running" ]; then
    echo "Error: Source pod is not running (status: $SOURCE_POD_STATUS)" | tee -a migration.log
    exit 1
fi

# Step 3: Take backup using kubectl exec (more reliable than port-forward)
echo "Taking MongoDB backup from source pod..." | tee -a migration.log

# Create backup script for source pod
BACKUP_SCRIPT="
set -euo pipefail

# Test MongoDB connection
echo 'Testing MongoDB connection...'
if ! mongosh '${SOURCE_MONGO_URI}' --eval 'db.adminCommand(\"ping\")' --quiet; then
    echo 'Error: Cannot connect to source MongoDB'
    exit 1
fi

# Clean up old backup if exists
rm -rf /${BACKUP_DIR} /${BACKUP_DIR}.tar.gz

# Take backup
echo 'Taking backup...'
if ! mongodump --uri='${SOURCE_MONGO_URI}' --out=/${BACKUP_DIR} --verbose; then
    echo 'Error: Backup failed'
    exit 1
fi

# Verify backup has content
if [ ! -d /${BACKUP_DIR} ] || [ -z \"\$(ls -A /${BACKUP_DIR})\" ]; then
    echo 'Error: Backup directory is empty'
    exit 1
fi

echo 'Backup contents:'
ls -la /${BACKUP_DIR}

# Compress backup
echo 'Compressing backup...'
cd /
tar -czf ${BACKUP_DIR}.tar.gz ${BACKUP_DIR}/
ls -lh ${BACKUP_DIR}.tar.gz

echo 'Backup completed successfully'
"

# Execute backup in source pod
kubectl exec -n "${SOURCE_K8S_NAMESPACE}" "${SOURCE_K8S_POD}" -- bash -c "$BACKUP_SCRIPT" | tee -a migration.log

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "Error: Backup failed in source pod" | tee -a migration.log
    exit 1
fi

# Step 4: Copy backup from source pod to local machine
echo "Copying backup from source pod..." | tee -a migration.log
BACKUP_FILE="${BACKUP_DIR}_$(date +%Y%m%d_%H%M%S).tar.gz"

for i in {1..3}; do
    if kubectl cp "${SOURCE_K8S_NAMESPACE}/${SOURCE_K8S_POD}:/${BACKUP_DIR}.tar.gz" "./${BACKUP_FILE}"; then
        break
    fi
    echo "Copy attempt $i failed, retrying..." | tee -a migration.log
    sleep 5
done

if [ ! -f "./${BACKUP_FILE}" ]; then
    echo "Error: Failed to copy backup from source pod" | tee -a migration.log
    exit 1
fi

echo "Backup copied successfully, size: $(ls -lh "${BACKUP_FILE}" | awk '{print $5}')"

# Step 5: Switch to target Kubernetes context
echo "Switching to target Kubernetes context..." | tee -a migration.log
if ! kubectx "$TARGET_K8S_CONTEXT"; then
    echo "Error: Failed to switch to target Kubernetes context '$TARGET_K8S_CONTEXT'" | tee -a migration.log
    exit 1
fi

# Step 6: Check target pod status
echo "Checking target pod status..." | tee -a migration.log
TARGET_POD_STATUS=$(kubectl get pod -n "$TARGET_K8S_NAMESPACE" "$TARGET_K8S_POD" -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
if [ "$TARGET_POD_STATUS" != "Running" ]; then
    echo "Error: Target pod is not running (status: $TARGET_POD_STATUS)" | tee -a migration.log
    exit 1
fi

# Step 7: Copy backup to target pod
echo "Copying backup to target pod..." | tee -a migration.log
for i in {1..3}; do
    if kubectl cp "./${BACKUP_FILE}" "${TARGET_K8S_NAMESPACE}/${TARGET_K8S_POD}:/${BACKUP_FILE}"; then
        break
    fi
    echo "Copy to target attempt $i failed, retrying..." | tee -a migration.log
    sleep 5
done

# Verify transfer to target pod
if ! kubectl exec -n "${TARGET_K8S_NAMESPACE}" "${TARGET_K8S_POD}" -- ls -la "/${BACKUP_FILE}" >/dev/null 2>&1; then
    echo "Error: Failed to copy backup to target pod" | tee -a migration.log
    exit 1
fi

# Step 8: Restore backup in target pod
echo "Restoring backup in target pod..." | tee -a migration.log

RESTORE_SCRIPT="
set -euo pipefail

# Extract backup
echo 'Extracting backup...'
cd /
tar -xzf /${BACKUP_FILE}

if [ ! -d /${BACKUP_DIR} ]; then
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
if ! mongorestore --uri='${TARGET_MONGO_URI}' --drop /${BACKUP_DIR} --verbose; then
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

# Cleanup files in pod
echo 'Cleaning up files in pod...'
rm -rf /${BACKUP_DIR} /${BACKUP_FILE}

echo 'Restore completed successfully'
"

# Execute restore in target pod
kubectl exec -n "${TARGET_K8S_NAMESPACE}" "${TARGET_K8S_POD}" -- bash -c "$RESTORE_SCRIPT" | tee -a migration.log

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "Error: Restore failed in target pod" | tee -a migration.log
    exit 1
fi

# Step 9: Clean up backup files in source pod
echo "Cleaning up source pod..." | tee -a migration.log
kubectx "$SOURCE_K8S_CONTEXT" > /dev/null
kubectl exec -n "${SOURCE_K8S_NAMESPACE}" "${SOURCE_K8S_POD}" -- bash -c "rm -rf /${BACKUP_DIR} /${BACKUP_DIR}.tar.gz" 2>/dev/null || true

echo "StatefulSet to StatefulSet migration completed successfully at $(date)" | tee -a migration.log
echo "Migration log saved to: migration.log"