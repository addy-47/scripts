#!/bin/bash
# Dockerz Uninstallation Script
# Removes dockerz and optionally the custom apt repository

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
    log_info "Uninstalling dockerz via apt..."

    # Remove dockerz package
    sudo apt remove -y dockerz

    # Remove configuration files
    sudo apt purge -y dockerz

    log_success "dockerz uninstalled via apt"
}

# Remove via binary
uninstall_via_binary() {
    log_info "Uninstalling dockerz binary..."

    # Remove from common installation paths
    sudo rm -f /usr/local/bin/dockerz
    rm -f "$HOME/.local/bin/dockerz"

    log_success "dockerz binary removed"
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
    log_info "Starting dockerz uninstallation..."

    # Check if dockerz is installed
    if ! command -v dockerz &> /dev/null; then
        log_warning "dockerz is not installed"
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
    if ! command -v dockerz &> /dev/null; then
        log_success "dockerz uninstallation completed"
    else
        log_error "dockerz uninstallation may have failed"
        exit 1
    fi
}

# Run main function
main "$@"