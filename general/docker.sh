#!/usr/bin/env bash
set -euo pipefail

echo "=== Installing prerequisites for Docker & Compose ==="

# Update and install basic tools
apt-get update
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common

# Add Docker’s official GPG key and repository
echo "Adding Docker’s official GPG key and apt repository"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

ARCH=$(dpkg --print-architecture)  # e.g. amd64
CODENAME=$(lsb_release -cs)        # e.g. focal, jammy

echo \
  "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
   ${CODENAME} stable" \
   | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update apt index
apt-get update

echo "=== Installing Docker Engine (docker-ce) ==="
apt-get install -y docker-ce docker-ce-cli containerd.io \
                   docker-buildx-plugin docker-compose-plugin

# Enable and start Docker service
echo "Enabling and starting docker service"
systemctl enable docker
systemctl start docker

# Add the current user (if any) to the docker group
# (so that `docker` can be run without sudo)
if [ -n "${SUDO_USER-}" ]; then
  echo "Adding user ${SUDO_USER} to docker group"
  usermod -aG docker ${SUDO_USER}
fi

echo "=== Verifying installations ==="
docker --version
docker compose version

echo "Installation complete. You may need to log out and log back in for docker group membership to apply."
