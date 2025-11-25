#!/usr/bin/env bash
# Script to generate APT repository metadata (Packages, Release)

set -euo pipefail

# Configuration
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APT_DIR="$REPO_ROOT/apt"
DIST_CODENAME="stable"
COMPONENT="main"
ARCH="amd64"

# Check dependencies
if ! command -v dpkg-scanpackages >/dev/null 2>&1; then
    echo "Error: dpkg-scanpackages not found. Install 'dpkg-dev'." >&2
    exit 1
fi
if ! command -v apt-ftparchive >/dev/null 2>&1; then
    echo "Error: apt-ftparchive not found. Install 'apt-utils'." >&2
    exit 1
fi

echo "Generating APT metadata in $APT_DIR..."

# 1. Generate Packages and Packages.gz
cd "$APT_DIR"

# Ensure dist directories exist
mkdir -p "dists/$DIST_CODENAME/$COMPONENT/binary-$ARCH"

echo "Scanning packages in pool/$COMPONENT..."
# Scan pool/main and output to dists/.../Packages
# We use . as the prefix so the filenames in Packages are relative to apt root (e.g. pool/main/...)
dpkg-scanpackages --multiversion pool/$COMPONENT /dev/null > "dists/$DIST_CODENAME/$COMPONENT/binary-$ARCH/Packages"
gzip -9c "dists/$DIST_CODENAME/$COMPONENT/binary-$ARCH/Packages" > "dists/$DIST_CODENAME/$COMPONENT/binary-$ARCH/Packages.gz"

echo "Generated Packages and Packages.gz"

# 2. Generate Release file
echo "Generating Release file..."
cd "dists/$DIST_CODENAME"
apt-ftparchive \
    -o APT::FTPArchive::Release::Origin="DevOpsToolkit" \
    -o APT::FTPArchive::Release::Label="DevOpsToolkit" \
    -o APT::FTPArchive::Release::Suite="$DIST_CODENAME" \
    -o APT::FTPArchive::Release::Codename="$DIST_CODENAME" \
    -o APT::FTPArchive::Release::Architectures="$ARCH" \
    -o APT::FTPArchive::Release::Components="$COMPONENT" \
    release . > Release

echo "Generated Release file at dists/$DIST_CODENAME/Release"

# Note: We are NOT signing the Release file as per user request (trusted=yes)
echo "Skipping GPG signing (unsigned repo)."

echo "Done."
