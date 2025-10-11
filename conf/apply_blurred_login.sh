#!/bin/bash
# This script applies your current wallpaper, blurred, to the GDM login screen.

# Ensure ImageMagick is installed
if ! command -v convert &> /dev/null
then
    echo "ImageMagick not found."
    echo "Please install it by running: sudo apt-get update && sudo apt-get install imagemagick"
    exit 1
fi

set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
# Strength of the blur. A higher number means more blur. 25 is a good starting point.
BLUR_STRENGTH="0x25"
# Directory to store the generated theme
THEME_DIR="/usr/share/gnome-shell/theme/Blurred-Login"
# Location for the final blurred wallpaper
FINAL_WALLPAPER_PATH="/usr/share/backgrounds/blurred-login-wallpaper.png"

echo "🚀 Starting GDM background blur script..."

# 1. Get current wallpaper
CURRENT_WALLPAPER_URI=$(gsettings get org.gnome.desktop.background picture-uri)
CURRENT_WALLPAPER_PATH=$(echo "$CURRENT_WALLPAPER_URI" | sed "s/^'file:\/\///" | sed "s/'$//")

if [ ! -f "$CURRENT_WALLPAPER_PATH" ]; then
    echo "❌ Wallpaper file not found at: $CURRENT_WALLPAPER_PATH"
    exit 1
fi
echo "🖼️ Current wallpaper: $CURRENT_WALLPAPER_PATH"

# 2. Create blurred wallpaper
echo "✨ Applying blur ($BLUR_STRENGTH)..."
# Create a temporary file for the blurred wallpaper
TEMP_WALLPAPER="/tmp/blurred_wallpaper.png"
convert "$CURRENT_WALLPAPER_PATH" -blur $BLUR_STRENGTH "$TEMP_WALLPAPER"

# 3. Copy blurred wallpaper to a system location
echo "📁 Placing blurred wallpaper in system directory..."
sudo cp "$TEMP_WALLPAPER" "$FINAL_WALLPAPER_PATH"
rm "$TEMP_WALLPAPER"

# 4. Create and install the GDM theme
echo "🎨 Generating and installing GDM theme..."
sudo mkdir -p "$THEME_DIR"

# Create the CSS file
sudo tee "$THEME_DIR/gdm3.css" > /dev/null << GDMEOF
#lockDialogGroup {
  background-image: url("file://$FINAL_WALLPAPER_PATH");
  background-size: cover;
  background-position: center;
}
GDMEOF

# Create the gresource XML file
sudo tee "$THEME_DIR/gnome-shell-theme.gresource.xml" > /dev/null << RESEOF
<?xml version="1.0" encoding="UTF-8"?>
<gresources>
  <gresource prefix="/org/gnome/shell/theme">
    <file>gdm3.css</file>
  </gresource>
</gresources>
RESEOF

# Compile the theme
(cd "$THEME_DIR" && sudo glib-compile-resources gnome-shell-theme.gresource.xml)

# Apply the new theme
sudo update-alternatives --install /usr/share/gnome-shell/gnome-shell-theme.gresource gnome-shell-theme.gresource "$THEME_DIR/gnome-shell-theme.gresource" 50
sudo update-alternatives --set gnome-shell-theme.gresource "$THEME_DIR/gnome-shell-theme.gresource"

echo "✅ Done!"
echo "Log out or press Super+L to see the new blurred login screen."
