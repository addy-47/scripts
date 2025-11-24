# APT Repository Setup

This directory contains the APT repository for the DevOps Toolkit.

## Quick Setup

To generate the repository metadata, run:

```bash
cd apt
./generate-repo.sh
```

## Repository Structure

```
apt/
├── Packages              # Package metadata
├── Packages.gz          # Compressed package metadata
├── Release              # Repository metadata with checksums
├── Release.gpg          # Signed repository metadata
├── dockerz/
│   └── dockerz_*.deb    # Dockerz packages
└── u-cli/
    └── u-cli_*.deb      # U-CLI packages
```

## Publishing to GitHub Pages

1. **Generate repository metadata:**
   ```bash
   cd apt
   ./generate-repo.sh
   ```

2. **Sign the Release file (optional but recommended):**
   ```bash
   gpg --clearsign --armor --output Release.gpg Release
   ```

3. **Commit and push to GitHub:**
   ```bash
   git add .
   git commit -m "Update APT repository"
   git push origin main
   ```

4. **Enable GitHub Pages:**
   - Go to repository Settings > Pages
   - Select "Deploy from a branch"
   - Choose "main" branch and "/ (root)" folder
   - Repository will be available at: `https://addy-47.github.io/scripts/install`

## Testing the Repository

```bash
# Test repository access
curl -I https://addy-47.github.io/scripts/install/Packages.gz

# Test installation
curl -fsSL https://raw.githubusercontent.com/addy-47/scripts/install/tools/dockerz/install.sh | bash
```

## Troubleshooting

- **404 errors**: Ensure GitHub Pages is enabled
- **GPG errors**: Repository works without signing, but apt may warn
- **Missing packages**: Check that .deb files exist in dockerz/ and u-cli/ directories