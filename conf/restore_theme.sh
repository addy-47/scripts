#!/bin/bash
# ===================================================================================
# Restore Saved Theme Script
# This script restores saved GNOME theme settings from a backup file.
# ===================================================================================

_log() { echo -e "\n\e[1;32m🔄  $1\e[0m"; }

BACKUP_FILE="$HOME/.config/adhbhut_theme_backup"

if [ ! -f "$BACKUP_FILE" ]; then
    _log "❌ Backup file not found at $BACKUP_FILE."
    _log "Please save a theme first using the 'Save current theme' option."
    exit 1
fi

_log "Restoring theme settings from $BACKUP_FILE..."

# Read from the backup file and apply each setting
while IFS='=' read -r key value; do
    if [ -n "$key" ]; then
        case "$key" in
            "gtk-theme")
                gsettings set org.gnome.desktop.interface gtk-theme "$value"
                ;;
            "icon-theme")
                gsettings set org.gnome.desktop.interface icon-theme "$value"
                ;;
            "cursor-theme")
                gsettings set org.gnome.desktop.interface cursor-theme "$value"
                ;;
            "user-theme")
                gsettings set org.gnome.shell.extensions.user-theme name "$value"
                ;;
            "picture-uri")
                gsettings set org.gnome.desktop.background picture-uri "$value"
                ;;
            "picture-uri-dark")
                gsettings set org.gnome.desktop.background picture-uri-dark "$value"
                ;;
        esac
    fi
done < "$BACKUP_FILE"

_log "✅ Theme settings restored successfully."
