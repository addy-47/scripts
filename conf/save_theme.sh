#!/bin/bash
# ===================================================================================
# Save Current Theme Script
# This script saves the current GNOME theme settings to a backup file.
# ===================================================================================

_log() { echo -e "\n\e[1;32m💾  $1\e[0m"; }

BACKUP_FILE="$HOME/.config/adhbhut_theme_backup"

_log "Saving current theme settings to $BACKUP_FILE..."

# Read and save each gsettings key
echo "gtk-theme=$(gsettings get org.gnome.desktop.interface gtk-theme)" > "$BACKUP_FILE"
echo "icon-theme=$(gsettings get org.gnome.desktop.interface icon-theme)" >> "$BACKUP_FILE"
echo "cursor-theme=$(gsettings get org.gnome.desktop.interface cursor-theme)" >> "$BACKUP_FILE"
echo "user-theme=$(gsettings get org.gnome.shell.extensions.user-theme name)" >> "$BACKUP_FILE"
echo "picture-uri=$(gsettings get org.gnome.desktop.background picture-uri)" >> "$BACKUP_FILE"
echo "picture-uri-dark=$(gsettings get org.gnome.desktop.background picture-uri-dark)" >> "$BACKUP_FILE"

_log "✅ Current theme settings saved successfully."
_log "You can restore these settings later using the 'Restore saved theme' option."
