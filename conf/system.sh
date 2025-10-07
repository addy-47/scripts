#!/bin/bash
# ===================================================================================
# System Theme & Appearance Consolidation Script
#
# This script automates the setup of a complete GNOME desktop appearance.
# It installs the Yaru-Colors theme pack, a custom transparent shell theme,
# and applies all necessary system settings.
# ===================================================================================

# -----------------------------------------------------------------------------------
# SECTION 1: THEME CONFIGURATION
# These variables define the names for your desktop appearance.
# -----------------------------------------------------------------------------------
THEME_GTK_NAME="Yaru-red-dark"
THEME_ICONS_NAME="Yaru-red"
THEME_CURSOR="Adwaita"
THEME_SHELL="Adhbhut-Transparent"
THEME_WALLPAPER_URI="file:///home/addy/Downloads/tmp/cyberpunk-rooftop-reflection.jpg"

# --- Custom Transparent Theme Settings ---
CUSTOM_THEME_NAME="Adhbhut-Transparent"
CUSTOM_THEME_COLOR="#E67CA0"
CUSTOM_THEME_COLOR_RGB="230, 124, 160"
CUSTOM_SHELL_OPACITY="0.9"

# -----------------------------------------------------------------------------------
# SECTION 2: HELPER FUNCTIONS
# -----------------------------------------------------------------------------------
_log() { echo -e "\n\e[1;34m➡️  $1\e[0m"; }

get_installer() {
    if command -v apt-get &>/dev/null; then echo "sudo apt-get install -y";
    elif command -v dnf &>/dev/null; then echo "sudo dnf install -y";
    elif command -v pacman &>/dev/null; then echo "sudo pacman -Syu --noconfirm";
    else echo "echo 'Warning: Could not find a known package manager.' && exit 1"; fi
}

check_dependencies() {
    _log "Checking dependencies for system theme..."
    local INSTALLER=$(get_installer)
    local missing_deps=0

    if ! command -v gnome-shell &>/dev/null; then _log "❌ GNOME Shell not found."; exit 1; fi
    if ! command -v git &>/dev/null; then _log "git not found, installing..."; $INSTALLER git || missing_deps=1; fi
    if ! command -v gsettings &>/dev/null; then _log "gsettings not found, installing..."; $INSTALLER libglib2.0-bin || missing_deps=1; fi
    
    if ! gnome-extensions list | grep -q "user-theme@gnome-shell-extensions.gcampax.github.com"; then
        _log "User Themes extension not found, installing..."; $INSTALLER gnome-shell-extension-user-theme || missing_deps=1
        gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com
    fi

    if [ $missing_deps -ne 0 ]; then
        _log "❌ Could not install all required dependencies. Please install them manually and re-run."
        exit 1
    fi
    _log "✅ Dependencies satisfied."
}

# -----------------------------------------------------------------------------------
# SECTION 3: THEME INSTALLERS
# -----------------------------------------------------------------------------------

install_yaru_themes() {
    _log "Installing Yaru-Colors GTK and Icon themes..."
    local YARU_DIR="/tmp/yaru-colors-theme"
    
    if [ -d "$YARU_DIR" ]; then
        _log "Yaru-Colors directory already exists. Skipping download."
    else
        _log "Cloning Yaru-Colors repository from GitHub..."
        if ! git clone https://github.com/Jannomag/Yaru-Colors.git "$YARU_DIR"; then
            _log "❌ Failed to clone the repository. Please check your internet connection."
            exit 1
        fi
    fi
    
    _log "Running the Yaru-Colors installer non-interactively..."
    (cd "$YARU_DIR" && ./install.sh -d -c red)
    
    _log "✅ Yaru-Colors installation script finished."
}

install_shell_theme() {
    _log "Installing custom shell theme: $CUSTOM_THEME_NAME"
    local THEME_DIR="$HOME/.themes/$CUSTOM_THEME_NAME"
    mkdir -p "$THEME_DIR"/gnome-shell

    cat > "$THEME_DIR/gnome-shell/gnome-shell.css" << SHELLEOF
/* GNOME Shell Theme | Opacity: $CUSTOM_SHELL_OPACITY */
#panel { background: rgba(20, 20, 30, $CUSTOM_SHELL_OPACITY); color: $CUSTOM_THEME_COLOR; }
.overview, .dash, .app-grid, .search-section-content, .notification-banner, .message-tray { background: rgba(25, 25, 35, $CUSTOM_SHELL_OPACITY); }
SHELLEOF

    cat > "$THEME_DIR/index.theme" << METADATAEOF
[Desktop Entry]
Name=$CUSTOM_THEME_NAME
Comment=Transparent shell theme
Type=X-GNOME-Metatheme
[X-GNOME-Metatheme]
Name=$CUSTOM_THEME_NAME
METADATAEOF

    _log "✅ Custom shell theme created."
}

apply_css_overrides() {
    _log "Applying custom CSS overrides for GTK3 and GTK4..."
    
    # Create GTK3 override file
    mkdir -p "$HOME/.config/gtk-3.0/"
    cat > "$HOME/.config/gtk-3.0/gtk.css" << GTK3EOF
/* ==========================================================
   Elegant Transparent Theme - Matched to GNOME Terminal (38% transparency)
   ========================================================== */

/* === GLOBAL HEADERBAR / TITLEBAR === */
headerbar,
.titlebar,
windowcontrols,
dialog > headerbar {
    backdrop-filter: blur(12px);
    background: rgba(20, 20, 30, 0.8); /* Slightly darker than terminal (55% opacity) */
    color: #E67CA0;
    border: none;
    box-shadow: none;
}

/* === HEADER TEXT === */
headerbar label,
headerbar .title,
headerbar .subtitle,
dialog headerbar label {
    color: #E67CA0;
    font-weight: 600;
}

/* === WINDOW CONTROL BUTTONS === */
headerbar button.titlebutton,
dialog headerbar button,
headerbar button.flat {
    color: #E67CA0;
    background: transparent;
    border: none;
    border-radius: 6px;
    margin: 0 2px;
    min-width: 24px;
    min-height: 24px;
    transition: all 0.25s ease;
}

/* === SEARCH BUTTON === */
headerbar button.search,
headerbar .search-button {
    color: #E67CA0;
    background: transparent;
    border: none;
    border-radius: 6px;
    margin: 0 2px;
    min-width: 24px;
    min-height: 24px;
    transition: all 0.25s ease;
}
headerbar button.search:hover,
headerbar .search-button:hover {
    color: #fff;
    background: rgba(230, 124, 160, 0.15);
    box-shadow: 0 0 6px rgba(230, 124, 160, 0.4);
}
headerbar button.search:active,
headerbar .search-button:active {
    background: rgba(230, 124, 160, 0.25);
    transform: scale(0.95);
}

/* === NEW TERMINAL / NEW TAB BUTTON === */
headerbar button.new-tab-button,
headerbar .image-button.new {
    color: #E67CA0;
    background: transparent;
    border: none;
    border-radius: 6px;
    margin: 0 2px;
    min-width: 24px;
    min-height: 24px;
    transition: all 0.25s ease;
}
headerbar button.new-tab-button:hover,
headerbar .image-button.new:hover {
    color: #fff;
    background: rgba(230, 124, 160, 0.15);
    box-shadow: 0 0 6px rgba(230, 124, 160, 0.4);
}
headerbar button.new-tab-button:active,
headerbar .image-button.new:active {
    background: rgba(230, 124, 160, 0.25);
    transform: scale(0.95);
}

/* Hover / Active Animations for Title Buttons */
headerbar button.titlebutton:hover,
dialog headerbar button:hover {
    color: #fff;
    background: rgba(230, 124, 160, 0.15);
    box-shadow: 0 0 6px rgba(230, 124, 160, 0.4);
}
headerbar button.titlebutton:active,
dialog headerbar button:active {
    background: rgba(230, 124, 160, 0.25);
    transform: scale(0.95);
}

/* === ENSURE BUTTONS ARE RIGHT-ALIGNED === */
windowcontrols.start { margin-left: auto; }
windowcontrols.end   { margin-right: 6px; }
headerbar .start,
headerbar .end {
    padding: 0 6px;
}

/* === FILECHOOSERS / DIALOG WINDOWS === */
filechooser,
filechooserwidget,
dialog,
messagedialog {
    background: rgba(25, 25, 35, 0.62); /* Match terminal opacity */
    color: #E67CA0;
}
dialog .dialog-content,
.dialog-action-area button {
    color: #E67CA0;
    background: rgba(40, 40, 55, 0.62); /* Match terminal opacity */
    border: 1px solid rgba(230, 124, 160, 0.2);
    border-radius: 8px;
    transition: all 0.2s ease;
}
.dialog-action-area button:hover {
    background: rgba(230, 124, 160, 0.15);
    color: #fff;
}

/* === MENUS / POPOVERS === */
popover,
.menu,
menuitem,
.popup {
    background: rgba(20, 20, 30, 0.62); /* Match terminal opacity */
    color: #E67CA0;
    border-radius: 8px;
    border: 1px solid rgba(230, 124, 160, 0.2);
}
menuitem:hover,
popover menuitem:hover {
    background: rgba(230, 124, 160, 0.15);
    color: #fff;
}

/* === SCROLLBARS === */
scrollbar slider {
    background: rgba(230, 124, 160, 0.4);
    border-radius: 6px;
}
scrollbar slider:hover {
    background: rgba(230, 124, 160, 0.6);
}

/* === ENTRIES / SEARCH BOXES === */
entry,
textview,
.search-entry {
    background: rgba(30, 30, 45, 0.62); /* Match terminal opacity */
    color: #E67CA0;
    border-radius: 6px;
    border: 1px solid rgba(230, 124, 160, 0.25);
}
entry:focus,
.search-entry:focus {
    border-color: rgba(230, 124, 160, 0.6);
    box-shadow: 0 0 6px rgba(230, 124, 160, 0.4);
}

/* === BOTTOM STATUS BAR / FOOTER (TMUX WINDOWS LIST) === */
.terminal-window .status-bar,
statusbar {
    backdrop-filter: blur(12px);
    background: rgba(20, 20, 30, 0.55); /* Match header transparency */
    color: #E67CA0;
    border: none;
}
GTK3EOF

    # Create GTK4 override file
    mkdir -p "$HOME/.config/gtk-4.0/"
    cat > "$HOME/.config/gtk-4.0/gtk.css" << GTK4EOF
/* Libadwaita Accent Color Override */
@define-color accent_bg_color #E67CA0;
@define-color accent_color #E67CA0;
@define-color accent_fg_color #ffffff;

@define-color destructive_bg_color #E67CA0;
@define-color destructive_color #E67CA0;
@define-color destructive_fg_color #ffffff;

@define-color success_bg_color #E67CA0;
@define-color success_color #E67CA0;
@define-color success_fg_color #ffffff;

@define-color warning_bg_color #E67CA0;
@define-color warning_color #E67CA0;
@define-color warning_fg_color #ffffff;

@define-color error_bg_color #E67CA0;
@define-color error_color #E67CA0;
@define-color error_fg_color #ffffff;

/* Apply to switches, checkboxes, and toggles */
switch:checked {
    background-color: @accent_bg_color;
    border-color: @accent_bg_color;
}

switch:checked slider {
    background-color: @accent_fg_color;
}

check:checked {
    background-color: @accent_bg_color;
    border-color: @accent_bg_color;
}

radio:checked {
    background-color: @accent_bg_color;
    border-color: @accent_bg_color;
}

progressbar progress {
    background-color: @accent_bg_color;
}

button.suggested-action {
    background-color: @accent_bg_color;
    color: @accent_fg_color;
}

button.destructive-action {
    background-color: @destructive_bg_color;
    color: @destructive_fg_color;
}
GTK4EOF
    _log "✅ Custom CSS overrides applied."
}

# -----------------------------------------------------------------------------------
# SECTION 4: MAIN EXECUTION
# -----------------------------------------------------------------------------------
main() {
    _log "Starting full system theme setup..."
    
    # 1. Verify system and install dependencies
    check_dependencies
    
    # 2. Install all required themes
    install_yaru_themes
    install_shell_theme
    
    # 3. Apply all theme settings via gsettings
    _log "Applying final desktop appearance settings..."
    gsettings set org.gnome.desktop.interface gtk-theme "$THEME_GTK_NAME"
    gsettings set org.gnome.desktop.interface icon-theme "$THEME_ICONS_NAME"
    gsettings set org.gnome.desktop.interface cursor-theme "$THEME_CURSOR"
    gsettings set org.gnome.shell.extensions.user-theme name "$THEME_SHELL"
    gsettings set org.gnome.desktop.background picture-uri "$THEME_WALLPAPER_URI"
    gsettings set org.gnome.desktop.background picture-uri-dark "$THEME_WALLPAPER_URI"
    gsettings set org.gnome.desktop.interface accent-color "$CUSTOM_THEME_COLOR"

    # 4. Apply custom CSS overrides
    apply_css_overrides

    _log "🎯 Theme application complete!"
}

main
