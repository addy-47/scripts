#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# --- Helpers ---
print_info()  { echo -e "\033[34m[INFO]\033[0m  $*"; }
print_warn()  { echo -e "\033[33m[WARN]\033[0m  $*"; }
print_error() { echo -e "\033[31m[ERROR]\033[0m $*"; exit 1; }
print_success(){ echo -e "\033[32m[SUCCESS]\033[0m $*"; }

# Make apt non-interactive
export DEBIAN_FRONTEND=noninteractive

# --- Update ---
print_info "Updating package lists..."
sudo apt-get update -y

# --- Core packages list ---
CORE_PACKAGES=(
  aircrack-ng ansible apt-transport-https bandit base-passwd bat bsdutils build-essential
  ca-certificates cabextract dash debhelper devscripts dh-make dh-python diffutils
  docker-compose dpkg-dev efibootmgr fakeroot ffmpeg findutils fonts-indic forticlient
  fzf genisoimage gh git gnome-shell-extensions gnome-tweaks gnupg gpg grep grub-common
  grub-efi-amd64-bin grub-efi-amd64-signed grub-gfxpayload-lists grub-pc grub-pc-bin
  grub2-common gzip hostname htop iftop init language-pack-en language-pack-en-base
  libc6 libdebconfclient0 libftdi1-2 libfuse2 libreoffice-help-common libreoffice-help-en-us
  linux-generic linux-generic-hwe-22.04 login lsb-release mongodb-database-tools
  ncurses-base ncurses-bin neofetch net-tools nghttp2-client nodejs obs-studio openssh-server
  os-prober p7zip-full papirus-icon-theme pass pipx portaudio19-dev pybuild-plugin-pyproject
  python3 python3-all python3-httpx python3-pip python3-pytest python3-setuptools python3-venv
  python3-yaml ripgrep shim-signed software-properties-common thunderbird-locale-en thunderbird-locale-en-us
  tmux trivy ubuntu-minimal ubuntu-standard ubuntu-wallpapers uvicorn vlc wget wrk xclip zsh
)

# --- Install each package separately ---
print_info "Installing core packages one by one..."
for pkg in "${CORE_PACKAGES[@]}"; do
    print_info "Installing $pkg ..."
    if sudo apt-get install -y "$pkg"; then
        print_success "$pkg installed successfully."
    else
        print_warn "Failed to install $pkg"
    fi
done

# --- Third-party installs ---
# Brave
add_brave() {
  print_info "Adding Brave repo..."
  sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-core.asc
  echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=$(dpkg --print-architecture)] https://brave-browser-apt-release.s3.brave.com/ stable main" \
    | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
  sudo apt-get update
  sudo apt-get install -y brave-browser
}

# Google Chrome
add_google_chrome() {
  print_info "Adding Google Chrome repo..."
  wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-linux-signing-key.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/google-linux-signing-key.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
    | sudo tee /etc/apt/sources.list.d/google-chrome.list
  sudo apt-get update
  sudo apt-get install -y google-chrome-stable
}

# Docker CE (official)
add_docker() {
  print_info "Adding Docker repo..."
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
}

# dockerz (your custom tool)
add_dockerz() {
  print_info "Installing dockerz from your repo..."
  curl -fsSL https://addy-47.github.io/scripts/apt/setup.sh | sudo bash
  sudo apt-get update
  sudo apt-get install -y dockerz
}

# MongoDB
add_mongodb() {
  print_info "Adding MongoDB repo..."
  wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-6.0.gpg
  echo "deb [signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg] https://repo.mongodb.org/apt/ubuntu $(lsb_release -sc)/mongodb-org/6.0 multiverse" \
    | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
  sudo apt-get update
  sudo apt-get install -y mongodb-org
}

# --- Call whichever extra repos you want ---
add_brave
add_google_chrome
add_docker
add_dockerz
add_mongodb

# --- Cleanup ---
print_info "Cleaning up..."
sudo apt-get autoremove -y
sudo apt-get clean

print_success "Setup complete."
