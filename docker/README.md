# Multi-Service Docker Build Script

This Python script automates building multiple Docker images in parallel for services located in a project directory, including nested subdirectories. It saves time during namespace migrations or branch deployments by eliminating manual, sequential builds. The script supports configurable image names, global and service-specific tags, and defaults to the short Git commit ID if no tag is specified.

## Features

- **Parallel Builds**: Builds Docker images concurrently using Python's multiprocessing, with a configurable limit to prevent system overload
- **Flexible Directory Structure**: Supports services in nested subdirectories (e.g., `services/service-a`, `subdir/service-b`) using relative paths
- **Configurable**: Reads a `services.yaml` file to specify service directories, Google Artifact Registry (GAR) details, and tags
- **Flexible Tagging**: Supports a global tag, service-specific tags, or defaults to the short Git commit ID
- **Error Handling**: Logs build successes and failures to a file and console without stopping other builds
- **Image Naming**: Constructs image names as `{region}-docker.pkg.dev/{project_id}/{gar_name}/{service_name}:{tag}`

## ## Prerequisites

Before using the script, ensure the following are installed and configured:

### Python 3.8+
- Required to run the script
- Install from [python.org](https://python.org) or your package manager (e.g., apt, brew, yum)
- Verify with: `python3 --version`

### Docker
- Required to build Docker images
- Install [Docker Desktop](https://www.docker.com/products/docker-desktop) (Windows/Mac) or [Docker Engine](https://docs.docker.com/engine/install/) (Linux)
- Ensure the Docker daemon is running and your user has Docker permissions
  ```bash
  # Add user to docker group on Linux
  sudo usermod -aG docker $USER
  ```
- Verify with: `docker --version`

### Git
- Required to fetch the short commit ID for default tags
- Install from [git-scm.com](https://git-scm.com) or your package manager
- Verify with: `git --version`


### PyYAML
- Python library for parsing YAML configuration files
- Install via pip: `pip install pyyaml`
- Verify with: `pip show pyyaml`

### Google Cloud SDK (Optional)
- Required only if pushing images to Google Artifact Registry (GAR)
- Install from [cloud.google.com/sdk](https://cloud.google.com/sdk)
- Authenticate with GAR: 
  ```bash
  gcloud auth configure-docker {region}-docker.pkg.dev
  ```
- Verify with: `gcloud --version`

## System Requirements

| Component | Requirement |
|-----------|------------|
| OS | Linux, macOS, or Windows (WSL2 recommended for Windows) |
| CPU | Multi-core CPU for parallel builds |
| Memory | At least 4GB RAM (8GB+ recommended for 10–12+ services) |
| Disk Space | Sufficient space for Docker images and build cache |



## Setup

### 1. Clone the Repository (if applicable)
```bash
git clone <repository-url>
```

### 2. Prepare Service Directories
- Organize services in the project directory, with each service in its own subdirectory containing a `Dockerfile`
- Services can be in nested subdirectories (e.g., `services/service-a`, `subdir/service-b`)

Example structure:
```
project_root/
├── services/
│   ├── service-a/
│   │   └── Dockerfile
│   ├── service-b/
│   │   └── Dockerfile
├── subdir/
│   ├── service-c/
│   │   └── Dockerfile
├── services.yaml
└── build_services.py
```




### 3. Create Configuration File

Create a `services.yaml` file in the project root using relative paths for flexibility.

Example `services.yaml`:
```yaml
# Base directory to scan for Dockerfiles (relative path)
services_dir: ./services

# Google Cloud Configuration
project_id: my-project
gar_name: my-artifact-registry
region: us-central1

# Build Configuration
global_tag: v1.0.0  # Optional global tag
max_processes: 4    # Max parallel builds (optional, defaults to half CPU cores)

# Optional: explicitly list services
services:
  - name: services/service-a
    tag: v1.0.1  # Optional service-specific tag
  - name: services/service-b
  - name: subdir/service-c
```

#### Configuration Fields

| Field | Description |
|-------|-------------|
| `services_dir` | Base directory to recursively scan for Dockerfiles (relative to project root). If omitted, services must be explicitly listed |
| `project_id` | Google Cloud project ID |
| `gar_name` | GAR repository name |
| `region` | GAR region (e.g., us-central1) |
| `global_tag` | Tag applied to all services unless overridden (optional) |
| `max_processes` | Maximum number of parallel builds (optional) |
| `services` | List of service directories (relative paths) and optional tags. If omitted, all subdirectories with Dockerfiles under services_dir are built |




### 4. Install Dependencies
```bash
pip install pyyaml
```

## Usage

### Running the Script

1. Place `build_services.py` in the project root
2. Run from the project root:
   ```bash
   python3 build_services.py
   ```
   Optional: Specify max processes:
   ```bash
   python3 build_services.py --max-processes 4
   ```

The script will:
- Read `services.yaml`
- Discover services (via `services_dir` or explicit services list)
- Validate Dockerfiles in each service directory
- Build images in parallel, respecting `max_processes`
- Log progress and errors to `build.log` and console

### Example Output

Images will be named following this pattern:
```
us-central1-docker.pkg.dev/my-project/my-artifact-registry/service-a:v1.0.1
```
Default tag: Short Git commit ID (e.g., `abc1234`) if no tag specified

### Optional: Push to GAR

1. Ensure GAR authentication:
   ```bash
   gcloud auth configure-docker {region}-docker.pkg.dev
   ```
2. Modify the script to include `docker push` or run manually after builds



## Configuration Details

| Feature | Description |
|---------|-------------|
| Nested Directories | Use relative paths in `services.yaml` (e.g., `services/service-a`, `subdir/service-c`). Run the script from the project root |
| Parallel Builds | Controlled by `max_processes` in `services.yaml` or via `--max-processes`. Defaults to half the CPU cores |
| Service Discovery | Script recursively scans `services_dir` for Dockerfiles if `services` is omitted |
| Tag Fallback | Uses `global_tag`, service-specific tag, or short Git commit ID (via `git rev-parse --short HEAD`) |
| Logging | Outputs to `build.log` and console for debugging |

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Path Errors | Ensure relative paths in `services.yaml` are correct and run script from project root |
| System Overload | Reduce `max_processes` in `services.yaml` or via `--max-processes` |
| Docker Permission Errors | Run `sudo usermod -aG docker $USER` (Linux) and log out/in |
| Missing Dockerfile | Verify each service directory contains a `Dockerfile` |
| PyYAML Not Found | Install with `pip install pyyaml` |
| Git Errors | Ensure the project is a Git repository (`git init` if needed) |
| GAR Authentication | Run `gcloud auth configure-docker {region}-docker.pkg.dev` |

## Next Steps

1. Review `services.yaml` and adjust paths/tags as needed
2. Test with a small number of services and low `max_processes` (e.g., 2)
3. Check `build.log` for issues
4. If pushing to GAR, test authentication with a single service
