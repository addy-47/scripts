#!/bin/bash
# Dockerz Installation Script
# Adds custom apt repository and installs dockerz (Debian/Ubuntu)
# Falls back to binary installation for other systems

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../scripts/common.sh"

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

    # Download and add GPG key
    curl -fsSL "$repo_key" | sudo gpg --dearmor -o /usr/share/keyrings/devops-toolkit.gpg

    # Update package list
    sudo apt update

    log_success "Apt repository added successfully"
}

# Install via apt
install_via_apt() {
    log_info "Installing dockerz via apt..."

    # Install dockerz
    sudo apt install -y dockerz

    log_success "dockerz installed via apt"
}

# Install via binary (fallback)
install_via_binary() {
    log_info "Installing dockerz via binary (fallback method)..."

    # Source the main setup script for binary installation
    bash "$SCRIPT_DIR/../setup.sh"
}

# Main installation function
main() {
    log_info "Starting dockerz installation..."

    if is_debian_based; then
        log_info "Detected Debian/Ubuntu system. Using apt installation."

        # Check if repository is already added
        if [[ ! -f /etc/apt/sources.list.d/devops-toolkit.list ]]; then
            add_apt_repo
        else
            log_info "Apt repository already configured"
        fi

        # Install dockerz
        install_via_apt
    else
        log_info "Non-Debian system detected. Using binary installation."
        install_via_binary
    fi

    # Verify installation
    if command -v dockerz &> /dev/null; then
        local version=$(dockerz --version 2>/dev/null || echo "unknown")
        log_success "dockerz installation completed (version: $version)"
        log_info "Run 'dockerz --help' to get started"
    else
        log_error "dockerz installation failed"
        exit 1
    fi
}

# Run main function
main "$@"