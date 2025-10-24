# GEMINI Project Analysis: dockerz

## Project Overview

`dockerz` is a command-line tool written in Python that builds and pushes multiple Docker images in parallel. It is designed to streamline CI/CD workflows, particularly for projects with many services. The tool is configured via a central `services.yaml` file where users can define service locations, Google Artifact Registry (GAR) details, and custom tags. The core logic uses Python's `multiprocessing` module to execute `docker build` and `docker push` commands concurrently.

**Key Technologies:**
- **Language:** Python 3.8+
- **CLI Framework:** `click`
- **Configuration:** `pyyaml` for parsing `services.yaml`
- **Build System:** `hatchling` (defined in `pyproject.toml`)

## Building and Running

### Installation
The tool is packaged and can be installed from PyPI:
```bash
pip install dockerz
```

### Running the Tool
The tool provides two main commands:

1.  **Initialize Configuration:** Creates a template `services.yaml` file in the current directory.
    ```bash
    dockerz init
    ```

2.  **Build Images:** Reads the `services.yaml` and runs the parallel build process.
    ```bash
    dockerz build [--config services.yaml] [--max-processes 4]
    ```

The entry point for the script is `dockerz.cli:main`, as defined in `pyproject.toml`.

## Development Conventions

- **Structure:** The project is structured as a standard Python package.
  - `dockerz/`: Main source directory.
  - `dockerz/cli.py`: Handles command-line argument parsing and command registration using `click`.
  - `dockerz/builder.py`: Contains the core logic for reading the configuration, discovering Dockerfiles, and executing build/push commands in parallel subprocesses.
  - `debian/`: Contains files for creating a Debian package.
- **Dependencies:** Project dependencies are managed in `pyproject.toml` and include `click` and `pyyaml`.
- **Packaging:** The project is packaged as a wheel using `hatchling`.
- **Configuration:** The tool is driven by a `services.yaml` file, which allows for declarative configuration of services, tags, and GAR integration settings.
- **Tagging:** If not specified, the default Docker tag is the short Git commit hash, fetched using `git rev-parse --short HEAD`.
