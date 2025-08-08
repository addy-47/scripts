#!/bin/bash
set -e
echo "Adding Dockerz APT repository..."
sudo mkdir -p /etc/apt/sources.list.d
sudo rm -f /etc/apt/sources.list.d/dockerz.list
echo "deb [trusted=yes] https://addy-47.github.io/scripts/apt/ stable main" | sudo tee /etc/apt/sources.list.d/dockerz.list
echo "Repository added. Run 'sudo apt update && sudo apt install dockerz' to install."
