# Multi-Service Docker Build Script

This Python script automates building multiple Docker images in parallel for services located in a project directory, including those in nested subdirectories. It streamlines the development workflow by eliminating the need for manual, sequential builds, which is especially useful during namespace migrations or branch deployments.

The script is highly configurable, supporting custom image names, global and service-specific tags, and defaults to using the short Git commit ID as a tag if none is specified.

> **Important Note**: This script must be run from the root directory of the project where you intend to build Docker images, not from the script's own directory. You can execute it by providing the absolute path to the script.

## Prerequisites

Before you begin, ensure the following tools are installed and configured on your system.

| Requirement | Purpose | Verification |
| :--- | :--- | :--- |
| **Python 3.8+** | Required to execute the build script. | `python3 --version` |
| **Docker** | Required for building Docker images. | `docker --version` |
| **Git** | Required for default version tagging. | `git --version` |
| **PyYAML** | Python library for parsing the `services.yaml` file. | `pip show pyyaml` |
| **Google Cloud SDK** (Optional) | Required only if pushing images to Google Artifact Registry (GAR). | `gcloud --version` |

### System Requirements

| Component | Recommendation |
| :--- | :--- |
| **OS** | Linux, macOS, or Windows (WSL2 recommended). |
| **CPU** | A multi-core CPU is recommended for parallel builds. |
| **Memory** | At least 4GB of RAM. 8GB+ is recommended for 10 or more services. |
| **Disk Space** | Sufficient disk space to store Docker images and build caches. |

## Usage

1.  **Configure Services**: Create a `services.yaml` file in your project's root directory to define the services you want to build. See the [Configuration](#configuration) section for detailed instructions.

2.  **Run the Script**: Execute the script from your project's root directory.

    ```bash
    python3 /path/to/docker.py
    ```

    You can also specify the maximum number of parallel processes using the `--max-processes` flag:

    ```bash
    python3 /path/to/docker.py --max-processes 4
    ```

    > **Tip**: To simplify execution, create a shell alias in your `.bashrc` or `.zshrc` file:
    >
    > ```bash
    > alias dockerx='python3 /path/to/docker.py'
    > ```

## Configuration

The script is configured through a `services.yaml` file located in the project's root directory.

### Example `services.yaml`

```yaml
# Base directory to scan for Dockerfiles (relative to project root)
services_dir: ./services

# Google Cloud Configuration
project_id: my-gcp-project
gar_name: my-artifact-registry
region: us-central1

# Build Configuration
global_tag: v1.0.0          # Optional: A global tag applied to all services
max_processes: 4            # Optional: Max parallel builds (defaults to half of CPU cores)
use_gar: true               # Optional: Use Google Artifact Registry naming (default: true)
push_to_gar: true           # Optional: Push to GAR after building (default: same as use_gar)

# Optional: Explicitly list services to build
services:
  - name: services/service-a
    tag: v1.0.1             # Optional: Service-specific tag
  - name: services/service-b
  - name: subdir/service-c
```

### Configuration Fields

| Field | Description |
| :--- | :--- |
| `services_dir` | The base directory to recursively scan for Dockerfiles. If omitted, you must explicitly list the services to be built. |
| `project_id` | Your Google Cloud project ID. |
| `gar_name` | The name of your Google Artifact Registry repository. |
| `region` | The GAR region (e.g., `us-central1`). |
| `global_tag` | An optional tag applied to all services unless a service-specific tag is provided. |
| `max_processes` | The maximum number of parallel builds. Defaults to half the available CPU cores. |
| `services` | A list of service directories (relative paths) and optional tags. If this is omitted, the script will build all subdirectories containing a `Dockerfile` under `services_dir`. |
| `use_gar` | If `true`, images will be named using the GAR format. Defaults to `true`. |
| `push_to_gar` | If `true`, images will be pushed to GAR after a successful build. Defaults to the value of `use_gar`. |

### Environment Variables

You can also override the `use_gar` and `push_to_gar` settings using environment variables:

| Variable | Description |
| :--- | :--- |
| `USE_GAR` | Set to `true` or `false` to override the `use_gar` setting in the configuration file. |
| `PUSH_TO_GAR` | Set to `true` or `false` to override the `push_to_gar` setting in the configuration file. |

## Features

- **Parallel Builds**: Concurrently builds Docker images to save time, with a configurable limit to prevent system overload.
- **Flexible Directory Structure**: Supports services in nested subdirectories.
- **Configurable**: Uses a `services.yaml` file to manage service directories, GAR details, and tags.
- **Flexible Tagging**: Supports a global tag, service-specific tags, or defaults to the short Git commit ID.
- **Error Handling**: Logs build successes and failures to a file and the console without interrupting other builds.
- **Image Naming**: Constructs image names in the format `{region}-docker.pkg.dev/{project_id}/{gar_name}/{service_name}:{tag}`.

## Google Artifact Registry (GAR) Integration

The script is designed to integrate seamlessly with Google Artifact Registry.

1.  **Enable GAR Integration**: In `services.yaml`, set `use_gar` to `true` to use GAR naming conventions and `push_to_gar` to `true` to automatically push images after a successful build.

2.  **Authentication**: Ensure you are authenticated with GAR by running:
    ```bash
    gcloud auth configure-docker {region}-docker.pkg.dev
    ```

When GAR integration is enabled, the script will:
- Name images using the format: `{region}-docker.pkg.dev/{project_id}/{gar_name}/{service_name}:{tag}`.
- Automatically push images to GAR if `push_to_gar` is `true`.
- Log failed pushes separately in the build summary.
- Store detailed build and push logs in the `logs` directory.

## Troubleshooting

| Issue | Solution |
| :--- | :--- |
| **Script Not Found** | Use the absolute path to the script (e.g., `python3 /path/to/docker.py`). |
| **`services.yaml` Not Found** | Ensure the `services.yaml` file is in your project's root directory, not the script's directory. |
| **Wrong Working Directory** | Always run the script from the root of the project where you want to build Docker images. |
| **Path Errors** | Verify that the relative paths in `services.yaml` are correct and that the script is run from the project root. |
| **System Overload** | Reduce the `max_processes` value in `services.yaml` or via the `--max-processes` flag. |
| **Docker Permission Errors** | On Linux, run `sudo usermod -aG docker $USER` and then log out and back in. |
| **Missing `Dockerfile`** | Ensure that each service directory contains a valid `Dockerfile`. |
| **`PyYAML` Not Found** | Install the required library by running `pip install pyyaml`. |
| **Git Errors** | Make sure the project is a Git repository. If not, run `git init`. |
| **GAR Authentication** | Authenticate with GAR by running `gcloud auth configure-docker {region}-docker.pkg.dev`. |