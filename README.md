# DevOps Toolkit Installation System

A professional multi-tool installation system for the DevOps toolkit containing dockerz and u-cli tools.

## Quick Start

### Option 1: Apt Repository Setup (Recommended for Debian/Ubuntu)
```bash
# Add repository and install everything
curl -fsSL https://raw.githubusercontent.com/addy-47/scripts/install/tools/dockerz/install.sh | bash

# Now use apt like official packages
sudo apt update
sudo apt install dockerz u-cli

# Updates work automatically
sudo apt update && sudo apt upgrade dockerz u-cli

# Uninstall cleanly
sudo apt remove dockerz u-cli
```

### Option 2: One-Click Binary Setup (Universal)
```bash
# Install everything via binaries (fallback for non-apt systems)
curl -fsSL https://raw.githubusercontent.com/addy-47/scripts/install/setup.sh | bash
```

### Option 3: Tool-Specific Installation
```bash
# Install just Dockerz (adds repo + installs)
curl -fsSL https://raw.githubusercontent.com/addy-47/scripts/install/tools/dockerz/install.sh | bash

# Install just u-cli (adds repo + installs)
curl -fsSL https://raw.githubusercontent.com/addy-47/scripts/install/tools/u-cli/install.sh | bash
```

### Option 4: Manual Download
```bash
# Download pre-built binaries (for non-Debian systems)
wget https://github.com/addy-47/scripts/releases/download/v2.0/dockerz-linux-amd64.tar.gz
tar -xzf dockerz-linux-amd64.tar.gz
sudo mv dockerz /usr/local/bin/
```

## Available Tools

- **dockerz**: Docker container management and orchestration tool
- **u-cli**: Universal CLI tool for development workflows

## Directory Structure

```
├── README.md                    # This installation guide
├── setup.sh                     # Main setup script (one-click install)
├── tools/                       # Individual tool configurations
│   ├── dockerz/
│   │   ├── install.sh           # Dockerz-specific installation
│   │   ├── uninstall.sh         # Dockerz-specific uninstallation
│   │   ├── config/              # Default configs
│   │   │   └── services.yaml
│   │   └── docs/                # Tool-specific docs
│   │       └── README.md
│   └── u-cli/
│       ├── install.sh
│       ├── uninstall.sh
│       ├── config/
│       └── docs/
├── scripts/                     # Shared utility scripts
│   ├── common.sh                # Shared functions
│   ├── detect-os.sh             # OS detection
│   ├── install-go.sh            # Go installation helper
│   ├── add-apt-repo.sh          # Add custom apt repository
│   └── verify-installation.sh   # Post-install verification
├── apt/                         # Debian packaging and repository
│   ├── dockerz/
│   │   ├── dockerz_2.0_amd64.deb
│   │   └── dockerz_2.0_arm64.deb
│   ├── u-cli/
│   │   ├── u-cli_1.0_amd64.deb
│   │   └── u-cli_1.0_arm64.deb
│   ├── Packages.gz              # Package index
│   ├── Release                   # Repository metadata
│   ├── Release.gpg              # GPG signature
│   └── setup.sh                 # Legacy setup script
├── releases/                    # Pre-built binaries
│   ├── dockerz/
│   │   ├── dockerz-linux-amd64.tar.gz
│   │   ├── dockerz-darwin-amd64.tar.gz
│   │   └── dockerz-windows-amd64.zip
│   └── u-cli/
└── .github/workflows/           # GitHub Actions for releases
    ├── release-dockerz.yml
    ├── release-u-cli.yml
    └── update-apt-repo.yml
```

## Features

- **Professional UX**: Clear installation paths with comprehensive logging
- **Cross-Platform Support**: Linux, macOS, Windows
- **Apt Repository**: Official package manager experience for Debian/Ubuntu
- **Automatic Updates**: Via `apt update && apt upgrade`
- **Fallback Mechanisms**: Binary installation for non-apt systems
- **Clean Uninstallation**: Remove tools and repository cleanly
- **CI/CD Ready**: Automated releases and repository updates

## Troubleshooting

### Common Issues

1. **Permission Denied**: Run with `sudo` for system-wide installation
2. **Repository Not Found**: Ensure internet connection and correct URLs
3. **GPG Key Issues**: Import GPG key manually if automatic import fails
4. **Architecture Mismatch**: Check system architecture (amd64/arm64)

### Manual Installation

If automated installation fails, download binaries manually from the [releases page](https://github.com/addy-47/scripts/releases).

## Contributing

This installation system is designed to be extensible. To add a new tool:

1. Create a new directory under `tools/`
2. Add `install.sh` and `uninstall.sh` scripts
3. Add configuration files under `config/`
4. Update the main `setup.sh` script
5. Add CI/CD workflow for releases

## License

See individual tool licenses for details.