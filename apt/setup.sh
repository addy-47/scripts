#!/bin/bash

# scripts/apt/setup.sh - Simple Debian/Ubuntu Package Installer
# This script installs packages directly from .deb files
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to install a package
install_package() {
    local package_name=$1
    local deb_file=$2

    print_status "Installing $package_name..."

    # Download the deb file to a temporary location
    local temp_deb="/tmp/${deb_file}"

    if curl -fsSL "https://addy-47.github.io/scripts/apt/packages/${deb_file}" -o "$temp_deb"; then
        # Install the package
        if dpkg -i "$temp_deb"; then
            print_status "$package_name installed successfully!"
            # Clean up
            rm -f "$temp_deb"
        else
            print_error "Failed to install $package_name"
            rm -f "$temp_deb"
            exit 1
        fi
    else
        print_error "Failed to download $package_name"
        exit 1
    fi
}

# Main function
main() {
    print_status "Addy Gupta's Simple Package Installer"
    print_status "===================================="

    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi

    # Parse command line arguments
    if [[ $# -eq 0 ]]; then
        print_status ""
        print_status "Usage: $0 <package-name>"
        print_status ""
        print_status "Available packages:"
        print_status "  - dockerz (Parallel Docker build tool)"
        print_status "  - u-cli (Universal Linux undo command)"
        print_status ""
        print_status "Examples:"
        print_status "  sudo $0 dockerz"
        print_status "  sudo $0 u-cli"
        exit 0
    fi

    local package=$1

    case $package in
        dockerz)
            install_package "dockerz" "dockerz_1.0.4_all.deb"
            ;;
        u-cli)
            install_package "u-cli" "u-cli_1.0.0-1_amd64.deb"
            ;;
        *)
            print_error "Unknown package: $package"
            print_status "Available packages: dockerz, u-cli"
            exit 1
            ;;
    esac

    print_status ""
    print_status "🎉 Installation completed successfully!"
}

# Run main function
main "$@"