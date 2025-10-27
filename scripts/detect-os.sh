#!/bin/bash
# OS and architecture detection script

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Detect OS
detect_os() {
    local os
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        os="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        os="darwin"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        os="windows"
    else
        log_error "Unsupported OS: $OSTYPE"
        exit 1
    fi
    echo "$os"
}

# Detect architecture
detect_arch() {
    local arch=$(uname -m)
    case $arch in
        x86_64)
            arch="amd64"
            ;;
        aarch64|arm64)
            arch="arm64"
            ;;
        i386|i686)
            arch="386"
            ;;
        *)
            log_warning "Unknown architecture: $arch"
            ;;
    esac
    echo "$arch"
}

# Detect distribution (for Linux)
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "$ID"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    elif [[ -f /etc/redhat-release ]]; then
        echo "rhel"
    else
        echo "unknown"
    fi
}

# Check if running on Debian/Ubuntu
is_debian_based() {
    local distro=$(detect_distro)
    [[ "$distro" == "debian" ]] || [[ "$distro" == "ubuntu" ]] || [[ -f /etc/debian_version ]]
}

# Check if running on RHEL/CentOS/Fedora
is_rhel_based() {
    local distro=$(detect_distro)
    [[ "$distro" == "rhel" ]] || [[ "$distro" == "centos" ]] || [[ "$distro" == "fedora" ]]
}

# Get system information
get_system_info() {
    local os=$(detect_os)
    local arch=$(detect_arch)
    local distro=$(detect_distro)

    echo "OS: $os"
    echo "Architecture: $arch"
    echo "Distribution: $distro"
    echo "Debian-based: $(is_debian_based && echo "yes" || echo "no")"
    echo "RHEL-based: $(is_rhel_based && echo "yes" || echo "no")"
}

# Main function
main() {
    case "${1:-info}" in
        os)
            detect_os
            ;;
        arch)
            detect_arch
            ;;
        distro)
            detect_distro
            ;;
        debian)
            is_debian_based && echo "true" || echo "false"
            ;;
        rhel)
            is_rhel_based && echo "true" || echo "false"
            ;;
        info|*)
            get_system_info
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi