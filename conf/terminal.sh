#!/bin/bash
# ===================================================================================
# Terminal Theme Library
#
# This script is a collection of functions to apply color themes to GNOME Terminal.
# It is intended to be sourced by an orchestrator script like main.sh.
# ===================================================================================

_log_terminal() { echo -e "\n\e[1;36m➡️  $1\e[0m"; }

# -----------------------------------------------------------------------------------
# SECTION 1: HELPER FUNCTION
# -----------------------------------------------------------------------------------

# Applies a color palette and settings to the default GNOME terminal profile
apply_terminal_theme() {
    local THEME_NAME=$1
    local PALETTE=$2
    local FG_COLOR=$3
    local BG_COLOR='#000000' # Assuming background is always black
    local PROFILE_ID=$(dconf list /org/gnome/terminal/legacy/profiles:/ | grep -E '^:' | head -1 | sed 's/://' | sed 's/\///')
    if [ -z "$PROFILE_ID" ]; then
        # Create new profile if none exists
        _log_terminal "No existing terminal profile found. Creating a new one..."
        PROFILE_ID=$(uuidgen)
        dconf write /org/gnome/terminal/legacy/profiles:/list "['$PROFILE_ID']"
    fi
    local PROFILE_PATH="/org/gnome/terminal/legacy/profiles:/$PROFILE_ID"

    _log_terminal "Applying '$THEME_NAME' theme to GNOME Terminal..."

    dconf write "$PROFILE_PATH/visible-name" "'$THEME_NAME'"
    dconf write "$PROFILE_PATH/palette" "$PALETTE"
    dconf write "$PROFILE_PATH/foreground-color" "$FG_COLOR"
    dconf write "$PROFILE_PATH/background-color" "$BG_COLOR"
    dconf write "$PROFILE_PATH/bold-color" "$FG_COLOR"
    dconf write "$PROFILE_PATH/use-transparent-background" "true"
    dconf write "$PROFILE_PATH/background-transparency-percent" "50"

    _log_terminal "✅ Terminal theme '$THEME_NAME' applied."
}

# -----------------------------------------------------------------------------------
# SECTION 2: THEME DEFINITIONS
# -----------------------------------------------------------------------------------

set_terminal_theme_red() {
    local PALETTE="['#000000', '#cc241d', '#E67CA0', '#d79921', '#458588', '#b16286', '#689d6a', '#a89984', '#928374', '#fb4934', '#b8bb26', '#fabd2f', '#83a598', '#d3869b', '#8ec07c', '#ebdbb2']"
    local FG_COLOR="'#E67CA0'"
    apply_terminal_theme "addy-red" "$PALETTE" "$FG_COLOR"
}

set_terminal_theme_green() {
    local PALETTE="['#000000', '#879993', '#d1d1d1', '#b9a8c8', '#a570d2', '#54a4a7', '#27b78e', '#eee8d5', '#73b0c0', '#b0bbb6', '#597f8b', '#657b83', '#839496', '#d8239a', '#93a1a1', '#fdf6e3']"
    local FG_COLOR="'#b3f7d8'"
    apply_terminal_theme "addy-green" "$PALETTE" "$FG_COLOR"
}
