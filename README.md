# Dockerz v2.5.0 - Intelligent Multi-Service Docker Builder

Dockerz is a powerful CLI tool for building and pushing multiple Docker images in parallel with advanced **smart features** for optimized CI/CD workflows. It combines intelligent change detection, multi-level caching, and smart build orchestration to dramatically improve build performance and reduce CI/CD pipeline times.

## 🚀 Key Features

### Core Features
- **Parallel Building**: Build multiple Docker images simultaneously with configurable process limits
- **Google Artifact Registry (GAR)**: Native support for GAR with automatic authentication and image naming
- **Auto-Discovery**: Automatically find and build services from directory structure or explicit configurations
- **Flexible Configuration**: YAML-based configuration with comprehensive CLI flag overrides
- **Cross-Platform**: Works on Linux, macOS, and Windows (WSL2)

### 🧠 Smart Features (v2.5)
- **Git Change Detection**: Automatically detect which services have changed using git diff analysis
- **Multi-Level Caching**: Layer, local hash, and registry-based caching for optimal performance
- **Smart Build Orchestration**: Intelligently skip unchanged services, only rebuild what needs rebuilding
- **SHA256 Hash Calculation**: Content-based hashing for accurate change detection
- **CI/CD Integration**: Input/output files for changed services to integrate with external CI/CD systems
- **Intelligent Discovery**: Auto-excludes build directories, dependency folders, and version control systems

## Installation

> **Note**: Dockerz is already installed on your system. Verify with: `dockerz --version`

### For Development
```bash
git clone <repository-url>
cd dockerz
go build -o dockerz ./cmd/dockerz
```

### For Users
Dockerz is distributed as a standalone binary. Download the latest release for your platform from the releases page and add it to your PATH.

## Quick Start

1. **Initialize a new project:**
   ```bash
   dockerz init
   ```

2. **Edit the generated `services.yaml`** with your service configurations

3. **Build all services:**
   ```bash
   dockerz build
   ```

4. **Smart build with change detection (recommended for CI/CD):**
   ```bash
   dockerz build --smart --git-track --cache
   ```

## Prerequisites

| Requirement | Purpose | Verification |
|-------------|---------|--------------|
| **Docker** | Required for building Docker images | `docker --version` |
| **Git** | Required for change detection and default tagging | `git --version` |
| **Go 1.19+** (for building from source) | Required to build Dockerz | `go version` |
| **Google Cloud SDK** (Optional) | Required only for GAR integration | `gcloud --version` |

## Usage

### Basic Usage

```bash
# Initialize project configuration
dockerz init

# Build all discovered services
dockerz build

# Build with custom parallel processes
dockerz build --max-processes 8

# Build with custom configuration
dockerz build --project my-project --region us-west1 --gar my-registry --tag v2.5.0
```

### Smart Features Usage

#### Enable Smart Build Orchestration
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

#### Combined Smart Build (Recommended for CI/CD)
```bash
dockerz build --smart --git-track --cache --max-processes 6
```

### Advanced Usage

#### CI/CD Integration with External Change Detection
```bash
# Use external change detection
dockerz build --input-changed-services changed_services.txt

# Generate change detection for downstream steps
dockerz build --git-track --smart --output-changed-services changed_services.txt
```

#### Build with Custom Services Directory
```bash
# Scan specific directories for services
dockerz build --services-dir ./backend,./frontend,./api
```

#### Git Track Depth Configuration
```bash
# Check last 3 commits for changes (default is 2)
dockerz build --smart --git-track --git-track-depth 3
```

#### Build Specific Services
```bash
# Build only explicitly defined services
dockerz build --services-dir services/api,services/web
```

## Configuration

Dockerz is configured through a `services.yaml` file. Generate a sample configuration:

```bash
dockerz init
```

### Example `services.yaml`

```yaml
# Dockerz v2.5 Configuration
# This file configures how Dockerz builds and manages your microservices.

# ===== DIRECTORY CONFIGURATION =====
# Directory to scan for services (leave empty for auto-discovery)
services_dir: 

# ===== GOOGLE CLOUD CONFIGURATION =====
project: my-gcp-project          # Your GCP project ID
gar: my-artifact-registry        # GAR repository name
region: us-central1              # GCP region

# ===== BUILD CONFIGURATION =====
global_tag: latest               # Global tag (defaults to Git commit hash)
max_processes: 4                 # Max parallel builds
use_gar: true                    # Use GAR naming
push_to_gar: true                # Push to GAR after building

# ===== SMART FEATURES (v2.5) =====
smart: false                     # Enable smart build orchestration
git_track: false                 # Enable git change detection
cache: false                     # Enable build caching
force: false                     # Force rebuild all services
git_track_depth: 2               # Number of commits to check

# ===== CHANGE DETECTION FILES =====
input_changed_services:          # Input file with changed services
output_changed_services:         # Output file for detected changes

# ===== SERVICE DEFINITIONS =====
# Explicitly define services (leave empty for auto-discovery)
services:
  # - name: services/api
  #   image_name: my-api-service    # Custom image name
  #   tag: v1.0.0                   # Service-specific tag
```

### Configuration Fields

| Field | Description | Default |
|-------|-------------|---------|
| `services_dir` | Base directory to scan for Dockerfiles | Current directory (.) |
| `project` | GCP project ID for GAR | Required for GAR |
| `gar` | GAR repository name | Required for GAR |
| `region` | GCP region for GAR | Required for GAR |
| `global_tag` | Global tag for all images | Git commit hash |
| `max_processes` | Max parallel build processes | 4 |
| `use_gar` | Use GAR naming convention | false |
| `push_to_gar` | Push to GAR after building | false |
| `smart` | Enable smart orchestration | false |
| `git_track` | Enable git change detection | false |
| `cache` | Enable build caching | false |
| `force` | Force rebuild all services | false |
| `git_track_depth` | Commits to check for changes | 2 |

### CLI Override Flags

| Flag | Description | Example |
|------|-------------|---------|
| `--config` | Configuration file path | `--config my-config.yaml` |
| `--max-processes` | Override parallel processes | `--max-processes 8` |
| `--project` | Override GCP project | `--project my-project` |
| `--region` | Override GCP region | `--region us-west1` |
| `--gar` | Override GAR repository | `--gar my-registry` |
| `--global-tag` | Override global tag | `--global-tag v2.5.0` |
| `--services-dir` | Override services directory | `--services-dir ./backend,./api` |
| `--input-changed-services` | Input changed services file | `--input-changed-services changed.txt` |
| `--output-changed-services` | Output changed services file | `--output-changed-services changed.txt` |
| `--git-track` | Enable git tracking | `--git-track` |
| `--git-track-depth` | Git tracking depth | `--git-track-depth 3` |
| `--cache` | Enable caching | `--cache` |
| `--force` | Force rebuild | `--force` |
| `--smart` | Enable smart features | `--smart` |
| `--use-gar` | Use GAR naming | `--use-gar` |
| `--push-to-gar` | Push to GAR | `--push-to-gar` |

## Smart Features Deep Dive

### Automatic Service Discovery
Dockerz v2.5 intelligently discovers services by:
- Scanning for `Dockerfile` files recursively
- Excluding build directories (`debian/`, `build/`, `dist/`)
- Excluding dependency directories (`node_modules/`, `vendor/`, `__pycache__/`)
- Excluding version control (`.git/`, `.svn/`, `.hg/`)
- Excluding IDE directories (`.vscode/`, `.idea/`, `.vs/`)
- Normalizing service names to Docker-compatible kebab-case

### Git Change Detection
When `--git-track` is enabled, Dockerz analyzes git history:

```bash
dockerz build --smart --git-track
```

**How it works:**
1. Compares current working directory with recent commits
2. Identifies modified, added, or deleted files
3. Maps changed files to service directories
4. Only rebuilds services containing changed files
5. Significantly reduces build times for large projects

### Multi-Level Caching
Dockerz implements three cache levels for optimal performance:

```bash
dockerz build --smart --cache
```

**Cache Levels:**
- **Layer Cache**: Caches Docker layer information
- **Local Hash Cache**: Stores SHA256 hashes of service contents  
- **Registry Cache**: Caches build results with TTL

### Smart Orchestration Logic
The `--smart` flag enables intelligent decisions:

1. Calculate SHA256 hash of each service
2. Check git for changes since last build
3. Compare with cached build results
4. Skip services that haven't changed
5. Build only necessary services in parallel
6. Trust Git over cache for accuracy

### CI/CD Integration

#### Using External Change Detection
```bash
# CI/CD pipeline creates changed_services.txt
echo "services/api-gateway" > changed_services.txt
echo "services/user-service" >> changed_services.txt

# Dockerz builds only changed services
dockerz build --input-changed-services changed_services.txt
```

#### Generating Change Detection for Downstream
```bash
# Dockerz detects changes and outputs to file
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

## Google Artifact Registry (GAR) Integration

### Setup GAR Integration

1. **Configure GAR in services.yaml:**
   ```yaml
   use_gar: true
   push_to_gar: true
   project: my-gcp-project
   gar: my-artifact-registry
   region: us-central1
   ```

2. **Authenticate with GAR:**
   ```bash
   gcloud auth configure-docker us-central1-docker.pkg.dev
   ```

### GAR Features

- **Automatic Naming**: `{region}-docker.pkg.dev/{project}/{gar}/{service}:{tag}`
- **Custom Image Names**: Override with `image_name` in service config
- **Push Integration**: Automatically push successful builds
- **Error Handling**: Failed pushes logged separately
- **Build Logging**: Comprehensive logs stored in `build.log`

## Troubleshooting

| Issue | Solution |
|-------|----------|
| **Binary not found** | Use absolute path or add to PATH |
| **services.yaml not found** | Run `dockerz init` or specify with `--config` |
| **Wrong working directory** | Run from project root containing services |
| **Path errors** | Verify relative paths in configuration |
| **System overload** | Reduce `--max-processes` value |
| **Docker permission errors** | Run `sudo usermod -aG docker $USER` |
| **Missing Dockerfile** | Ensure service directories contain valid Dockerfile |
| **Git errors** | Ensure project is a Git repository |
| **GAR authentication** | Run `gcloud auth configure-docker {region}-docker.pkg.dev` |
| **Smart features not working** | Ensure Git repository with committed changes |

## Development

### Building from Source
```bash
git clone <repository-url>
cd dockerz
go build -o dockerz ./cmd/dockerz
```

### Running Tests
```bash
go test ./...
```

### Building for Multiple Platforms
```bash
# Linux
GOOS=linux GOARCH=amd64 go build -o dockerz-linux-amd64 ./cmd/dockerz

# macOS  
GOOS=darwin GOARCH=amd64 go build -o dockerz-darwin-amd64 ./cmd/dockerz

# Windows
GOOS=windows GOARCH=amd64 go build -o dockerz-windows-amd64.exe ./cmd/dockerz
```

## Dockerz 3.0 Roadmap 🎯

<!-- TODO: Implement unified CLI for services and directories -->
- [ ] Add support for `dockerz build [path...] [--image-name NAME] [--tag TAG] ... [global-flags]` where:
  - `path` can be:
    - A **service directory** (e.g. `backend/`) → auto-detects `Dockerfile` and builds it
    - A **parent directory** (e.g. `services/`) → recursively scans for all `Dockerfile`s
    - Omitted → uses `services_dir` from `services.yaml`
  - Per-service overrides (`--image-name`, `--tag`) apply to the **last service/directory before them**
  - Repeated flags allowed for multiple overrides
  - Deduplicate services to prevent double builds
  - Preserve existing auto-discovery logic
  - Update help text and examples

---

**Dockerz v2.5.0** - Making container build orchestration intelligent, fast, and developer-friendly.