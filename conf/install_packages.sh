#!/bin/bash

# --- Helper Functions ---
print_info() {
    echo -e "\033[34m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[32m[SUCCESS]\033[0m $1"
}

# --- Package Installation ---
print_info "Updating package lists..."
sudo apt-get update

print_info "Installing packages..."
sudo apt-get install -y \
aircrack-ng ansible apt-transport-https bandit base-passwd bat brave-browser bsdutils build-essential \
ca-certificates cabextract code coturn curl dash debhelper devscripts dh-make dh-python diffutils \
docker-compose dockerz dpkg-dev efibootmgr fakeroot ffmpeg findutils flow-app fonts-indic forticlient \
fzf genisoimage gh git gnome-shell-extensions gnome-tweaks gnupg google-chrome-stable \
google-cloud-cli-gke-gcloud-auth-plugin google-cloud-sdk gpg grep grub-common grub-efi-amd64-bin \
grub-efi-amd64-signed grub-gfxpayload-lists grub-pc grub-pc-bin grub2-common gzip hostname htop \
hyphen-en-us iftop init language-pack-en language-pack-en-base language-pack-gnome-en \
language-pack-gnome-en-base libc6 libdebconfclient0 libflashrom1 libftdi1-2 libfuse2t64 libllvm13 \
libreoffice-help-common libreoffice-help-en-us linux-generic linux-generic-hwe-22.04 login lsb-release \
microsoft-edge-stable mokutil mongodb-compass mongodb-database-tools mongodb-mongosh mongodb-org-shell \
mythes-en-us ncurses-base ncurses-bin neofetch net-tools nghttp2-client nodejs obs-studio openssh-server \
os-prober p7zip-full papirus-icon-theme pass pipx portaudio19-dev pybuild-plugin-pyproject python3 \
python3-all python3-hatchling python3-httpx python3-pip python3-pytest python3-setuptools python3-venv \
python3-yaml ripgrep shim-signed software-properties-common thunderbird-locale-en thunderbird-locale-en-us \
tmux trivy ubuntu-desktop ubuntu-desktop-minimal ubuntu-minimal ubuntu-restricted-addons ubuntu-standard \
ubuntu-wallpapers uvicorn vlc warp-terminal wget wrk xclip zsh

print_success "All packages installed."
