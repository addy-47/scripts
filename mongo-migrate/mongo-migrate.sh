#!/bin/bash

# Master script for MongoDB data migration
# Usage: mongo-migrate <migration-type> [config-file]
# Example: mongo-migrate vm-vm [~/mongo-migrate.conf]

set -euo pipefail

# Global variables
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
MIGRATION_LOG=""
START_TIME=$(date +%Y%m%d_%H%M%S)

# Cleanup function
cleanup() {
    if [ -n "${MIGRATION_LOG:-}" ] && [ -f "$MIGRATION_LOG" ]; then
        echo "Migration log saved to: $MIGRATION_LOG"
    fi
}

# Set trap for cleanup
trap cleanup EXIT INT TERM

# Function to display usage
usage() {
    cat << EOF
Usage: $0 <migration-type> [config-file]

Supported migration types:
  vm-vm   - VM to VM migration
  vm-ss   - VM to StatefulSet migration  
  ss-ss   - StatefulSet to StatefulSet migration

Options:
  config-file    Path to configuration file (default: ~/mongo-migrate.conf)

Examples:
  $0 vm-vm
  $0 vm-ss ~/my-config.conf
  $0 ss-ss /path/to/config.conf

Configuration file should contain variables like:
  SOURCE_MONGO_URI="mongodb://..."
  TARGET_MONGO_URI="mongodb://..."
  BACKUP_DIR="mongodb_backup"
  # ... and migration-type-specific variables

For more details, check the documentation or example config files.
EOF
    exit 1
}

# Function to log messages with timestamp
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$MIGRATION_LOG"
}

# Function to log error and exit
log_error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] ERROR: $message" | tee -a "$MIGRATION_LOG" >&2
    exit 1
}

# Check if migration type is provided
if [ $# -eq 0 ]; then
    usage
fi

MIGRATION_TYPE="$1"
CONFIG_FILE="${2:-$HOME/mongo-migrate.conf}"

# Set up migration log file
MIGRATION_LOG="migration_${MIGRATION_TYPE}_${START_TIME}.log"
log "Starting MongoDB migration: $MIGRATION_TYPE"
log "Using config file: $CONFIG_FILE"

# Validate migration type
case "$MIGRATION_TYPE" in
    vm-vm|vm-ss|ss-ss)
        log "Migration type '$MIGRATION_TYPE' is supported"
        ;;
    *)
        log_error "Unsupported migration type '$MIGRATION_TYPE'"
        ;;
esac

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    log_error "Config file '$CONFIG_FILE' not found"
fi

# Source the config file
log "Loading configuration..."
if ! source "$CONFIG_FILE"; then
    log_error "Failed to source config file '$CONFIG_FILE'"
fi

# Basic config validation
log "Validating basic configuration..."
basic_required_vars=("SOURCE_MONGO_URI" "TARGET_MONGO_URI" "BACKUP_DIR")
for var in "${basic_required_vars[@]}"; do
    if [ -z "${!var:-}" ]; then
        log_error "Required config variable '$var' is not set in $CONFIG_FILE"
    fi
done

# Migration-type-specific validation
log "Validating migration-type-specific configuration..."
case "$MIGRATION_TYPE" in
    vm-vm)
        vm_vm_vars=("SOURCE_VM_IP" "SOURCE_VM_USER" "TARGET_VM_IP" "TARGET_VM_USER" "TARGET_DOCKER_CONTAINER")
        for var in "${vm_vm_vars[@]}"; do
            if [ -z "${!var:-}" ]; then
                log_error "Required variable '$var' for vm-vm migration is not set in $CONFIG_FILE"
            fi
        done
        ;;
    vm-ss)
        vm_ss_vars=("SOURCE_VM_IP" "SOURCE_VM_USER" "TARGET_K8S_CONTEXT" "TARGET_K8S_NAMESPACE" "TARGET_K8S_POD")
        for var in "${vm_ss_vars[@]}"; do
            if [ -z "${!var:-}" ]; then
                log_error "Required variable '$var' for vm-ss migration is not set in $CONFIG_FILE"
            fi
        done
        ;;
    ss-ss)
        ss_ss_vars=("SOURCE_K8S_CONTEXT" "SOURCE_K8S_NAMESPACE" "SOURCE_K8S_POD" "TARGET_K8S_CONTEXT" "TARGET_K8S_NAMESPACE" "TARGET_K8S_POD")
        for var in "${ss_ss_vars[@]}"; do
            if [ -z "${!var:-}" ]; then
                log_error "Required variable '$var' for ss-ss migration is not set in $CONFIG_FILE"
            fi
        done
        ;;
esac

# Check prerequisites based on migration type
log "Checking prerequisites..."

# Common tools
if ! command -v mongodump >/dev/null 2>&1; then
    log_error "mongodump not found. Please install MongoDB database tools"
fi

if ! command -v mongorestore >/dev/null 2>&1; then
    log_error "mongorestore not found. Please install MongoDB database tools"
fi

# Migration-type-specific tools
case "$MIGRATION_TYPE" in
    vm-vm|vm-ss)
        if ! command -v ssh >/dev/null 2>&1; then
            log_error "ssh not found. Required for VM migrations"
        fi
        if ! command -v scp >/dev/null 2>&1; then
            log_error "scp not found. Required for VM migrations"
        fi
        ;;
    vm-ss|ss-ss)
        if ! command -v kubectl >/dev/null 2>&1; then
            log_error "kubectl not found. Required for Kubernetes migrations"
        fi
        if ! command -v kubectx >/dev/null 2>&1; then
            log_error "kubectx not found. Required for Kubernetes context switching"
        fi
        ;;
esac

# Additional validation for Docker (vm-vm)
if [ "$MIGRATION_TYPE" = "vm-vm" ]; then
    log "Checking target Docker container..."
    if ! ssh "${TARGET_VM_USER}@${TARGET_VM_IP}" "docker ps --format 'table {{.Names}}' | grep -q '^${TARGET_DOCKER_CONTAINER}$'" 2>/dev/null; then
        log_error "Docker container '${TARGET_DOCKER_CONTAINER}' not found or not running on target VM"
    fi
fi

# Test MongoDB connectivity
log "Testing MongoDB connectivity..."
if ! mongosh "$SOURCE_MONGO_URI" --eval 'db.adminCommand("ping")' --quiet 2>/dev/null; then
    log_error "Cannot connect to source MongoDB at: $SOURCE_MONGO_URI"
fi

log "Source MongoDB connection successful"

# Check if helper script exists
MIGRATIONS_DIR="$SCRIPT_DIR/migrations"
HELPER_SCRIPT="$MIGRATIONS_DIR/${MIGRATION_TYPE}.sh"

if [ ! -d "$MIGRATIONS_DIR" ]; then
    log_error "Migrations directory not found at: $MIGRATIONS_DIR"
fi

if [ ! -f "$HELPER_SCRIPT" ]; then
    log_error "Helper script for '$MIGRATION_TYPE' not found at: $HELPER_SCRIPT"
fi

if [ ! -x "$HELPER_SCRIPT" ]; then
    log_error "Helper script '$HELPER_SCRIPT' is not executable"
fi

# Display migration summary
log "Migration Summary:"
log "  Type: $MIGRATION_TYPE"
log "  Source: $SOURCE_MONGO_URI"
log "  Target: $TARGET_MONGO_URI"
log "  Backup Directory: $BACKUP_DIR"
case "$MIGRATION_TYPE" in
    vm-vm)
        log "  Source VM: ${SOURCE_VM_USER}@${SOURCE_VM_IP}"
        log "  Target VM: ${TARGET_VM_USER}@${TARGET_VM_IP}"
        log "  Target Container: ${TARGET_DOCKER_CONTAINER}"
        ;;
    vm-ss)
        log "  Source VM: ${SOURCE_VM_USER}@${SOURCE_VM_IP}"
        log "  Target K8s: ${TARGET_K8S_CONTEXT}/${TARGET_K8S_NAMESPACE}/${TARGET_K8S_POD}"
        ;;
    ss-ss)
        log "  Source K8s: ${SOURCE_K8S_CONTEXT}/${SOURCE_K8S_NAMESPACE}/${SOURCE_K8S_POD}"
        log "  Target K8s: ${TARGET_K8S_CONTEXT}/${TARGET_K8S_NAMESPACE}/${TARGET_K8S_POD}"
        ;;
esac

# Confirmation prompt (can be disabled with SKIP_CONFIRMATION=1)
if [ "${SKIP_CONFIRMATION:-0}" != "1" ]; then
    echo
    read -p "Proceed with migration? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Migration cancelled by user"
        exit 0
    fi
fi

# Execute the helper script
log "Executing migration script: $HELPER_SCRIPT"
log "=========================================="

# Create a temporary log file for the helper script
HELPER_LOG="helper_${MIGRATION_TYPE}_${START_TIME}.log"

if ! bash "$HELPER_SCRIPT" "$CONFIG_FILE" 2>&1 | tee "$HELPER_LOG"; then
    log ""
    log "----------------------------------------"
    log_error "Migration '$MIGRATION_TYPE' failed."
    log "Last 10 lines of the log:"
    tail -n 10 "$HELPER_LOG" | while IFS= read -r line; do log "  $line"; done
    log "Check the full log at $MIGRATION_LOG for more details."
    exit 1
fi

# Append helper script log to main log
log "=========================================="
log "Helper script output:"
cat "$HELPER_LOG" >> "$MIGRATION_LOG"
rm -f "$HELPER_LOG"

# Final verification
log "Performing final verification..."
if ! mongosh "$TARGET_MONGO_URI" --eval 'db.adminCommand("ping")' --quiet 2>/dev/null; then
    log_error "Final verification failed: Cannot connect to target MongoDB"
fi

log "Final verification successful"
log "Migration '$MIGRATION_TYPE' completed successfully"
log "Total duration: $(($(date +%s) - $(date -d "$START_TIME" +%s 2>/dev/null || echo 0))) seconds"