#!/bin/bash
# DevOps Toolkit - CI/CD Installation Script
# No sudo required, installs to user-space directories
# Designed for CI/CD environments and automated installations

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Try to source common.sh from local repository first, then from GitHub
COMMON_SH_AVAILABLE=false
if [[ -f "$SCRIPT_DIR/scripts/common.sh" ]]; then
    # Temporarily disable exit on error for the source command
    set +e
    source "$SCRIPT_DIR/scripts/common.sh"
    SOURCE_RESULT=$?
    set -e
    
    if [[ $SOURCE_RESULT -eq 0 ]]; then
        COMMON_SH_AVAILABLE=true
        log_info "Loaded common functions from local repository"
    fi
fi

# If common.sh was not available locally, download it from GitHub
if [[ "$COMMON_SH_AVAILABLE" == "false" ]]; then
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
    
    if [[ -f "$TEMP_COMMON_SH" ]]; then
        source "$TEMP_COMMON_SH"
        log_info "Loaded common functions from GitHub"
    else
        log_error "Failed to download common functions"
        exit 1
    fi
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

# Install Go if not present (user-space)
install_go_if_needed() {
    if ! command -v go &> /dev/null; then
        log_info "Go not found. Installing Go to user-space..."
        bash "$SCRIPT_DIR/scripts/install-go.sh"
    else
        log_info "Go is already installed"
    fi
}

# Download and install tool to user-space
install_tool() {
    local tool_name=$1
    local version=$2
    local repo="addy-47/scripts"

    log_info "Installing $tool_name v$version (CI/CD mode)..."

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

    # Install to user-space (no sudo required)
    local install_dir="$HOME/.local/bin"
    mkdir -p "$install_dir"
    
    # Export PATH for this session and future sessions
    export PATH="$install_dir:$PATH"
    echo "export PATH=\"$install_dir:\$PATH\"" >> "$HOME/.bashrc"
    
    chmod +x "$tool_name"
    mv "$tool_name" "$install_dir/"

    # Cleanup
    cd - > /dev/null
    rm -rf "$temp_dir"

    log_success "$tool_name installed successfully to $install_dir"
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
        echo "DevOps Toolkit CI/CD Installation Script"
        echo "========================================="
        echo ""
        echo "This script installs dockerz (CI/CD tool) without requiring sudo."
        echo "Designed for CI/CD environments and automated installations."
        echo "Installs to ~/.local/bin and updates PATH automatically."
        echo ""
        echo "Note: u-cli is a development tool and not installed in CI/CD mode."
        echo "      For development machines, use the standard installation method."
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h    Show this help message"
        echo "  --dry-run     Show what would be installed without actually installing"
        echo ""
        echo "Examples:"
        echo "  $0              # Install dockerz (CI/CD mode)"
        echo "  $0 --dry-run    # Show installation plan"
        echo "  $0 --help       # Show this help"
        return 0
    fi

    # Dry run mode
    if [[ "${1:-}" == "--dry-run" ]]; then
        log_info "DRY RUN MODE - No actual installation will be performed"
        log_info "=================================================="
    fi

    log_info "Starting DevOps Toolkit CI/CD installation..."
    log_info "Installing to user-space directories (no sudo required)"

    # Detect OS and architecture
    detect_os

    # Install Go if needed
    if [[ "${1:-}" != "--dry-run" ]]; then
        install_go_if_needed
    else
        log_info "[DRY RUN] Would install Go if needed"
    fi

    # Install tools (dockerz is CI/CD focused tool, u-cli is for development)
    if [[ "${1:-}" != "--dry-run" ]]; then
        install_tool "dockerz" "2.5.0"
        log_info "Note: u-cli is a development tool, not installed in CI/CD mode"
        log_info "For development machines, use the standard installation method"
    else
        log_info "[DRY RUN] Would install dockerz v2.5.0 (CI/CD tool)"
        log_info "[DRY RUN] u-cli would NOT be installed (development tool only)"
    fi

    # Verify installations
    if [[ "${1:-}" != "--dry-run" ]]; then
        log_info "Verifying installations..."
        verify_installation "dockerz"

        log_success "DevOps Toolkit CI/CD installation completed!"
        log_info "dockerz installed to: $HOME/.local/bin"
        log_info "PATH updated in: $HOME/.bashrc"
        log_info "You can now use 'dockerz' commands in CI/CD pipelines."
        log_info "For development tools like u-cli, use the standard installation method."
        log_info "Run 'dockerz --help' to get started."
    else
        log_info "[DRY RUN] Would verify dockerz installation"
        log_info "[DRY RUN] CI/CD installation simulation completed"
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