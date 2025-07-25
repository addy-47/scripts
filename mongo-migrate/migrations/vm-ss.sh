#!/bin/bash

# Helper script for VM to StatefulSet MongoDB migration
# Usage: vm-ss.sh <config-file>

CONFIG_FILE="$1"
if [ -z "$CONFIG_FILE" ] || [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not provided or does not exist"
    exit 1
fi

# Source the config file
source "$CONFIG_FILE"

# Validate required variables for VM-to-StatefulSet migration
required_vars=("SOURCE_MONGO_URI" "TARGET_MONGO_URI" "BACKUP_DIR" "SOURCE_VM_IP" "SOURCE_VM_USER" "TARGET_K8S_CONTEXT" "TARGET_K8S_NAMESPACE" "TARGET_K8S_POD")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: Required variable '$var' is not set"
        exit 1
    fi
done

# Step 1: Check MongoDB connectivity on source VM
echo "Checking MongoDB connectivity on source VM..."
ssh "${SOURCE_VM_USER}@${SOURCE_VM_IP}" "mongosh '${SOURCE_MONGO_URI}' --eval 'db.adminCommand(\"ping\")'"
if [ $? -ne 0 ]; then
    echo "Error: Cannot connect to source MongoDB"
    exit 1
fi

# Step 2: Install MongoDB tools on source VM
echo "Installing MongoDB tools on source VM..."
ssh "${SOURCE_VM_USER}@${SOURCE_VM_IP}" << 'EOF'
    sudo apt remove mongo-tools -y
    wget -qO - https://www.mongodb.org/static/pgp/server-8.0.asc | sudo apt-key add -
    echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
    sudo apt update
    sudo apt install -y mongodb-database-tools
    mongodump --version
EOF

# Step 3: Take backup on source VM
echo "Taking MongoDB backup on source VM..."
ssh "${SOURCE_VM_USER}@${SOURCE_VM_IP}" "mongodump --uri='${SOURCE_MONGO_URI}' --out='${BACKUP_DIR}' --verbose"
if [ $? -ne 0 ]; then
    echo "Error: Backup failed on source VM"
    exit 1
fi

# Step 4: Compress backup
echo "Compressing backup on source VM..."
ssh "${SOURCE_VM_USER}@${SOURCE_VM_IP}" "tar -czvf ${BACKUP_DIR}.tar.gz ${BACKUP_DIR}"

# Step 5: Transfer backup to local machine
echo "Transferring backup to local machine..."
scp "${SOURCE_VM_USER}@${SOURCE_VM_IP}:${BACKUP_DIR}.tar.gz" .

# Step 6: Switch to target Kubernetes context
echo "Switching to target Kubernetes context..."
kubectx "$TARGET_K8S_CONTEXT"

# Step 7: Transfer backup to target pod
echo "Transferring backup to target pod..."
kubectl cp "${BACKUP_DIR}.tar.gz" "${TARGET_K8S_NAMESPACE}/${TARGET_K8S_POD}:/${BACKUP_DIR}.tar.gz"

# Step 8: Extract backup in pod
echo "Extracting backup in target pod..."
kubectl exec -it -n "${TARGET_K8S_NAMESPACE}" "${TARGET_K8S_POD}" -- bash -c "tar -xzvf /${BACKUP_DIR}.tar.gz"

# Step 9: Drop existing databases in target pod
echo "Dropping existing databases in target pod..."
kubectl exec -it -n "${TARGET_K8S_NAMESPACE}" "${TARGET_K8S_POD}" -- mongosh -u "${TARGET_MONGO_URI##*//}" --eval "db.adminCommand('listDatabases').databases.forEach(function(d) { if (d.name !== 'admin' && d.name !== 'local' && d.name !== 'config') { db.getMongo().getDB(d.name).dropDatabase(); } })"

# Step 10: Restore backup in pod
echo "Restoring backup in target pod..."
kubectl exec -it -n "${TARGET_K8S_NAMESPACE}" "${TARGET_K8S_POD}" -- mongorestore --uri="${TARGET_MONGO_URI}" --drop "/${BACKUP_DIR}" --verbose

# Step 11: Verify restoration
echo "Verifying restoration in target pod..."
kubectl exec -it -n "${TARGET_K8S_NAMESPACE}" "${TARGET_K8S_POD}" -- mongosh -u "${TARGET_MONGO_URI##*//}" --eval 'db.adminCommand("listDatabases")'

# Step 12: Cleanup
echo "Cleaning up..."
rm "${BACKUP_DIR}.tar.gz"
ssh "${SOURCE_VM_USER}@${SOURCE_VM_IP}" "rm -rf ${BACKUP_DIR} ${BACKUP_DIR}.tar.gz"
kubectl exec -it -n "${TARGET_K8S_NAMESPACE}" "${TARGET_K8S_POD}" -- rm -rf "/${BACKUP_DIR}" "/${BACKUP_DIR}.tar.gz"

echo "VM to StatefulSet migration completed successfully"