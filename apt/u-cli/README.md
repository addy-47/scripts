# u - Universal Linux Undo Command

🧰 A single command — `u` — that instantly undos the last terminal operation safely, across all shells.

## Installation

### From Debian Package (Recommended)

```bash
# Download the .deb package and install
sudo dpkg -i u_1.0.0-1_amd64.deb
sudo apt-get install -f  # Install any missing dependencies
```

### From Source

```bash
# Clone the repository
git clone https://github.com/adhbutg/u.git
cd u

# Build the binary
go build -o u .

# Install system-wide
sudo cp u /usr/local/bin/
```

### From Go

```bash
go install github.com/adhbutg/u@latest
```

## Quick Start

After installation, you'll see a welcome message. To start using u:

```bash
# Initialize tracking
u init

# View available commands
u help

# Undo the last command
u

# Undo the second-to-last command
u 2
```

## Shell Integration

Add the appropriate hook to your shell configuration:

### Bash (~/.bashrc)
```bash
export PROMPT_COMMAND='u_track "$BASH_COMMAND"'
```

### Zsh (~/.zshrc)
```bash
preexec_functions+=(u_track)
```

### Fish (~/.config/fish/functions/fish_prompt.fish)
```fish
function fish_preexec --on-event fish_preexec
    u_track $argv
end
```

## Supported Operations

u can undo these common operations:

- **File operations**: `mkdir`, `touch`, `mv`, `cp`, `rm`, `chmod`, `chown`
- **Package management**: `apt install/remove`, `pip install/uninstall`, `npm install/uninstall`, `brew install/remove`
- **Git operations**: `git clone`, `git commit`, `git merge`, `git pull`, `git checkout`
- **Docker operations**: `docker run`, `docker build`, `docker pull`, `docker network create`
- **System operations**: `service start/stop`, `ufw enable/disable`

## How It Works

1. **Command Tracking**: Hooks into shell preexec/prompt commands to capture every command
2. **File Change Detection**: Uses mtime diff and inotify to detect which files were affected
3. **Backup System**: Automatically backs up changed/deleted files before operations
4. **Instant Restore**: When you run `u`, it restores the last operation's changes

## Safety Features

- Only tracks operations that are safe to undo
- Never modifies files outside your home directory
- Automatic backup cleanup after 24 hours
- Confirmation prompts for destructive operations

## Project Structure

```
u/
├── cmd/           # CLI commands (cobra)
├── internal/      # Internal packages
│   ├── tracker/   # Command tracking and file change detection
│   ├── backup/    # Backup and restore engine
│   ├── fsnotify/  # File watching utilities
│   ├── config/    # Configuration management
│   └── store/     # BoltDB storage
├── debian/        # Debian packaging files
├── scripts/       # Installation scripts
└── main.go        # Application entry point
```

## Development

```bash
# Run tests
go test ./...

# Build for current platform
go build -o u .

# Build Debian package
dpkg-buildpackage -us -uc -b
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Author

Adhbhut Gupta <adhbutg@gmail.com>