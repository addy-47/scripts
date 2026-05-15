#!/bin/bash
# ===================================================================================
# Save Current Theme Script (Fully Automatic Generator)
# This script reads current GNOME desktop and terminal settings, extracts
# accent colors and theme names, and generates a new reusable theme entry.
# ===================================================================================

_log() { echo -e "\n\e[1;32m💾  $1\e[0m"; }
_err() { echo -e "\n\e[1;31m❌  $1\e[0m"; }

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Prompt ONLY for theme name
echo -e "\e[1;36mCreate a new theme based on your current settings!\e[0m"
read -p "Enter new theme name (e.g. aqua, sunset): " THEME_SUFFIX
if [[ -z "$THEME_SUFFIX" ]]; then
    _err "Theme name cannot be empty."
    exit 1
fi

FULL_THEME_NAME="addy-$THEME_SUFFIX"
FUNC_SUFFIX="${THEME_SUFFIX//-/_}"

_log "Capturing current system state for '$FULL_THEME_NAME'..."

# 1. Capture Yaru color from current GTK theme
GTK_THEME=$(gsettings get org.gnome.desktop.interface gtk-theme | tr -d "'")
# Extract color name between 'Yaru' and '-' (e.g. Yarured-dark -> red)
YARU_COLOR=$(echo "$GTK_THEME" | sed -E 's/Yaru([a-z-]+)(-dark)?/\1/')
# Fallback to blue if detection fails
if [[ -z "$YARU_COLOR" || "$YARU_COLOR" == "$GTK_THEME" ]]; then
    YARU_COLOR="blue"
fi
_log "Detected base Yaru color: $YARU_COLOR"

# 2. Capture Terminal Colors and derive Accent
DEFAULT_PROFILE=$(dconf read /org/gnome/terminal/legacy/profiles:/default | tr -d "'")
if [[ -n "$DEFAULT_PROFILE" ]]; then
    PROFILE_PATH="/org/gnome/terminal/legacy/profiles:/:$DEFAULT_PROFILE"
    PALETTE=$(dconf read "$PROFILE_PATH/palette")
    FG_COLOR=$(dconf read "$PROFILE_PATH/foreground-color")
    BOLD_COLOR=$(dconf read "$PROFILE_PATH/bold-color")
    
    # Derrive HEX Accent from Terminal Foreground
    # Strip quotes and 'rgb()'
    CLEAN_RGB=$(echo "$FG_COLOR" | tr -d "'rgb()")
    IFS=',' read -r r g b <<< "$CLEAN_RGB"
    ACCENT_HEX=$(printf "#%02x%02x%02x" $r $g $b)
    ACCENT_RGB="$r, $g, $b"
    _log "Derived accent color from terminal: $ACCENT_HEX"
else
    _err "Could not detect terminal profile. Using fallbacks."
    PALETTE="['rgb(0,0,0)', 'rgb(205,0,0)', 'rgb(0,205,0)', 'rgb(205,205,0)', 'rgb(0,0,238)', 'rgb(205,0,205)', 'rgb(0,205,205)', 'rgb(229,229,229)', 'rgb(127,127,127)', 'rgb(255,0,0)', 'rgb(0,255,0)', 'rgb(255,255,0)', 'rgb(92,108,232)', 'rgb(255,0,255)', 'rgb(0,255,255)', 'rgb(255,255,255)']"
    FG_COLOR="'rgb(255,255,255)'"
    BOLD_COLOR="'rgb(255,255,255)'"
    ACCENT_HEX="#FFFFFF"
    ACCENT_RGB="255, 255, 255"
fi

# 3. Capture Wallpaper
WALLPAPER_URI=$(gsettings get org.gnome.desktop.background picture-uri | tr -d "'")
if [[ "$WALLPAPER_URI" == file://* ]]; then
    WALLPAPER_PATH="${WALLPAPER_URI#file://}"
    if [ -f "$WALLPAPER_PATH" ]; then
        mkdir -p "$SCRIPT_DIR/wallpapers"
        cp "$WALLPAPER_PATH" "$SCRIPT_DIR/wallpapers/${THEME_SUFFIX}.png"
        _log "Captured wallpaper: wallpapers/${THEME_SUFFIX}.png"
    else
        _err "Wallpaper file not found at $WALLPAPER_PATH"
    fi
else
    _log "Wallpaper is not a local file. Skipping wallpaper copy."
fi

# 4. Generate and Append to system.sh
_log "Updating system.sh..."
cat << EOF >> "$SCRIPT_DIR/system.sh"

set_system_theme_${FUNC_SUFFIX}() {
    _log_system "Setting up system theme: ${FULL_THEME_NAME}"
    local THEME_COLOR="${ACCENT_HEX}"
    local THEME_COLOR_RGB="${ACCENT_RGB}"
    local YARU_COLOR="${YARU_COLOR}"

    install_yaru_theme "\$YARU_COLOR"
    create_shell_theme "\$THEME_COLOR" "\$THEME_COLOR_RGB"
    apply_custom_css "\$THEME_COLOR" "\$THEME_COLOR_RGB"

    gsettings set org.gnome.desktop.interface gtk-theme "Yaru\$YARU_COLOR-dark"
    gsettings set org.gnome.desktop.interface icon-theme "Yaru\$YARU_COLOR"
    gsettings set org.gnome.desktop.interface cursor-theme "Yaru"
    gsettings set org.gnome.shell.extensions.user-theme name "Adhbhut-Transparent"
    gsettings set org.gnome.desktop.background picture-uri "file://\$SCRIPT_DIR/wallpapers/${THEME_SUFFIX}.png"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://\$SCRIPT_DIR/wallpapers/${THEME_SUFFIX}.png"
    gsettings set org.gnome.shell.ubuntu color-scheme prefer-dark
    
    _log_system "✅ System theme '${FULL_THEME_NAME}' applied successfully."
    return 0
}
EOF

# 5. Generate and Append to terminal.sh
_log "Updating terminal.sh..."
cat << EOF >> "$SCRIPT_DIR/terminal.sh"

set_terminal_theme_${FUNC_SUFFIX}() {
    local PALETTE="${PALETTE}"
    local FG_COLOR="${FG_COLOR}"
    local BOLD_COLOR="${BOLD_COLOR}"
    apply_terminal_theme "${FULL_THEME_NAME}" "\$PALETTE" "\$FG_COLOR" "\$BOLD_COLOR"
    
    set_default_profile_by_name "${FULL_THEME_NAME}"
    restart_gnome_terminal
    
    set_tmux_theme_${FUNC_SUFFIX}
}

set_tmux_theme_${FUNC_SUFFIX}() {
    local tmux_conf="\$HOME/.tmux.conf"
    if command -v sed &> /dev/null; then
        sed -i -E 's/fg=#[0-9A-Fa-f]{6}/fg=${ACCENT_HEX}/g' "\$tmux_conf"
    fi
    tmux source-file "\$tmux_conf" 2>/dev/null || true
}
EOF

_log "✅ Theme '${FULL_THEME_NAME}' has been successfully captured!"
_log "You can now find it in the main menu."
