# 🚀 A dev's automation Toolkit

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Shell Script](https://img.shields.io/badge/Shell%20Script-123456?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Go](https://img.shields.io/badge/Go-00ADD8?style=for-the-badge&logo=go&logoColor=white)](https://golang.org/)
[![Ansible](https://img.shields.io/badge/Ansible-%231A1918.svg?style=for-the-badge&logo=ansible&logoColor=#1A1918)](https://www.ansible.com/)

![DevOps Toolkit Banner](public/scripts.png)

> **Your one-stop solution for modern DevOps workflows, system automation, and container orchestration**

## 📖 Table of Contents

- [✨ Features](#-features)
- [🛠️ Tools Overview](#️-tools-overview)
- [🚀 Quick Start](#-quick-start)
- [📚 Detailed Documentation](#-detailed-documentation)
- [🔧 Installation](#-installation)
- [⚡ Usage Examples](#-usage-examples)
- [🏗️ Architecture](#️-architecture)
- [🐛 Troubleshooting](#-troubleshooting)
- [🤝 Contributing](#-contributing)
- [📜 License](#-license)

## ✨ Features

### 🐳 Container & Orchestration
- **Dockerz v2.75**: Parallel Docker build tool with smart caching and Git integration
- **Kubernetes**: GKE cluster management and context switching
- **Multi-registry support**: Google Artifact Registry integration

### 🔧 System Automation
- **Ansible Playbooks**: VM provisioning and configuration management
- **Shell Configuration**: Zsh, Bash, Tmux, and Git setup
- **Theme Management**: GNOME desktop customization with transparent themes

### 🛠️ Development Tools
- **Universal Undo**: Linux terminal undo command (`u`)
- **Kubernetes Patching**: YAML-based resource patching
- **MongoDB Migration**: Automated data migration between environments

### 🚀 CI/CD & Deployment
- **GitHub Actions**: Complete GKE CI/CD pipeline
- **Load Testing**: Performance testing tools
- **Monitoring**: Kubernetes event watching and alerting

## 🛠️ Tools Overview

| Tool | Category | Description | Status |
|------|----------|-------------|--------|
| **[Dockerz](dockerz/)** | 🐳 Container | Ultimate Docker build companion with parallel builds, smart caching, and Git integration | 🚀 Production |
| **[Ansible](ansible/)** | 🔧 Automation | VM provisioning and configuration management playbooks | 🚀 Production |
| **[Conf](conf/)** | 💻 System | GNOME desktop setup, shell configuration, and theme management | 🚀 Production |
| **[u-cli](u-cli/)** | 🛠️ Development | Universal Linux undo command for terminal operations | 🚀 Production |
| **[Switch](switch/)** | 🚀 CI/CD | GCP project and Kubernetes context switching tool | 🚀 Production |
| **[General](general/)** | 🛠️ Utilities | Deployment scripts, load testing, and monitoring tools | 🚀 Production |

### 🎯 Tool Highlights

#### 🐳 Dockerz v2.75 - The Ultimate Docker Companion
```bash
# Smart parallel builds with Git change detection
dockerz build --smart --git-track --cache --max-processes 8

# Google Artifact Registry integration
dockerz build --project my-gcp-project --region us-central1 --gar my-registry --push-to-gar
```

**Key Features:**
- 🔄 **Parallel Building**: Build multiple Docker images simultaneously
- 🧠 **Smart Features**: Git change detection, multi-level caching, intelligent orchestration
- 🏗️ **Modular Architecture**: Clean separation of concerns with dedicated modules
- ☁️ **GAR Integration**: Native Google Artifact Registry support
- 📊 **Performance Optimized**: Reduces CI/CD pipeline times significantly

#### 🔧 Ansible - Infrastructure as Code
```yaml
# Provision VMs with a single command
ansible-playbook provision-vm.yml -i inventory.ini
```

**Capabilities:**
- 🖥️ **VM Provisioning**: Automated server setup and configuration
- 🔒 **Security**: Best practices implementation
- 📦 **Package Management**: Consistent software installation
- 🔄 **Idempotent**: Safe to run multiple times

#### 💻 Conf - System Configuration Suite
```bash
# Complete system setup
cd conf && bash main.sh
# Choose option 0 for full setup
```

**Features:**
- 🎨 **Theme Management**: Orchis GTK themes with custom CSS
- 🖼️ **Wallpaper Management**: Multiple theme variants (red, green, yellow, dark)
- 🐚 **Shell Setup**: Zsh, Bash, Tmux, and Git configuration
- 🔒 **Lockscreen**: Custom GDM lockscreen with blur effects
- 💾 **Backup/Restore**: Save and restore theme configurations

#### 🛠️ u-cli - Universal Undo Command
```bash
# Install and start tracking
curl -fsSL https://u.sh/install | sudo bash
u init

# Undo operations
u          # Undo last command
u 2        # Undo second last command
u log      # Show recent commands
```

**Supported Operations:**
- 📁 **File Operations**: `mv`, `cp`, `rm`, `touch`, `mkdir`
- 📂 **Directory Navigation**: `cd` command reversal
- 🗂️ **Package Management**: `apt install` → `apt remove`
- 🌿 **Git Operations**: `git clone` → directory removal

#### 🚀 Switch - GCP & Kubernetes Context Manager
```bash
# Switch between GCP projects and clusters
switch prod-main
switch dev-test
```

**Features:**
- ☁️ **GCP Integration**: Automatic `gcloud` configuration switching
- 🐳 **Kubernetes**: Context and namespace switching with `kubectx`/`kubens`
- 🔐 **Authentication**: Smart `gcloud auth login` prompts
- 📋 **Aliases**: Memorable project names instead of long IDs

## 🚀 Quick Start

### Prerequisites
- **Linux/macOS**: Primary development platforms
- **Docker**: Required for container tools
- **Git**: Required for version control and change detection
- **Go 1.19+**: Required for building from source

### 1. Clone and Explore
```bash
git clone <repository-url>
cd scripts
ls -la
```

### 2. Choose Your Tool
```bash
# For container management
cd dockerz && ./dockerz --help

# For system setup
cd conf && bash main.sh

# For infrastructure automation
cd ansible && ansible-playbook --help

# For universal undo
cd u-cli && ./install.sh
```

### 3. Get Started
Each tool has its own comprehensive documentation:
- [Dockerz Documentation](dockerz/README.md)
- [Ansible Playbooks](ansible/)
- [System Configuration](conf/README.md)
- [Universal Undo](u-cli/README.md)

## 📚 Detailed Documentation

### 🐳 Dockerz v2.75 Documentation

#### Installation
```bash
# Download binary
curl -L https://github.com/your-repo/dockerz/releases/download/v2.75/dockerz-linux-amd64 -o /usr/local/bin/dockerz
chmod +x /usr/local/bin/dockerz

# Initialize project
dockerz init
```

#### Configuration
```yaml
# build.yaml
project: my-gcp-project
gar: my-artifact-registry
region: us-central1
max_processes: 8
smart: true
git_track: true
cache: true
```

#### Advanced Usage
```bash
# Smart build with change detection
dockerz build --smart --git-track --depth 3 --cache

# CI/CD integration
dockerz build --input-changed-services changed_services.txt
dockerz build --output-changed-services detected_changes.txt

# Force rebuild
dockerz build --force
```

### 🔧 Ansible Documentation

#### Inventory Setup
```ini
# inventory.ini
[production]
prod-server-1 ansible_host=192.168.1.100
prod-server-2 ansible_host=192.168.1.101

[development]
dev-server-1 ansible_host=192.168.1.200
```

#### Running Playbooks
```bash
# Provision production servers
ansible-playbook provision-vm.yml -i inventory.ini -l production

# Run with verbose output
ansible-playbook provision-vm.yml -i inventory.ini -v
```

### 💻 System Configuration Documentation

#### Complete Setup
```bash
cd conf
bash main.sh
# Select option 0 for complete setup
```

#### Theme Management
```bash
# Save current theme
bash save_theme.sh

# Restore saved theme
bash restore_theme.sh

# Apply specific theme
bash apply_blurred_login.sh
```

### 🛠️ Universal Undo Documentation

#### Installation
```bash
# One-liner installation
curl -fsSL https://u.sh/install | sudo bash

# Initialize tracking
u init
```

#### Usage
```bash
# Basic undo
u

# Undo multiple steps
u 2
u 3

# View history
u log

# Cleanup old backups
u cleanup
```

## 🔧 Installation

### System Requirements
- **Operating System**: Linux (Ubuntu 20.04+), macOS 10.15+
- **Memory**: 4GB RAM minimum, 8GB recommended
- **Storage**: 2GB free space for tools and dependencies
- **Network**: Internet connection for package downloads

### Quick Installation Script
```bash
# Download and run installation script
curl -fsSL https://raw.githubusercontent.com/your-repo/scripts/main/install.sh | bash
```

### Manual Installation

#### Dockerz
```bash
# Download binary
wget https://github.com/your-repo/dockerz/releases/download/v2.75/dockerz-linux-amd64
sudo mv dockerz-linux-amd64 /usr/local/bin/dockerz
sudo chmod +x /usr/local/bin/dockerz
```

#### Ansible
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install ansible

# macOS
brew install ansible
```

#### u-cli
```bash
# Download and install
curl -fsSL https://u.sh/install | sudo bash
```

## ⚡ Usage Examples

### 🏗️ Complete Development Environment Setup
```bash
# 1. Set up system configuration
cd conf && bash main.sh

# 2. Install infrastructure tools
cd ansible && ansible-playbook provision-vm.yml

# 3. Configure container management
cd dockerz && dockerz init

# 4. Set up universal undo
curl -fsSL https://u.sh/install | sudo bash && u init
```

### 🚀 CI/CD Pipeline with Dockerz
```bash
# 1. Initialize Dockerz project
dockerz init

# 2. Configure for your project
cat > build.yaml << EOF
project: my-gcp-project
gar: my-registry
region: us-central1
max_processes: 8
smart: true
git_track: true
cache: true
EOF

# 3. Build with smart features
dockerz build --smart --git-track --cache

# 4. Push to registry
dockerz build --push-to-gar
```

### ☁️ GCP Multi-Project Management
```bash
# 1. Configure switch tool
cat > gcloud-kubectl-switch.conf << EOF
CONFIGS=(
  ["prod"]="my-prod-project|user@company.com|gke-prod-cluster|us-central1|prod"
  ["dev"]="my-dev-project|user@company.com|gke-dev-cluster|us-west1|dev"
)
EOF

# 2. Switch between environments
switch prod
switch dev
```

### 🛠️ Development Workflow with Universal Undo
```bash
# 1. Initialize tracking
u init

# 2. Work normally (tracking is automatic)
git clone https://github.com/user/repo.git
mv file.txt new_location/
rm old_file.txt

# 3. Undo mistakes
u          # Undo last operation
u 2        # Undo last two operations

# 4. View history
u log
```

## 🏗️ Architecture

### System Overview
```
┌─────────────────────────────────────────────────────────────┐
│                    Adhbhut's DevOps Toolkit                 │
├─────────────────────────────────────────────────────────────┤
│  🚀 Presentation Layer                                      │
│  ├── CLI Tools (Dockerz, u-cli, switch)                    │
│  ├── Shell Scripts (conf, ansible, general)                │
│  └── Configuration Files (YAML, INI, Shell)                │
├─────────────────────────────────────────────────────────────┤
│  🛠️ Application Layer                                       │
│  ├── Container Management (Dockerz)                        │
│  ├── System Configuration (conf)                           │
│  ├── Infrastructure (ansible)                              │
│  ├── Development Tools (u-cli, kubepat)                    │
│  └── CI/CD Utilities (general)                             │
├─────────────────────────────────────────────────────────────┤
│  🔧 Infrastructure Layer                                    │
│  ├── Docker Engine                                         │
│  ├── Kubernetes Cluster                                    │
│  ├── GCP Services                                          │
│  └── System Packages                                       │
└─────────────────────────────────────────────────────────────┘
```

### Dockerz Architecture
```
dockerz/
├── cmd/
│   └── dockerz/          # CLI entry point with ASCII art banner
├── internal/
│   ├── builder/          # Parallel Docker image building
│   ├── cache/            # Multi-level caching (layer, hash, registry)
│   ├── config/           # Configuration management and validation
│   ├── discovery/        # Service discovery and file scanning
│   ├── git/              # Git change detection and tracking
│   └── smart/            # Intelligent build orchestration
├── tests/                # Comprehensive test scenarios
└── debian/               # Debian package configuration
```

### Ansible Structure
```
ansible/
├── inventory.ini         # Target hosts configuration
├── provision-vm.yml      # Main provisioning playbook
└── roles/               # Reusable automation roles
```

### Configuration Management
```
conf/
├── main.sh              # Primary setup script
├── setup_*.sh           # Individual component setup
├── themes/              # GNOME theme configurations
├── wallpapers/          # Desktop backgrounds
└── backup/              # Configuration backups
```

## 🐛 Troubleshooting

### Common Issues

#### Dockerz Problems
```bash
# Permission denied
sudo usermod -aG docker $USER
newgrp docker

# build.yaml not found
dockerz init

# Docker daemon not running
sudo systemctl start docker
```

#### Ansible Issues
```bash
# Permission denied
ssh-keygen -t rsa -b 4096
ssh-copy-id user@hostname

# Missing Python
sudo apt install python3 python3-pip
```

#### System Configuration Problems
```bash
# Theme not applying
sudo systemctl restart gdm

# Shell not loading
source ~/.bashrc  # or ~/.zshrc

# Missing dependencies
bash conf/install_packages.sh
```

#### Universal Undo Issues
```bash
# Tracking not working
u init

# Command not found
echo 'source ~/scripts/u-cli/u.sh' >> ~/.bashrc
source ~/.bashrc
```

### Debug Mode
Most tools support verbose logging:
```bash
# Dockerz verbose output
dockerz build -v

# Ansible verbose mode
ansible-playbook -v playbook.yml

# u-cli debug mode
u --debug log
```

### Log Locations
- **Dockerz**: `./build.log`
- **Ansible**: Console output (use `-v` for verbose)
- **u-cli**: `~/.u/history.log`
- **System**: `~/.config/adhbhut_theme_backup/`

## 🤝 Contributing

### Development Setup
```bash
# Fork and clone the repository
git clone https://github.com/your-username/scripts.git
cd scripts

# Install development dependencies
make install-dev

# Run tests
make test
```

### Contribution Guidelines

1. **Fork the Repository**: Create your own fork of this repository
2. **Create Feature Branch**: `git checkout -b feature/your-feature`
3. **Make Changes**: Implement your improvements
4. **Test Thoroughly**: Ensure all existing functionality works
5. **Update Documentation**: Keep README and tool docs current
6. **Submit Pull Request**: Describe your changes clearly

### Code Style
- **Shell Scripts**: Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- **Go Code**: Use `gofmt` and follow [Effective Go](https://golang.org/doc/effective_go.html)
- **YAML**: Use 2-space indentation, no tabs
- **Documentation**: Use clear, concise language with examples

### Testing
```bash
# Run all tests
make test

# Test specific tool
cd dockerz && go test ./...

# Test shell scripts
shellcheck conf/*.sh
```

### Reporting Issues
When reporting bugs or requesting features:

1. **Search Existing Issues**: Check if your issue is already reported
2. **Provide Details**: Include OS, tool versions, and reproduction steps
3. **Include Logs**: Attach relevant error messages and logs
4. **Minimal Example**: Provide a minimal reproduction case when possible

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2024 Adhbhut Gupta

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## 🙏 Acknowledgments

- **Docker Community**: For the amazing containerization platform
- **Kubernetes Team**: For revolutionizing container orchestration
- **Ansible Contributors**: For making infrastructure automation accessible
- **Go Community**: For the excellent programming language and tools
- **All Contributors**: For their time and effort in improving this toolkit

## 📞 Contact

- **Developer**: Adhbhut Gupta
- **Email**: [your-email@example.com](mailto:your-email@example.com)
- **Issues**: [GitHub Issues](https://github.com/your-repo/scripts/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-repo/scripts/discussions)

---

**Made with ❤️ for the DevOps community**

[![GitHub stars](https://img.shields.io/github/stars/your-repo/scripts?style=social)](https://github.com/your-repo/scripts)
[![Twitter Follow](https://img.shields.io/twitter/follow/yourhandle?style=social)](https://twitter.com/yourhandle)