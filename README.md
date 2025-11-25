# Scripts & Tools

A collection of DevOps scripts and tools.

## Installation

You can install the tools using our single-line installer:

```bash
curl -fsSL https://addy-47.github.io/scripts/install.sh | bash
```

This will install `dockerz` and `u-cli` by default.

### Install Specific Tools

```bash
curl -fsSL https://addy-47.github.io/scripts/install.sh | bash -s -- dockerz
```

### CI / Automated Installation

For CI environments (non-interactive, assumes root):

```bash
curl -fsSL https://addy-47.github.io/scripts/install.sh | bash -s -- --ci
```

### Uninstall

```bash
curl -fsSL https://addy-47.github.io/scripts/install.sh | bash -s -- --remove
```

## Repository Information

The APT repository is hosted via GitHub Pages.

- **URL**: `https://addy-47.github.io/scripts/`
- **Public Key**: `https://addy-47.github.io/scripts/public.gpg`

## Maintenance

### Adding New Packages

1. Place `.deb` files in `apt/pool/main/<package>/`.
2. Run the generation script:
   ```bash
   ./scripts/generate-repo.sh
   ```
3. Commit and push the changes.

### Local Testing

1. Serve the `apt` directory:
   ```bash
   python3 -m http.server
   ```
2. Run the installer pointing to localhost (requires modifying `install.sh` or manual steps).
