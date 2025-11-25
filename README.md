# DevOps Toolkit

**dockerz** - Docker management tool for CI/CD  
**u-cli** - Development utility tool

## Installation

### Individual Tools

#### dockerz only
```bash
# CI/CD (no sudo)
curl -fsSL https://raw.githubusercontent.com/addy-47/scripts/install/setup-cicd.sh | bash

# Individual tool install
curl -fsSL https://raw.githubusercontent.com/addy-47/scripts/install/tools/dockerz/install.sh | bash
```

#### u-cli only
```bash
# Individual tool install
curl -fsSL https://raw.githubusercontent.com/addy-47/scripts/install/tools/u-cli/install.sh | bash
```

### Complete Installation (Both Tools)

#### Standard Install
```bash
curl -fsSL https://raw.githubusercontent.com/addy-47/scripts/install/setup.sh | bash
```

#### Ubuntu/Debian
```bash
curl -fsSL https://raw.githubusercontent.com/addy-47/scripts/install/scripts/add-apt-repo.sh | sudo bash
sudo apt update
sudo apt install dockerz u-cli
```

### Direct DEB Installation
```bash
# dockerz
sudo bash https://raw.githubusercontent.com/addy-47/scripts/install/apt/setup.sh dockerz

# u-cli
sudo bash https://raw.githubusercontent.com/addy-47/scripts/install/apt/setup.sh u-cli
```

### Windows and macOS
```bash
# Download and install manually from GitHub releases
# Or use the standard installation script
curl -fsSL https://raw.githubusercontent.com/addy-47/scripts/install/setup.sh | bash
```

## Uninstall
```bash
bash https://raw.githubusercontent.com/addy-47/scripts/install/uninstall.sh
```

## Usage Examples

### GitHub Actions
```yaml
- name: Install dockerz
  run: curl -fsSL https://raw.githubusercontent.com/addy-47/scripts/install/setup-cicd.sh | bash
  
- name: Use dockerz
  run: dockerz --help
```

### Docker
```dockerfile
RUN curl -fsSL https://raw.githubusercontent.com/addy-47/scripts/install/setup-cicd.sh | bash
```

### Local Development
```bash
curl -fsSL https://raw.githubusercontent.com/addy-47/scripts/install/setup.sh | bash
```

## Tool Selection Guide

- **dockerz** - Use in CI/CD pipelines and development
- **u-cli** - Use only in development environments (not for CI/CD)

Choose the installation method that fits your needs:
- CI/CD: `setup-cicd.sh` (dockerz only)
- Development: `setup.sh` or APT (both tools)
- Individual tools: Direct DEB or specific installation scripts
