# Adhbhut System Setup Scripts

This directory contains scripts to set up and customize your GNOME desktop environment with transparent themes, wallpapers, and terminal configurations.

## Prerequisites

- Ubuntu 20.04+ or compatible GNOME-based distribution
- Run scripts from your user shell (not as root)
- Ensure you have sudo access for system-level changes

## Usage

1. **Run from your user shell** (important! Do not run as root or inside tmux/screen):
   ```bash
   cd /path/to/scripts/conf
   bash main.sh
   ```

2. Follow the interactive menu to choose setup options.

   **Important**: Run option 1 or 2 first to install required packages before applying themes (option 3).

## What the Scripts Do

### User-Level Changes
- Installs custom GTK themes and CSS overrides in `~/.themes/` and `~/.config/gtk-*/`
- Sets GNOME Terminal color schemes via dconf
- Applies wallpapers and accent colors via gsettings

### System-Level Changes (requires sudo)
- Installs packages (dconf-cli, libglib2.0-bin, dbus-x11, etc.)
- Modifies GNOME Shell theme files in `/usr/share/gnome-shell/theme/Adhbhut-Lockscreen/`
- Sets GDM lockscreen background in `/etc/dconf/db/gdm.d/`
- Copies wallpaper to `/usr/share/backgrounds/`

## Troubleshooting

- If themes don't apply, ensure you're running from a user shell with D-Bus access
- Check that required packages are installed
- For lockscreen changes, restart GDM: `sudo systemctl restart gdm`

## Safety

- Scripts prompt for sudo password when needed
- User configurations are stored in your home directory
- System files are backed up where possible