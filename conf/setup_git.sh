#!/bin/bash

# --- Helper Functions ---
print_info() {
    echo -e "\033[34m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[32m[SUCCESS]\033[0m $1"
}

# --- Git Configuration ---
print_info "Writing .gitconfig..."
cat << 'EOF' > ~/.gitconfig
[user]
	name = addy-hypr4
	email = adhbhut.gupta@hypr4.io
[credential "https://github.com"]
	helper = 
	helper = !/usr/bin/gh auth git-credential
[credential "https://gist.github.com"]
	helper = 
	helper = !/usr/bin/gh auth git-credential
[push]
	autoSetupRemote = true
EOF
print_success ".gitconfig created."
