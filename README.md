🧰 u – Universal Linux Undo Command
Version: 1.0 (MVP)
Language Target: Go 
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
u init  Start tracking commands
u help show all cmds and what u can do
u	Undo last tracked command
u 2	Undo second last command (will add upto 10 in future)
u log	Show recent tracked commands
u cleanup	Remove old backups (>1 day)
u disable	Temporarily stop tracking
u list	Show all undo mappings
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
curl -fsSL https://u.sh/install | sudo bash 
sudo apt update && sudo apt install u

This will:

install Go binary. and prints a ASCII-art banner / welcome message 
using " go get github.com/common-nighthawk/go-figure "
and show user two points 
1. run `u init` to start tracking
2. run `u help` to see what u can do

Place binary in /usr/local/bin/u

Add shell hooks automatically.

Create ~/.u directory with config + empty state.

Use a JSON/YAML "Undo Map" File (Recommended)

This is cleaner and extensible.
You define all reversible commands and their undo logic as data, not code.

Example: u-map.yaml

rm: "restore_file"
mv: "mv {args[1]} {args[0]}"
touch: "rm {args[0]}"
mkdir: "rmdir {args[0]}"
cp: "rm {args[1]}"
apt install: "apt remove {args[1]}"
git clone: "rm -rf {args[1].split('/')[-1]}"

How your Go code uses it:
// Simplified example
type UndoMap map[string]string

func loadUndoMap() UndoMap {
    data, _ := os.ReadFile("undo_map.yaml")
    var mapping UndoMap
    yaml.Unmarshal(data, &mapping)
    return mapping
}

func findReverse(cmd string, args []string, mapping UndoMap) string {
    for key, val := range mapping {
        if strings.HasPrefix(cmd, key) {
            // Replace placeholders {args[0]}, {args[1]}, etc.
            result := val
            for i, arg := range args {
                result = strings.ReplaceAll(result, fmt.Sprintf("{args[%d]}", i), arg)
            }
            return result
        }
    }
    return ""
}

✅ Pros

Easy to extend (users can add their own reverses)

No rebuild needed to add new reversals

Cleaner architecture: logic ≠ data

You can even crowdsource "undo recipes" later (like a plugin ecosystem)

🧭 Future Enhancements
Feature	Description
Smart command diffing	Show what u will undo before confirmation
Configurable scope	Users choose directories to track
Plugin system	Define custom undo logic for arbitrary commands
Cloud sync	Optional off-site backup of recent states
GUI mini-dashboard	View recent undos visually


CONTEXT : @/u-cli/u.md  @/u-cli/README.md 

GOAL:  build "u-cli " v2.0 

USER OBSERVATIONS : so cmds are working but the tracking functionality is not working  or hooks are not correctly implmented  aslo the welcome message should only be displayed when user installs the package or when they run u"  help"  , as currenlty it is showing when we run only " u" everytime hence not allowing user to use the undo fucntionality 

TASK : procedd one subversion at a time  by follwing these steps exactly , do not deviate :
1.  read  user observvation  ,the md files in u-cli and examine current ocdebase to understand the project  and the goal 
2. proceed one subversion at at a time for example currenlty we are on v1.0 next proceed with v1.1. 
3.  create a  plan for the subverison based on md  and apply the changes for that subversion 
4.  package the newly created subversion - ask user to run teh dpkg cmd 
5. test hte new functionality  and ifxes  by creating sample files  and running all u cmds to verify 
6. after success move to teh next subversion and repeat from step 1