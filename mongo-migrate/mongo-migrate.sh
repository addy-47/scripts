#!/bin/bash

# Master script for MongoDB data migration

# Function to display usage
usage() {
    echo "Usage: $0 <migration-type> [config-file]"
    echo "Supported migration types: vm-vm, vm-ss, ss-ss"
    echo "Default config file: ~/mongo-migrate.conf"
    exit 1
}

# Check if migration type is provided
if [ -z "$1" ]; then
    usage
fi

MIGRATION_TYPE="$1"
CONFIG_FILE="${2:-$HOME/mongo-migrate.conf}"

# Validate migration type
case "$MIGRATION_TYPE" in
    vm-vm|vm-ss|ss-ss)
        ;;
    *)
        echo "Error: Unsupported migration type '$MIGRATION_TYPE'"
        usage
        ;;
esac

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file '$CONFIG_FILE' not found"
    exit 1
fi

# Source the config file
source "$CONFIG_FILE"

# Validate required config variables
required_vars=(
    "SOURCE_MONGO_URI" "TARGET_MONGO_URI" "BACKUP_DIR"
)
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: Required config variable '$var' is not set in $CONFIG_FILE"
        exit 1
    fi
done

# Directory for helper scripts
SCRIPT_DIR="$(dirname "$0")/migrations"

# Check if helper script exists for the migration type
HELPER_SCRIPT="$SCRIPT_DIR/$MIGRATION_TYPE.sh"
if [ ! -f "$HELPER_SCRIPT" ]; then
    echo "Error: Helper script for '$MIGRATION_TYPE' not found at $HELPER_SCRIPT"
    exit 1
fi

# Execute the helper script
bash "$HELPER_SCRIPT" "$CONFIG_FILE"
if [ $? -ne 0 ]; then
    echo "Error: Migration '$MIGRATION_TYPE' failed"
    exit 1
fi

echo "Migration '$MIGRATION_TYPE' completed successfully"