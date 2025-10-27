#!/bin/bash
# DevOps Toolkit - Universal Setup Script
# Installs dockerz and u-cli tools via binaries (fallback for non-apt systems)

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/common.sh"

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

# Detect OS and architecture
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="darwin"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        OS="windows"
    else
        log_error "Unsupported OS: $OSTYPE"
        exit 1
    fi

    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        ARCH="amd64"
    elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
        ARCH="arm64"
    else
        log_error "Unsupported architecture: $ARCH"
        exit 1
    fi

    log_info "Detected OS: $OS, Architecture: $ARCH"
}

# Install Go if not present
install_go_if_needed() {
    if ! command -v go &> /dev/null; then
        log_info "Go not found. Installing Go..."
        bash "$SCRIPT_DIR/scripts/install-go.sh"
    else
        log_info "Go is already installed"
    fi
}

# Download and install tool
install_tool() {
    local tool_name=$1
    local version=$2
    local repo="addy-47/scripts"

    log_info "Installing $tool_name..."

    # Create temp directory
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    # Determine archive name
    local archive_name
    if [[ "$OS" == "windows" ]]; then
        archive_name="${tool_name}-${version}-${OS}-${ARCH}.zip"
    else
        archive_name="${tool_name}-${version}-${OS}-${ARCH}.tar.gz"
    fi

    # Download archive
    local download_url="https://github.com/$repo/releases/download/v$version/$archive_name"
    log_info "Downloading $download_url"

    if command -v curl &> /dev/null; then
        curl -L -o "$archive_name" "$download_url"
    elif command -v wget &> /dev/null; then
        wget -O "$archive_name" "$download_url"
    else
        log_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi

    # Extract archive
    if [[ "$OS" == "windows" ]]; then
        unzip "$archive_name"
    else
        tar -xzf "$archive_name"
    fi

    # Install binary
    local install_dir="/usr/local/bin"
    if [[ ! -w "$install_dir" ]]; then
        install_dir="$HOME/.local/bin"
        mkdir -p "$install_dir"
        export PATH="$install_dir:$PATH"
    fi

    chmod +x "$tool_name"
    mv "$tool_name" "$install_dir/"

    # Cleanup
    cd - > /dev/null
    rm -rf "$temp_dir"

    log_success "$tool_name installed successfully"
}

# Verify installation
verify_installation() {
    local tool_name=$1

    if command -v "$tool_name" &> /dev/null; then
        local version=$("$tool_name" --version 2>/dev/null || echo "unknown")
        log_success "$tool_name is working (version: $version)"
    else
        log_error "$tool_name installation failed"
        exit 1
    fi
}

# Main installation function
main() {
    log_info "Starting DevOps Toolkit installation..."

    # Detect OS and architecture
    detect_os

    # Install Go if needed
    install_go_if_needed

    # Install tools
    install_tool "dockerz" "2.0"
    install_tool "u-cli" "1.0"

    # Verify installations
    log_info "Verifying installations..."
    verify_installation "dockerz"
    verify_installation "u-cli"

    log_success "DevOps Toolkit installation completed!"
    log_info "You can now use 'dockerz' and 'u-cli' commands."
    log_info "Run 'dockerz --help' or 'u-cli --help' to get started."
}

# Run main function
main "$@"