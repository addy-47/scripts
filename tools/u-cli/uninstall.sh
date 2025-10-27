#!/bin/bash
# U-CLI Uninstallation Script
# Removes u-cli and optionally the custom apt repository

set -e

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

# Remove via apt
uninstall_via_apt() {
    log_info "Uninstalling u-cli via apt..."

    # Remove u-cli package
    sudo apt remove -y u-cli

    # Remove configuration files
    sudo apt purge -y u-cli

    log_success "u-cli uninstalled via apt"
}

# Remove via binary
uninstall_via_binary() {
    log_info "Uninstalling u-cli binary..."

    # Remove from common installation paths
    sudo rm -f /usr/local/bin/u-cli
    rm -f "$HOME/.local/bin/u-cli"

    log_success "u-cli binary removed"
}

# Remove apt repository
remove_apt_repo() {
    log_info "Removing DevOps Toolkit apt repository..."

    # Remove sources list
    sudo rm -f /etc/apt/sources.list.d/devops-toolkit.list

    # Remove GPG key
    sudo rm -f /usr/share/keyrings/devops-toolkit.gpg

    # Update package list
    sudo apt update

    log_success "Apt repository removed"
}

# Main uninstallation function
main() {
    log_info "Starting u-cli uninstallation..."

    # Check if u-cli is installed
    if ! command -v u-cli &> /dev/null; then
        log_warning "u-cli is not installed"
        exit 0
    fi

    if is_debian_based && [[ -f /etc/apt/sources.list.d/devops-toolkit.list ]]; then
        log_info "Detected apt installation. Using apt removal."

        # Uninstall via apt
        uninstall_via_apt

        # Ask if user wants to remove repository
        echo
        read -p "Remove the DevOps Toolkit apt repository? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            remove_apt_repo
        fi
    else
        log_info "Detected binary installation. Using binary removal."
        uninstall_via_binary
    fi

    # Verify removal
    if ! command -v u-cli &> /dev/null; then
        log_success "u-cli uninstallation completed"
    else
        log_error "u-cli uninstallation may have failed"
        exit 1
    fi
}

# Run main function
main "$@"