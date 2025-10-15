#!/bin/bash

# scripts/apt/setup.sh - Addy Gupta's Debian/Ubuntu Repository Setup
# This script adds the addy-47/scripts repository to apt sources
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

# Check if running as root or with sudo
if [[ $EUID -eq 0 ]]; then
    print_warning "Running as root. This is not recommended for security reasons."
else
    print_status "Running with sudo privileges."
fi

# Detect OS and architecture
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    else
        print_error "Cannot detect OS. This script supports Debian and Ubuntu only."
        exit 1
    fi

    case $OS in
        ubuntu)
            print_status "Detected Ubuntu $VERSION"
            ;;
        debian)
            print_status "Detected Debian $VERSION"
            ;;
        *)
            print_error "Unsupported OS: $OS. This script supports Debian and Ubuntu only."
            exit 1
            ;;
    esac
}

# Install required packages
install_dependencies() {
    print_status "Installing required packages..."

    # Update package list
    apt-get update -qq

    # Install required packages
    apt-get install -y -qq \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    print_status "Dependencies installed successfully."
}

# Add repository GPG key
add_gpg_key() {
    print_status "Adding repository GPG key..."

    # Create keyring directory if it doesn't exist
    mkdir -p /usr/share/keyrings

    # Download and add GPG key
    curl -fsSL https://addy-47.github.io/scripts/apt/gpg | gpg --dearmor -o /usr/share/keyrings/addy-47-scripts.gpg

    print_status "GPG key added successfully."
}

# Add repository to sources.list.d
add_repository() {
    print_status "Adding repository to apt sources..."

    # Detect codename
    CODENAME=$(lsb_release -cs)

    # Create sources.list.d entry
    cat > /etc/apt/sources.list.d/addy-47-scripts.list << EOF
deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/addy-47-scripts.gpg] https://addy-47.github.io/scripts/apt $CODENAME main
EOF

    print_status "Repository added successfully."
}

# Update package list
update_package_list() {
    print_status "Updating package list..."
    apt-get update -qq
    print_status "Package list updated successfully."
}

# Main function
main() {
    print_status "Addy Gupta's Debian/Ubuntu Repository Setup"
    print_status "=========================================="

    detect_os
    install_dependencies
    add_gpg_key
    add_repository
    update_package_list

    print_status ""
    print_status "🎉 Repository setup completed successfully!"
    print_status ""
    print_status "You can now install packages with:"
    print_status "  sudo apt install <package-name>"
    print_status ""
    print_status "Available packages:"
        print_status "  - dockerz (Parallel Docker build tool)"
        print_status "  - u (Universal Linux undo command)"
        print_status ""
        print_status "Example:"
        print_status "  sudo apt install dockerz"
        print_status "  sudo apt install u"
}

# Run main function
main "$@"