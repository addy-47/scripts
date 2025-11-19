#!/bin/bash

# --- Helper Functions ---
print_info() {
    echo -e "\033[34m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[32m[SUCCESS]\033[0m $1"
}

# --- Oh My Zsh Installation ---
if [ -d "$HOME/.oh-my-zsh" ]; then
    print_info "Oh My Zsh is already installed."
else
    print_info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    print_success "Oh My Zsh installed."
fi

if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
fi

# Create gcp-switch plugin directory and file
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/gcp-switch" ]; then
  mkdir -p ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/gcp-switch
fi

cat << 'EOF' > ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/gcp-switch/gcp-switch.plugin.zsh
source $HOME/projects/scripts/gcp-k8s/gcloud-kubectl-switch.zsh
EOF


# --- Zsh Configuration ---
print_info "Writing .zshrc..."
cat << 'EOF' > ~/.zshrc
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  kubectl kubectx
  docker docker-compose
  gcloud aws
  terraform helm
  sudo
  fzf
  z
  command-not-found
  colored-man-pages
  history-substring-search
  zsh-autosuggestions
  zsh-syntax-highlighting
  gcp-switch
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
# Fix fzf history widget
fzf-history-widget() {
  BUFFER=$(fc -rl 1 | fzf --tac +s --no-sort | sed 's/^[[:space:]]*[0-9]\+[[:space:]]*//')
  CURSOR=$#BUFFER
  zle reset-prompt
}
zle -N fzf-history-widget
bindkey '^R' fzf-history-widget

# Remap beginning-of-line to C-b when inside tmux
if [ -n "$TMUX" ]; then
  bindkey '^B' beginning-of-line
fi

# ------------------------------------------------------------------
# TMUX - Per-pane Zsh History
# ------------------------------------------------------------------
# The following configuration ensures that each tmux pane gets its own
# separate Zsh history file, preventing histories from being overwritten
# or mixed between concurrent shell sessions in a single tmux window.
#
# It works by checking for the TMUX_PANE environment variable, which is
# unique to each pane. It then creates a unique history file inside
# the ~/.zsh_history_tmux/ directory.

# if [ -n "$TMUX_PANE" ]; then
#  TMUX_HISTORY_DIR=~/.zsh_history_tmux
#  mkdir -p "$TMUX_HISTORY_DIR"
#  # Sanitize the pane ID for the filename
#  sanitized_pane_id=${TMUX_PANE//%}
#  export HISTFILE="$TMUX_HISTORY_DIR/history_${sanitized_pane_id}"
#fi
# ------------------------------------------------------------------

export KUBECTX_IGNORE_FZF=true

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export PATH="$HOME/bin:$PATH"
EOF
print_success ".zshrc created."

print_info "Writing custom aliases..."
cat << 'EOF' > ~/.oh-my-zsh/custom/aliases.zsh
alias mongo-migrate="$HOME/projects/scripts/mongo-migrate/mongo-migrate.sh"
alias c='clear'
# classic ls helpers (keep if you still want them)
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias x='exit'
alias dcu='docker compose up -d'
alias d='docker ps -a'
alias dcd='docker compose down'
alias dl='docker logs'
alias dip='docker image prune'
alias de='docker exec -it'

#git alisa
alias g='git add .'
alias gc='git checkout '
alias gcm='git commit -m '
alias gpo='git push origin'
alias gr='git reset HEAD~1'
alias gs='git status'
alias gl='git log'
alias grst='git restore .'

alias fd='fdfind'
alias rp='fd --exec sd'

#ansible alias
alias apl='ansible-playbook -i inventory.ini'
alias aping='ansible all -i inventory.ini -m ping'
alias apinit='ansible-playbook -i inventory.ini provision-vm.yml'

# Interactive ripgrep search with fzf (using batcat)
search() {
    rg --color=always --line-number --no-heading --smart-case "" | \
    fzf --ansi \
        --exact \
        --disabled \
        --query "$1" \
        --delimiter : \
        --bind "change:reload:rg --color=always --line-number --no-heading --smart-case {q}" \
        --preview "batcat --color=always --style=numbers --highlight-line {2} {1}" \
        --preview-window='right:60%:wrap:+{2}-5'
}

# Search in specific directory
searchin() {
    local dir=${1:-.}
    rg --color=always --line-number --no-heading --smart-case "" "$dir" | \
    fzf --ansi \
        --exact \
        --disabled \
        --delimiter : \
        --bind "change:reload:rg --color=always --line-number --no-heading --smart-case {q} $dir" \
        --preview "batcat --color=always --style=numbers --highlight-line {2} {1}" \
        --preview-window='right:60%:wrap:+{2}-5'
}

EOF
print_success "Custom aliases created."

print_info "Writing custom path..."
cat << 'EOF' > ~/.oh-my-zsh/custom/path.zsh
export PATH="$PATH:/usr/local/go/bin"
export PATH="$PATH:/opt/nvim/bin"
EOF
print_success "Custom path created."
