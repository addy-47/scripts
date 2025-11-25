#!/bin/bash
# Dockerz Installation Script
# Adds custom apt repository and installs dockerz (Debian/Ubuntu)
# Falls back to binary installation for other systems

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Try to source common.sh from local repository first, then from GitHub
COMMON_SH_AVAILABLE=false
if [[ -f "$SCRIPT_DIR/../../scripts/common.sh" ]]; then
    # Temporarily disable exit on error for the source command
    set +e
    source "$SCRIPT_DIR/../../scripts/common.sh"
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

# No need for conditional logging functions - they're defined above

# Check if running on Debian/Ubuntu
is_debian_based() {
    if [[ -f /etc/debian_version ]] || [[ -f /etc/os-release && $(grep -c "ID=ubuntu\|ID=debian" /etc/os-release) -gt 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Add custom apt repository
add_apt_repo() {
    log_info "Adding DevOps Toolkit apt repository..."

    # Repository details
    local repo_url="https://addy-47.github.io/scripts/install"
    local repo_key="https://addy-47.github.io/scripts/install/Release.gpg"
    local sources_list="/etc/apt/sources.list.d/devops-toolkit.list"

    # Add repository to sources.list.d
    echo "deb [signed-by=/usr/share/keyrings/devops-toolkit.gpg] $repo_url /" | sudo tee "$sources_list" > /dev/null

    # Download and add GPG key (with error handling)
    if curl -fsSL "$repo_key" | sudo gpg --dearmor -o /usr/share/keyrings/devops-toolkit.gpg 2>/dev/null; then
        log_info "GPG key added successfully"
    else
        log_warning "GPG key download failed, continuing without signature verification"
        # Remove the signed-by option if GPG key fails
        echo "deb $repo_url /" | sudo tee "$sources_list" > /dev/null
    fi

    # Update package list (with error handling)
    if sudo apt update 2>/dev/null; then
        log_success "Apt repository added successfully"
        return 0
    else
        log_warning "Apt repository update failed, will fallback to binary installation"
        return 1
    fi
}

# Install via apt
install_via_apt() {
    log_info "Installing dockerz via apt..."

    # Install dockerz
    if sudo apt install -y dockerz 2>/dev/null; then
        log_success "dockerz installed via apt"
        return 0
    else
        log_warning "Apt installation failed, will fallback to binary installation"
        return 1
    fi
}

# Install via binary (fallback)
install_via_binary() {
    log_info "Installing dockerz via binary (fallback method)..."

    # Source the main setup script for binary installation
    # Use absolute path to avoid resolution issues
    local setup_script="$SCRIPT_DIR/../../setup.sh"
    if [[ -f "$setup_script" ]]; then
        bash "$setup_script"
    else
        # Fallback: download and run from GitHub if local script not found
        log_info "Local setup script not found, downloading from GitHub..."
        curl -fsSL "https://raw.githubusercontent.com/addy-47/scripts/install/setup.sh" | bash
    fi
}

# Main installation function
main() {
    log_info "Starting dockerz installation..."

    if is_debian_based; then
        log_info "Detected Debian/Ubuntu system. Using apt installation."

        # Check if repository is already added
        if [[ ! -f /etc/apt/sources.list.d/devops-toolkit.list ]]; then
            if ! add_apt_repo; then
                log_info "Repository setup failed, using binary installation instead"
                install_via_binary
            else
                # Repository setup successful, try apt installation
                if ! install_via_apt; then
                    log_info "Apt installation failed, using binary installation instead"
                    install_via_binary
                fi
            fi
        else
            log_info "Apt repository already configured"
            # Try apt installation, fallback to binary if it fails
            if ! install_via_apt; then
                log_info "Apt installation failed, using binary installation instead"
                install_via_binary
            fi
        fi
    else
        log_info "Non-Debian system detected. Using binary installation."
        install_via_binary
    fi

    # Verify installation
    if command -v dockerz &> /dev/null; then
        local version=$(dockerz --version 2>/dev/null || echo "unknown")
        log_success "dockerz installation completed (version: $version)"
        log_info "Run 'dockerz --help' to get started"
        log_info "Installation location: $(command -v dockerz)"
    else
        log_error "dockerz installation failed"
        exit 1
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