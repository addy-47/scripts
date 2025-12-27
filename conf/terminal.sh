#!/bin/bash
# ===================================================================================
# Terminal Theme Library - CORRECTED
#
# This script is a collection of functions to apply color themes to GNOME Terminal.
# It is intended to be sourced by an orchestrator script like main.sh.
# ===================================================================================

_log_terminal() { echo -e "\n\e[1;36m➡️  $1\e[0m"; }

# -----------------------------------------------------------------------------------
# SECTION 1: HELPER FUNCTIONS
# -----------------------------------------------------------------------------------

# Converts a hex color code to an rgb(r,g,b) string
hex_to_rgb() {
    local hex=$(echo "$1" | sed 's/#//')
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    echo "rgb($r,$g,$b)"
}

# Applies a color palette and settings to a GNOME terminal profile (create if doesn't exist)
apply_terminal_theme() {
    local THEME_NAME=$1
    local PALETTE=$2
    local FG_COLOR=$3
    local BG_COLOR="'rgb(0,0,0)'"
    local BOLD_COLOR=$4

    # Check if profile already exists
    _log_terminal "Checking for existing terminal profile: $THEME_NAME"
    local PROFILE_ID=""
    
    # Get all profile IDs and find the one with matching name
    local PROFILES_LIST=$(dconf read /org/gnome/terminal/legacy/profiles:/list)
    if [[ "$PROFILES_LIST" != "[]" && "$PROFILES_LIST" != "@as []" ]]; then
        # Extract profile IDs
        echo "$PROFILES_LIST" | tr -d "[]'" | tr ',' '\n' | while read -r pid; do
            if [[ -n "$pid" ]]; then
                local profile_name=$(dconf read "/org/gnome/terminal/legacy/profiles:/:$pid/visible-name" 2>/dev/null | tr -d "'")
                if [[ "$profile_name" == "$THEME_NAME" ]]; then
                    PROFILE_ID="$pid"
                    break
                fi
            fi
        done
    fi
    
    if [[ -z "$PROFILE_ID" ]]; then
        # Create new profile if it doesn't exist
        _log_terminal "Creating new terminal profile: $THEME_NAME"
        PROFILE_ID=$(uuidgen)
        
        # Add new profile to list
        if [[ "$PROFILES_LIST" == "[]" || "$PROFILES_LIST" == "@as []" ]]; then
            dconf write /org/gnome/terminal/legacy/profiles:/list "['$PROFILE_ID']"
        else
            dconf write /org/gnome/terminal/legacy/profiles:/list "$PROFILES_LIST, '$PROFILE_ID'"
        fi
    else
        # Update existing profile
        _log_terminal "Updating existing terminal profile: $THEME_NAME"
    fi
    
    local PROFILE_PATH="/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID"

    # --- Apply THEME-SPECIFIC colors ---
    dconf write "$PROFILE_PATH/visible-name" "'$THEME_NAME'"
    dconf write "$PROFILE_PATH/palette" "$PALETTE"
    dconf write "$PROFILE_PATH/foreground-color" "$FG_COLOR"
    dconf write "$PROFILE_PATH/background-color" "$BG_COLOR"
    dconf write "$PROFILE_PATH/bold-color" "$BOLD_COLOR"

    # --- Apply COMMON settings from the 'addy' profile ---
    dconf write "$PROFILE_PATH/audible-bell" "true"
    dconf write "$PROFILE_PATH/background-transparency-percent" "46"
    dconf write "$PROFILE_PATH/bold-color-same-as-fg" "false"
    dconf write "$PROFILE_PATH/bold-is-bright" "false"
    dconf write "$PROFILE_PATH/cell-height-scale" "1.0"
    dconf write "$PROFILE_PATH/cell-width-scale" "1.0"
    dconf write "$PROFILE_PATH/cursor-background-color" "'rgb(255,255,255)'"
    dconf write "$PROFILE_PATH/cursor-blink-mode" "'on'"
    dconf write "$PROFILE_PATH/cursor-colors-set" "true"
    dconf write "$PROFILE_PATH/cursor-foreground-color" "'rgb(0,0,0)'"
    dconf write "$PROFILE_PATH/cursor-shape" "'ibeam'"
    dconf write "$PROFILE_PATH/font" "'Ubuntu Mono 14'"
    dconf write "$PROFILE_PATH/highlight-background-color" "'rgb(0,0,0)'"
    dconf write "$PROFILE_PATH/highlight-colors-set" "true"
    dconf write "$PROFILE_PATH/highlight-foreground-color" "'rgb(255,255,255)'"
    dconf write "$PROFILE_PATH/scroll-on-output" "true"
    dconf write "$PROFILE_PATH/use-system-font" "false"
    dconf write "$PROFILE_PATH/use-theme-colors" "false"
    dconf write "$PROFILE_PATH/use-theme-transparency" "false"
    dconf write "$PROFILE_PATH/use-transparent-background" "true"

    _log_terminal "Adding new profile to the list..."
    local PROFILES_LIST=$(dconf read /org/gnome/terminal/legacy/profiles:/list)
    
    if [[ "$PROFILES_LIST" == "[]" || "$PROFILES_LIST" == "@as []" ]]; then
        PROFILES_LIST="['$PROFILE_ID']"
    else
        PROFILES_LIST=$(echo "$PROFILES_LIST" | sed "s/]$/, '$PROFILE_ID']/")
    fi
    
    dconf write /org/gnome/terminal/legacy/profiles:/list "$PROFILES_LIST"
    
    _log_terminal "Setting '$THEME_NAME' as default profile."
    dconf write /org/gnome/terminal/legacy/profiles:/default "'$PROFILE_ID'"

    _log_terminal "✅ Terminal theme '$THEME_NAME' applied successfully."
}

# -----------------------------------------------------------------------------------
# SECTION 2: THEME DEFINITIONS
# -----------------------------------------------------------------------------------

set_terminal_theme_red() {
    local colors=('#1f1e1e' '#bcb4b9' '#cceef2' '#c484c1' '#87ceff' '#e9d1ed' '#a7b3f3' '#eee8d5' '#c38eca' '#adacb3' '#cf9bf1' '#dc96d5' '#efafaf' '#d8239a' '#764176' '#ff9acb')
    local PALETTE_ARRAY=()
    for color in "${colors[@]}"; do
        PALETTE_ARRAY+=("'$(hex_to_rgb "$color")'")
    done
    local PALETTE_STRING=$(IFS=,; echo "${PALETTE_ARRAY[*]}")
    local PALETTE="[$PALETTE_STRING]"

    local FG_COLOR="'$(hex_to_rgb "#E37E9E")'"
    local BOLD_COLOR="'$(hex_to_rgb "#7f6b79")'"
    apply_terminal_theme "addy-red" "$PALETTE" "$FG_COLOR" "$BOLD_COLOR"
    
    # Set as default and restart terminal safely
    set_default_profile_by_name "addy-red"
    restart_gnome_terminal
    
    # Apply tmux colors for red theme
    apply_tmux_theme "red"
}

set_terminal_theme_green() {
    local colors=('#000000' '#879993' '#d1d1d1' '#b9a8c8' '#a570d2' '#54a4a7' '#27b78e' '#eee8d5' '#73b0c0' '#b0bbb6' '#597f8b' '#657b83' '#839496' '#d8239a' '#93a1a1' '#fdf6e3')
    local PALETTE_ARRAY=()
    for color in "${colors[@]}"; do
        PALETTE_ARRAY+=("'$(hex_to_rgb "$color")'")
    done
    local PALETTE_STRING=$(IFS=,; echo "${PALETTE_ARRAY[*]}")
    local PALETTE="[$PALETTE_STRING]"
    
    local FG_COLOR="'$(hex_to_rgb "#b3f7d8")'"
    local BOLD_COLOR="'$(hex_to_rgb "#597f8b")'"
    apply_terminal_theme "addy-green" "$PALETTE" "$FG_COLOR" "$BOLD_COLOR"
    
    # Set as default and restart terminal safely
    set_default_profile_by_name "addy-green"
    restart_gnome_terminal
    
    # Apply tmux colors for green theme
    apply_tmux_theme "green"
}

set_terminal_theme_yellow() {
    local colors=('#2A2828' '#FFF3CD' '#F4E5A1' '#FFD700' '#FFFF00' '#F7E46C' '#E5CF74' '#FFEB3B' '#F9E79F' '#F8C471' '#F4D03F' '#F1C40F' '#D4AC0D' '#F7DC6F' '#F39C12' '#FCF3CF')
    local PALETTE_ARRAY=()
    for color in "${colors[@]}"; do
        PALETTE_ARRAY+=("'$(hex_to_rgb "$color")'")
    done
    local PALETTE_STRING=$(IFS=,; echo "${PALETTE_ARRAY[*]}")
    local PALETTE="[$PALETTE_STRING]"

    local FG_COLOR="'$(hex_to_rgb "#F39C12")'"
    local BOLD_COLOR="'$(hex_to_rgb "#D4AC0D")'"
    apply_terminal_theme "addy-yellow" "$PALETTE" "$FG_COLOR" "$BOLD_COLOR"
    
    # Set as default and restart terminal safely
    set_default_profile_by_name "addy-yellow"
    restart_gnome_terminal
    
    # Apply tmux colors for yellow theme
    apply_tmux_theme "yellow"
}

set_terminal_theme_grey() {
    # Colors from the current 'addy' profile (converted from RGB to hex)
    # Original RGB values: rgb(31,30,30), rgb(188,180,185), rgb(204,238,242), etc.
    local colors=('#1f1e1e' '#bcb4b9' '#cceef2' '#84b6c4' '#89a8a4' '#c7d1cd' '#597372' '#e0eed5' '#8eadca' '#adaca3' '#9bf1a3' '#96dcc8' '#1e6152' '#135564' '#417656' '#9affd2')
    local PALETTE_ARRAY=()
    for color in "${colors[@]}"; do
        PALETTE_ARRAY+=("'$(hex_to_rgb "$color")'")
    done
    local PALETTE_STRING=$(IFS=,; echo "${PALETTE_ARRAY[*]}")
    local PALETTE="[$PALETTE_STRING]"

    # Use the exact colors from the current 'addy' profile
    local FG_COLOR="'rgb(233,243,242)'"
    local BOLD_COLOR="'rgb(107,127,111)'"
    apply_terminal_theme "addy-grey" "$PALETTE" "$FG_COLOR" "$BOLD_COLOR"
    local PROFILE_PATH=$(dconf read /org/gnome/terminal/legacy/profiles:/default | tr -d "'")
    # Ensure path starts with slash
    if [[ ! "$PROFILE_PATH" =~ ^/ ]]; then
        PROFILE_PATH="/$PROFILE_PATH"
    fi
    dconf write "$PROFILE_PATH/background-transparency-percent" "82"
    
    # Set as default and restart terminal safely
    set_default_profile_by_name "addy-grey"
    restart_gnome_terminal
    
    # Apply tmux colors for grey theme
    apply_tmux_theme "grey"
}
set_terminal_theme_grey_green() {
    # Colors from the current 'addy' profile (converted from RGB to hex)
    # Original RGB values: rgb(31,30,30), rgb(188,180,185), rgb(204,238,242), etc.
    local colors=('#000000' '#B4AEAE' '#B3ACAC' '#B4A68E' '#7A818A' '#8FAB9D' '#88A99E' '#95BEB3' '#B1C5C1' '#7EA2A7' '#121312' '#9FA7C4' '#9987BC' '#86AF9A' '#C4C4C4' '#91BBAC')
    local PALETTE_ARRAY=()
    for color in "${colors[@]}"; do
        PALETTE_ARRAY+=("'$(hex_to_rgb "$color")'")
    done
    local PALETTE_STRING=$(IFS=,; echo "${PALETTE_ARRAY[*]}")
    local PALETTE="[$PALETTE_STRING]"

    # Use the exact colors from the current 'addy' profile
    local FG_COLOR="'rgb(255,255,255)'"
    local BOLD_COLOR="'rgb(255,255,255)'"
    apply_terminal_theme "addy-grey-green" "$PALETTE" "$FG_COLOR" "$BOLD_COLOR"
    
    # Set as default and restart terminal safely
    set_default_profile_by_name "addy-grey-green"
    restart_gnome_terminal
    
    # Apply tmux colors for grey-green theme
    apply_tmux_theme "grey-green"
}

# -----------------------------------------------------------------------------------
# SECTION 3: TMUX THEME FUNCTIONS USING SED
# -----------------------------------------------------------------------------------

# Apply tmux theme colors using sed
apply_tmux_theme() {
    local theme="$1"
    local tmux_conf="$HOME/.tmux.conf"
    
    case $theme in
        "red")
            sd 'fg=#[0-9A-Fa-f]{6}' 'fg=#DC143C' "$tmux_conf"
            ;;
        "green")
            sd 'fg=#[0-9A-Fa-f]{6}' 'fg=#32CD32' "$tmux_conf"
            ;;
        "yellow")
            sd 'fg=#[0-9A-Fa-f]{6}' 'fg=#FFD700' "$tmux_conf"
            ;;
        "grey")
            sd 'fg=#[0-9A-Fa-f]{6}' 'fg=#808080' "$tmux_conf"
            ;;
        "grey-green")
            sd 'fg=#[0-9A-Fa-f]{6}' 'fg=#53635b' "$tmux_conf"
            ;;    
    esac
    
    reload_tmux
}

# Reload tmux configuration
reload_tmux() {
    tmux source-file ~/.tmux.conf
}

# -----------------------------------------------------------------------------------
# SECTION 4: TMUX THEME WRAPPER FUNCTIONS
# -----------------------------------------------------------------------------------

set_tmux_theme_red() {
    apply_tmux_theme "red"
}

set_tmux_theme_green() {
    apply_tmux_theme "green"
}

set_tmux_theme_yellow() {
    apply_tmux_theme "yellow"
}

set_tmux_theme_grey() {
    apply_tmux_theme "grey"
}

set_tmux_theme_grey_green() {
    apply_tmux_theme "grey-green"
}

# -----------------------------------------------------------------------------------
# HELPER FUNCTIONS FOR SAFE TERMINAL MANAGEMENT
# -----------------------------------------------------------------------------------

# Restart gnome-terminal safely to avoid D-Bus conflicts
restart_gnome_terminal() {
    _log_terminal "Restarting gnome-terminal to avoid D-Bus conflicts..."
    
    # Kill any existing gnome-terminal instances
    pkill -f gnome-terminal 2>/dev/null || true
    sleep 1
    
    # Wait a moment for D-Bus cleanup
    sleep 1
}

# Get profile ID by name
get_profile_id_by_name() {
    local profile_name="$1"
    local profiles_list=$(dconf read /org/gnome/terminal/legacy/profiles:/list)
    
    if [[ "$profiles_list" != "[]" && "$profiles_list" != "@as []" ]]; then
        echo "$profiles_list" | tr -d "[]'" | tr ',' '\n' | while read -r pid; do
            if [[ -n "$pid" ]]; then
                local current_name=$(dconf read "/org/gnome/terminal/legacy/profiles:/:$pid/visible-name" 2>/dev/null | tr -d "'")
                if [[ "$current_name" == "$profile_name" ]]; then
                    echo "$pid"
                    break
                fi
            fi
        done
    fi
}

# Set default profile by name
set_default_profile_by_name() {
    local profile_name="$1"
    local profile_id=$(get_profile_id_by_name "$profile_name")
    
    if [[ -n "$profile_id" ]]; then
        dconf write /org/gnome/terminal/legacy/profiles:/default "'$profile_id'"
        _log_terminal "Set '$profile_name' as default profile"
    fi
}
