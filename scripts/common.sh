#!/bin/bash
# Common functions and utilities for DevOps Toolkit installation scripts

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if running as root
is_root() {
    [[ $EUID -eq 0 ]]
}

# Get OS information
get_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "darwin"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# Get architecture
get_arch() {
    local arch=$(uname -m)
    case $arch in
        x86_64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            echo "$arch"
            ;;
    esac
}

# Check if Debian/Ubuntu based
is_debian_based() {
    [[ -f /etc/debian_version ]] || [[ -f /etc/os-release && $(grep -c "ID=ubuntu\|ID=debian" /etc/os-release) -gt 0 ]]
}

# Download file with fallback
download_file() {
    local url=$1
    local output=$2

    if command_exists curl; then
        curl -L -o "$output" "$url"
    elif command_exists wget; then
        wget -O "$output" "$url"
    else
        log_error "Neither curl nor wget found. Please install one of them."
        return 1
    fi
}

# Create directory if it doesn't exist
ensure_dir() {
    local dir=$1
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
    fi
}

# Check if file is executable, make it if not
ensure_executable() {
    local file=$1
    if [[ -f "$file" && ! -x "$file" ]]; then
        chmod +x "$file"
    fi
}

# Get absolute path
get_absolute_path() {
    local path=$1
    if [[ -d "$path" ]]; then
        (cd "$path" && pwd)
    else
        echo "$(cd "$(dirname "$path")" && pwd)/$(basename "$path")"
    fi
}

# Validate checksum
validate_checksum() {
    local file=$1
    local expected_checksum=$2
    local algorithm=${3:-sha256}

    if [[ ! -f "$file" ]]; then
        log_error "File $file does not exist"
        return 1
    fi

    local actual_checksum
    case $algorithm in
        sha256)
            actual_checksum=$(sha256sum "$file" | cut -d' ' -f1)
            ;;
        md5)
            actual_checksum=$(md5sum "$file" | cut -d' ' -f1)
            ;;
        *)
            log_error "Unsupported checksum algorithm: $algorithm"
            return 1
            ;;
    esac

    if [[ "$actual_checksum" != "$expected_checksum" ]]; then
        log_error "Checksum validation failed for $file"
        log_error "Expected: $expected_checksum"
        log_error "Actual: $actual_checksum"
        return 1
    fi

    log_success "Checksum validation passed for $file"
}

# Clean up function for trap
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Script failed with exit code $exit_code"
    fi
    # Add cleanup logic here if needed
}

# Set up cleanup trap
trap cleanup EXIT