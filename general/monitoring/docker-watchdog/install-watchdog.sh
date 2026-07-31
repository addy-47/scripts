#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Docker Watchdog Installation Script for Linux VMs
# Installs Watchdog into /opt/docker-watchdog and launches via Docker Compose
# ==============================================================================

TARGET_DIR="/opt/docker-watchdog"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "${GCHAT_WEBHOOK_URL:-}" ]; then
  echo "[ERROR] GCHAT_WEBHOOK_URL environment variable must be set before running this script!"
  echo "Example: export GCHAT_WEBHOOK_URL='https://chat.googleapis.com/v1/spaces/.../messages?key=...&token=...'"
  exit 1
fi

echo "================================================="
echo "[INFO] Installing Docker Watchdog into: ${TARGET_DIR}"
echo "================================================="

# 1. Create target directory
sudo mkdir -p "${TARGET_DIR}"

# 2. Copy source files to /opt/docker-watchdog
sudo cp "${SCRIPT_DIR}/watchdog.py" "${TARGET_DIR}/"
sudo cp "${SCRIPT_DIR}/Dockerfile" "${TARGET_DIR}/"
sudo cp "${SCRIPT_DIR}/docker-compose.yaml" "${TARGET_DIR}/"

# 3. Create .env file with webhook URL
echo "[INFO] Creating ${TARGET_DIR}/.env configuration..."
sudo bash -c "cat <<EOF > ${TARGET_DIR}/.env
GCHAT_WEBHOOK_URL=${GCHAT_WEBHOOK_URL}
ALERT_COOLDOWN_SECONDS=900
MAX_LOG_LINES=15
EOF"

sudo chmod 600 "${TARGET_DIR}/.env"

# 4. Build and Launch Container
echo "[INFO] Launching Docker Watchdog..."
cd "${TARGET_DIR}"
if command -v docker-compose &> /dev/null; then
  sudo docker-compose up -d --build
elif docker compose version &> /dev/null; then
  sudo docker compose up -d --build
else
  echo "[ERROR] Neither docker-compose nor 'docker compose' found!"
  exit 1
fi

echo "================================================="
echo "[INFO] ✓ Docker Watchdog installed & running at ${TARGET_DIR}"
echo "================================================="
