#!/bin/bash

# This is the main script to set up a new machine.
# It runs all the scripts in the conf/ directory in order.

# --- Helper Functions ---
print_info() {
    echo -e "\033[34m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[32m[SUCCESS]\033[0m $1"
}

print_warning() {
    echo -e "\033[33m[WARNING]\033[0m $1"
}


print_info "Starting setup..."

print_info "Running install_packages.sh..."
"./install_packages.sh"

print_info "Running setup_zsh.sh..."
"./setup_zsh.sh"

print_info "Running setup_bash.sh..."
"./setup_bash.sh"

print_info "Running setup_tmux.sh..."
"./setup_tmux.sh"

print_info "Running setup_git.sh..."
"./setup_git.sh"

print_info "Running setup_warp.sh..."
"./setup_warp.sh"

print_info "Running theme.sh..."
"./theme.sh"

# --- Final Instructions ---
echo ""
print_success "Setup script finished!"
print_info "To complete the setup, please do the following:"
print_info "1. Restart your terminal or run 'source ~/.zshrc' or 'source ~/.bashrc'."
print_info "2. Open tmux and press 'prefix + I' (Ctrl+a + I) to install the tmux plugins."
print_warning "Some configurations, like custom scripts, might need to be manually copied to the new machine."
print_warning "The script for 'gcloud-kubectl-switch.sh' and 'mongo-migrate.sh' will need to be copied to the appropriate paths."
