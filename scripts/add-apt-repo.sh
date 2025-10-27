#!/bin/bash
# Add custom apt repository script for DevOps Toolkit

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Repository configuration
REPO_URL="https://addy-47.github.io/scripts/install"
REPO_KEY_URL="${REPO_URL}/Release.gpg"
SOURCES_LIST="/etc/apt/sources.list.d/devops-toolkit.list"
KEYRING_PATH="/usr/share/keyrings/devops-toolkit.gpg"

# Add apt repository
add_repository() {
    log_info "Adding DevOps Toolkit apt repository"

    # Check if running as root
    if ! is_root; then
        log_error "This script must be run as root (sudo)"
        exit 1
    fi

    # Check if Debian/Ubuntu
    if ! is_debian_based; then
        log_error "This script is only for Debian/Ubuntu systems"
        exit 1
    fi

    # Check if repository already exists
    if [[ -f "$SOURCES_LIST" ]]; then
        log_warning "Repository already exists at $SOURCES_LIST"
        read -p "Overwrite existing repository? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Repository addition cancelled"
            return 0
        fi
    fi

    # Create keyring directory if it doesn't exist
    ensure_dir "/usr/share/keyrings"

    # Download GPG key
    log_info "Downloading GPG key from $REPO_KEY_URL"
    if ! download_file "$REPO_KEY_URL" "/tmp/devops-toolkit.gpg"; then
        log_error "Failed to download GPG key"
        exit 1
    fi

    # Add GPG key to keyring
    log_info "Adding GPG key to keyring"
    gpg --dearmor -o "$KEYRING_PATH" /tmp/devops-toolkit.gpg
    rm -f /tmp/devops-toolkit.gpg

    # Add repository to sources.list.d
    log_info "Adding repository to sources.list.d"
    cat > "$SOURCES_LIST" << EOF
deb [signed-by=$KEYRING_PATH] $REPO_URL /
EOF

    # Update package list
    log_info "Updating package list"
    apt update

    log_success "DevOps Toolkit repository added successfully"
    log_info "You can now install packages with: apt install dockerz u-cli"
}

# Remove apt repository
remove_repository() {
    log_info "Removing DevOps Toolkit apt repository"

    # Check if running as root
    if ! is_root; then
        log_error "This script must be run as root (sudo)"
        exit 1
    fi

    # Remove sources list
    if [[ -f "$SOURCES_LIST" ]]; then
        rm -f "$SOURCES_LIST"
        log_info "Removed sources list: $SOURCES_LIST"
    else
        log_warning "Sources list not found: $SOURCES_LIST"
    fi

    # Remove GPG key
    if [[ -f "$KEYRING_PATH" ]]; then
        rm -f "$KEYRING_PATH"
        log_info "Removed GPG key: $KEYRING_PATH"
    else
        log_warning "GPG key not found: $KEYRING_PATH"
    fi

    # Update package list
    log_info "Updating package list"
    apt update

    log_success "DevOps Toolkit repository removed successfully"
}

# Show repository status
show_status() {
    log_info "DevOps Toolkit repository status:"

    echo "Sources list: $([[ -f "$SOURCES_LIST" ]] && echo "Present" || echo "Not found")"
    echo "GPG Key: $([[ -f "$KEYRING_PATH" ]] && echo "Present" || echo "Not found")"
    echo "Repository URL: $REPO_URL"
    echo "Key URL: $REPO_KEY_URL"

    if [[ -f "$SOURCES_LIST" ]]; then
        echo
        echo "Sources list content:"
        cat "$SOURCES_LIST"
    fi
}

# Main function
main() {
    case "${1:-add}" in
        add)
            add_repository
            ;;
        remove|rm)
            remove_repository
            ;;
        status|info)
            show_status
            ;;
        *)
            log_error "Usage: $0 {add|remove|status}"
            log_info "  add    - Add the DevOps Toolkit repository"
            log_info "  remove - Remove the DevOps Toolkit repository"
            log_info "  status - Show repository status"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi