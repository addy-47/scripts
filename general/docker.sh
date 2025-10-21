#!/usr/bin/env bash
set -euo pipefail

echo "=== Installing prerequisites for Docker & Compose ==="

# Remove old Docker repo if it exists
# sudo rm -f /etc/apt/sources.list.d/docker.list

# Update and install basic tools
apt-get update -y
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common

# Detect distro
DISTRO=$(lsb_release -is | tr '[:upper:]' '[:lower:]')  # ubuntu or debian
CODENAME=$(lsb_release -cs)
ARCH=$(dpkg --print-architecture)

echo "Detected OS: ${DISTRO} ${CODENAME} (${ARCH})"

# Add Docker’s official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/${DISTRO}/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

chmod a+r /etc/apt/keyrings/docker.gpg

# Add the correct Docker repo for your distro
echo \
  "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${DISTRO} \
  ${CODENAME} stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update apt index
apt-get update -y

echo "=== Installing Docker Engine & Compose Plugin ==="
apt-get install -y docker-ce docker-ce-cli containerd.io \
                   docker-buildx-plugin docker-compose-plugin

# Enable and start Docker service
systemctl enable docker
systemctl start docker

# Add the current user to docker group (if using sudo)
if [ -n "${SUDO_USER-}" ]; then
  echo "Adding ${SUDO_USER} to docker group"
  usermod -aG docker ${SUDO_USER}
fi

echo "=== Verifying installation ==="
docker --version
docker compose version

echo "✅ Docker installation complete!"
echo "You may need to log out and log back in for group changes to apply."
