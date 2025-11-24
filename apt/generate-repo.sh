#!/bin/bash
# Generate APT repository metadata

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Generating APT repository metadata..."

# Generate Packages.gz
echo "Creating Packages.gz..."
gzip -c "$REPO_DIR/Packages" > "$REPO_DIR/Packages.gz"

# Calculate checksums
echo "Calculating checksums..."

# Get MD5 and SHA256 checksums for Packages
PACKAGES_MD5=$(md5sum "$REPO_DIR/Packages" | cut -d' ' -f1)
PACKAGES_SHA256=$(sha256sum "$REPO_DIR/Packages" | cut -d' ' -f1)
PACKAGES_SIZE=$(stat -f%z "$REPO_DIR/Packages" 2>/dev/null || stat -c%s "$REPO_DIR/Packages")

# Get MD5 and SHA256 checksums for Packages.gz  
PACKAGES_GZ_MD5=$(md5sum "$REPO_DIR/Packages.gz" | cut -d' ' -f1)
PACKAGES_GZ_SHA256=$(sha256sum "$REPO_DIR/Packages.gz" | cut -d' ' -f1)
PACKAGES_GZ_SIZE=$(stat -f%z "$REPO_DIR/Packages.gz" 2>/dev/null || stat -c%s "$REPO_DIR/Packages.gz")

# Update Release file with checksums
cat > "$REPO_DIR/Release" << EOF
Origin: DevOps Toolkit
Label: DevOps Toolkit
Suite: stable
Version: 1.0
Codename: stable
Architectures: amd64 arm64
Components: main
Description: DevOps Toolkit Repository
Date: $(date -R)
MD5Sum:
 $(printf " %s %16d Packages" "$PACKAGES_MD5" "$PACKAGES_SIZE")
 $(printf " %s %16d Packages.gz" "$PACKAGES_GZ_MD5" "$PACKAGES_GZ_SIZE")
SHA256:
 $(printf " %s %16d Packages" "$PACKAGES_SHA256" "$PACKAGES_SIZE")
 $(printf " %s %16d Packages.gz" "$PACKAGES_GZ_SHA256" "$PACKAGES_GZ_SIZE")
EOF

echo "Repository metadata generated successfully!"
echo "Files created:"
echo "  - $REPO_DIR/Release"
echo "  - $REPO_DIR/Packages" 
echo "  - $REPO_DIR/Packages.gz"
echo ""
echo "To sign the Release file, run:"
echo "  gpg --clearsign --armor --output Release.gpg --passphrase YOUR_PASSPHRASE Release"