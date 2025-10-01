#!/bin/bash

# --- Helper Functions ---
print_info() {
    echo -e "\033[34m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[32m[SUCCESS]\033[0m $1"
}

# --- Warp Terminal Configuration ---
print_info "Configuring Warp terminal..."
mkdir -p ~/.config/warp-terminal
cat << 'EOF' > ~/.config/warp-terminal/user_preferences.json
{
  "prefs": {
    "Theme": "\"CyberWave\""
  }
}
EOF
print_success "Warp terminal configured."
