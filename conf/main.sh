#!/bin/bash
# ==================================================================
# MAIN SETUP SCRIPT
# This script orchestrates the entire machine setup by calling
# all configuration scripts in the correct order.
# ==================================================================

set -e # Exit immediately if a command exits with a non-zero status.

# --- Helper Functions ---
print_info() {
    echo -e "\n\033[1;35m======= $1 =======\033[0m"
}

# Get the directory of the currently executing script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# --- Main Execution Flow ---
print_info "Starting Full System Setup..."

print_info "Step 1: Installing Packages"
"$SCRIPT_DIR/install_packages.sh"

print_info "Step 2: Configuring Shells (Zsh, Bash)"
"$SCRIPT_DIR/setup_zsh.sh"
"$SCRIPT_DIR/setup_bash.sh"

print_info "Step 3: Configuring Tools (Tmux, Git)"
"$SCRIPT_DIR/setup_tmux.sh"
"$SCRIPT_DIR/setup_git.sh"

print_info "Step 4: Applying System-wide Desktop Theme"
"$SCRIPT_DIR/system.sh"

print_info "Step 5: Applying Terminal Theme"
"$SCRIPT_DIR/theme.sh"

print_info "Step 6: Applying Lock Screen Theme"
"$SCRIPT_DIR/lockscreen.sh"

echo -e "\n\033[1;32m✅ ✅ ✅ ALL SETUP SCRIPTS FINISHED! ✅ ✅ ✅\033[0m"
print_info "To complete the setup, please do the following:"
echo "1. RESTART your computer for all changes (especially lock screen) to take effect."
echo "2. Open tmux and press 'prefix + I' (usually Ctrl+a + I) to install the tmux plugins."