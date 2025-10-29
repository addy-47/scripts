#!/bin/bash
# Go installation script for DevOps Toolkit

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Default Go version
DEFAULT_GO_VERSION="1.21.5"

# Install Go
install_go() {
    local version=${1:-$DEFAULT_GO_VERSION}
    local os=$(get_os)
    local arch=$(get_arch)

    if [[ "$os" == "unknown" ]]; then
        log_error "Unsupported OS for Go installation"
        return 1
    fi

    if [[ "$arch" == "unknown" ]]; then
        log_error "Unsupported architecture for Go installation"
        return 1
    fi

    log_info "Installing Go $version for $os/$arch"

    # Create temp directory
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    # Determine archive name
    local archive_name="go${version}.${os}-${arch}.tar.gz"
    local download_url="https://golang.org/dl/${archive_name}"

    # Download Go
    log_info "Downloading Go from $download_url"
    download_file "$download_url" "$archive_name"

    # Remove any existing Go installation
    sudo rm -rf /usr/local/go

    # Extract Go
    log_info "Extracting Go archive"
    sudo tar -C /usr/local -xzf "$archive_name"

    # Clean up
    cd - > /dev/null
    rm -rf "$temp_dir"

    # Add Go to PATH if not already there
    if ! grep -q "/usr/local/go/bin" ~/.bashrc 2>/dev/null; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        echo 'export GOPATH=$HOME/go' >> ~/.bashrc
        echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
    fi

    # Set PATH for current session
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=$HOME/go
    export PATH=$PATH:$GOPATH/bin

    log_success "Go $version installed successfully"
}

# Verify Go installation
verify_go() {
    if command_exists go; then
        local version=$(go version | awk '{print $3}' | sed 's/go//')
        log_success "Go is working (version: $version)"
        return 0
    else
        log_error "Go installation failed"
        return 1
    fi
}

# Main function
main() {
    local version=${1:-$DEFAULT_GO_VERSION}

    # Show help if requested
    if [[ "$version" == "--help" ]] || [[ "$version" == "-h" ]]; then
        echo "Go Installation Script for DevOps Toolkit"
        echo "========================================="
        echo ""
        echo "This script installs or upgrades Go programming language."
        echo ""
        echo "Usage: $0 [version]"
        echo ""
        echo "Arguments:"
        echo "  version    Go version to install (default: $DEFAULT_GO_VERSION)"
        echo ""
        echo "Examples:"
        echo "  $0                    # Install default version ($DEFAULT_GO_VERSION)"
        echo "  $0 1.22.0            # Install specific version"
        echo "  $0 --help             # Show this help"
        return 0
    fi

    # Check if Go is already installed
    if command_exists go; then
        local current_version=$(go version | awk '{print $3}' | sed 's/go//')
        log_info "Go is already installed (version: $current_version)"

        # Compare versions (simple comparison)
        if [[ "$current_version" == "$version" ]]; then
            log_info "Go version $version is already installed"
            verify_go
            exit 0
        else
            log_info "Upgrading Go from $current_version to $version"
        fi
    fi

    # Install Go
    install_go "$version"

    # Verify installation
    verify_go

    # Show Go environment
    log_info "Go environment:"
    go env GOPATH GOROOT
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi