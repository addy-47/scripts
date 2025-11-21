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

# Applies a color palette and settings to a new GNOME terminal profile
apply_terminal_theme() {
    local THEME_NAME=$1
    local PALETTE=$2
    local FG_COLOR=$3
    local BG_COLOR="'rgb(0,0,0)'"
    local BOLD_COLOR=$4

    _log_terminal "Creating new terminal profile: $THEME_NAME"
    local PROFILE_ID=$(uuidgen)
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
}
