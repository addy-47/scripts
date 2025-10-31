# Scripts Repository

This repository contains a collection of utility scripts and tools designed to automate and streamline various development and operational tasks. Each tool is self-contained in its own directory and includes its own detailed documentation.

## Tools Overview

| Tool | Description | Documentation |
| :--- | :--- | :--- |
| `ansible` | Ansible playbooks for VM provisioning and configuration management. | [`ansible/`](./ansible/) |
| `conf` | System configuration scripts for customizing Linux environments including shell, git, tmux, and system settings. | [`conf/`](./conf/) |
| `dockerz` | A parallel Docker build tool for automating the construction of multiple Docker images with smart caching and Git integration. | [`dockerz/README.md`](./dockerz/README.md) |
| `gcp-k8s` | A tool to easily switch between different `gcloud` and `kubectl` contexts for multi-project GCP/GKE environments. | [`gcp-k8s/README.md`](./gcp-k8s/README.md) |
| `general` | General-purpose scripts for deployment and Docker operations. | [`general/`](./general/) |
| `kubepat` | A Python script for patching Kubernetes resources with YAML configurations. | [`kubepat/`](./kubepat/) |
| `mongo-migrate` | A tool for automating MongoDB data migrations between VMs and Kubernetes StatefulSets. | [`mongo-migrate/README.md`](./mongo-migrate/README.md) |
| `u-cli` | A CLI tool for managing system configurations with backup capabilities and filesystem monitoring. | [`u-cli/README.md`](./u-cli/README.md) |

## Getting Started

To use a specific tool or script:

1. Navigate to the tool's directory
2. Check the tool's README or documentation for specific requirements
3. Follow the installation and configuration instructions

Most tools have their own configuration files and setup requirements. Some tools may require building from source or installing dependencies.

## Contributing

Contributions are welcome! Please feel free to:
- Open an issue for bugs or feature requests
- Submit a pull request with improvements
- Suggest new tools or scripts that could benefit the collection



apt repo step failing 