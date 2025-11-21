# Adhbhut System Setup Scripts

This directory contains scripts to set up and customize your GNOME desktop environment with transparent themes, wallpapers, and terminal configurations.

## Prerequisites

- Ubuntu 20.04+ or compatible GNOME-based distribution
- Run scripts from your user shell (not as root)
- Ensure you have sudo access for system-level changes
- `git` must be installed for theme installation.

## Usage

1. **Run from your user shell** (important! Do not run as root or inside tmux/screen):
   ```bash
   cd /path/to/scripts/conf
   bash main.sh
   ```

2. Follow the interactive menu to choose setup options.

   **Important**: Run option 1 or 2 first to install required packages before applying themes (option 4).

## What the Scripts Do

### User-Level Changes
- Installs **Orchis GTK themes** with various color accents (red, green, yellow) and a dark variant. The theme repository is cached in `~/.config/orchis-theme-repo` for faster updates.
- Installs custom CSS overrides in `~/.themes/` and `~/.config/gtk-*/`. Existing `gtk.css` files are backed up to `.bak`.
- Sets GNOME Terminal color schemes and other settings via dconf. Each theme creates a new, dedicated terminal profile.
- Applies wallpapers and accent colors via gsettings.
- **Save/Restore Theme**: `save_theme.sh` saves your current GNOME theme settings (GTK, Icons, Cursor, Shell, Wallpaper) to `~/.config/adhbhut_theme_backup`. `restore_theme.sh` applies these saved settings.

### System-Level Changes (requires sudo)
- Installs packages (dconf-cli, libglib2.0-bin, dbus-x11, etc.)
- Modifies GNOME Shell theme files in `/usr/share/gnome-shell/theme/Adhbhut-Lockscreen/`
- Sets GDM lockscreen background in `/etc/dconf/db/gdm.d/`
- Copies wallpaper to `/usr/share/backgrounds/`

## Troubleshooting

- If themes don't apply, ensure you're running from a user shell with D-Bus access
- Check that required packages are installed (especially `git` for theme installation).
- For lockscreen changes, restart GDM: `sudo systemctl restart gdm`

## Safety

- Scripts prompt for sudo password when needed
- User configurations are stored in your home directory
- System files are backed up where possible

## Main Menu Options

The `main.sh` script provides the following options:
- **0) Run complete scripts (default)**: Installs packages, sets up shells (Zsh, Bash), Tmux, Git, applies lock screen theme, and then prompts for theme selection.
- **1) Install packages only**: Installs all necessary system packages.
- **2) Install packages and setup tools**: Installs packages and configures Git and Tmux.
- **3) Install packages and setup terminals**: Installs packages and configures Zsh and Bash shells.
- **4) Apply themes only**: Installs the selected Orchis theme, applies custom CSS, and sets terminal and system themes.
- **5) Save current theme**: Saves your current GTK, Icon, Cursor, Shell, and Wallpaper settings.
- **6) Restore saved theme**: Restores previously saved GTK, Icon, Cursor, Shell, and Wallpaper settings.
- **7) Exit**: Exits the setup script.