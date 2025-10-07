🧰 u – Universal Linux Undo Command
Version: 1.0 (MVP)
Language Target: Go (Python optional for prototype)
Goal: A single command — u — that instantly undos the last terminal operation safely, across all shells.
🪴 Product Vision

Bring Ctrl+Z to the Linux terminal — a universal undo command for common shell operations.

u lets developers and sysadmins revert recent, non-destructive terminal actions (like accidental mv, cp, or rm) instantly, without needing git, snapshots, or complex tooling.

🎯 Key Principles
Principle	Description
Universal	Works across bash, zsh, and fish automatically.
Safe-first	Only undoes operations with reversible effects (starts with file-creation/deletion/modification commands).
Simple mental model	One command: u (undo last) or u 2 (undo two steps back).
Fast	Instant response. No heavy scanning. Uses cached metadata of changed files.
Lightweight	No dependencies, single Go binary, installed via one-liner.
Transparent	Logs actions in ~/.u/history.log for visibility.
💡 Core Concept

The u tool runs as a lightweight daemon + shell hook system:

Hooks shell commands (PROMPT_COMMAND, preexec, or fish equivalent).

Detects what files were affected by the last terminal command.

Backs up changed/deleted files (compressed, incremental snapshot).

When user runs u, it:

Loads metadata from ~/.u/history.log

Restores last snapshot to previous state.

Think: Git, but only for your last 2 terminal commands.

⚙️ Functional Features
1. Undo Commands
Command	Description
u	Undo last tracked command
u 2	Undo second last command
u log	Show recent tracked commands
u cleanup	Remove old backups (>1 day)
u disable	Temporarily stop tracking
2. Supported Operations (MVP)
Command	Undo Action
mkdir dir	rmdir dir
touch file	rm file
mv src dest	mv dest src
cp src dest	rm dest
rm file	Restore from backup
cd path	cd $OLDPWD
3. Shell Integration
bash

Add in .bashrc:

export PROMPT_COMMAND='u_track "$BASH_COMMAND"'

zsh

Add in .zshrc:

preexec_functions+=(u_track)

fish

Add in ~/.config/fish/functions/fish_prompt.fish:

function fish_preexec --on-event fish_preexec
    u_track $argv
end

🗂️ File Structure
~/.u/
├── config.yaml       # user config (ignored dirs, TTL, etc.)
├── history.log       # list of recent commands with metadata
├── backups/
│   ├── 2025-10-05T16-12-00.tar.zst
│   └── 2025-10-05T16-14-00.tar.zst
└── state/
    └── tracking.db   # small BoltDB for metadata

🧠 Internal Architecture
1. Command Tracker

Hooks into shell preexec or prompt command.

Logs:

{
  "cmd": "mv a b",
  "cwd": "/home/user/projects",
  "timestamp": "2025-10-05T16:12:00",
  "changed_files": ["/home/user/projects/a", "/home/user/projects/b"]
}


Writes to ~/.u/history.log.

2. Backup Engine

Detects changed files via:

inotify (Linux), or

Fallback: find with mtime < 1 minute.

Copies changed/deleted files into .u/backups/<timestamp>.tar.zst.

Keeps only last 2 backups.

TTL cleanup after 24 hours.

3. Undo Engine

Reads metadata of last command.

Extracts relevant files from backup archive.

Moves/restores files to original locations.

Logs undo operation.

4. Safe Wrapper Aliases

Automatically replaces destructive commands on install:

alias rm='u_safe_rm'
alias mv='u_safe_mv'
alias cp='u_safe_cp'


Example (u_safe_rm):

u_safe_rm() {
    mkdir -p ~/.u/trash
    local stamp=$(date +%s)
    cp -r "$@" ~/.u/trash/$stamp/ 2>/dev/null
    command rm "$@"
    echo "Safe deleted. Use 'u' to restore."
}

⚡ Performance Notes

Track only files under $HOME and user-created dirs.

Default ignore list: .cache, .git, node_modules, venv, /tmp, /proc, /sys.

Backup only modified files using mtime diff.

Use zstd compression for fast and small archives.

🧩 Go Project Structure
u/
├── cmd/
│   └── root.go        # CLI entrypoint (cobra)
├── internal/
│   ├── tracker/       # preexec hooks, command parsing
│   ├── backup/        # backup + restore engine
│   ├── fsnotify/      # change detection
│   ├── config/        # YAML loader + defaults
│   └── store/         # BoltDB state store
├── scripts/
│   ├── install.sh     # setup + alias injection
│   └── uninstall.sh
└── main.go

🧠 Libraries to Use (Go)
Purpose	Library
CLI framework	spf13/cobra
File watching	fsnotify/fsnotify
Compression	klauspost/compress/zstd
Config	spf13/viper
DB (metadata)	bbolt
Logging	rs/zerolog
🔒 Safety Rules

Never modify or delete files outside $HOME.

Backups are auto-cleaned after 24 hours.

Never auto-run a destructive undo (ask for confirmation on rm/mv restores).

Support dry-run mode: u --dry-run.

🚀 Installation
curl -fsSL https://u.sh/install | bash


This will:

Place binary in /usr/local/bin/u

Add shell hooks automatically.

Create ~/.u directory with config + empty state.

🧭 Future Enhancements
Feature	Description
Smart command diffing	Show what u will undo before confirmation
Configurable scope	Users choose directories to track
Plugin system	Define custom undo logic for arbitrary commands
Cloud sync	Optional off-site backup of recent states
GUI mini-dashboard	View recent undos visually
