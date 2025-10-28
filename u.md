# 🧰 u – Universal Linux Undo Command
**Product Roadmap & Implementation Guide**

Version: 1.0 → 2.0  
Language: Go  
Focus: Text files and development workflows

---

## 📦 Current State (v1.0 - MVP Completed)

### ✅ Implemented Features
- ✅ Core CLI commands (`init`, `u`, `u 2`, `log`, `cleanup`, `disable`, `list`)
- ✅ BoltDB-based command tracking
- ✅ Backup/restore with zstd compression
- ✅ YAML-based undo mapping system
- ✅ Basic file change detection (mtime-based)
- ✅ Shell integration instructions (bash/zsh/fish)
- ✅ `~/.u` directory structure with config

---

## 🎯 Prioritized Roadmap

### **v1.1 - Critical Fixes & Safety** (PRIORITY 1 - Do This First)
**Goal**: Make the tool production-safe and fix breaking issues

#### 🔴 Critical Issues to Fix

1. **Fix Shell Hook Implementation** ⚠️ BLOCKER
   ```bash
   # Current (broken):
   export PROMPT_COMMAND='u_track "$BASH_COMMAND"'
   
   # Fixed approach:
   # For bash:
   trap 'u_track "$BASH_COMMAND"' DEBUG
   
   # For zsh:
   preexec() { u_track "$1"; }
   
   # For fish:
   function u_track --on-event fish_preexec
       u track "$argv"
   end
   ```
   - **Why**: Current implementation won't capture commands correctly
   - **Effort**: 2-3 days
   - **Files**: Update `scripts/install.sh` and README instructions

2. **Add File Locking for Concurrent Access**
   ```go
   // Add to internal/store/store.go
   import "github.com/gofrs/flock"
   
   func (s *Store) acquireLock() error {
       lock := flock.New("/tmp/u.lock")
       return lock.Lock()
   }
   ```
   - **Why**: Multiple terminals can corrupt state
   - **Effort**: 1 day
   - **Files**: `internal/store/store.go`

3. **Implement Pre-Command Snapshotting**
   - **Current**: Snapshot after command runs (race conditions)
   - **Better**: Snapshot before + compare after
   ```go
   // Add to internal/tracker/tracker.go
   type Snapshot struct {
       Path  string
       Mtime time.Time
       Size  int64
       Hash  string // for text files only
   }
   
   func CapturePreSnapshot(workingDir string) ([]Snapshot, error)
   func DetectChanges(before, after []Snapshot) []FileChange
   ```
   - **Why**: More reliable change detection
   - **Effort**: 3-4 days
   - **Files**: New `internal/tracker/snapshot.go`

4. **Add Size Limits for Text Files**
   ```yaml
   # Add to config.yaml
   backup:
     max_file_size: 10485760  # 10MB for text files
     skip_binary: true
     ignore_patterns:
       - "*.log"
       - "*.min.js"
       - "node_modules/**"
   ```
   - **Why**: Prevent disk explosion
   - **Effort**: 1 day
   - **Files**: `internal/config/config.go`, `internal/backup/backup.go`

5. **Handle Failed Commands (Non-Zero Exit)**
   ```go
   // Add to shell hook
   u_track() {
       local exit_code=$?
       if [ $exit_code -eq 0 ]; then
           /usr/local/bin/u track "$1" --exit-code=0
       fi
   }
   ```
   - **Why**: Don't backup if command failed
   - **Effort**: 1 day
   - **Files**: `scripts/install.sh`, `cmd/track.go`

6. **Add Disk Space Checks**
   ```go
   // Add to internal/backup/backup.go
   func CheckAvailableSpace(required int64) error {
       var stat syscall.Statfs_t
       syscall.Statfs(os.Getenv("HOME"), &stat)
       available := stat.Bavail * uint64(stat.Bsize)
       if available < uint64(required * 2) { // 2x safety margin
           return ErrInsufficientSpace
       }
       return nil
   }
   ```
   - **Why**: Don't fill user's disk
   - **Effort**: 1 day
   - **Files**: `internal/backup/backup.go`

**Timeline**: 2 weeks  
**Release**: v1.1.0

---

### **v1.2 - Enhanced Safety & UX** (PRIORITY 2)
**Goal**: Make undo operations safer and more transparent

#### 🟡 High Priority Improvements

1. **Add `u diff` Command**
   ```bash
   $ u diff
   Will undo: mv src.txt dest.txt
   
   Changes:
     + Restore: src.txt (1.2 KB)
     - Remove:  dest.txt (1.2 KB)
   
   Run 'u --force' to apply
   ```
   - **Effort**: 2 days
   - **Files**: New `cmd/diff.go`

2. **Implement Interactive Mode**
   ```go
   import "github.com/manifoldco/promptui"
   
   prompt := promptui.Select{
       Label: "Undo 'rm important.txt'?",
       Items: []string{"Yes, restore it", "No, keep deleted", "Show diff first"},
   }
   ```
   - **Effort**: 3 days
   - **Files**: `cmd/root.go`, add promptui dependency

4. **Better Undo Mapping with Regex**
   ```yaml
   # Update undo_map.yaml
   rm:
     pattern: '^rm\s+(?:-[rf]+\s+)?(.+)$'
     undo: "restore_from_backup"
     capture_groups: [1]  # File path
     requires_backup: true
     safety: unsafe
   
   mv:
     pattern: '^mv\s+(.+?)\s+(.+)$'
     undo: "mv {1} {0}"
     capture_groups: [0, 1]
     atomic: true
     safety: safe
   ```
   - **Effort**: 4 days
   - **Files**: `internal/mapping/mapping.go`, `undo_map.yaml`

5. **Handle Commands with Wildcards**
   ```go
   // internal/tracker/glob.go
   func ExpandGlobArgs(cmd string) ([]string, error) {
       // Expand rm *.txt -> rm file1.txt file2.txt file3.txt
       // Track all matched files individually
   }
   ```
   - **Effort**: 2 days

6. **Add `u status` Command**
   ```bash
   $ u status
   Tracking: Enabled
   Commands tracked: 47
   Backups stored: 12
   Disk usage: 3.2 MB / 100 MB limit
   Oldest backup: 6 hours ago
   ```
   - **Effort**: 1 day
   - **Files**: New `cmd/status.go`

**Timeline**: 2 weeks  
**Release**: v1.2.0

---

### **v1.3 - Developer Workflow Focus** (PRIORITY 3)
**Goal**: Optimize for text files and dev tools

#### 🟢 Developer-Focused Features

1. **Git Integration**
   ```yaml
   # config.yaml
   integrations:
     git:
       enabled: true
       skip_tracked_files: true  # Don't backup files in git
       use_git_restore: true     # Use git restore instead of u for tracked files
   ```
   ```bash
   $ u  # If file is git-tracked
   ℹ️  File is tracked by git. Use 'git restore' instead.
   $ u --force  # Override and use u anyway
   ```
   - **Effort**: 3 days
   - **Files**: New `internal/integrations/git.go`

2. **Smart Text File Detection**
   ```go
   // internal/backup/detector.go
   func IsTextFile(path string) bool {
       // Check extension
       ext := filepath.Ext(path)
       if textExts[ext] { return true }
       
       // Check content (first 512 bytes)
       content, _ := os.ReadFile(path)
       return isUTF8(content[:512])
   }
   ```
   - Only backup text files by default
   - Add `--include-binary` flag for special cases
   - **Effort**: 2 days

3. **Content-Addressed Storage (Deduplication)**
   ```
   ~/.u/
   ├── pool/              # Store unique file contents by hash
   │   ├── a1b2c3...
   │   └── d4e5f6...
   └── snapshots/
       └── cmd_123.json   # References to pool
   ```
   ```go
   // internal/backup/pool.go
   func StoreInPool(content []byte) (hash string, err error)
   func RetrieveFromPool(hash string) ([]byte, error)
   ```
   - **Why**: Multiple backups of same file = wasted space
   - **Effort**: 5 days
   - **Files**: New `internal/backup/pool.go`

4. **Configurable Ignore Patterns**
   ```yaml
   # config.yaml
   tracking:
     ignore_dirs:
       - ".git"
       - "node_modules"
       - ".venv"
       - "__pycache__"
       - "target"       # Rust
       - "dist"
       - "build"
     
     ignore_files:
       - "*.pyc"
       - "*.o"
       - "*.so"
       - ".DS_Store"
       - "*.swp"
   ```
   - **Effort**: 1 day
   - **Files**: `internal/config/config.go`

5. **Track Editor Operations**
   ```bash
   # Detect common editor patterns
   $ vim file.txt
   # u knows this is an edit, not create
   
   $ u
   Restoring file.txt to state before vim edit (23 lines changed)
   ```
   - **Effort**: 3 days
   - **Files**: `internal/tracker/editor.go`

6. **Add `u export` Command**
   ```bash
   $ u export --format json > undo-history.json
   $ u export --last 5 --format yaml
   ```
   - **Effort**: 1 day
   - **Files**: New `cmd/export.go`

**Timeline**: 2-3 weeks  
**Release**: v1.3.0

---

### **v1.4 - Advanced Features** (PRIORITY 4)
**Goal**: Power user features and edge case handling

#### 🔵 Nice-to-Have Features

1. **Redo Support (Undo Stack)**
   ```bash
   $ u        # Undo last command
   $ u redo   # Redo what was just undone
   ```
   - Implement as a stack: `[cmd1, cmd2, cmd3] ← undo pointer`
   - **Effort**: 4 days

2. **Multi-Terminal Session Tracking**
   ```yaml
   # config.yaml
   sessions:
     mode: per_terminal  # or 'global' or 'per_tmux_pane'
     tmux_aware: true
   ```
   - Track `$TMUX_PANE` or `$TERM_SESSION_ID`
   - **Effort**: 5 days

3. **Shell Completion**
   ```bash
   $ u <TAB>
   init  log  cleanup  diff  redo  status  list
   
   $ u 3<TAB>  # Shows: "3 - rm old.txt (5 min ago)"
   ```
   - Use Cobra's built-in completion
   - **Effort**: 2 days
   - **Files**: `cmd/completion.go`

4. **Partial Undo (Multi-File Operations)**
   ```bash
   $ touch a.txt b.txt c.txt
   $ u --select
   ? Which files to undo?
     [x] a.txt
     [ ] b.txt
     [x] c.txt
   ```
   - **Effort**: 4 days

5. **Background Daemon Mode**
   ```bash
   $ u daemon start
   # Runs in background, watches all terminals
   ```
   - More efficient than per-shell hooks
   - Uses inotify for real-time tracking
   - **Effort**: 1 week
   - **Files**: New `internal/daemon/`

6. **Desktop Notifications**
   ```go
   import "github.com/gen2brain/beeep"
   
   beeep.Notify("u - Undo Successful", 
       "Restored 3 files from 2 minutes ago", "")
   ```
   - **Effort**: 1 day

**Timeline**: 3-4 weeks  
**Release**: v1.4.0

---

### **v2.0 - Advanced Architecture** (FUTURE)
**Goal**: Plugin system and community features

1. **Plugin System for Custom Undo Logic**
   ```yaml
   # plugins/docker.yaml
   docker rm:
     pattern: '^docker rm\s+(.+)$'
     undo: "docker start {0}"
   ```

2. **Cloud Backup (Optional)**
   - Sync to S3/GCS for disaster recovery
   - Encrypted backups

3. **GUI Dashboard**
   - Web UI showing timeline of changes
   - Visual diff viewer

4. **Collaborative Undo**
   - Team shares undo history
   - "What did I break yesterday?"

**Timeline**: TBD  
**Release**: v2.0.0

---

## 🏗️ Implementation Priority Matrix

| Priority | Version | Feature | Impact | Effort | Reason |
|----------|---------|---------|--------|--------|--------|
| 🔴 P1 | v1.1 | Fix shell hooks | High | Low | Blocker - tool doesn't work without this |
| 🔴 P1 | v1.1 | File locking | High | Low | Data corruption risk |
| 🔴 P1 | v1.1 | Pre-command snapshot | High | Medium | Reliability issue |
| 🔴 P1 | v1.1 | Size limits | High | Low | Disk space safety |
| 🟡 P2 | v1.2 | Dry-run default | High | Low | Safety + UX |
| 🟡 P2 | v1.2 | Interactive mode | Medium | Medium | User confidence |
| 🟡 P2 | v1.2 | Better regex mapping | High | Medium | Correctness |
| 🟢 P3 | v1.3 | Git integration | High | Medium | Dev workflow focus |
| 🟢 P3 | v1.3 | Deduplication | Medium | High | Storage efficiency |
| 🟢 P3 | v1.3 | Ignore patterns | Medium | Low | Noise reduction |
| 🔵 P4 | v1.4 | Redo support | Low | Medium | Nice to have |
| 🔵 P4 | v1.4 | Shell completion | Low | Low | Convenience |

---

## 📝 Updated Architecture

### Enhanced File Structure
```
~/.u/
├── config.yaml          # User config (updated with new fields)
├── history.db           # BoltDB with command log + snapshots
├── .disabled            # Marker file (if tracking disabled)
├── .lock                # flock lockfile
├── pool/                # Content-addressed storage (v1.3+)
│   ├── a1b2c3...        # File content by hash
│   └── d4e5f6...
├── backups/             # Compressed archives (legacy, v1.0-1.2)
│   └── *.tar.zst
└── sessions/            # Per-terminal tracking (v1.4+)
    ├── tty1.db
    └── tmux-0.db
```

### Updated Config Schema
```yaml
version: "1.3"

tracking:
  enabled: true
  max_history: 100
  ignore_dirs:
    - ".git"
    - "node_modules"
    - ".venv"
  ignore_files:
    - "*.pyc"
    - "*.log"

backup:
  max_file_size: 10485760  # 10MB
  max_total_size: 104857600  # 100MB
  ttl_hours: 24
  compression: zstd
  deduplication: true  # v1.3+
  text_files_only: true

safety:
  dry_run_default: true  # v1.2+
  require_confirmation: ["rm", "mv"]
  max_undo_depth: 10

integrations:
  git:
    enabled: true
    skip_tracked_files: true  # v1.3+
  
sessions:
  mode: per_terminal  # v1.4+
  tmux_aware: true
```

---

## 🚀 Updated Installation

```bash
# v1.1+ installation
curl -fsSL https://raw.githubusercontent.com/user/u/main/install.sh | bash

# What it does:
# 1. Downloads pre-built binary
# 2. Verifies checksum
# 3. Installs to /usr/local/bin/u (or ~/.local/bin for non-sudo)
# 4. Runs u init automatically
# 5. Offers to add shell hooks (with corrected implementation)
# 6. Shows ASCII welcome banner
```

### Shell Hook Installation (Fixed)
```bash
# ~/.bashrc (CORRECTED)
if command -v u &> /dev/null; then
    u_track() {
        local exit_code=$?
        [ $exit_code -eq 0 ] && /usr/local/bin/u track "$BASH_COMMAND" &>/dev/null
    }
    trap 'u_track' DEBUG
fi

# ~/.zshrc (CORRECTED)
if command -v u &> /dev/null; then
    preexec() { u track "$1" &>/dev/null; }
fi

# ~/.config/fish/conf.d/u.fish (CORRECTED)
if command -v u &> /dev/null
    function u_track --on-event fish_preexec
        u track $argv[1] &>/dev/null
    end
end
```

---

## 🧪 Testing Checklist

### v1.1 Testing
- [ ] Shell hooks capture commands correctly in all shells
- [ ] Concurrent `u` commands don't corrupt state
- [ ] Pre-snapshots detect all file changes
- [ ] Large files are skipped with warning
- [ ] Failed commands are not backed up
- [ ] Disk space checks prevent overfill

### v1.2 Testing
- [ ] Dry-run shows accurate preview
- [ ] Interactive prompts work correctly
- [ ] Regex patterns match all command variants
- [ ] Wildcards are expanded correctly
- [ ] `u status` shows accurate info

### v1.3 Testing
- [ ] Git-tracked files are skipped
- [ ] Text detection works for common formats
- [ ] Deduplication saves disk space
- [ ] Ignore patterns work recursively
- [ ] Editor operations are detected

---

## 📦 Deployment Strategy

### Release Cycle
- **v1.1**: Critical fixes → 2 weeks → Announce to early testers
- **v1.2**: Safety features → 2 weeks → Publish to GitHub releases
- **v1.3**: Dev focus → 3 weeks → Submit to package managers (AUR, Homebrew)
- **v1.4**: Polish → 1 month → Announce on r/commandline, HN

### Package Managers
```bash
# Arch (AUR)
yay -S u-undo

# Homebrew
brew install u-undo

# Debian/Ubuntu (via PPA)
sudo add-apt-repository ppa:u-undo/stable
sudo apt install u
```

---

## 🎯 Success Metrics

| Metric | v1.1 Target | v1.3 Target |
|--------|-------------|-------------|
| GitHub Stars | 50 | 500 |
| Active Users | 10 | 100 |
| Bug Reports | 0 critical | 0 critical |
| Avg Backup Size | <5MB | <2MB (dedup) |
| Command Success Rate | 95% | 99% |

---

## 🔐 Security Considerations

1. **Never track sensitive commands**
   ```yaml
   blacklist:
     - "^export.*PASSWORD"
     - "^.*api[_-]?key"
     - "^ssh.*@"
   ```

2. **Encrypt backups (v2.0)**
   - Use age or gpg for pool storage

3. **Audit log**
   - Track who undid what (multi-user systems)

---

## 📚 Documentation Priorities

1. **v1.1**: Fix README with correct shell hooks
2. **v1.2**: Add EXAMPLES.md with common scenarios
3. **v1.3**: Create CONTRIBUTING.md for plugin system
4. **v1.4**: Full docs site with mkdocs

---

## 💡 Key Decisions Made

1. ✅ **Focus on text files only** - Simplifies scope, 90% of dev use cases
2. ✅ **Dry-run by default (v1.2)** - Safety over convenience
3. ✅ **Git integration (v1.3)** - Don't duplicate git's job
4. ✅ **Content deduplication (v1.3)** - Essential for storage efficiency
5. ✅ **Per-terminal tracking (v1.4)** - Better UX than global undo

---

## 🎉 Quick Start Checklist

- [ ] Fix shell hooks (v1.1 - Week 1)
- [ ] Add file locking (v1.1 - Week 1)
- [ ] Implement pre-snapshots (v1.1 - Week 2)
- [ ] Add size limits + disk checks (v1.1 - Week 2)
- [ ] Release v1.1.0 (End Week 2)
- [ ] Start v1.2 with dry-run + diff (Week 3-4)

**Start Here**: Fix the shell hooks in `scripts/install.sh` - this is the biggest blocker!


### u init example after completion of v1.0 -> v2.0 roadmap:

$ u init

🚀 Initializing u-cli...

📁 Creating ~/.u directory structure...
   ✓ Created ~/.u
   ✓ Created ~/.u/backups
   ✓ Created ~/.u/pool
   
⚙️  Writing default config to ~/.u/config.yaml...
   ✓ Config created

🗄️  Initializing command store...
   ✓ Database created at ~/.u/history.db

🔗 Shell Integration Setup
Detected shell: zsh (with Oh My Zsh)

This will add the following to ~/.zshrc:

  # u-cli: Universal undo command tracking
  preexec_functions+=(u_track_cmd)

Install shell hook? [Y/n]: y

✅ Shell hook installed to /home/user/.zshrc
⚠️  Please restart your shell or run: source ~/.zshrc

✨ Initialization complete!

┌─────────────────────────────────────────┐
│  🧰 u - Universal Undo Command          │
│                                         │
│  Commands:                              │
│    u          Undo last command         │
│    u log      Show tracked commands     │
│    u help     Show all commands         │
│                                         │
│  Happy undoing! 🎉                      │
└─────────────────────────────────────────┘