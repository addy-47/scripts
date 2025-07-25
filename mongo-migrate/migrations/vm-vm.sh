#!/bin/bash

# Helper script for VM to VM MongoDB migration
# Usage: vm-vm.sh <config-file>

CONFIG_FILE="$1"
if [ -z "$CONFIG_FILE" ] || [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not provided or does not exist"
    exit 1
fi

# Source the config file
source "$CONFIG_FILE"

# Validate required variables for VM-to-VM migration
required_vars=("SOURCE_MONGO_URI" "TARGET_MONGO_URI" "BACKUP_DIR" "SOURCE_VM_IP" "SOURCE_VM_USER" "TARGET_VM_IP" "TARGET_VM_USER")
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

# Step 6: Transfer backup to target VM
echo "Transferring backup to target VM..."
scp "${BACKUP_DIR}.tar.gz" "${TARGET_VM_USER}@${TARGET_VM_IP}:${BACKUP_DIR}.tar.gz"

# Step 7: Extract and restore on target VM
echo "Restoring backup on target VM..."
ssh "${TARGET_VM_USER}@${TARGET_VM_IP}" << EOF
    tar -xzvf ${BACKUP_DIR}.tar.gz
    docker cp ${BACKUP_DIR} ${DOCKER_CONTAINER}:/${BACKUP_DIR}
    docker exec ${DOCKER_CONTAINER} bash -c "mongosh -u ${TARGET_MONGO_URI##*//} --eval \"db.adminCommand('listDatabases').databases.forEach(function(d) { if (d.name !== 'admin' && d.name !== 'local' && d.name !== 'config') { db.getMongo().getDB(d.name).dropDatabase(); } })\""
    docker exec ${DOCKER_CONTAINER} mongorestore --uri="${TARGET_MONGO_URI}" --drop ${BACKUP_DIR} --verbose
EOF

# Step 8: Verify restoration
echo "Verifying restoration on target VM..."
ssh "${TARGET_VM_USER}@${TARGET_VM_IP}" "docker exec ${DOCKER_CONTAINER} mongosh -u ${TARGET_MONGO_URI##*//} --eval 'db.adminCommand(\"listDatabases\")'"

# Step 9: Cleanup
echo "Cleaning up..."
rm "${BACKUP_DIR}.tar.gz"
ssh "${SOURCE_VM_USER}@${SOURCE_VM_IP}" "rm -rf ${BACKUP_DIR} ${BACKUP_DIR}.tar.gz"
ssh "${TARGET_VM_USER}@${TARGET_VM_IP}" "docker exec ${DOCKER_CONTAINER} rm -rf ${BACKUP_DIR}; rm -rf ${BACKUP_DIR} ${BACKUP_DIR}.tar.gz"

echo "VM to VM migration completed successfully"