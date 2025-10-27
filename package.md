# DevOps Toolkit Installation System - Implementation Plan

## Overview
This plan outlines the creation of a professional installation system for the DevOps Toolkit, including `dockerz` (v2.0) and `u-cli` (v1.0). It supports installation via apt (Debian/Ubuntu) and binary downloads, with automated CI/CD for releases and an apt repository hosted on GitHub Pages. The guide details the setup, what to build, and the flow from a commit in `master` to a user updating via `apt`.

## Repository Structure
- **Repository**: `https://github.com/addy-47/scripts`
- **Master Branch**: Contains tool source code (`dockerz/`, `u-cli/`) and CI/CD workflows.
- **Install Branch**: Hosts the apt repository and installation scripts, served via GitHub Pages at `https://addy-47.github.io/scripts/`.

## Installation System Architecture
The `install` branch structure:
- `apt/`: Apt repository with `.deb` packages, `Packages.gz`, `Release`, `Release.gpg`, and `setup.sh`.
- `tools/dockerz/`: Dockerz-specific scripts (`install.sh`, `uninstall.sh`), configs (`services.yaml`), and docs.
- `tools/u-cli/`: u-cli-specific scripts and docs.
- `scripts/`: Shared utilities (`common.sh`, `detect-os.sh`, `install-go.sh`, `add-apt-repo.sh`, `verify-installation.sh`).
- `releases/`: Pre-built binaries (`.tar.gz`, `.zip`).
- `README.md`: Installation guide.
- `setup.sh`: Universal binary installation script.

## CI/CD Flow: From Commit to User Update
1. **Developer Action**: Push a commit to `master` (e.g., update `dockerz`).
2. **CI Trigger**: GitHub Actions workflows in `master` run automatically:
   - Build `dockerz` and `u-cli` binaries (`.tar.gz` for Linux/macOS, `.zip` for Windows).
   - Create `.deb` packages for Debian/Ubuntu.
   - Store artifacts temporarily.
3. **Apt Repo Update**: A workflow copies artifacts to `install` branch (`apt/dockerz/`, `apt/u-cli/`, `releases/dockerz/`, `releases/u-cli/`), regenerates `Packages.gz`, `Release`, and `Release.gpg`, and pushes to `install`.
4. **GitHub Pages Update**: `https://addy-47.github.io/scripts/apt/` reflects new packages.
5. **User Action**: User runs `sudo apt update && sudo apt upgrade dockerz u-cli` to get the updated packages.

## What to Build
- **Binaries**: 
  - `dockerz`: Linux (`dockerz-linux-amd64.tar.gz`), macOS (`dockerz-darwin-amd64.tar.gz`), Windows (`dockerz-windows-amd64.zip`).
  - `u-cli`: Similar formats.
- **Debian Packages**: 
  - `dockerz_2.0_amd64.deb`, `dockerz_2.0_arm64.deb`.
  - `u-cli_1.0_amd64.deb`, `u-cli_1.0_arm64.deb`.
- **Apt Repository Files**: `Packages.gz`, `Release`, `Release.gpg` for the apt repo.
- **Scripts**:
  - `setup.sh`: Universal binary installer.
  - `tools/dockerz/install.sh`, `tools/u-cli/install.sh`: Apt setup and tool installation.
  - `tools/dockerz/uninstall.sh`, `tools/u-cli/uninstall.sh`: Clean removal.
  - `scripts/*.sh`: Shared utilities for OS detection, Go installation, apt repo setup, and verification.
- **Workflows** (in `master`):
  - `build-dockerz.yml`: Builds `dockerz` binaries and `.deb` packages.
  - `build-u-cli.yml`: Builds `u-cli` binaries and `.deb` packages.
  - `update-apt-repo.yml`: Updates `install` branch with new packages and repo metadata.

## Step-by-Step Implementation Guide

### Step 1: Create `install` Branch
- **Action**: Create a new `install` branch from `master` if it doesn’t exist.
- **Purpose**: Host the apt repository and installation scripts.
- **Tasks**:
  - Switch to `master`, create `install` branch, push to GitHub.
- **Verification**: Check `https://github.com/addy-47/scripts/tree/install` exists.

### Step 2: Configure GitHub Pages
- **Action**: Set up GitHub Pages to serve `install` branch root.
- **Purpose**: Host the apt repository at `https://addy-47.github.io/scripts/apt/`.
- **Tasks**:
  - In GitHub repo settings, under Pages, set source to `install` branch, folder `/ (root)`.
  - Verify URL `https://addy-47.github.io/scripts/` returns HTTP 200.
- **Verification**: Visit `https://addy-47.github.io/scripts/`. A 404 for `/apt/` is okay until Step 3.

### Step 3: Set Up `install` Branch Directory Structure
- **Action**: Create directories and placeholder files in `install` branch.
- **Purpose**: Establish the structure for apt repo, scripts, and binaries.
- **Tasks**:
  - Create directories: `apt/`, `tools/dockerz/config/`, `tools/dockerz/docs/`, `tools/u-cli/docs/`, `scripts/`, `releases/dockerz/`, `releases/u-cli/`.
  - Add files: `README.md` (installation guide), `setup.sh`, `tools/dockerz/install.sh`, `tools/dockerz/uninstall.sh`, `tools/dockerz/config/services.yaml`, `tools/dockerz/docs/README.md`, `tools/u-cli/install.sh`, `tools/u-cli/uninstall.sh`, `tools/u-cli/docs/README.md`, `scripts/common.sh`, `scripts/detect-os.sh`, `scripts/install-go.sh`, `scripts/add-apt-repo.sh`, `scripts/verify-installation.sh`, `apt/Packages.gz`, `apt/Release`, `apt/Release.gpg`.
  - Commit and push to `install`.
- **Verification**: Check `https://github.com/addy-47/scripts/tree/install` for correct structure.

### Step 4: Create CI/CD Workflows in `master`
- **Action**: Add GitHub Actions workflows in `master/.github/workflows/`.
- **Purpose**: Automate building and publishing packages.
- **Tasks**:
  - Create `build-dockerz.yml`: Builds `dockerz` binaries and `.deb` packages, uploads artifacts.
  - Create `build-u-cli.yml`: Builds `u-cli` binaries and `.deb` packages, uploads artifacts.
  - Create `update-apt-repo.yml`: Copies artifacts to `install` branch, regenerates apt metadata, pushes changes.
  - Ensure workflows trigger on push to `master` or tags (e.g., `dockerz-v*`).
- **Verification**: Push a test commit to `master`, check Actions tab for workflow runs.

### Step 5: Set Up GPG Key for Apt Repository
- **Action**: Generate and configure a GPG key for signing the apt repository.
- **Purpose**: Ensure secure package distribution.
- **Tasks**:
  - Generate a GPG key locally or via CI.
  - Export public key for user distribution.
  - Add private key to GitHub Secrets for signing in CI.
  - Update `add-apt-repo.sh` to include public key.
- **Verification**: Test signing a file with the GPG key locally.

### Step 6: Implement Installation Scripts
- **Action**: Write functional scripts in `install` branch.
- **Purpose**: Enable user installation via apt or binaries.
- **Tasks**:
  - Write `setup.sh`: Detects OS, downloads binaries, installs them.
  - Write `tools/dockerz/install.sh`, `tools/u-cli/install.sh`: Add apt repo, install via `apt`.
  - Write `tools/dockerz/uninstall.sh`, `tools/u-cli/uninstall.sh`: Remove tools cleanly.
  - Write `scripts/*.sh`: Implement OS detection, Go installation, apt repo setup, and verification logic.
  - Commit and push to `install`.
- **Verification**: Test scripts locally on a Debian/Ubuntu machine and a non-Debian system.

### Step 7: Test CI/CD Pipeline
- **Action**: Simulate a full release cycle.
- **Purpose**: Verify the flow from commit to apt update.
- **Tasks**:
  - Make a small change in `dockerz/` (e.g., update version in code).
  - Push to `master`.
  - Monitor GitHub Actions for build and repo update.
  - Check `install` branch for new `.deb` and binary files.
  - Verify `Packages.gz`, `Release`, `Release.gpg` are updated.
- **Verification**: Run `apt update` on a test machine to detect new packages.

### Step 8: Validate User Installation
- **Action**: Test installation on a Debian/Ubuntu machine.
- **Purpose**: Ensure users can install and update via apt.
- **Tasks**:
  - Run `curl -fsSL https://raw.githubusercontent.com/addy-47/scripts/install/tools/dockerz/install.sh | bash`.
  - Run `sudo apt update && sudo apt install dockerz u-cli`.
  - Update `dockerz` version in `master`, push, and run `sudo apt update && sudo apt upgrade dockerz`.
- **Verification**: Confirm `dockerz --version` and `u-cli --version` reflect the latest versions.

## Success Criteria
- Apt repository accessible at `https://addy-47.github.io/scripts/apt/`.
- `apt update` detects new `dockerz` and `u-cli` packages.
- `apt install dockerz u-cli` installs tools successfully.
- Binary installation works on Linux, macOS, Windows.
- CI/CD automatically builds and publishes packages.
- Clear documentation in `install/README.md`.
- Clean uninstallation via `apt remove` or `uninstall.sh`.

## Risk Mitigation
- **Apt Repo Issues**: Use GPG signing and validate `Packages.gz` generation.
- **CI Failures**: Add error handling in workflows, test on multiple platforms.
- **User Errors**: Provide detailed troubleshooting in `README.md`.
- **Version Conflicts**: Use independent versioning for `dockerz` and `u-cli`.

This plan ensures a robust, user-friendly installation system with automated updates.