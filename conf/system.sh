#!/bin/bash
# ===================================================================================
# System Theme Library - Yaru Theme
# This script is a collection of functions to apply system-wide themes (GTK, icons).
# It uses the Yaru theme for a modern, Ubuntu-native look.
# ===================================================================================

_log_system() { echo -e "\n\e[1;33m➡️  $1\e[0m"; }

# Installs the Yaru theme for a given color
install_yaru_theme() {
    local color=$1
    _log_system "Installing Yaru GTK theme with '$color' accent..."
    
    # Yaru is typically pre-installed on Ubuntu systems
    # Check if Yaru themes are available
    if [ ! -d "/usr/share/themes/Yaru" ] && [ ! -d "$HOME/.themes/Yaru" ]; then
        _log_system "❌ Yaru theme not found. Installing yaru-theme package..."
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y yaru-theme-gtk yaru-theme-icon yaru-theme-sound
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y yaru-theme
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm yaru
        else
            _log_system "⚠️ Unable to install Yaru automatically. Please install manually."
            return 1
        fi
    else
        _log_system "✅ Yaru theme is already available on the system."
    fi
    
    return 0
}

# Creates the custom shell theme directory and files
create_shell_theme() {
    local THEME_COLOR=$1
    local THEME_COLOR_RGB=$2
    local THEME_NAME="Adhbhut-Transparent"
    local THEME_DIR="$HOME/.themes/$THEME_NAME"
    
    _log_system "Creating shell theme: $THEME_NAME"
    mkdir -p "$THEME_DIR/gnome-shell"
    
    cat > "$THEME_DIR/gnome-shell/gnome-shell.css" << SHELLEOF
/* GNOME Shell Theme */
#panel { 
    background: rgba(0, 0, 0, 0.7); 
    color: $THEME_COLOR; 
}

.overview, 
.dash, 
.app-grid, 
.search-section-content, 
.notification-banner, 
.message-tray { 
    background: rgba(0, 0, 0, 0.7); 
}

/* System menu */
.popup-menu {
    background: rgba(0, 0, 0, 0.85);
    color: $THEME_COLOR;
    border: 1px solid rgba($THEME_COLOR_RGB, 0.3);
}

/* App menu */
.app-menu {
    background: rgba(0, 0, 0, 0.85);
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

    _log_system "✅ Shell theme '$THEME_NAME' created."
}

# Generates the custom GTK3 and GTK4 CSS override files based on a color
apply_custom_css() {
    local THEME_COLOR=$1
    local THEME_COLOR_RGB=$2
    _log_system "Applying custom CSS overrides with accent color $THEME_COLOR..."
    mkdir -p "$HOME/.config/gtk-3.0/" "$HOME/.config/gtk-4.0/"

    # Backup existing CSS files if they exist
    if [ -f "$HOME/.config/gtk-3.0/gtk.css" ]; then
        _log_system "Backing up existing GTK3 CSS to gtk.css.bak"
        mv "$HOME/.config/gtk-3.0/gtk.css" "$HOME/.config/gtk-3.0/gtk.css.bak"
    fi
    if [ -f "$HOME/.config/gtk-4.0/gtk.css" ]; then
        _log_system "Backing up existing GTK4 CSS to gtk.css.bak"
        mv "$HOME/.config/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css.bak"
    fi

    # --- Write GTK3 CSS Override ---
    cat > "$HOME/.config/gtk-3.0/gtk.css" << GTK3EOF
/* ========================================================== 
   Elegant Transparent Theme - Yaru Compatible
   ========================================================== */

/* === GLOBAL HEADERBAR / TITLEBAR === */
headerbar,
.titlebar,
windowcontrols,
dialog > headerbar {
    background: rgba(0, 0, 0, 0.54);
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
    min-width: 16px;
    min-height: 16px;
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
    min-width: 16px;
    min-height: 16px;
    transition: all 0.25s ease;
}

headerbar button.new-tab-button:hover,
headerbar .image-button.new:hover {
    color: #fff;
    background: rgba($THEME_COLOR_RGB, 0.15);
    box-shadow: 0 0 6px rgba($THEME_COLOR_RGB, 0.4);
}

/* === TERMINAL SPECIFIC BUTTONS === */
/* Terminal buttons - minimal styling */
headerbar button.image-button {
    color: $THEME_COLOR;
    background: transparent;
    border: none;
    min-width: 16px;
    min-height: 16px;
}

headerbar button.image-button:hover {
    color: #fff;
    background: rgba($THEME_COLOR_RGB, 0.15);
    box-shadow: 0 0 6px rgba($THEME_COLOR_RGB, 0.4);
}

/* === ENSURE BUTTONS ARE RIGHT-ALIGNED === */
windowcontrols.start { }
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
    background: rgba(0, 0, 0, 0.62);
    color: $THEME_COLOR;
}

dialog .dialog-content,
.dialog-action-area button {
    color: $THEME_COLOR;
    background: rgba(0, 0, 0, 0.62);
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
    background: rgba(0, 0, 0, 0.62);
    color: $THEME_COLOR;
    border-radius: 8px;
    border: 1px solid rgba($THEME_COLOR_RGB, 0.2);
}

menuitem:hover,
popover menuitem:hover {
    background: rgba($THEME_COLOR_RGB, 0.15);
    color: #fff;
}

/* === MINIMAL CURVED SCROLLBAR === */
scrollbar {
    background: transparent;
    border: none;
}

scrollbar slider {
    background: rgba($THEME_COLOR_RGB, 0.3);
    border-radius: 10px;
    min-width: 3px;
    border: none;
}

scrollbar slider:hover {
    background: rgba($THEME_COLOR_RGB, 0.6);
}

scrollbar.vertical slider {
    min-width: 3px;
    border-radius: 10px;
}

scrollbar.horizontal slider {
    min-height: 3px;
    border-radius: 10px;
}

/* === ENTRIES / SEARCH BOXES === */
entry,
textview,
.search-entry {
    background: rgba(0, 0, 0, 0.62);
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
    background: rgba(0, 0, 0, 0.55);
    color: $THEME_COLOR;
    border: none;
}

/* === ACCENT COLOR OVERRIDE FOR GTK3 === */
check:checked,
switch:checked,
progressbar trough progress {
    background-color: $THEME_COLOR;
    border-color: $THEME_COLOR;
}

switch:checked slider {
    background-color: #ffffff;
}

radio:checked {
    background-color: $THEME_COLOR;
    border-color: $THEME_COLOR;
}

scale highlight {
    background-color: $THEME_COLOR;
}

scale slider {
    background-color: $THEME_COLOR;
}

/* ====== Nautilus (Files) Sidebar ====== */
.nautilus-window .sidebar,
.nautilus-window .navigation-sidebar,
.nautilus-window .places-sidebar,
.sidebar {
    background: rgba(0, 0, 0, 0.7);
    color: $THEME_COLOR;
    border-right: 1px solid rgba($THEME_COLOR_RGB, 0.2);
}

.nautilus-window .sidebar row,
.nautilus-window .navigation-sidebar row,
.nautilus-window .places-sidebar row,
.sidebar row {
    color: $THEME_COLOR;
    border-radius: 6px;
    margin: 2px 4px;
    transition: all 0.2s ease;
}

.nautilus-window .sidebar row:hover,
.nautilus-window .navigation-sidebar row:hover,
.nautilus-window .places-sidebar row:hover,
.sidebar row:hover {
    background: rgba($THEME_COLOR_RGB, 0.15);
    color: #fff;
    box-shadow: 0 0 4px rgba($THEME_COLOR_RGB, 0.3);
}

.nautilus-window .sidebar row:selected,
.nautilus-window .navigation-sidebar row:selected,
.nautilus-window .places-sidebar row:selected,
.sidebar row:selected {
    background: rgba($THEME_COLOR_RGB, 0.25);
    color: #fff;
    box-shadow: 0 0 6px rgba($THEME_COLOR_RGB, 0.4);
}

.nautilus-window .sidebar scrollbar,
.nautilus-window .navigation-sidebar scrollbar,
.nautilus-window .places-sidebar scrollbar,
.sidebar scrollbar {
    background: transparent;
    border: none;
}

.nautilus-window .sidebar scrollbar slider,
.nautilus-window .navigation-sidebar scrollbar slider,
.nautilus-window .places-sidebar scrollbar slider,
.sidebar scrollbar slider {
    background: rgba($THEME_COLOR_RGB, 0.3);
    border-radius: 10px;
    min-width: 3px;
    border: none;
}

.nautilus-window .sidebar scrollbar slider:hover,
.nautilus-window .navigation-sidebar scrollbar slider:hover,
.nautilus-window .places-sidebar scrollbar slider:hover,
.sidebar scrollbar slider:hover {
    background: rgba($THEME_COLOR_RGB, 0.6);
}

.nautilus-window .sidebar .search-entry,
.nautilus-window .navigation-sidebar .search-entry,
.nautilus-window .places-sidebar .search-entry,
.sidebar .search-entry {
    background: rgba(0, 0, 0, 0.62);
    color: $THEME_COLOR;
    border-radius: 6px;
    border: 1px solid rgba($THEME_COLOR_RGB, 0.25);
}

.nautilus-window .sidebar .search-entry:focus,
.nautilus-window .navigation-sidebar .search-entry:focus,
.nautilus-window .places-sidebar .search-entry:focus,
.sidebar .search-entry:focus {
    border-color: rgba($THEME_COLOR_RGB, 0.6);
    box-shadow: 0 0 6px rgba($THEME_COLOR_RGB, 0.4);
}
GTK3EOF

    # --- Write GTK4 CSS Override ---
    cat > "$HOME/.config/gtk-4.0/gtk.css" << GTK4EOF
/* Libadwaita Accent Color Override - Yaru Compatible */
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
    background-color: rgba(0, 0, 0, 0.8);
}

headerbar {
    background: rgba(0, 0, 0, 0.7);
    color: @accent_color;
}

/* ====== Nautilus (Files) Sidebar GTK4 ====== */
.nautilus-window .sidebar,
.nautilus-window .navigation-sidebar,
.nautilus-window .places-sidebar,
.sidebar {
    background: rgba(0, 0, 0, 0.7);
    color: @accent_color;
    border-right: 1px solid rgba(var(--accent-color-rgb), 0.2);
}

.nautilus-window .sidebar row,
.nautilus-window .navigation-sidebar row,
.nautilus-window .places-sidebar row,
.sidebar row {
    color: @accent_color;
    border-radius: 6px;
    margin: 2px 4px;
    transition: all 0.2s ease;
}

.nautilus-window .sidebar row:hover,
.nautilus-window .navigation-sidebar row:hover,
.nautilus-window .places-sidebar row:hover,
.sidebar row:hover {
    background: rgba(var(--accent-color-rgb), 0.15);
    color: #fff;
    box-shadow: 0 0 4px rgba(var(--accent-color-rgb), 0.3);
}

.nautilus-window .sidebar row:selected,
.nautilus-window .navigation-sidebar row:selected,
.nautilus-window .places-sidebar row:selected,
.sidebar row:selected {
    background: rgba(var(--accent-color-rgb), 0.25);
    color: #fff;
    box-shadow: 0 0 6px rgba(var(--accent-color-rgb), 0.4);
}

.nautilus-window .sidebar scrollbar,
.nautilus-window .navigation-sidebar scrollbar,
.nautilus-window .places-sidebar scrollbar,
.sidebar scrollbar {
    background: transparent;
    border: none;
}

.nautilus-window .sidebar scrollbar slider,
.nautilus-window .navigation-sidebar scrollbar slider,
.nautilus-window .places-sidebar scrollbar slider,
.sidebar scrollbar slider {
    background: rgba(var(--accent-color-rgb), 0.3);
    border-radius: 10px;
    min-width: 3px;
    border: none;
}

.nautilus-window .sidebar scrollbar slider:hover,
.nautilus-window .navigation-sidebar scrollbar slider:hover,
.nautilus-window .places-sidebar scrollbar slider:hover,
.sidebar scrollbar slider:hover {
    background: rgba(var(--accent-color-rgb), 0.6);
}

.nautilus-window .sidebar .search-entry,
.nautilus-window .navigation-sidebar .search-entry,
.nautilus-window .places-sidebar .search-entry,
.sidebar .search-entry {
    background: rgba(0, 0, 0, 0.62);
    color: @accent_color;
    border-radius: 6px;
    border: 1px solid rgba(var(--accent-color-rgb), 0.25);
}

.nautilus-window .sidebar .search-entry:focus,
.nautilus-window .navigation-sidebar .search-entry:focus,
.nautilus-window .places-sidebar .search-entry:focus,
.sidebar .search-entry:focus {
    border-color: rgba(var(--accent-color-rgb), 0.6);
    box-shadow: 0 0 6px rgba(var(--accent-color-rgb), 0.4);
}
GTK4EOF
    _log_system "✅ Custom CSS files created."
}

# ===================================================================================
# SECTION 2: THEME DEFINITIONS
# ===================================================================================

set_system_theme_red() {
    _log_system "Setting up system theme: addy-red"
    local THEME_COLOR="#E95420"
    local THEME_COLOR_RGB="233, 84, 32"
    local YARU_COLOR="red"

    # Install Yaru theme
    install_yaru_theme "$YARU_COLOR"
    
    create_shell_theme "$THEME_COLOR" "$THEME_COLOR_RGB"
    apply_custom_css "$THEME_COLOR" "$THEME_COLOR_RGB"

    # Apply system settings with Yaru theme
    gsettings set org.gnome.desktop.interface gtk-theme "Yaru$YARU_COLOR-dark"
    gsettings set org.gnome.desktop.interface icon-theme "Yaru$YARU_COLOR-dark"
    gsettings set org.gnome.desktop.interface cursor-theme "Yaru"
    gsettings set org.gnome.shell.extensions.user-theme name "Adhbhut-Transparent"
    gsettings set org.gnome.desktop.background picture-uri "file:///home/addy/projects/scripts/conf/wallpapers/red.png"
    gsettings set org.gnome.desktop.background picture-uri-dark "file:///home/addy/projects/scripts/conf/wallpapers/red.png"
    
    # Set prefer-dark color scheme for Ubuntu
    gsettings set org.gnome.shell.ubuntu color-scheme prefer-dark
    
    _log_system "✅ System theme 'addy-red' applied successfully."
    return 0
}

set_system_theme_green() {
    _log_system "Setting up system theme: addy-green"
    local THEME_COLOR="#00A153"
    local THEME_COLOR_RGB="0, 161, 83"
    local YARU_COLOR="green"

    # Install Yaru theme
    install_yaru_theme "$YARU_COLOR"
    
    create_shell_theme "$THEME_COLOR" "$THEME_COLOR_RGB"
    apply_custom_css "$THEME_COLOR" "$THEME_COLOR_RGB"

    # Apply system settings with Yaru theme
    gsettings set org.gnome.desktop.interface gtk-theme "Yaru$YARU_COLOR"
    gsettings set org.gnome.desktop.interface icon-theme "Yaru$YARU_COLOR"
    gsettings set org.gnome.desktop.interface cursor-theme "Yaru"
    gsettings set org.gnome.shell.extensions.user-theme name "Adhbhut-Transparent"
    gsettings set org.gnome.desktop.background picture-uri "file:///home/addy/projects/scripts/conf/wallpapers/green.png"
    gsettings set org.gnome.desktop.background picture-uri-dark "file:///home/addy/projects/scripts/conf/wallpapers/green.png"
    
    # Set prefer-dark color scheme for Ubuntu
    gsettings set org.gnome.shell.ubuntu color-scheme prefer-dark
    
    _log_system "✅ System theme 'addy-green' applied successfully."
    return 0
}
    
set_system_theme_yellow() {
    _log_system "Setting up system theme: addy-yellow"
    local THEME_COLOR="#FFAA00"
    local THEME_COLOR_RGB="255, 170, 0"
    local YARU_COLOR="yellow"

    # Install Yaru theme
    install_yaru_theme "$YARU_COLOR"
    
    create_shell_theme "$THEME_COLOR" "$THEME_COLOR_RGB"
    apply_custom_css "$THEME_COLOR" "$THEME_COLOR_RGB"

    # Apply system settings with Yaru theme
    gsettings set org.gnome.desktop.interface gtk-theme "Yaru$YARU_COLOR"
    gsettings set org.gnome.desktop.interface icon-theme "Yaru$YARU_COLOR"
    gsettings set org.gnome.desktop.interface cursor-theme "Yaru"
    gsettings set org.gnome.shell.extensions.user-theme name "Adhbhut-Transparent"
    gsettings set org.gnome.desktop.background picture-uri "file:///home/addy/projects/scripts/conf/wallpapers/yellow.png"
    gsettings set org.gnome.desktop.background picture-uri-dark "file:///home/addy/projects/scripts/conf/wallpapers/yellow.png"
    
    # Set prefer-dark color scheme for Ubuntu
    gsettings set org.gnome.shell.ubuntu color-scheme prefer-dark
    
    _log_system "✅ System theme 'addy-yellow' applied successfully."
    return 0
}

set_system_theme_grey() {
    _log_system "Setting up system theme: addy-grey"
    # Using the exact colors from the current 'addy' profile
    local THEME_COLOR="#E9F3F2"
    local THEME_COLOR_RGB="233, 243, 242"
    local YARU_COLOR="grey"

    # Install Yaru theme
    install_yaru_theme "$YARU_COLOR"
    
    create_shell_theme "$THEME_COLOR" "$THEME_COLOR_RGB"
    apply_custom_css "$THEME_COLOR" "$THEME_COLOR_RGB"

    # Apply system settings with Yaru theme
    gsettings set org.gnome.desktop.interface gtk-theme "Yaru$YARU_COLOR"
    gsettings set org.gnome.desktop.interface icon-theme "Yaru$YARU_COLOR"
    gsettings set org.gnome.desktop.interface cursor-theme "Yaru"
    gsettings set org.gnome.shell.extensions.user-theme name "Adhbhut-Transparent"
    gsettings set org.gnome.desktop.background picture-uri "file:///home/addy/projects/scripts/conf/wallpapers/grey.png"
    gsettings set org.gnome.desktop.background picture-uri-dark "file:///home/addy/projects/scripts/conf/wallpapers/grey.png"
    
    # Set prefer-dark color scheme for Ubuntu
    gsettings set org.gnome.shell.ubuntu color-scheme prefer-dark
    
    sed -i 's/background: rgba(0, 0, 0, 0.54);/background: rgba(0, 0, 0, 0.18);/g' "$HOME/.config/gtk-3.0/gtk.css"
    
    _log_system "✅ System theme 'addy-grey' applied successfully with custom settings."
    return 0
}

