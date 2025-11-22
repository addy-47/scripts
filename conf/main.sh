#!/bin/bash
# ==================================================================
# INTERACTIVE MAIN SETUP SCRIPT
# This script provides an interactive menu to choose different setup options
# with comprehensive validation checks and error handling.
# ==================================================================

# Enable debugging temporarily for troubleshooting
set -euo pipefail  # Exit on errors, undefined variables, and pipe failures

# --- Helper Functions ---
print_banner() {
    echo -e "\n\033[1;36m======= $1 =======\033[0m"
}

print_error() {
    echo -e "\033[31m[ERROR]\033[0m $1" >&2
}

print_success() {
    echo -e "\033[32m[SUCCESS]\033[0m $1"
}

print_warning() {
    echo -e "\033[33m[WARNING]\033[0m $1"
}

print_info() {
    echo -e "\033[34m[INFO]\033[0m $1"
}

print_debug() {
    echo -e "\033[35m[DEBUG]\033[0m $1"
}

# Validation check functions
validate_script_exists() {
    local script_path="$1"
    if [ ! -f "$script_path" ]; then
        print_error "Script not found: $script_path"
        return 1
    fi
    if [ ! -r "$script_path" ]; then
        print_error "Script not readable: $script_path"
        return 1
    fi
    return 0
}

validate_command_exists() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        print_error "Required command not found: $cmd"
        return 1
    fi
    return 0
}

# Get the directory of the currently executing script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Check if required scripts exist
validate_script_exists "$SCRIPT_DIR/system.sh" || exit 1
validate_script_exists "$SCRIPT_DIR/terminal.sh" || exit 1

# Source theme libraries with error handling
print_info "Loading theme libraries..."

if [ ! -f "$SCRIPT_DIR/system.sh" ]; then
    print_error "system.sh not found at $SCRIPT_DIR/system.sh"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/terminal.sh" ]; then
    print_error "terminal.sh not found at $SCRIPT_DIR/terminal.sh"
    exit 1
fi

# Source theme libraries directly to avoid permission issues
print_info "Loading theme libraries..."

# Source system.sh with error handling
if ! source "$SCRIPT_DIR/system.sh" 2>/dev/null; then
    print_error "Failed to source system.sh"
    print_warning "Continuing without system theme functions..."
else
    print_info "System theme library loaded successfully."
fi

# Source terminal.sh with error handling
if ! source "$SCRIPT_DIR/terminal.sh" 2>/dev/null; then
    print_error "Failed to source terminal.sh"
    print_warning "Continuing without terminal theme functions..."
else
    print_info "Terminal theme library loaded successfully."
fi

# Verify theme functions are available (move to main function)
print_info "Theme libraries loaded successfully."

# Theme selection function with better error handling
select_theme() {
    print_banner "Theme Selection"
    
    # Check if wallpaper files exist
    local available_themes=()
    
    [ -f "$SCRIPT_DIR/wallpapers/red.png" ] && available_themes+=("addy-red" "Red Theme")
    [ -f "$SCRIPT_DIR/wallpapers/green.png" ] && available_themes+=("addy-green" "Green Theme")
    [ -f "$SCRIPT_DIR/wallpapers/yellow.png" ] && available_themes+=("addy-yellow" "Yellow Theme")
    [ -f "$SCRIPT_DIR/wallpapers/grey.png" ] && available_themes+=("addy-grey" "Grey Theme")
    available_themes+=("Skip" "Skip theme application")
    
    if [ ${#available_themes[@]} -eq 2 ]; then
        print_warning "No theme wallpapers found. Please check wallpapers directory."
        return 1
    fi
    
    # Display available themes first
    echo -e "\033[1;33mAvailable themes:\033[0m"
    local theme_count=1
    for ((i=0; i<${#available_themes[@]}; i+=2)); do
        echo "  $theme_count) ${available_themes[i+1]}"
        ((theme_count++))
    done
    echo ""
    
    while true; do
        echo -n "Enter your choice (1-$((theme_count-1))): "
        read -r choice
        
        # Validate input is a number
        if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
            print_error "Please enter a valid number."
            continue
        fi
        
        local selected_index=$((choice-1))
        local theme_names=()
        
        # Build theme names array
        for ((i=0; i<${#available_themes[@]}; i+=2)); do
            theme_names+=("${available_themes[i]}")
        done
        
        if [ $selected_index -ge 0 ] && [ $selected_index -lt ${#theme_names[@]} ]; then
            local selected_theme="${theme_names[$selected_index]}"
            if [ "$selected_theme" != "Skip" ]; then
                print_info "Selected theme: $selected_theme"
                apply_theme "$selected_theme"
                return 0
            else
                print_info "Skipping theme application."
                return 0
            fi
        else
            print_error "Invalid option '$choice'. Please choose between 1 and $((theme_count-1))."
        fi
    done
}

# Apply theme function with comprehensive error handling
apply_theme() {
    local theme_name="$1"
    print_debug "Starting apply_theme with: $theme_name"
    
    if [ -z "$theme_name" ]; then
        print_error "No theme name provided to apply_theme function."
        return 1
    fi
    
    print_info "Applying theme: $theme_name"
    
    # Validate that required functions exist
    local required_functions=()
    case $theme_name in
        "addy-red")
            required_functions=("set_system_theme_red" 
            "set_terminal_theme_red" "set_tmux_theme_red")
            ;; 
        "addy-green")
            required_functions=("set_system_theme_green" "set_terminal_theme_green" "set_tmux_theme_green")
            ;; 
        "addy-yellow")
            required_functions=("set_system_theme_yellow" "set_terminal_theme_yellow" "set_tmux_theme_yellow")
            ;; 
        "addy-grey")
            required_functions=("set_system_theme_grey" 
            "set_terminal_theme_grey" "set_tmux_theme_grey")
            ;; 
        *)
            print_error "Unknown theme: $theme_name"
            return 1
            ;; 
    esac
    
    print_debug "Checking for required functions: ${required_functions[*]}"
    
    # Check if functions exist
    for func in "${required_functions[@]}"; do
        if ! declare -f "$func" &>/dev/null; then
            print_error "Required function '$func' not found. Theme functions may not be loaded properly."
            print_debug "Available functions: $(declare -F | cut -d' ' -f3 | grep theme)"
            return 1
        fi
    done
    
    print_debug "All required functions found. Starting theme application..."
    
    # Apply themes with error handling
    local system_success=false
    local terminal_success=false
    
    # Apply system theme
    print_info "Applying system theme..."
    case $theme_name in
        "addy-red")
            print_debug "Calling set_system_theme_red..."
            SYSTEM_LOG_FILE=$(mktemp /tmp/system_theme.XXXXXX)
            if set_system_theme_red 2>&1 | tee "$SYSTEM_LOG_FILE"; then
                system_success=true
                print_debug "System theme red succeeded"
            else
                print_warning "System theme application encountered issues, but continuing..."
                print_debug "System theme red failed. Check $SYSTEM_LOG_FILE"
                system_success=true  # Don't fail completely
            fi
            ;; 
        "addy-green")
            print_debug "Calling set_system_theme_green..."
            SYSTEM_LOG_FILE=$(mktemp /tmp/system_theme.XXXXXX)
            if set_system_theme_green 2>&1 | tee "$SYSTEM_LOG_FILE"; then
                system_success=true
                print_debug "System theme green succeeded"
            else
                print_warning "System theme application encountered issues, but continuing..."
                print_debug "System theme green failed. Check $SYSTEM_LOG_FILE"
                system_success=true
            fi
            ;; 
        "addy-grey")
            print_debug "Calling set_system_theme_grey..."
            SYSTEM_LOG_FILE=$(mktemp /tmp/system_theme.XXXXXX)
            if set_system_theme_grey 2>&1 | tee "$SYSTEM_LOG_FILE"; then
                system_success=true
                print_debug "System theme grey succeeded"
            else
                print_warning "System theme application encountered issues, but continuing..."
                print_debug "System theme grey failed. Check $SYSTEM_LOG_FILE"
                system_success=true
            fi
            ;; 
        "addy-yellow")
            print_debug "Calling set_system_theme_yellow..."
            SYSTEM_LOG_FILE=$(mktemp /tmp/system_theme.XXXXXX)
            if set_system_theme_yellow 2>&1 | tee "$SYSTEM_LOG_FILE"; then
                system_success=true
                print_debug "System theme yellow succeeded"
            else
                print_warning "System theme application encountered issues, but continuing..."
                print_debug "System theme yellow failed. Check $SYSTEM_LOG_FILE"
                system_success=true
            fi
            ;; 
    esac
    
    # Apply terminal theme
    print_info "Applying terminal theme..."
    case $theme_name in
        "addy-red")
            print_debug "Calling set_terminal_theme_red..."
            TERMINAL_LOG_FILE=$(mktemp /tmp/terminal_theme.XXXXXX)
            if set_terminal_theme_red 2>&1 | tee "$TERMINAL_LOG_FILE"; then
                terminal_success=true
                print_debug "Terminal theme red succeeded"
            else
                print_warning "Terminal theme application encountered issues."
                print_debug "Terminal theme red failed. Check $TERMINAL_LOG_FILE"
                terminal_success=false
            fi
            
            # Apply tmux theme
            print_info "Applying tmux colors for red theme..."
            if declare -f set_tmux_theme_red &>/dev/null; then
                if set_tmux_theme_red 2>/dev/null; then
                    print_debug "Tmux theme red applied successfully"
                else
                    print_warning "Tmux theme application encountered issues, but continuing..."
                fi
            else
                print_warning "set_tmux_theme_red function not found"
            fi
            ;; 
        "addy-green")
            print_debug "Calling set_terminal_theme_green..."
            TERMINAL_LOG_FILE=$(mktemp /tmp/terminal_theme.XXXXXX)
            if set_terminal_theme_green 2>&1 | tee "$TERMINAL_LOG_FILE"; then
                terminal_success=true
                print_debug "Terminal theme green succeeded"
            else
                print_warning "Terminal theme application encountered issues."
                print_debug "Terminal theme green failed. Check $TERMINAL_LOG_FILE"
                terminal_success=false
            fi
            
            # Apply tmux theme
            print_info "Applying tmux colors for green theme..."
            if declare -f set_tmux_theme_green &>/dev/null; then
                if set_tmux_theme_green 2>/dev/null; then
                    print_debug "Tmux theme green applied successfully"
                else
                    print_warning "Tmux theme application encountered issues, but continuing..."
                fi
            else
                print_warning "set_tmux_theme_green function not found"
            fi
            ;; 
        "addy-yellow")
            print_debug "Calling set_terminal_theme_yellow..."
            TERMINAL_LOG_FILE=$(mktemp /tmp/terminal_theme.XXXXXX)
            if set_terminal_theme_yellow 2>&1 | tee "$TERMINAL_LOG_FILE"; then
                terminal_success=true
                print_debug "Terminal theme yellow succeeded"
            else
                print_warning "Terminal theme application encountered issues."
                print_debug "Terminal theme yellow failed. Check $TERMINAL_LOG_FILE"
                terminal_success=false
            fi
            
            # Apply tmux theme
            print_info "Applying tmux colors for yellow theme..."
            if declare -f set_tmux_theme_yellow &>/dev/null; then
                if set_tmux_theme_yellow 2>/dev/null; then
                    print_debug "Tmux theme yellow applied successfully"
                else
                    print_warning "Tmux theme application encountered issues, but continuing..."
                fi
            else
                print_warning "set_tmux_theme_yellow function not found"
            fi
            ;; 
        "addy-grey")
            print_debug "Calling set_terminal_theme_grey..."
            TERMINAL_LOG_FILE=$(mktemp /tmp/terminal_theme.XXXXXX)
            if set_terminal_theme_grey 2>&1 | tee "$TERMINAL_LOG_FILE"; then
                terminal_success=true
                print_debug "Terminal theme grey succeeded"
            else
                print_warning "Terminal theme application encountered issues."
                print_debug "Terminal theme grey failed. Check $TERMINAL_LOG_FILE"
                terminal_success=false
            fi
            
            # Apply tmux theme
            print_info "Applying tmux colors for grey theme..."
            if declare -f set_tmux_theme_grey &>/dev/null; then
                if set_tmux_theme_grey 2>/dev/null; then
                    print_debug "Tmux theme grey applied successfully"
                else
                    print_warning "Tmux theme application encountered issues, but continuing..."
                fi
            else
                print_warning "set_tmux_theme_grey function not found"
            fi
            ;; 
    esac
    
    # Report results
    print_debug "System success: $system_success, Terminal success: $terminal_success"
    
    if [ "$terminal_success" = true ]; then
        print_success "${theme_name} theme applied successfully."
        return 0
    else
        print_warning "${theme_name} theme partially applied. Some components may need manual configuration."
        return 0  # Don't fail completely, as some parts may have worked
    fi
}

# Option 0: Run complete setup (default behavior)
run_complete_setup() {
    print_banner "Running Complete Setup"
    
    local scripts_to_run=(
        "install_packages.sh:Installing packages and dependencies"
        "setup_zsh.sh:Configuring Zsh shell"
        "setup_bash.sh:Configuring Bash shell"
        "setup_tmux.sh:Configuring Tmux"
        "setup_git.sh:Configuring Git"
        "lockscreen.sh:Applying lock screen theme"
    )
    
    for script_info in "${scripts_to_run[@]}"; do
        IFS=':' read -r script_name description <<< "$script_info"
        local script_path="$SCRIPT_DIR/$script_name"
        
        print_info "$description..."
        
        if ! validate_script_exists "$script_path"; then
            print_warning "Skipping $script_name - script not found"
            continue
        fi
        
        if bash "$script_path"; then
            print_success "$description completed."
        else
            print_error "$description failed. Continuing with next step..."
        fi
    done
    
    # Apply theme
    select_theme
    
    print_banner "Setup Complete"
    echo -e "\033[1;32m✅ ✅ ✅ ALL SETUP SCRIPTS FINISHED! ✅ ✅ ✅\033[0m"
    print_info "To complete the setup, please do the following:"
    echo "1. RESTART your computer for all changes (especially lock screen) to take effect."
    echo "2. Open tmux and press 'prefix + I' (usually Ctrl+a + I) to install the tmux plugins."
}

# Option 1: Install packages only
install_packages_only() {
    print_banner "Installing Packages Only"

    local script_path="$SCRIPT_DIR/install_packages.sh"

    if ! validate_script_exists "$script_path"; then
        print_error "install_packages.sh not found. Aborting."
        return 1
    fi

    print_info "Installing packages and dependencies..."
    if bash "$script_path"; then
        print_success "Package installation completed successfully."
    else
        print_error "Package installation failed."
        return 1
    fi
}

# Option 2: Install packages and setup tools
install_packages_and_tools() {
    print_banner "Installing Packages and Setup Tools"
    
    local script_path="$SCRIPT_DIR/install_packages.sh"
    
    if ! validate_script_exists "$script_path"; then
        print_error "install_packages.sh not found. Aborting."
        return 1
    fi
    
    print_info "Installing packages and dependencies..."
    if bash "$script_path"; then
        print_success "Package installation completed successfully."
    else
        print_error "Package installation failed."
        return 1
    fi
    
    # Setup tools
    local tools=(
        "setup_git.sh:Configuring Git"
        "setup_tmux.sh:Configuring Tmux"
    )
    
    for tool_info in "${tools[@]}"; do
        IFS=':' read -r tool_script description <<< "$tool_info"
        local tool_path="$SCRIPT_DIR/$tool_script"
        
        print_info "$description..."
        
        if validate_script_exists "$tool_path"; then
            if bash "$tool_path"; then
                print_success "$description completed."
            else
                print_warning "$description failed. Continuing..."
            fi
        else
            print_warning "Skipping $tool_script - not found"
        fi
    done
    
    print_success "Package and tool setup completed!"
}

# Option 3: Install packages and setup terminals
install_packages_and_terminals() {
    print_banner "Installing Packages and Setup Terminals"
    
    local script_path="$SCRIPT_DIR/install_packages.sh"
    
    if ! validate_script_exists "$script_path"; then
        print_error "install_packages.sh not found. Aborting."
        return 1
    fi
    
    print_info "Installing packages..."
    if bash "$script_path"; then
        print_success "Package installation completed successfully."
    else
        print_error "Package installation failed."
        return 1
    fi
    
    # Setup terminals
    local terminals=(
        "setup_zsh.sh:Configuring Zsh shell"
        "setup_bash.sh:Configuring Bash shell"
    )
    
    for terminal_info in "${terminals[@]}"; do
        IFS=':' read -r terminal_script description <<< "$terminal_info"
        local terminal_path="$SCRIPT_DIR/$terminal_script"
        
        print_info "$description..."
        
        if validate_script_exists "$terminal_path"; then
            if bash "$terminal_path"; then
                print_success "$description completed."
            else
                print_warning "$description failed. Continuing..."
            fi
        else
            print_warning "Skipping $terminal_script - not found"
        fi
    done
    
    print_success "Package and terminal setup completed!"
}

# Option 4: Apply themes only
apply_themes_only() {
    print_banner "Applying Themes Only"

    # Check if required commands are available
    local required_commands=("dconf" "glib-compile-resources" "gsettings")
    for cmd in "${required_commands[@]}"; do
        if ! which "$cmd" &> /dev/null; then
            print_error "Required command '$cmd' not found. Please run option 1 or 2 first to install packages."
            return 1
        fi
    done

    if select_theme; then
        print_success "Theme application completed!"
    else
        print_error "Theme application failed or was skipped."
        return 1
    fi
    
    # Apply lock screen theme
    local lockscreen_script="$SCRIPT_DIR/lockscreen.sh"
    if validate_script_exists "$lockscreen_script"; then
        print_info "Applying lock screen theme..."
        if bash "$lockscreen_script"; then
            print_success "Lock screen theme applied successfully."
        else
            print_warning "Lock screen theme application failed."
        fi
    else
        print_warning "lockscreen.sh not found. Skipping lock screen theme."
    fi
}

# Option 5: Save current theme
save_current_theme() {
    print_banner "Saving Current Theme"
    local script_path="$SCRIPT_DIR/save_theme.sh"
    if validate_script_exists "$script_path"; then
        if bash "$script_path"; then
            print_success "Current theme saved successfully."
        else
            print_error "Failed to save current theme."
        fi
    else
        print_warning "save_theme.sh not found."
    fi
}

# Option 6: Restore saved theme
restore_saved_theme() {
    print_banner "Restoring Saved Theme"
    local script_path="$SCRIPT_DIR/restore_theme.sh"
    if validate_script_exists "$script_path"; then
        if bash "$script_path"; then
            print_success "Saved theme restored successfully."
        else
            print_error "Failed to restore saved theme."
        fi
    else
        print_warning "restore_theme.sh not found."
    fi
}

# Main menu function
show_main_menu() {
    print_banner "Adhbhut System Setup - Interactive Menu"
    echo -e "\033[1;33mPlease select an option:\033[0m"
    echo ""
    echo "0) Run complete scripts (default)"
    echo "1) Install packages only"
    echo "2) Install packages and setup tools"
    echo "3) Install packages and setup terminals"
    echo "4) Apply themes only"
    echo "5) Save current theme"
    echo "6) Restore saved theme"
    echo "7) Exit"
    echo ""
}

# Main script logic
main() {
    # Set up logging
    LOG_FILE="$PWD/adhbhut_setup_$(date +%Y%m%d_%H%M%S).log"
    print_info "All output will be logged to: $LOG_FILE"
    exec > >(tee "$LOG_FILE") 2>&1

    # Set up signal handling for graceful exit
    trap 'echo -e "\n\033[33m[SIGNAL]\033[0m Script interrupted. Exiting..."; exit 130' INT TERM
    
    # Check if running in interactive terminal
    if [ ! -t 0 ] && [ $# -eq 0 ]; then
        print_error "This script must be run in an interactive terminal or with command line arguments."
        print_info "Usage: $0 [0-7] (for non-interactive mode)"
        exit 1
    fi
    
    # Validate required commands
    local required_commands=("bash" "git" "curl" "wget")
    for cmd in "${required_commands[@]}"; do
        if ! validate_command_exists "$cmd"; then
            print_error "Required command '$cmd' not found. Please install it first."
            exit 1
        fi
    done
    
    # Check if running in expected directory
    if [ ! -d "$SCRIPT_DIR/wallpapers" ]; then
        print_warning "Wallpapers directory not found. Theme functionality may be limited."
    fi
    
    while true; do
        show_main_menu
        
        if [ $# -eq 0 ]; then
            # Interactive mode
            echo -n "Enter your choice (0-7): "
            read -r choice
        else
            # Command line argument mode
            choice="$1"
        fi
        
        case $choice in
            0|"")
                print_info "Running complete setup..."
                run_complete_setup
                break
                ;; 
            1)
                install_packages_only
                break
                ;; 
            2)
                install_packages_and_tools
                break
                ;; 
            3)
                install_packages_and_terminals
                break
                ;; 
            4)
                apply_themes_only
                break
                ;; 
            5)
                save_current_theme
                break
                ;; 
            6)
                restore_saved_theme
                break
                ;; 
            7)
                print_info "Exiting setup script."
                exit 0
                ;; 
            *)
                print_error "Invalid option '$choice'. Please choose 0-7."
                if [ $# -eq 0 ]; then
                    echo ""
                    sleep 1
                    continue
                else
                    exit 1
                fi
                ;; 
        esac
    done
    
    print_banner "Setup Complete"
    print_success "All requested operations completed!"
}

# Run main function with all arguments
main "$@"