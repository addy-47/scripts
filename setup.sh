#!/bin/bash
# DevOps Toolkit - Universal Setup Script
# Installs dockerz and u-cli tools via binaries (fallback for non-apt systems)

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Try to source common.sh from local repository first, then from GitHub
if [[ -f "$SCRIPT_DIR/scripts/common.sh" ]]; then
    source "$SCRIPT_DIR/scripts/common.sh"
    COMMON_SH_AVAILABLE=true
else
    # Download common.sh from GitHub if not available locally
    log_info "Downloading common functions from GitHub..."
    COMMON_SH_URL="https://raw.githubusercontent.com/addy-47/scripts/install/scripts/common.sh"
    TEMP_COMMON_SH=$(mktemp)
    if command_exists curl; then
        curl -fsSL "$COMMON_SH_URL" -o "$TEMP_COMMON_SH"
    elif command_exists wget; then
        wget -q "$COMMON_SH_URL" -O "$TEMP_COMMON_SH"
    else
        log_error "Neither curl nor wget found. Cannot download common functions."
        exit 1
    fi
    source "$TEMP_COMMON_SH"
    COMMON_SH_AVAILABLE=false
fi

# If common.sh was downloaded, we need to define logging functions here
if [[ "$COMMON_SH_AVAILABLE" == "false" ]]; then
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
fi

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
    # Show help if requested
    if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
        echo "DevOps Toolkit Universal Setup Script"
        echo "====================================="
        echo ""
        echo "This script installs dockerz and u-cli tools via binaries."
        echo "It detects your OS and architecture automatically."
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h    Show this help message"
        echo "  --dry-run     Show what would be installed without actually installing"
        echo ""
        echo "Examples:"
        echo "  $0              # Install both tools"
        echo "  $0 --dry-run    # Show installation plan"
        echo "  $0 --help       # Show this help"
        return 0
    fi

    # Dry run mode
    if [[ "${1:-}" == "--dry-run" ]]; then
        log_info "DRY RUN MODE - No actual installation will be performed"
        log_info "=================================================="
    fi

    log_info "Starting DevOps Toolkit installation..."

    # Detect OS and architecture
    detect_os

    # Install Go if needed
    if [[ "${1:-}" != "--dry-run" ]]; then
        install_go_if_needed
    else
        log_info "[DRY RUN] Would install Go if needed"
    fi

    # Install tools
    if [[ "${1:-}" != "--dry-run" ]]; then
        install_tool "dockerz" "2.0"
        install_tool "u-cli" "1.0"
    else
        log_info "[DRY RUN] Would install dockerz v2.0"
        log_info "[DRY RUN] Would install u-cli v1.0"
    fi

    # Verify installations
    if [[ "${1:-}" != "--dry-run" ]]; then
        log_info "Verifying installations..."
        verify_installation "dockerz"
        verify_installation "u-cli"

        log_success "DevOps Toolkit installation completed!"
        log_info "You can now use 'dockerz' and 'u-cli' commands."
        log_info "Run 'dockerz --help' or 'u-cli --help' to get started."
        log_info "Installation locations:"
        log_info "  dockerz: $(command -v dockerz 2>/dev/null || echo 'not found')"
        log_info "  u-cli: $(command -v u-cli 2>/dev/null || echo 'not found')"
    else
        log_info "[DRY RUN] Would verify dockerz and u-cli installations"
        log_info "[DRY RUN] Installation simulation completed"
    fi
}

# Cleanup function
cleanup() {
    # Remove temporary common.sh if it was downloaded
    if [[ "$COMMON_SH_AVAILABLE" == "false" && -n "$TEMP_COMMON_SH" && -f "$TEMP_COMMON_SH" ]]; then
        rm -f "$TEMP_COMMON_SH"
    fi
}

# Set up cleanup trap
trap cleanup EXIT

# Run main function
main "$@"