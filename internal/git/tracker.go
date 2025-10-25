package git

import (
	"fmt"
	"os/exec"
	"path/filepath"
	"strings"
)

// NewTracker creates a new git tracker
func NewTracker() *Tracker {
	return &Tracker{}
}

// GetChangedFiles returns files changed in the service directory since last commit
func (t *Tracker) GetChangedFiles(servicePath string) ([]string, error) {
	// Get git status for the service directory
	cmd := exec.Command("git", "status", "--porcelain", servicePath)
	cmd.Dir = filepath.Dir(servicePath) // Run from parent directory
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to get git status for %s: %w", servicePath, err)
	}

	var changedFiles []string
	lines := strings.Split(strings.TrimSpace(string(output)), "\n")

	for _, line := range lines {
		if line == "" {
			continue
		}

		// Parse git status line (format: "XY file")
		parts := strings.Fields(line)
		if len(parts) >= 2 {
			filePath := parts[len(parts)-1] // Last part is the file path

			// Check if file is within service directory
			if strings.HasPrefix(filePath, servicePath+"/") || filePath == filepath.Base(servicePath) {
				changedFiles = append(changedFiles, filePath)
			}
		}
	}

	return changedFiles, nil
}

// GetLastCommit gets the last commit hash for a service
func (t *Tracker) GetLastCommit(servicePath string) (string, error) {
	cmd := exec.Command("git", "log", "-1", "--format=%H", servicePath)
	cmd.Dir = filepath.Dir(servicePath)
	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("failed to get last commit for %s: %w", servicePath, err)
	}

	return strings.TrimSpace(string(output)), nil
}

// IsGitRepository checks if the given path is within a git repository
func (t *Tracker) IsGitRepository(servicePath string) bool {
	cmd := exec.Command("git", "rev-parse", "--git-dir")
	cmd.Dir = servicePath
	return cmd.Run() == nil
}

// GetServiceChanges gets changes specific to a service directory
func (t *Tracker) GetServiceChanges(servicePath string) (*DiffResult, error) {
	if !t.IsGitRepository(servicePath) {
		return nil, fmt.Errorf("not a git repository: %s", servicePath)
	}

	// Get changes since last commit
	return GetUncommittedChanges()
}