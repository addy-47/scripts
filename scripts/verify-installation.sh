#!/bin/bash
# Post-installation verification script for DevOps Toolkit

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Tools to verify
TOOLS=("dockerz" "u-cli")

# Verify tool installation
verify_tool() {
    local tool=$1
    local expected_version=${2:-}

    log_info "Verifying $tool installation..."

    # Check if tool exists
    if ! command_exists "$tool"; then
        log_error "$tool is not installed or not in PATH"
        return 1
    fi

    # Try to get version
    local version_output
    if version_output=$("$tool" --version 2>/dev/null); then
        local version=$(echo "$version_output" | head -n1 | awk '{print $NF}')
        log_success "$tool is installed (version: $version)"

        # Check version if expected version provided
        if [[ -n "$expected_version" && "$version" != *"$expected_version"* ]]; then
            log_warning "Version mismatch. Expected: $expected_version, Got: $version"
        fi
    else
        log_success "$tool is installed (version info not available)"
    fi

    # Basic functionality test
    if "$tool" --help >/dev/null 2>&1; then
        log_success "$tool basic functionality test passed"
    else
        log_warning "$tool --help command failed"
    fi
}

# Verify system dependencies
verify_dependencies() {
    log_info "Verifying system dependencies..."

    local deps=("python3" "docker" "git")
    local missing_deps=()

    for dep in "${deps[@]}"; do
        if command_exists "$dep"; then
            local version=$("$dep" --version 2>/dev/null | head -n1 || echo "unknown")
            log_success "$dep is available ($version)"
        else
            log_warning "$dep is not available"
            missing_deps+=("$dep")
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_warning "Missing dependencies: ${missing_deps[*]}"
        log_info "Some features may not work without these dependencies"
    fi
}

# Verify Go installation (if needed)
verify_go() {
    if command_exists go; then
        local version=$(go version | awk '{print $3}' | sed 's/go//')
        log_success "Go is available (version: $version)"
    else
        log_info "Go is not installed (some tools may require it)"
    fi
}

# Check PATH configuration
verify_path() {
    log_info "Verifying PATH configuration..."

    local common_paths=("/usr/local/bin" "/usr/local/go/bin" "$HOME/.local/bin" "$HOME/go/bin")
    local path_issues=()

    for path_dir in "${common_paths[@]}"; do
        if [[ ":$PATH:" != *":$path_dir:"* ]]; then
            if [[ -d "$path_dir" ]]; then
                path_issues+=("$path_dir")
            fi
        fi
    done

    if [[ ${#path_issues[@]} -gt 0 ]]; then
        log_warning "PATH may not include: ${path_issues[*]}"
        log_info "Consider adding these to your PATH for better tool accessibility"
    else
        log_success "PATH configuration looks good"
    fi
}

# Generate installation report
generate_report() {
    local report_file="/tmp/devops-toolkit-verification-$(date +%Y%m%d-%H%M%S).txt"

    {
        echo "DevOps Toolkit Installation Verification Report"
        echo "Generated on: $(date)"
        echo "System: $(get_os) $(get_arch)"
        echo
        echo "=== Tool Verification ==="

        for tool in "${TOOLS[@]}"; do
            if command_exists "$tool"; then
                local version=$("$tool" --version 2>/dev/null | head -n1 || echo "unknown")
                echo "✓ $tool: $version"
            else
                echo "✗ $tool: NOT INSTALLED"
            fi
        done

        echo
        echo "=== System Dependencies ==="
        local deps=("python3" "docker" "git" "go")
        for dep in "${deps[@]}"; do
            if command_exists "$dep"; then
                echo "✓ $dep"
            else
                echo "✗ $dep"
            fi
        done

        echo
        echo "=== Recommendations ==="
        if ! command_exists dockerz; then
            echo "- Install dockerz: curl -fsSL https://raw.githubusercontent.com/addy-47/scripts/install/tools/dockerz/install.sh | bash"
        fi
        if ! command_exists u-cli; then
            echo "- Install u-cli: curl -fsSL https://raw.githubusercontent.com/addy-47/scripts/install/tools/u-cli/install.sh | bash"
        fi

    } > "$report_file"

    log_success "Verification report saved to: $report_file"
}

# Main function
main() {
    log_info "Starting DevOps Toolkit installation verification..."

    # Verify tools
    for tool in "${TOOLS[@]}"; do
        verify_tool "$tool"
    done

    echo

    # Verify system dependencies
    verify_dependencies

    echo

    # Verify Go
    verify_go

    echo

    # Verify PATH
    verify_path

    echo

    # Generate report
    generate_report

    log_success "Verification completed"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi