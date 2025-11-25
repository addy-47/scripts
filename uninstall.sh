#!/bin/bash
# DevOps Toolkit - Complete Uninstall Script
# Removes dockerz, u-cli, and all related configuration

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

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if running as root
is_root() {
    [[ $EUID -eq 0 ]]
}

# Remove binary installations
remove_binary_installations() {
    log_info "Removing binary installations..."
    
    local install_locations=(
        "/usr/local/bin/dockerz"
        "/usr/local/bin/u-cli"
        "$HOME/.local/bin/dockerz"
        "$HOME/.local/bin/u-cli"
    )
    
    for location in "${install_locations[@]}"; do
        if [[ -f "$location" ]]; then
            log_info "Removing $location"
            rm -f "$location"
        fi
    done
    
    # Remove from PATH in shell rc files
    if [[ -f "$HOME/.bashrc" ]]; then
        log_info "Cleaning PATH in .bashrc"
        sed -i '/\.local\/bin/d' "$HOME/.bashrc" 2>/dev/null || true
    fi
    
    if [[ -f "$HOME/.zshrc" ]]; then
        log_info "Cleaning PATH in .zshrc"
        sed -i '/\.local\/bin/d' "$HOME/.zshrc" 2>/dev/null || true
    fi
}

# Remove APT packages
remove_apt_packages() {
    log_info "Removing APT packages..."
    
    if command_exists apt; then
        apt remove -y dockerz u-cli 2>/dev/null || log_warning "APT packages not found or already removed"
    else
        log_warning "APT not available"
    fi
}

# Remove APT repository
remove_apt_repository() {
    log_info "Removing APT repository..."
    
    if is_root; then
        # Remove sources list
        if [[ -f "/etc/apt/sources.list.d/devops-toolkit.list" ]]; then
            rm -f "/etc/apt/sources.list.d/devops-toolkit.list"
            log_info "Removed APT sources list"
        fi
        
        # Remove GPG key
        if [[ -f "/usr/share/keyrings/devops-toolkit.gpg" ]]; then
            rm -f "/usr/share/keyrings/devops-toolkit.gpg"
            log_info "Removed GPG key"
        fi
        
        # Update package list
        if command_exists apt; then
            log_info "Updating package list..."
            apt update 2>/dev/null || log_warning "APT update failed"
        fi
    else
        log_warning "Not running as root, skipping APT repository removal"
        log_info "To remove APT repository, run: sudo bash $0"
    fi
}

# Clean up configuration files
cleanup_configs() {
    log_info "Cleaning up configuration files..."
    
    local config_dirs=(
        "$HOME/.config/dockerz"
        "$HOME/.dockerz"
        "/etc/dockerz"
    )
    
    for dir in "${config_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log_info "Removing $dir"
            rm -rf "$dir"
        fi
    done
}

# Verify removal
verify_removal() {
    log_info "Verifying removal..."
    
    local tools=("dockerz" "u-cli")
    local found_tools=()
    
    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            found_tools+=("$tool")
        fi
    done
    
    if [[ ${#found_tools[@]} -eq 0 ]]; then
        log_success "All tools have been successfully removed"
    else
        log_warning "Some tools still found: ${found_tools[*]}"
        log_info "You may need to restart your shell or manually remove remaining binaries"
    fi
}

# Show help
show_help() {
    echo "DevOps Toolkit - Complete Uninstall Script"
    echo "==========================================="
    echo ""
    echo "This script removes dockerz, u-cli, and all related configuration."
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --help, -h    Show this help message"
    echo "  --force       Skip confirmation prompts"
    echo "  --binary-only Only remove binary installations"
    echo "  --apt-only    Only remove APT packages and repository"
    echo ""
    echo "Examples:"
    echo "  $0                    # Full removal (interactive)"
    echo "  $0 --force            # Full removal (no prompts)"
    echo "  $0 --binary-only      # Remove only binaries"
    echo "  $0 --apt-only         # Remove only APT components"
    echo ""
    echo "Note: Some operations require sudo (APT repository removal)"
}

# Main function
main() {
    local force=false
    local binary_only=false
    local apt_only=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --force)
                force=true
                shift
                ;;
            --binary-only)
                binary_only=true
                shift
                ;;
            --apt-only)
                apt_only=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Show warning
    log_warning "This will completely remove dockerz, u-cli, and all configuration"
    
    if [[ "$force" != "true" ]]; then
        echo -n "Continue? (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Uninstall cancelled"
            exit 0
        fi
    fi
    
    log_info "Starting DevOps Toolkit uninstallation..."
    
    # Perform removals based on options
    if [[ "$apt_only" != "true" ]]; then
        remove_binary_installations
        cleanup_configs
    fi
    
    if [[ "$binary_only" != "true" ]]; then
        remove_apt_packages
        remove_apt_repository
    fi
    
    verify_removal
    
    log_success "DevOps Toolkit uninstallation completed!"
    
    if [[ "$force" != "true" ]]; then
        echo ""
        echo "Note: You may need to restart your shell or run 'source ~/.bashrc' for PATH changes to take effect."
    fi
}

# Run main function
main "$@"