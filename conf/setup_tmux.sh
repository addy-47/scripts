#!/bin/bash

# --- Helper Functions ---
print_info() {
    echo -e "\033[34m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[32m[SUCCESS]\033[0m $1"
}

# Check if tmux is installed, install if not
if ! command -v tmux &> /dev/null; then
    print_info "tmux is not installed. Installing tmux..."
    sudo apt update
    sudo apt install -y tmux
    print_success "tmux installed."
else
    print_info "tmux is already installed."
fi

# --- Tmux Configuration ---
print_info "Writing .tmux.conf..."
cat << 'EOF' > ~/.tmux.conf
set -g mouse on

# Use vi keys in copy mode
setw -g mode-keys vi

# Copy to system clipboard
bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "xclip -in -selection clipboard"
bind -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "xclip -in -selection clipboard"

# set ctrl a as prefix 
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Remap pane splitting
unbind %
unbind '"'
bind h split-window -h   # horizontal split (side by side)
bind v split-window -v   # vertical split (top/bottom)

# Optional: easier pane navigation
bind -r Left select-pane -L
bind -r Right select-pane -R
bind -r Up select-pane -U
bind -r Down select-pane -D
set -g default-command "/usr/bin/zsh -l"

set-option -g mode-style "bg=#287D3C,fg=white"
set-option -g message-style "bg=black,fg=cyan"
set-option -g status-style "bg=black,fg=green"

# List of plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-resurrect'

# footer ui 
set -g status-style bg=default,fg=#E67CA0
set -g window-status-current-format "#[fg=white,bold]#I:#W#F"
set -g window-status-format "#[fg=#E67CA0]#I:#W#F"
set -g status-left "#[fg=#E67CA0] #S "
set -g status-right "#[fg=#E67CA0] %H:%M %d-%b-%y "

# Remove status line separators for cleaner look
set -g status-left-length 100
set -g status-right-length 100

# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
run '~/.tmux/plugins/tpm/tpm'
EOF
print_success ".tmux.conf created."

# --- Tmux Plugin Manager ---
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    print_info "Tmux Plugin Manager (tpm) is already installed."
else
    print_info "Installing Tmux Plugin Manager (tpm)..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    print_success "tpm installed."
    ~/.tmux/plugins/tpm/bin/install_plugins
    print_success "tpm plugins installed."
fi
