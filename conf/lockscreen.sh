#!/bin/bash

# Use the same variables as your theme script
export BASE_COLOR="#E67CA0"
export BACKGROUND_OPACITY="0.9"
export CURRENT_WALLPAPER=$(gsettings get org.gnome.desktop.background picture-uri | sed "s/file:\/\///" | sed "s/'//g")

echo "🎨 Setting up lock screen to match your theme..."

# =============================================
# 1. Create GDM Theme Directory
# =============================================
sudo mkdir -p /usr/share/gnome-shell/theme/Adhbhut-Lockscreen

# =============================================
# 2. Create GDM Theme CSS
# =============================================
sudo tee /usr/share/gnome-shell/theme/Adhbhut-Lockscreen/gdm3.css << GDMEOF
/* Adhbhut Lock Screen Theme */

#lockDialogGroup {
    background: rgba(25, 25, 35, $BACKGROUND_OPACITY);
    background-image: url("$CURRENT_WALLPAPER");
    background-size: cover;
    background-position: center;
}

.unlock-dialog {
    background: rgba(20, 20, 30, 0.95);
    border: 1px solid $BASE_COLOR;
    border-radius: 12px;
    box-shadow: 0 0 20px rgba(0, 0, 0, 0.5);
}

.unlock-dialog .button {
    background: rgba(30, 30, 45, 0.9);
    color: $BASE_COLOR;
    border: 1px solid $BASE_COLOR;
    border-radius: 6px;
}

.unlock-dialog .button:focus,
.unlock-dialog .button:hover {
    background: $BASE_COLOR;
    color: #ffffff;
}

.login-dialog {
    background: rgba(20, 20, 30, 0.95);
}

.user-widget-label {
    color: $BASE_COLOR;
}

.password-entry {
    background: rgba(30, 30, 45, 0.9);
    color: $BASE_COLOR;
    border: 1px solid $BASE_COLOR;
    border-radius: 6px;
}

.password-entry:focus {
    border-color: $BASE_COLOR;
    box-shadow: 0 0 8px $BASE_COLOR;
}

/* Clock and date */
.clock-time {
    color: $BASE_COLOR;
    font-size: 48pt;
}

.clock-date {
    color: $BASE_COLOR;
    font-size: 14pt;
}

/* System menu */
.popup-menu {
    background: rgba(20, 20, 30, 0.95);
    color: $BASE_COLOR;
    border: 1px solid $BASE_COLOR;
}

/* Power button */
.power-icon {
    color: $BASE_COLOR;
}

.power-icon:hover {
    color: #ffffff;
    background: $BASE_COLOR;
}
GDMEOF

# =============================================
# 3. Create GDM Theme Configuration
# =============================================
sudo tee /usr/share/gnome-shell/theme/Adhbhut-Lockscreen/gnome-shell-theme.gresource.xml << RESEOF
<?xml version="1.0" encoding="UTF-8"?>
<gresources>
  <gresource prefix="/org/gnome/shell/theme">
    <file>gdm3.css</file>
  </gresource>
</gresources>
RESEOF

# =============================================
# 4. Compile GDM Theme
# =============================================
echo "🔨 Compiling GDM theme..."
cd /usr/share/gnome-shell/theme/Adhbhut-Lockscreen
sudo glib-compile-resources gnome-shell-theme.gresource.xml

# =============================================
# 5. Backup Original GDM Theme
# =============================================
echo "💾 Backing up original GDM theme..."
sudo cp /usr/share/gnome-shell/theme/Yaru/gnome-shell-theme.gresource /usr/share/gnome-shell/theme/Yaru/gnome-shell-theme.gresource.backup

# =============================================
# 6. Apply Custom GDM Theme
# =============================================
echo "🎯 Applying custom lock screen..."
sudo update-alternatives --install /usr/share/gnome-shell/gnome-shell-theme.gresource gnome-shell-theme.gresource /usr/share/gnome-shell/theme/Adhbhut-Lockscreen/gnome-shell-theme.gresource 100
sudo update-alternatives --set gnome-shell-theme.gresource /usr/share/gnome-shell/theme/Adhbhut-Lockscreen/gnome-shell-theme.gresource

# =============================================
# 7. Set GDM Background (Alternative Method)
# =============================================
echo "🖼️ Setting GDM background..."
sudo cp "$CURRENT_WALLPAPER" /usr/share/backgrounds/adhbhut-lockscreen.jpg

# Create GDM background configuration directory
sudo mkdir -p /etc/dconf/db/gdm.d

sudo tee /etc/dconf/db/gdm.d/00-background << GDMBACKGROUND
[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/adhbhut-lockscreen.jpg'
GDMBACKGROUND

sudo dconf update

echo "✅ Lock screen setup complete!"
echo ""
echo "🔒 To test: Lock your screen (Super+L) or log out"
echo "🔄 If issues occur, restart GDM: sudo systemctl restart gdm"
