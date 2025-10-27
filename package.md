# DevOps Toolkit Installation System - Implementation Plan

## Overview
Create a professional multi-tool installation system for the DevOps toolkit containing dockerz and u-cli tools. The system will provide flexible installation options with fallback mechanisms and CI/CD-ready release automation.

## Current Repository Structure
- **Repository**: https://github.com/addy-47/scripts
- **Current Branch**: dockerz (tool-specific development branch)
- **Install Branch**: apt (needs to be renamed to 'install')
- **Tools**: dockerz v2.0, u-cli (structure for future tools)

## Branch Strategy
- **dockerz branch**: Tool-specific development (current location)
- **master branch**: Merge tested tool branches, each tool in separate directory
- **install branch**: User-facing installation system only

## Installation System Architecture

### Directory Structure (install branch)
```
install/
├── README.md                    # Installation guide for the entire toolkit
├── setup.sh                     # Main setup script (one-click install)
├── tools/                       # Individual tool configurations
│   ├── dockerz/
│   │   ├── install.sh           # Dockerz-specific installation (adds apt repo + installs)
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
├── releases/                    # Pre-built binaries (populated by CI)
│   ├── dockerz/
│   │   ├── dockerz-linux-amd64.tar.gz
│   │   ├── dockerz-darwin-amd64.tar.gz
│   │   └── dockerz-windows-amd64.zip
│   └── u-cli/
└── .github/workflows/           # GitHub Actions for releases
    ├── release-dockerz.yml
    ├── release-u-cli.yml
    └── update-apt-repo.yml      # Updates apt repository after releases
```

### Installation UX Flow

#### Option 1: Apt Repository Setup (Recommended for Debian/Ubuntu)
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

#### Option 2: One-Click Binary Setup (Universal)
```bash
# Install everything via binaries (fallback for non-apt systems)
curl -fsSL https://raw.githubusercontent.com/addy-47/scripts/install/setup.sh | bash
```

#### Option 3: Tool-Specific Installation
```bash
# Install just Dockerz (adds repo + installs)
curl -fsSL https://raw.githubusercontent.com/addy-47/scripts/install/tools/dockerz/install.sh | bash

# Install just u-cli (adds repo + installs)
curl -fsSL https://raw.githubusercontent.com/addy-47/scripts/install/tools/u-cli/install.sh | bash
```

#### Option 4: Manual Download
```bash
# Download pre-built binaries (for non-Debian systems)
wget https://github.com/addy-47/scripts/releases/download/v2.0/dockerz-linux-amd64.tar.gz
tar -xzf dockerz-linux-amd64.tar.gz
sudo mv dockerz /usr/local/bin/
```

## Implementation Details

### Apt Repository Management
- **Custom Apt Repository**: Hosted on GitHub Pages (addy-47.github.io/scripts)
- **Repository Setup**: Scripts add repository to `/etc/apt/sources.list.d/`
- **GPG Signing**: Repository signed with maintainer's GPG key
- **Package Index**: Automatically updated via CI/CD when new versions released
- **Multi-Architecture**: Support for amd64 and arm64 packages

### Main Setup Script (setup.sh)
- **Purpose**: Universal binary installation (fallback for non-apt systems)
- **Features**:
  - OS/architecture detection
  - Go installation if needed
  - Parallel tool installation via binaries
  - Post-installation verification
  - Comprehensive error handling and logging

### Tool-Specific Scripts (tools/*/install.sh)
- **Purpose**: Add apt repository + install tool (Debian/Ubuntu)
- **Features**:
  - Detect if running on Debian/Ubuntu
  - Add custom apt repository
  - Install tool via `apt install`
  - Fallback to binary installation for other systems
  - Platform-specific handling
  - Proper PATH management

### Shared Utilities (scripts/)
- **common.sh**: Logging functions, error handling, utility functions
- **detect-os.sh**: Cross-platform OS/architecture detection
- **install-go.sh**: Automated Go installation
- **add-apt-repo.sh**: Custom apt repository setup and GPG key management
- **verify-installation.sh**: Post-install checks and reporting

### CI/CD Integration (.github/workflows/)
- **Automated Releases**: Build binaries and .deb packages for multiple platforms
- **Apt Repository Updates**: Update Packages.gz and Release files after builds
- **Archive Creation**: tar.gz for Unix, zip for Windows, .deb for Debian
- **Release Tagging**: Triggered by version tags (e.g., dockerz-v*)
- **GitHub Pages**: Deploy apt repository to github.io for public access

## Key Features

### Professional UX
- **Clear Installation Paths**: Multiple installation methods for different user preferences
- **Comprehensive Logging**: Color-coded output with success/error indicators
- **Error Recovery**: Fallback mechanisms when primary installation fails
- **Progress Feedback**: Real-time status updates during installation

### Reliability
- **Cross-Platform Support**: Linux, macOS, Windows
- **Dependency Management**: Automatic installation of required tools (Go, etc.)
- **Verification**: Post-install checks to ensure successful installation
- **Rollback Support**: Uninstall scripts for clean removal

### Maintainability
- **Modular Design**: Shared scripts reduce duplication
- **Configuration-Driven**: Easy to add new tools
- **Documentation**: Comprehensive READMEs and inline comments
- **Testing**: Automated CI/CD with release validation

### Scalability
- **Tool Agnostic**: Structure supports any number of tools
- **Version Management**: Independent versioning per tool
- **Branch Strategy**: Clean separation of development and distribution

## Implementation Phases

### Phase 1: Branch & Repository Setup
1. Rename remote 'apt' branch to 'install'
2. Analyze current install branch content
3. Set up GitHub Pages for apt repository (addy-47.github.io/scripts)
4. Create GPG key for repository signing
5. Set up basic directory structure

### Phase 2: Apt Repository Infrastructure
1. Implement apt repository structure with Packages.gz and Release files
2. Create add-apt-repo.sh script for repository setup
3. Set up GPG key management and signing
4. Implement repository update automation

### Phase 3: Core Installation Scripts
1. Implement tool-specific install.sh scripts (apt repo + install)
2. Create main setup.sh with universal binary installation
3. Develop shared utility scripts (common.sh, detect-os.sh, etc.)
4. Add configuration files and documentation

### Phase 4: CI/CD Integration
1. Create GitHub Actions workflows for releases
2. Implement automated .deb package building
3. Set up apt repository updates via CI/CD
4. Add GitHub Pages deployment for repository

### Phase 5: Testing & Documentation
1. Test apt installation flow on Debian/Ubuntu
2. Test binary installation on all platforms
3. Update README with comprehensive documentation
4. Add troubleshooting guides and examples
5. Validate error handling and fallbacks

## Success Criteria
- ✅ Apt repository setup with `curl | bash` + `apt install` workflow
- ✅ Automatic updates via `apt update && apt upgrade`
- ✅ Clean uninstallation via `apt remove`
- ✅ Universal binary installation fallback for non-apt systems
- ✅ Cross-platform binary releases (Linux/macOS/Windows)
- ✅ Comprehensive error handling and logging
- ✅ CI/CD automated releases and repository updates
- ✅ Clear documentation and troubleshooting
- ✅ Easy addition of new tools to the system
- ✅ Official package manager experience for Debian/Ubuntu users

## Risk Mitigation
- **Apt Repository Reliability**: GPG signing and proper Release file management
- **Fallback Mechanisms**: Apt installation with universal binary backup
- **Platform Testing**: Validate apt flow on Debian/Ubuntu, binary flow everywhere
- **Error Handling**: Comprehensive logging and user-friendly error messages
- **Documentation**: Step-by-step guides and troubleshooting sections
- **Version Management**: Independent tool versioning prevents conflicts
- **Repository Updates**: Automated CI/CD ensures repository stays current

This implementation provides a professional, scalable installation system that grows with the toolkit while maintaining excellent user experience.