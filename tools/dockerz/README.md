# Dockerz v2.0 - Smart Multi-Service Docker Builder

Dockerz is a powerful CLI tool for building and pushing multiple Docker images in parallel, with advanced smart features for optimized CI/CD workflows. It supports intelligent change detection, multi-level caching, and smart build orchestration to significantly improve build performance.

## 🚀 Key Features

### Core Features
- **Parallel Building**: Build multiple Docker images simultaneously for faster CI/CD pipelines
- **Google Artifact Registry**: Native support for GAR with automatic authentication
- **Flexible Configuration**: YAML-based configuration with environment variable overrides

### 🧠 Smart Features (v2.0)
- **Git Change Detection**: Automatically detect which services have changed using git diff
- **Multi-Level Caching**: Layer, local hash, and registry-based caching for optimal performance
- **Smart Build Orchestration**: Skip unchanged services, only rebuild what needs rebuilding
- **SHA256 Hash Calculation**: Content-based hashing for accurate change detection
- **Intelligent CLI**: Comprehensive command-line interface with override flags

## Installation

### From Source (Go)
```bash
git clone <repository-url>
cd dockerz
go build -o dockerz ./cmd/dockerz
```

### Using Go Install
```bash
go install github.com/addy-47/dockerz/cmd/dockerz@latest
```

### Using pip (Legacy Python version)
```bash
pip install dockerz
```

### Using apt (Debian/Ubuntu)
```bash
curl -fsSL https://addy-47.github.io/scripts/apt/setup.sh | sudo bash
sudo apt update && sudo apt install dockerz
```

## Quick Start

1. Install the package using one of the installation methods above.

2. Initialize a new project:

   ```bash
   dockerz init
   ```

   This will create a sample `services.yaml` configuration file in your current directory.

3. Edit the `services.yaml` file to configure your services

4. Build your Docker images:
   ```bash
   dockerz build
   ```

## Quick Start

1. **Install Dockerz** using one of the methods above

2. **Initialize a new project:**
   ```bash
   dockerz init
   ```

3. **Edit the generated `services.yaml`** with your service configurations

4. **Build all services:**
   ```bash
   dockerz build
   ```

5. **Smart build with change detection:**
   ```bash
   dockerz build --smart --git-track
   ```

## Running Dockerz

After installation, run Dockerz from your project root directory:

```bash
dockerz [command] [flags]
```

Available commands:
- `init`: Create a new project with sample configuration
- `build`: Build Docker images based on services.yaml configuration
- `completion`: Generate shell autocompletion scripts

For help on any command:
```bash
dockerz [command] --help
```

> **Important Note**: Dockerz must be run from the root directory of the project where you intend to build Docker images.

## Prerequisites

Before you begin, ensure the following tools are installed and configured on your system.

| Requirement                     | Purpose                                                            | Verification        |
| :------------------------------ | :----------------------------------------------------------------- | :------------------ |
| **Go 1.19+** (for building)      | Required to build Dockerz from source.                             | `go version`        |
| **Docker**                      | Required for building Docker images.                               | `docker --version`  |
| **Git**                         | Required for change detection and default version tagging.         | `git --version`     |
| **Google Cloud SDK** (Optional) | Required only if pushing images to Google Artifact Registry (GAR). | `gcloud --version`  |

### System Requirements

| Component      | Recommendation                                                    |
| :------------- | :---------------------------------------------------------------- |
| **OS**         | Linux, macOS, or Windows (WSL2 recommended).                      |
| **CPU**        | A multi-core CPU is recommended for parallel builds.              |
| **Memory**     | At least 4GB of RAM. 8GB+ is recommended for 10 or more services. |
| **Disk Space** | Sufficient disk space to store Docker images and build caches.    |

## Usage

### Basic Usage

1. **Initialize a project:**
   ```bash
   dockerz init
   ```

2. **Build all services:**
   ```bash
   dockerz build
   ```

3. **Build with custom parallel processes:**
   ```bash
   dockerz build --max-processes 8
   ```

### Smart Features Usage

#### Enable Smart Orchestration
```bash
dockerz build --smart
```

#### Git-Based Change Detection
```bash
dockerz build --smart --git-track
```

#### Multi-Level Caching
```bash
dockerz build --smart --cache
```

#### Force Rebuild Everything
```bash
dockerz build --force
```

#### Override Configuration Values
```bash
dockerz build --project-id my-project --region us-west1 --gar-name my-registry --tag v2.0.0
```

#### CI/CD Integration with Changed Services
```bash
# Use external change detection
dockerz build --changed-services-file changed_services.txt

# Generate change detection for downstream steps
dockerz build --git-track --smart --output-changed-services changed_services.txt
```

#### Combined Smart Build
```bash
dockerz build --smart --git-track --cache --max-processes 6
```

## Configuration

Dockerz is configured through a `services.yaml` file located in your project's root directory. You can create a sample configuration file using:

```bash
dockerz init
```

### Example `services.yaml`

```yaml
# Base directory to scan for Dockerfiles (relative to project root)
services_dir: ./services

# Google Cloud Configuration
project_id: my-gcp-project
gar_name: my-artifact-registry
region: us-central1

# Build Configuration
global_tag: v1.0.0 # Optional: A global tag applied to all services
max_processes: 4 # Optional: Max parallel builds (defaults to half of CPU cores)
use_gar: true # Optional: Use Google Artifact Registry naming (default: true)
push_to_gar: true # Optional: Push to GAR after building (default: same as use_gar)

# Smart Features Configuration (v2.0)
smart_enabled: true # Enable smart build orchestration
git_tracking: true # Enable git change detection
cache_enabled: true # Enable build caching
force_rebuild: false # Force rebuild all services

# Optional: Explicitly list services to build
services:
  - name: services/service-a
    image_name: service-a-image # Optional: Custom image name
    tag: v1.0.1 # Optional: Service-specific tag
  - name: services/service-b
  - name: subdir/service-c
```

### Configuration Fields

| Field           | Description                                                                                                                                                                    |
| :-------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `services_dir`  | The base directory to recursively scan for Dockerfiles. If omitted, you must explicitly list the services to be built.                                                         |
| `project_id`    | Your Google Cloud project ID.                                                                                                                                                  |
| `gar_name`      | The name of your Google Artifact Registry repository.                                                                                                                          |
| `region`        | The GAR region (e.g., `us-central1`).                                                                                                                                          |
| `global_tag`    | An optional tag applied to all services unless a service-specific tag is provided.                                                                                             |
| `max_processes` | The maximum number of parallel builds. Defaults to half the available CPU cores.                                                                                               |
| `services`      | A list of service directories (relative paths) and optional tags. If this is omitted, the script will build all subdirectories containing a `Dockerfile` under `services_dir`. |
| `name`          | The relative path to the service directory containing the `Dockerfile`.                                                                                                        |
| `image_name`    | Optional custom image name for the service. If not provided, the script will construct the image name based on the GAR format or use the service directory name.               |
| `tag`           | Optional service-specific tag. If not provided, the script defaults to the short Git commit ID.                                                                                |
| `use_gar`       | If `true`, images will be named using the GAR format. Defaults to `true`.                                                                                                      |
| `push_to_gar`   | If `true`, images will be pushed to GAR after a successful build. Defaults to the value of `use_gar`.                                                                          |
| `smart_enabled` | Enable smart build orchestration (v2.0). Defaults to `false`.                                                                                                                  |
| `git_tracking`  | Enable git change detection for smart builds (v2.0). Defaults to `false`.                                                                                                       |
| `cache_enabled` | Enable build caching (v2.0). Defaults to `false`.                                                                                                                               |
| `force_rebuild` | Force rebuild all services, bypassing smart optimizations (v2.0). Defaults to `false`.                                                                                          |

### CLI Flags for Configuration Override

| Flag | Description |
|------|-------------|
| `--project-id` | Override GCP project ID |
| `--region` | Override GCP region |
| `--gar-name` | Override Google Artifact Registry name |
| `--tag` | Override global tag for all images |
| `--changed-services-file` | Input file with list of services to build |
| `--output-changed-services` | Output file for detected changed services |

### Environment Variables

You can override configuration settings using environment variables:

| Variable      | Description                                                                               |
| :------------ | :---------------------------------------------------------------------------------------- |
| `USE_GAR`     | Set to `true` or `false` to override the `use_gar` setting in the configuration file.     |
| `PUSH_TO_GAR` | Set to `true` or `false` to override the `push_to_gar` setting in the configuration file. |

### Command Line Flags

All configuration values can be overridden using command-line flags:

```bash
dockerz build --project-id my-project --region us-west1 --gar-name my-registry --tag v2.0.0 --smart --git-track --cache
```

See `dockerz build --help` for a complete list of available flags.

## Features

### Core Features
- **Parallel Builds**: Concurrently builds Docker images to save time, with a configurable limit to prevent system overload.
- **Flexible Directory Structure**: Supports services in nested subdirectories.
- **Configurable**: Uses a `services.yaml` file to manage service directories, GAR details, and tags.
- **Flexible Tagging**: Supports a global tag, service-specific tags, or defaults to the short Git commit ID.
- **Error Handling**: Logs build successes and failures to a file and the console without interrupting other builds.
- **Image Naming**: Constructs image names in the format `{region}-docker.pkg.dev/{project_id}/{gar_name}/{service_name}:{tag}`.

### Smart Features (v2.0)
- **Git Change Detection**: Automatically detects which services have changed using git diff analysis.
- **Multi-Level Caching**: Implements layer, local hash, and registry-based caching for optimal performance.
- **Smart Build Orchestration**: Intelligently skips unchanged services, only rebuilding what needs rebuilding.
- **SHA256 Hash Calculation**: Uses content-based hashing for accurate change detection and caching.
- **Comprehensive CLI**: Rich command-line interface with override flags for all configuration options.

## Google Artifact Registry (GAR) Integration

Dockerz integrates seamlessly with Google Artifact Registry for enterprise-grade container management.

### Setup GAR Integration

1. **Enable GAR in configuration:**
   ```yaml
   use_gar: true
   push_to_gar: true
   project_id: my-gcp-project
   gar_name: my-artifact-registry
   region: us-central1
   ```

2. **Authenticate with GAR:**
   ```bash
   gcloud auth configure-docker REGION-docker.pkg.dev
   ```

### GAR Features

- **Automatic Naming**: Images use the format `{region}-docker.pkg.dev/{project_id}/{gar_name}/{service_name}:{tag}`
- **Custom Image Names**: Override default naming with `image_name` in service configuration
- **Push Integration**: Automatically push successful builds to GAR
- **Error Handling**: Failed pushes are logged separately without stopping other builds
- **Detailed Logging**: Build and push logs stored for troubleshooting

### Override GAR Settings

Use CLI flags to override GAR configuration:
```bash
dockerz build --project-id new-project --region us-west2 --gar-name new-registry
```

## Smart Features Deep Dive

### Automatic Image Name Normalization
Dockerz v2.0 automatically converts service directory names to Docker-compatible kebab-case:

**Examples:**
- `PDF_processing` → `pdf-processing`
- `MyService` → `myservice`
- `some_service-name` → `some-service-name`
- `API_Gateway.v2` → `api-gateway-v2`

This eliminates manual configuration in CI/CD pipelines.

### Git Change Detection
When `--git-track` is enabled, Dockerz analyzes git history to detect which services have changed:

```bash
dockerz build --smart --git-track
```

**How it works:**
- Compares current working directory with last commit
- Identifies modified, added, or deleted files
- Only rebuilds services containing changed files
- Significantly reduces build times for large projects

### Multi-Level Caching
Dockerz implements three levels of caching for optimal performance:

```bash
dockerz build --smart --cache
```

**Cache Levels:**
- **Layer Cache**: Caches Docker layer information for faster rebuilds
- **Local Hash Cache**: Stores SHA256 hashes of service contents
- **Registry Cache**: Caches build results in the container registry

### Smart Orchestration
The `--smart` flag enables intelligent build decisions:

```bash
dockerz build --smart --git-track --cache --max-processes 6
```

**Orchestration Logic:**
1. Calculate SHA256 hash of each service
2. Check git for changes since last build
3. Compare with cached build results
4. Skip services that haven't changed
5. Build only necessary services in parallel

### CI/CD Integration

#### Using External Change Detection
```bash
# Your CI/CD pipeline detects changes and creates changed_services.txt
echo "services/api-gateway" > changed_services.txt
echo "services/user-service" >> changed_services.txt

# Dockerz builds only the changed services
dockerz build --changed-services-file changed_services.txt
```

#### Generating Change Detection for Downstream Steps
```bash
# Dockerz detects changes and outputs to file for other pipeline steps
dockerz build --git-track --smart --output-changed-services changed_services.txt

# Other pipeline steps can use this file
for service in $(cat changed_services.txt); do
  echo "Deploying $service"
  # deployment logic here
done
```

**Changed Services File Format:**
```
services/api-gateway
services/user-service
backend/service1/frontend
```

## Packaging Instructions

### For Windows:
```bash
# Build for Windows
GOOS=windows GOARCH=amd64 go build -o dockerz.exe ./cmd/dockerz

# Create ZIP archive
zip dockerz-windows-amd64.zip dockerz.exe README.md
```

### For macOS:
```bash
# Build for macOS
GOOS=darwin GOARCH=amd64 go build -o dockerz ./cmd/dockerz

# Create tar.gz archive
tar -czf dockerz-darwin-amd64.tar.gz dockerz README.md
```

### For Linux (Debian):
```bash
# Update version in debian/changelog (already done)
# Build the .deb package
dpkg-buildpackage -us -uc

# The .deb file will be created in the parent directory
```

## Troubleshooting

| Issue                         | Solution                                                                                                        |
| :---------------------------- | :-------------------------------------------------------------------------------------------------------------- |
| **Binary Not Found**          | Use the absolute path to the binary or add it to your PATH.                                                     |
| **`services.yaml` Not Found** | Ensure the `services.yaml` file is in your project's root directory.                                            |
| **Wrong Working Directory**   | Always run Dockerz from the root of the project where you want to build Docker images.                          |
| **Path Errors**               | Verify that the relative paths in `services.yaml` are correct and that Dockerz is run from the project root.    |
| **System Overload**           | Reduce the `max_processes` value in `services.yaml` or via the `--max-processes` flag.                          |
| **Docker Permission Errors**  | On Linux, run `sudo usermod -aG docker $USER` and then log out and back in.                                     |
| **Missing `Dockerfile`**      | Ensure that each service directory contains a valid `Dockerfile`.                                               |
| **Git Errors**                | Make sure the project is a Git repository. If not, run `git init`.                                              |
| **GAR Authentication**        | Authenticate with GAR by running `gcloud auth configure-docker {region}-docker.pkg.dev`.                        |
| **Smart Features Not Working**| Ensure you're in a git repository and have committed changes. Use `--force` to bypass smart features.           |
