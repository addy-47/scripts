#!/bin/bash

# Helper script for StatefulSet to StatefulSet MongoDB migration
# Usage: ss-ss.sh <config-file>

CONFIG_FILE="$1"
if [ -z "$CONFIG_FILE" ] || [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not provided or does not exist"
    exit 1
fi

# Source the config file
source "$CONFIG_FILE"

# Validate required variables for StatefulSet-to-StatefulSet migration
required_vars=("SOURCE_MONGO_URI" "TARGET_MONGO_URI" "BACKUP_DIR" "SOURCE_K8S_CONTEXT" "SOURCE_K8S_NAMESPACE" "SOURCE_K8S_POD" "TARGET_K8S_CONTEXT" "TARGET_K8S_NAMESPACE" "TARGET_K8S_POD")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; do
        echo "Error: Required variable '$var' is not set"
        exit 1
    fi
done

# Step 1: Switch to source Kubernetes context
echo "Switching to source Kubernetes context..."
kubectx "$SOURCE_K8S_CONTEXT"

# Step 2: Start port-forwarding for source pod
echo "Starting port-forwarding for source pod..."
kubectl port-forward -n "${SOURCE_K8S_NAMESPACE}" "${SOURCE_K8S_POD}" 27017:27017 &
PF_PID=$!
sleep 2

# Step 3: Scale down source StatefulSet
echo "Scaling down source StatefulSet..."
kubectl scale statefulset "${SOURCE_K8S_POD}" --replicas=0 -n "${SOURCE_K8S_NAMESPACE}"

# Step 4: Take backup
echo "Taking MongoDB backup from source pod..."
mkdir -p "${BACKUP_DIR}"
mongodump --uri="${SOURCE_MONGO_URI}" --out="${BACKUP_DIR}" --verbose
if [ $? -ne 0 ]; then
    echo "Error: Backup failed"
    kill $PF_PID
    exit 1
fi

# Step 5: Scale up source StatefulSet
echo "Scaling up source StatefulSet..."
kubectl scale statefulset "${SOURCE_K8S_POD}" --replicas=1 -n "${SOURCE_K8S_NAMESPACE}"

# Step 6: Stop port-forwarding
echo "Stopping port-forwarding for source pod..."
kill $PF_PID

# Step 7: Switch to target Kubernetes context
echo "Switching to target Kubernetes context..."
kubectx "$TARGET_K8S_CONTEXT"

# Step 8: Start port-forwarding for target pod
echo "Starting port-forwarding for target pod..."
kubectl port-forward -n "${TARGET_K8S_NAMESPACE}" "${TARGET_K8S_POD}" 27017:27017 &
PF_PID=$!
sleep 2

# Step 9: Restore backup to target pod
echo "Restoring backup to target pod..."
mongorestore --uri="${TARGET_MONGO_URI}" --drop "${BACKUP_DIR}" --verbose
if [ $? -ne 0 ]; then
    echo "Error: Restore failed"
    kill $PF_PID
    exit 1
fi

# Step 10: Verify restoration
echo "Verifying restoration in target pod..."
mongosh --host localhost --port 27017 -u "${TARGET_MONGO_URI##*//}" --eval 'db.adminCommand("listDatabases")'

# Step 11: Stop port-forwarding
echo "Stopping port-forwarding for target pod..."
kill $PF_PID

# Step 12: Cleanup
echo "Cleaning up..."
rm -rf "${BACKUP_DIR}"

echo "StatefulSet to StatefulSet migration completed successfully"