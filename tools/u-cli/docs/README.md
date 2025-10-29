# U-CLI v1.0 - Universal CLI Tool

U-CLI is a powerful command-line interface tool designed to enhance development workflows and provide universal utilities for DevOps tasks.

## Features

- **File System Monitoring**: Real-time file system change detection
- **Configuration Management**: Flexible YAML-based configuration system
- **Backup & Restore**: Automated backup and restoration capabilities
- **Shell Integration**: Seamless integration with various shell environments
- **Mapping System**: Intelligent file and directory mapping utilities

## Installation

### From Source (Go)
```bash
git clone <repository-url>
cd u-cli
go build -o u-cli ./main.go
```

### Using Go Install
```bash
go install github.com/addy-47/u-cli@latest
```

### Using apt (Debian/Ubuntu)
```bash
curl -fsSL https://addy-47.github.io/scripts/apt/setup.sh | sudo bash
sudo apt update && sudo apt install u-cli
```

## Quick Start

1. Install U-CLI using one of the methods above

2. Initialize configuration:
   ```bash
   u-cli init
   ```

3. Start monitoring:
   ```bash
   u-cli monitor
   ```

## Usage

```bash
u-cli [command] [flags]
```

Available commands:
- `init`: Initialize U-CLI configuration
- `monitor`: Start file system monitoring
- `backup`: Create backup of current state
- `restore`: Restore from backup
- `completion`: Generate shell autocompletion scripts

## Configuration

U-CLI uses a YAML configuration file (`u-map.yaml`) for customization. The configuration includes:

- **Monitoring Paths**: Directories to monitor for changes
- **Backup Settings**: Backup frequency and retention policies
- **Mapping Rules**: File and directory mapping configurations
- **Shell Integration**: Shell-specific settings

### Example Configuration

```yaml
# U-CLI Configuration
version: "1.0"

# Monitoring configuration
monitor:
  paths:
    - ~/projects
    - ~/config
  exclude_patterns:
    - "*.tmp"
    - ".git/*"

# Backup configuration
backup:
  enabled: true
  interval: "1h"
  retention: "7d"
  destination: "~/.u-cli/backups"

# Mapping configuration
mapping:
  rules:
    - source: "~/projects/scripts"
      target: "~/bin/scripts"
      sync: true
```

## Prerequisites

- **Go 1.19+** (for building from source)
- **Git** (for version control integration)
- **Supported OS**: Linux, macOS, Windows

## Commands

### Initialize
```bash
u-cli init
```
Creates default configuration files and sets up the environment.

### Monitor
```bash
u-cli monitor
```
Starts real-time file system monitoring with change detection.

### Backup
```bash
u-cli backup
```
Creates a backup of the current configuration and monitored files.

### Restore
```bash
u-cli restore [backup-name]
```
Restores from a specific backup or the latest backup.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| **Permission Denied** | Run with appropriate permissions or use sudo |
| **Configuration Not Found** | Run `u-cli init` to create default configuration |
| **Monitoring Not Working** | Check file system permissions and path configurations |
| **Backup Failed** | Verify destination directory exists and has write permissions |

## License

See individual tool licenses for details.