package tracker

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"u/internal/config"
)

func TestParseCommand(t *testing.T) {
	tests := []struct {
		input    string
		expected string
		args     []string
		hasError bool
	}{
		{"ls -la", "ls", []string{"-la"}, false},
		{"mv file1 file2", "mv", []string{"file1", "file2"}, false},
		{"", "", nil, true},
		{"   ", "", nil, true},
	}

	for _, test := range tests {
		cmd, args, err := ParseCommand(test.input)
		if test.hasError {
			if err == nil {
				t.Errorf("Expected error for input %q, got none", test.input)
			}
		} else {
			if err != nil {
				t.Errorf("Unexpected error for input %q: %v", test.input, err)
			}
			if cmd != test.expected {
				t.Errorf("Expected command %q, got %q", test.expected, cmd)
			}
			if len(args) != len(test.args) {
				t.Errorf("Expected %d args, got %d", len(test.args), len(args))
			}
			for i, arg := range args {
				if arg != test.args[i] {
					t.Errorf("Expected arg[%d] %q, got %q", i, test.args[i], arg)
				}
			}
		}
	}
}

func TestShouldTrackCommand(t *testing.T) {
	tracker := &Tracker{
		config: &config.Config{
			IgnoredDirs: []string{".cache", ".git", "node_modules"},
		},
	}

	tests := []struct {
		cmd      string
		expected bool
	}{
		{"ls -la", false},
		{"u help", false},
		{"u", false},
		{"mkdir test", true},
		{"touch file.txt", true},
		{"mv a b", true},
		{"cp src dst", true},
		{"rm file", true},
		{"pwd", false},
		{"cd /tmp", false},
		{"echo hello", false},
	}

	for _, test := range tests {
		result := tracker.shouldTrackCommand(test.cmd)
		if result != test.expected {
			t.Errorf("Command %q: expected %v, got %v", test.cmd, test.expected, result)
		}
	}
}

func TestFindChangedFiles(t *testing.T) {
	tracker := &Tracker{}

	// Use specific times to avoid precision issues
	baseTime := time.Date(2023, 1, 1, 12, 0, 0, 0, time.UTC)

	before := map[string]time.Time{
		"/home/user/file1.txt": baseTime,
		"/home/user/file2.txt": baseTime,
		"/home/user/file3.txt": baseTime,
	}

	after := map[string]time.Time{
		"/home/user/file1.txt": baseTime,        // unchanged
		"/home/user/file2.txt": baseTime.Add(time.Hour), // modified
		// file3.txt deleted
		"/home/user/file4.txt": baseTime.Add(time.Hour), // new file
	}

	changed := tracker.findChangedFiles(before, after)

	expected := map[string]bool{
		"/home/user/file2.txt": true,
		"/home/user/file4.txt": true,
		"/home/user/file3.txt": true,
	}

	if len(changed) != len(expected) {
		t.Errorf("Expected %d changed files, got %d: %v", len(expected), len(changed), changed)
	}

	for _, changedFile := range changed {
		if !expected[changedFile] {
			t.Errorf("Unexpected changed file: %q", changedFile)
		}
	}

	// Check that unchanged file is not in changed list
	for _, changedFile := range changed {
		if changedFile == "/home/user/file1.txt" {
			t.Errorf("Unchanged file should not be in changed list: %q", changedFile)
		}
	}
}

func TestIsIgnoredPath(t *testing.T) {
	tracker := &Tracker{
		config: &config.Config{
			IgnoredDirs: []string{".cache", ".git", "node_modules", "/tmp"},
		},
	}

	tests := []struct {
		path     string
		expected bool
	}{
		{"/home/user/.cache/file", true},
		{"/home/user/.git/config", true},
		{"/home/user/node_modules/package.json", true},
		{"/tmp/tempfile", true},
		{"/home/user/document.txt", false},
		{"/home/user/projects/code.go", false},
	}

	for _, test := range tests {
		result := tracker.isIgnoredPath(test.path)
		if result != test.expected {
			t.Errorf("Path %q: expected %v, got %v", test.path, test.expected, result)
		}
	}
}

func TestShellIntegration(t *testing.T) {
	si := NewShellIntegration()

	bashHook := si.GetBashHook()
	if !strings.Contains(bashHook, "PROMPT_COMMAND") {
		t.Error("Bash hook should contain PROMPT_COMMAND")
	}
	if !strings.Contains(bashHook, "u_track") {
		t.Error("Bash hook should contain u_track")
	}

	zshHook := si.GetZshHook()
	if !strings.Contains(zshHook, "preexec_functions") {
		t.Error("Zsh hook should contain preexec_functions")
	}
	if !strings.Contains(zshHook, "u_track") {
		t.Error("Zsh hook should contain u_track")
	}

	fishHook := si.GetFishHook()
	if !strings.Contains(fishHook, "fish_preexec") {
		t.Error("Fish hook should contain fish_preexec")
	}
	if !strings.Contains(fishHook, "u_track") {
		t.Error("Fish hook should contain u_track")
	}
}

func TestTrackerInit(t *testing.T) {
	// Create temporary directory for testing
	tempDir, err := os.MkdirTemp("", "u_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Set HOME to temp dir for testing
	oldHome := os.Getenv("HOME")
	os.Setenv("HOME", tempDir)
	defer os.Setenv("HOME", oldHome)

	// Create config directory and file
	configDir := filepath.Join(tempDir, ".u")
	os.MkdirAll(configDir, 0755)
	configFile := filepath.Join(configDir, "config.yaml")
	configContent := `
ignored_dirs:
  - .cache
  - .git
  - node_modules
ttl: 24h
`
	os.WriteFile(configFile, []byte(configContent), 0644)

	tracker := NewTracker()
	err = tracker.Init()
	if err != nil {
		t.Fatalf("Failed to initialize tracker: %v", err)
	}
	defer tracker.Close()

	if tracker.store == nil {
		t.Error("Store should be initialized")
	}
	if tracker.config == nil {
		t.Error("Config should be initialized")
	}
	if tracker.watcher == nil {
		t.Error("Watcher should be initialized")
	}
}

func TestTrackCommand(t *testing.T) {
	// Create temporary directory for testing
	tempDir, err := os.MkdirTemp("", "u_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Set HOME to temp dir for testing
	oldHome := os.Getenv("HOME")
	os.Setenv("HOME", tempDir)
	defer os.Setenv("HOME", oldHome)

	// Create config file
	configDir := filepath.Join(tempDir, ".u")
	os.MkdirAll(configDir, 0755)
	configFile := filepath.Join(configDir, "config.yaml")
	configContent := `
ignored_dirs:
  - .cache
  - .git
  - node_modules
ttl: 24h
`
	os.WriteFile(configFile, []byte(configContent), 0644)

	tracker := NewTracker()
	err = tracker.Init()
	if err != nil {
		t.Fatalf("Failed to initialize tracker: %v", err)
	}
	defer tracker.Close()

	// Test tracking a command
	err = tracker.TrackCommand("mkdir testdir", 0)
	if err != nil {
		t.Errorf("Failed to track command: %v", err)
	}

	// Verify command was logged
	logs, err := tracker.GetRecentCommands(1)
	if err != nil {
		t.Errorf("Failed to get recent commands: %v", err)
	}
	if len(logs) != 1 {
		t.Errorf("Expected 1 log, got %d", len(logs))
	}
	if logs[0].Cmd != "mkdir testdir" {
		t.Errorf("Expected command 'mkdir testdir', got %q", logs[0].Cmd)
	}
}