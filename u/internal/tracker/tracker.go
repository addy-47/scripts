package tracker

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/fsnotify/fsnotify"
	"u/internal/config"
	"u/internal/store"
)

// Tracker handles command tracking and file change detection
type Tracker struct {
	store   *store.Store
	config  *config.Config
	watcher *fsnotify.Watcher
}

// NewTracker creates a new tracker instance
func NewTracker() *Tracker {
	return &Tracker{}
}

// Init initializes the tracker with store and config
func (t *Tracker) Init() error {
	var err error
	t.store = store.NewStore()
	if err = t.store.Open(); err != nil {
		return fmt.Errorf("failed to open store: %w", err)
	}

	t.config, err = config.LoadConfig()
	if err != nil {
		return fmt.Errorf("failed to load config: %w", err)
	}

	// Initialize inotify watcher
	t.watcher, err = fsnotify.NewWatcher()
	if err != nil {
		return fmt.Errorf("failed to create file watcher: %w", err)
	}

	return nil
}

// Close closes the tracker and its resources
func (t *Tracker) Close() error {
	if t.watcher != nil {
		t.watcher.Close()
	}
	if t.store != nil {
		return t.store.Close()
	}
	return nil
}

// TrackCommand tracks a command executed in the shell
func (t *Tracker) TrackCommand(cmd string) error {
	if cmd == "" {
		return nil
	}

	// Skip tracking if command is not supported or is internal
	if !t.shouldTrackCommand(cmd) {
		return nil
	}

	// Get current working directory
	cwd, err := os.Getwd()
	if err != nil {
		return fmt.Errorf("failed to get current directory: %w", err)
	}

	// Detect changed files before command execution
	beforeFiles, err := t.detectChangedFilesMtime(cwd)
	if err != nil {
		// Log error but continue - mtime detection failure shouldn't stop tracking
		fmt.Fprintf(os.Stderr, "Warning: failed to detect files before command: %v\n", err)
	}

	// Execute the command to detect changes
	// Note: In real shell integration, this would be called after command execution
	// For now, we'll simulate by checking after a brief delay
	time.Sleep(100 * time.Millisecond)

	// Detect changed files after command execution
	afterFiles, err := t.detectChangedFilesMtime(cwd)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Warning: failed to detect files after command: %v\n", err)
	}

	// Find changed files
	changedFiles := t.findChangedFiles(beforeFiles, afterFiles)

	// Create command log
	log := &store.CommandLog{
		Cmd:          cmd,
		Cwd:          cwd,
		Timestamp:    time.Now().UTC().Format(time.RFC3339),
		ChangedFiles: changedFiles,
	}

	// Store the command log
	return t.store.StoreCommandLog(log)
}

// shouldTrackCommand determines if a command should be tracked
func (t *Tracker) shouldTrackCommand(cmd string) bool {
	// Skip internal u commands
	if strings.HasPrefix(cmd, "u ") || cmd == "u" {
		return false
	}

	// Skip common non-destructive commands
	skipCommands := []string{
		"ls", "pwd", "cd", "echo", "cat", "grep", "find", "which", "whereis",
		"ps", "top", "htop", "df", "du", "free", "uptime", "whoami", "id",
		"history", "clear", "exit", "logout", "su", "sudo", "man", "help",
	}

	parts := strings.Fields(cmd)
	if len(parts) == 0 {
		return false
	}

	baseCmd := filepath.Base(parts[0])
	for _, skip := range skipCommands {
		if baseCmd == skip {
			return false
		}
	}

	return true
}

// detectChangedFilesMtime detects files changed using mtime diff
func (t *Tracker) detectChangedFilesMtime(cwd string) (map[string]time.Time, error) {
	files := make(map[string]time.Time)

	// Walk the directory tree, respecting ignore list
	err := filepath.Walk(cwd, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil // Skip files we can't access
		}

		// Skip ignored directories
		for _, ignored := range t.config.IgnoredDirs {
			if strings.Contains(path, ignored) {
				if info.IsDir() {
					return filepath.SkipDir
				}
				return nil
			}
		}

		// Only track files under HOME
		home := os.Getenv("HOME")
		if !strings.HasPrefix(path, home) {
			return nil
		}

		// Skip directories
		if info.IsDir() {
			return nil
		}

		files[path] = info.ModTime()
		return nil
	})

	return files, err
}

// findChangedFiles compares before and after file states to find changes
func (t *Tracker) findChangedFiles(before, after map[string]time.Time) []string {
	var changed []string

	// Check for modified files
	for path, afterTime := range after {
		if beforeTime, exists := before[path]; exists {
			if afterTime.After(beforeTime) {
				changed = append(changed, path)
			}
		} else {
			// New file created
			changed = append(changed, path)
		}
	}

	// Check for deleted files (files that exist in before but not in after)
	for path := range before {
		if _, exists := after[path]; !exists {
			changed = append(changed, path)
		}
	}

	return changed
}

// detectChangedFilesInotify uses inotify to detect file changes (fallback)
func (t *Tracker) detectChangedFilesInotify(cwd string, duration time.Duration) ([]string, error) {
	var changed []string
	changedMap := make(map[string]bool)

	// Start watching the directory
	err := t.watcher.Add(cwd)
	if err != nil {
		return nil, fmt.Errorf("failed to watch directory: %w", err)
	}
	defer t.watcher.Remove(cwd)

	// Watch for events for the specified duration
	timeout := time.After(duration)
	for {
		select {
		case event, ok := <-t.watcher.Events:
			if !ok {
				return changed, nil
			}
			// Only track files under HOME
			home := os.Getenv("HOME")
			if strings.HasPrefix(event.Name, home) && !t.isIgnoredPath(event.Name) {
				changedMap[event.Name] = true
			}
		case <-timeout:
			// Convert map to slice
			for path := range changedMap {
				changed = append(changed, path)
			}
			return changed, nil
		case err, ok := <-t.watcher.Errors:
			if !ok {
				return changed, nil
			}
			return nil, err
		}
	}
}

// isIgnoredPath checks if a path should be ignored
func (t *Tracker) isIgnoredPath(path string) bool {
	for _, ignored := range t.config.IgnoredDirs {
		if strings.Contains(path, ignored) {
			return true
		}
	}
	return false
}

// ShellIntegration provides shell-specific integration patterns
type ShellIntegration struct{}

// GetBashHook returns the bash PROMPT_COMMAND integration
func (si *ShellIntegration) GetBashHook() string {
	return `export PROMPT_COMMAND='u_track "$BASH_COMMAND"'`
}

// GetZshHook returns the zsh preexec_functions integration
func (si *ShellIntegration) GetZshHook() string {
	return `preexec_functions+=(u_track)`
}

// GetFishHook returns the fish fish_preexec integration
func (si *ShellIntegration) GetFishHook() string {
	return `function fish_preexec --on-event fish_preexec
    u_track $argv
end`
}

// NewShellIntegration creates a new shell integration instance
func NewShellIntegration() *ShellIntegration {
	return &ShellIntegration{}
}

// ParseCommand parses a command string and extracts arguments
func ParseCommand(cmd string) (string, []string, error) {
	if cmd == "" {
		return "", nil, fmt.Errorf("empty command")
	}

	parts := strings.Fields(cmd)
	if len(parts) == 0 {
		return "", nil, fmt.Errorf("invalid command format")
	}

	command := parts[0]
	args := parts[1:]
	return command, args, nil
}

// UTrack is the main function called from shell hooks
// This function is designed to be called from shell scripts
func UTrack(cmd string) error {
	tracker := NewTracker()
	defer tracker.Close()

	if err := tracker.Init(); err != nil {
		return fmt.Errorf("failed to initialize tracker: %w", err)
	}

	return tracker.TrackCommand(cmd)
}

// GetRecentCommands retrieves recent tracked commands
func (t *Tracker) GetRecentCommands(n int) ([]*store.CommandLog, error) {
	return t.store.GetRecentCommands(n)
}

// GetCommandLog retrieves a specific command log by index
func (t *Tracker) GetCommandLog(index int) (*store.CommandLog, error) {
	return t.store.GetCommandLog(index)
}
// Package tracker implements command tracking and file change detection for the u tool.
// It provides shell hook integration for bash, zsh, and fish shells, and detects
// file changes using both mtime diff and inotify fallback mechanisms.
//
// The tracker module is responsible for:
// - Parsing shell commands and extracting arguments
// - Detecting file changes before and after command execution
// - Logging command metadata to the store
// - Providing shell integration patterns for different shells
//
// Usage:
//   tracker := tracker.NewTracker()
//   err := tracker.Init()
//   if err != nil { /* handle error */ }
//   defer tracker.Close()
//
//   err = tracker.TrackCommand("mv file1 file2")
//   if err != nil { /* handle error */ }