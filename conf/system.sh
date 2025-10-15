#!/bin/bash
# ===================================================================================
# System Theme Library
#
# This script is a collection of functions to apply system-wide themes (GTK, icons).
# It is intended to be sourced by an orchestrator script like main.sh.
# ===================================================================================

_log_system() { echo -e "\n\e[1;33m\xe2\x86\x90  $1\e[0m"; }

# -----------------------------------------------------------------------------------
# SECTION 1: HELPER FUNCTIONS
# -----------------------------------------------------------------------------------

# Installs the base Yaru theme for a given color
install_yaru_themes() {
    local color=$1
    _log_system "Installing Yaru-$color-dark GTK and Icon themes..."
    local YARU_DIR="/tmp/yaru-colors-theme"
    
    if [ ! -d "$YARU_DIR" ]; then
        _log_system "Cloning Yaru-Colors repository from GitHub..."
        if ! git clone https://github.com/Jannomag/Yaru-Colors.git "$YARU_DIR"; then
            _log_system "\xe2\x9c\x96 Failed to clone the repository."; exit 1;
        fi
    fi
    
    _log_system "Running the Yaru-Colors installer for '$color' non-interactively..."
    (cd "$YARU_DIR" && ./install.sh -d -c "$color")
    _log_system "\xe2\x9c\x80 Yaru-Colors-$color installation script finished."
}

# Creates the custom shell theme directory and files
create_shell_theme() {
    local THEME_COLOR=$1
    local THEME_NAME="Adhbhut-Transparent"
    local THEME_DIR="$HOME/.themes/$THEME_NAME"
    
    _log_system "Creating shell theme: $THEME_NAME"
    mkdir -p "$THEME_DIR/gnome-shell"
    
    cat > "$THEME_DIR/gnome-shell/gnome-shell.css" << SHELLEOF
/* GNOME Shell Theme */
#panel { 
    background: rgba(20, 20, 30, 0.9); 
    color: $THEME_COLOR; 
}

.overview, 
.dash, 
.app-grid, 
.search-section-content, 
.notification-banner, 
.message-tray { 
    background: rgba(25, 25, 35, 0.9); 
}

/* System menu */
.popup-menu {
    background: rgba(20, 20, 30, 0.95);
    color: $THEME_COLOR;
    border: 1px solid rgba($THEME_COLOR_RGB, 0.3);
}

/* App menu */
.app-menu {
    background: rgba(20, 20, 30, 0.95);
}
SHELLEOF

    cat > "$THEME_DIR/index.theme" << METADATAEOF
[Desktop Entry]
Name=$THEME_NAME
Comment=Transparent shell theme with $THEME_COLOR accents
Type=X-GNOME-Metatheme

[X-GNOME-Metatheme]
GtkTheme=$THEME_NAME
MetacityTheme=$THEME_NAME
IconTheme=Adwaita
CursorTheme=Adwaita
ButtonLayout=menu:minimize,maximize,close

[Settings]
Gtk/DecorationLayout=menu:minimize,maximize,close
METADATAEOF

    _log_system "\xe2\x9c\x80 Shell theme '$THEME_NAME' created."
}

# Generates the custom GTK3 and GTK4 CSS override files based on a color
apply_custom_css() {
    local THEME_COLOR=$1
    local THEME_COLOR_RGB=$2
    _log_system "Applying custom CSS overrides with accent color $THEME_COLOR..."
    mkdir -p "$HOME/.config/gtk-3.0/" "$HOME/.config/gtk-4.0/"

    # --- Write GTK3 CSS Override ---
    cat > "$HOME/.config/gtk-3.0/gtk.css" << GTK3EOF
/* ========================================================== 
   Elegant Transparent Theme
   ========================================================== */

/* === GLOBAL HEADERBAR / TITLEBAR === */
headerbar,
.titlebar,
windowcontrols,
dialog > headerbar {
    backdrop-filter: blur(12px);
    background: rgba(20, 20, 30, 0.8);
    color: $THEME_COLOR;
    border: none;
    box-shadow: none;
}

/* === HEADER TEXT === */
headerbar label,
headerbar .title,
headerbar .subtitle,
dialog headerbar label {
    color: $THEME_COLOR;
    font-weight: 600;
}

/* === WINDOW CONTROL BUTTONS === */
headerbar button.titlebutton,
dialog headerbar button,
headerbar button.flat {
    color: $THEME_COLOR;
    background: transparent;
    border: none;
    border-radius: 6px;
    margin: 0 2px;
    min-width: 24px;
    min-height: 24px;
    transition: all 0.25s ease;
}

/* Hover / Active Animations */
headerbar button.titlebutton:hover,
dialog headerbar button:hover {
    color: #fff;
    background: rgba($THEME_COLOR_RGB, 0.15);
    box-shadow: 0 0 6px rgba($THEME_COLOR_RGB, 0.4);
}

headerbar button.titlebutton:active,
dialog headerbar button:active {
    background: rgba($THEME_COLOR_RGB, 0.25);
    transform: scale(0.95);
}

/* === SPECIFIC BUTTON TYPES === */
/* Search button */
headerbar button.search,
headerbar .search-button {
    color: $THEME_COLOR;
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
    background: rgba($THEME_COLOR_RGB, 0.15);
    box-shadow: 0 0 6px rgba($THEME_COLOR_RGB, 0.4);
}

/* New terminal / New tab button */
headerbar button.new-tab-button,
headerbar .image-button.new {
    color: $THEME_COLOR;
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
    background: rgba($THEME_COLOR_RGB, 0.15);
    box-shadow: 0 0 6px rgba($THEME_COLOR_RGB, 0.4);
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
    background: rgba(25, 25, 35, 0.62);
    color: $THEME_COLOR;
}

dialog .dialog-content,
.dialog-action-area button {
    color: $THEME_COLOR;
    background: rgba(40, 40, 55, 0.62);
    border: 1px solid rgba($THEME_COLOR_RGB, 0.2);
    border-radius: 8px;
    transition: all 0.2s ease;
}

.dialog-action-area button:hover {
    background: rgba($THEME_COLOR_RGB, 0.15);
    color: #fff;
}

/* === MENUS / POPOVERS === */
popover,
.menu,
menuitem,
.popup {
    background: rgba(20, 20, 30, 0.62);
    color: $THEME_COLOR;
    border-radius: 8px;
    border: 1px solid rgba($THEME_COLOR_RGB, 0.2);
}

menuitem:hover,
popover menuitem:hover {
    background: rgba($THEME_COLOR_RGB, 0.15);
    color: #fff;
}

/* === SCROLLBARS === */
scrollbar slider {
    background: rgba($THEME_COLOR_RGB, 0.4);
    border-radius: 6px;
}

scrollbar slider:hover {
    background: rgba($THEME_COLOR_RGB, 0.6);
}

/* === ENTRIES / SEARCH BOXES === */
entry,
textview,
.search-entry {
    background: rgba(30, 30, 45, 0.62);
    color: $THEME_COLOR;
    border-radius: 6px;
    border: 1px solid rgba($THEME_COLOR_RGB, 0.25);
}

entry:focus,
.search-entry:focus {
    border-color: rgba($THEME_COLOR_RGB, 0.6);
    box-shadow: 0 0 6px rgba($THEME_COLOR_RGB, 0.4);
}

/* === BOTTOM STATUS BAR / FOOTER === */
.terminal-window .status-bar,
statusbar {
    backdrop-filter: blur(12px);
    background: rgba(20, 20, 30, 0.55);
    color: $THEME_COLOR;
    border: none;
}

/* === ACCENT COLOR OVERRIDE FOR GTK3 === */
check:checked,
switch:checked,
progressbar trough progress {
    background-color: $THEME_COLOR !important;
    border-color: $THEME_COLOR !important;
}

switch:checked slider {
    background-color: #ffffff !important;
}

radio:checked {
    background-color: $THEME_COLOR !important;
    border-color: $THEME_COLOR !important;
}

scale highlight {
    background-color: $THEME_COLOR !important;
}

scale slider {
    background-color: $THEME_COLOR !important;
}
GTK3EOF

    # --- Write GTK4 CSS Override ---
    cat > "$HOME/.config/gtk-4.0/gtk.css" << GTK4EOF
/* Libadwaita Accent Color Override */
@define-color accent_bg_color $THEME_COLOR;
@define-color accent_color $THEME_COLOR;
@define-color accent_fg_color #ffffff;

@define-color destructive_bg_color $THEME_COLOR;
@define-color destructive_color $THEME_COLOR;
@define-color destructive_fg_color #ffffff;

@define-color success_bg_color $THEME_COLOR;
@define-color success_color $THEME_COLOR;
@define-color success_fg_color #ffffff;

@define-color warning_bg_color $THEME_COLOR;
@define-color warning_color $THEME_COLOR;
@define-color warning_fg_color #ffffff;

@define-color error_bg_color $THEME_COLOR;
@define-color error_color $THEME_COLOR;
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

/* Additional styling for libadwaita apps */
window {
    background-color: rgba(25, 25, 35, 0.9);
}

headerbar {
    background: rgba(20, 20, 30, 0.8);
    color: @accent_color;
}
GTK4EOF
    _log_system "\xe2\x9c\x80 Custom CSS files created."
}

# -----------------------------------------------------------------------------------
# SECTION 2: THEME DEFINITIONS
# -----------------------------------------------------------------------------------

set_system_theme_red() {
    _log_system "Setting up system theme: addy-red"
    local THEME_COLOR="#E67CA0"
    local THEME_COLOR_RGB="230, 124, 160"
    local YARU_COLOR="red"

    install_yaru_themes "$YARU_COLOR"
    create_shell_theme "$THEME_COLOR"
    apply_custom_css "$THEME_COLOR" "$THEME_COLOR_RGB"

    # Apply system settings
    gsettings set org.gnome.desktop.interface gtk-theme "Yaru-$YARU_COLOR-dark"
    gsettings set org.gnome.desktop.interface icon-theme "Yaru-$YARU_COLOR"
    gsettings set org.gnome.desktop.interface cursor-theme "Adwaita"
    gsettings set org.gnome.shell.extensions.user-theme name "Adhbhut-Transparent"
    gsettings set org.gnome.desktop.background picture-uri "file:///home/addy/Downloads/tmp/cyberpunk-rooftop-reflection.jpg"
    gsettings set org.gnome.desktop.background picture-uri-dark "$THEME_WALLPAPER_URI"
    gsettings set org.gnome.desktop.interface accent-color "$THEME_COLOR"
    
    _log_system "\xe2\x9c\x80 System theme 'addy-red' applied successfully."
}

set_system_theme_green() {
    _log_system "Setting up system theme: addy-green"
    local THEME_COLOR="#27b78e"
    local THEME_COLOR_RGB="39, 183, 142"
    local YARU_COLOR="green"

    install_yaru_themes "$YARU_COLOR"
    create_shell_theme "$THEME_COLOR"
    apply_custom_css "$THEME_COLOR" "$THEME_COLOR_RGB"

    # Apply system settings
    gsettings set org.gnome.desktop.interface gtk-theme "Yaru-$YARU_COLOR-dark"
    gsettings set org.gnome.desktop.interface icon-theme "Yaru-$YARU_COLOR"
    gsettings set org.gnome.desktop.interface cursor-theme "Adwaita"
    gsettings set org.gnome.shell.extensions.user-theme name "Adhbhut-Transparent"
    gsettings set org.gnome.desktop.background picture-uri "file:///home/addy/Downloads/tmp/cyberpunk-rooftop-reflection.jpg"
    gsettings set org.gnome.desktop.background picture-uri-dark "$THEME_WALLPAPER_URI"
    gsettings set org.gnome.desktop.interface accent-color "$THEME_COLOR"
    
    _log_system "\xe2\x9c\x80 System theme 'addy-green' applied successfully."
}