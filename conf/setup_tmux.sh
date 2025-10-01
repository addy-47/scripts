#!/bin/bash

# --- Helper Functions ---
print_info() {
    echo -e "\033[34m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[32m[SUCCESS]\033[0m $1"
}

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
fi
