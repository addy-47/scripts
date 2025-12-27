package git

import (
	"fmt"
	"os/exec"
	"strings"
	"time"

	"github.com/addy-47/dockerz/internal/logging"
)

// NewTracker creates a new git tracker
func NewTracker() *Tracker {
	return &Tracker{
		logger: nil, // Will be set by caller
		cache:  NewGitCache(),
	}
}

// SetLogger sets the logger for the tracker
func (t *Tracker) SetLogger(logger *logging.Logger) {
	t.logger = logger
	if t.cache != nil {
		t.cache.SetLogger(logger)
	}
}

// getGitRoot finds the root directory of the git repository
func (t *Tracker) getGitRoot() (string, error) {
	cmd := exec.Command("git", "rev-parse", "--show-toplevel")
	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("failed to find git root: %w", err)
	}
	return strings.TrimSpace(string(output)), nil
}

// GetChangedFiles returns files changed in the service directory from both git status and recent commits
func (t *Tracker) GetChangedFiles(servicePath string, depth int) ([]string, error) {
	var allChangedFiles []string
	fileSet := make(map[string]bool) // Use map to deduplicate files

	if t.logger != nil {
		t.logger.Debug(logging.CATEGORY_GIT, fmt.Sprintf("Analyzing git changes for %s (depth: %d)", servicePath, depth))
	}

	// Check cache first for git status
	if t.cache != nil {
		if cachedStatus, found := t.cache.GetCachedStatus(servicePath, depth); found {
			statusFiles := cachedStatus
			if t.logger != nil {
				t.logger.Debug(logging.CATEGORY_GIT, fmt.Sprintf("Using cached git status for %s: %d files", servicePath, len(statusFiles)))
			}

			// Add status files to result
			for _, file := range statusFiles {
				if !fileSet[file] {
					fileSet[file] = true
					allChangedFiles = append(allChangedFiles, file)
				}
			}
		} else {
			// Cache miss - get uncommitted changes (git status --porcelain)
			statusFiles, err := t.getUncommittedChanges(servicePath)
			if err != nil {
				return nil, fmt.Errorf("failed to get uncommitted changes for %s: %w", servicePath, err)
			}

			if t.logger != nil {
				t.logger.Debug(logging.CATEGORY_GIT, fmt.Sprintf("Found %d uncommitted changes in %s", len(statusFiles), servicePath))
			}

			// Cache the result
			t.cache.CacheStatus(servicePath, depth, statusFiles, 5*time.Minute)

			// Add status files to result
			for _, file := range statusFiles {
				if !fileSet[file] {
					fileSet[file] = true
					allChangedFiles = append(allChangedFiles, file)
				}
			}
		}
	} else {
		// No cache - get uncommitted changes (git status --porcelain)
		statusFiles, err := t.getUncommittedChanges(servicePath)
		if err != nil {
			return nil, fmt.Errorf("failed to get uncommitted changes for %s: %w", servicePath, err)
		}

		if t.logger != nil {
			t.logger.Debug(logging.CATEGORY_GIT, fmt.Sprintf("Found %d uncommitted changes in %s", len(statusFiles), servicePath))
		}

		// Add status files to result
		for _, file := range statusFiles {
			if !fileSet[file] {
				fileSet[file] = true
				allChangedFiles = append(allChangedFiles, file)
			}
		}
	}

	// Check cache first for git diff
	if t.cache != nil {
		if cachedDiff, found := t.cache.GetCachedDiff(servicePath, depth); found {
			commitFiles := cachedDiff
			if t.logger != nil {
				t.logger.Debug(logging.CATEGORY_GIT, fmt.Sprintf("Using cached git diff for %s: %d files", servicePath, len(commitFiles)))
			}

			// Add commit files to result (deduplicated)
			for _, file := range commitFiles {
				if !fileSet[file] {
					fileSet[file] = true
					allChangedFiles = append(allChangedFiles, file)
				}
			}
		} else {
			// Cache miss - get changes from recent commits (git diff HEAD~N HEAD)
			commitFiles, err := t.getCommitChanges(servicePath, depth)
			if err != nil {
				return nil, fmt.Errorf("failed to get commit changes for %s: %w", servicePath, err)
			}

			if t.logger != nil {
				t.logger.Debug(logging.CATEGORY_GIT, fmt.Sprintf("Found %d commit changes in %s", len(commitFiles), servicePath))
			}

			// Cache the result
			t.cache.CacheDiff(servicePath, depth, commitFiles, 5*time.Minute)

			// Add commit files to result (deduplicated)
			for _, file := range commitFiles {
				if !fileSet[file] {
					fileSet[file] = true
					allChangedFiles = append(allChangedFiles, file)
				}
			}
		}
	} else {
		// No cache - get changes from recent commits (git diff HEAD~N HEAD)
		commitFiles, err := t.getCommitChanges(servicePath, depth)
		if err != nil {
			return nil, fmt.Errorf("failed to get commit changes for %s: %w", servicePath, err)
		}

		if t.logger != nil {
			t.logger.Debug(logging.CATEGORY_GIT, fmt.Sprintf("Found %d commit changes in %s", len(commitFiles), servicePath))
		}

		// Add commit files to result (deduplicated)
		for _, file := range commitFiles {
			if !fileSet[file] {
				fileSet[file] = true
				allChangedFiles = append(allChangedFiles, file)
			}
		}
	}

	if t.logger != nil {
		t.logger.Debug(logging.CATEGORY_GIT, fmt.Sprintf("Total changes in %s: %d (deduplicated)", servicePath, len(allChangedFiles)))
	}

	return allChangedFiles, nil
}

// getUncommittedChanges gets files changed but not committed (git status)
func (t *Tracker) getUncommittedChanges(servicePath string) ([]string, error) {
	// Get git root to run commands from there
	gitRoot, err := t.getGitRoot()
	if err != nil {
		return nil, fmt.Errorf("not a git repository: %w", err)
	}

	// Run git status from repository root with service path as filter
	cmd := exec.Command("git", "status", "--porcelain", "--", servicePath)
	cmd.Dir = gitRoot
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to get git status: %w", err)
	}

	var changedFiles []string
	lines := strings.Split(strings.TrimSpace(string(output)), "\n")

	for _, line := range lines {
		if line == "" {
			continue
		}

		// Parse git status line (format: "XY file")
		// Status codes are 2 characters, then space, then filename
		if len(line) < 4 {
			continue
		}

		filePath := strings.TrimSpace(line[3:]) // Skip status code and space

		// Only include files that are within the service path
		if strings.HasPrefix(filePath, servicePath+"/") || filePath == servicePath {
			changedFiles = append(changedFiles, filePath)
		}
	}

	return changedFiles, nil
}

// getCommitChanges gets files changed in recent commits (git diff HEAD~N HEAD)
func (t *Tracker) getCommitChanges(servicePath string, depth int) ([]string, error) {
	if depth < 2 {
		depth = 2 // Minimum depth for comparing 2 commits (HEAD vs HEAD~1)
	}

	// Get git root to run commands from there
	gitRoot, err := t.getGitRoot()
	if err != nil {
		return nil, fmt.Errorf("not a git repository: %w", err)
	}

	// Calculate the comparison range: HEAD~(depth-1) to HEAD
	// depth=2 means compare last 2 commits: HEAD~1..HEAD
	// depth=3 means compare last 3 commits: HEAD~2..HEAD
	fromCommit := fmt.Sprintf("HEAD~%d", depth-1)

	// git diff --name-only HEAD~N HEAD -- servicePath
	cmd := exec.Command("git", "diff", "--name-only", fromCommit, "HEAD", "--", servicePath)
	cmd.Dir = gitRoot
	output, err := cmd.Output()

	if err != nil {
		// Check if the error is due to insufficient commit history
		if exitErr, ok := err.(*exec.ExitError); ok && exitErr.ExitCode() == 128 {
			// Try with just HEAD (initial commit case or shallow clone)
			// This compares the working tree to HEAD, which is acceptable for initial commits
			cmd = exec.Command("git", "diff", "--name-only", "HEAD", "--", servicePath)
			cmd.Dir = gitRoot
			output, err = cmd.Output()
			if err != nil {
				// If still failing, might be no commits at all - return empty
				return []string{}, nil
			}
		} else {
			return nil, fmt.Errorf("failed to get git diff: %w", err)
		}
	}

	var changedFiles []string
	lines := strings.Split(strings.TrimSpace(string(output)), "\n")

	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line != "" {
			// Only include files within the service path
			if strings.HasPrefix(line, servicePath+"/") || line == servicePath {
				changedFiles = append(changedFiles, line)
			}
		}
	}

	return changedFiles, nil
}

// GetLastCommit gets the last commit hash for a service
func (t *Tracker) GetLastCommit(servicePath string) (string, error) {
	gitRoot, err := t.getGitRoot()
	if err != nil {
		return "", fmt.Errorf("not a git repository: %w", err)
	}

	cmd := exec.Command("git", "log", "-1", "--format=%H", "--", servicePath)
	cmd.Dir = gitRoot
	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("failed to get last commit for %s: %w", servicePath, err)
	}

	return strings.TrimSpace(string(output)), nil
}

// IsGitRepository checks if the current directory is within a git repository
func (t *Tracker) IsGitRepository(path string) bool {
	cmd := exec.Command("git", "rev-parse", "--git-dir")
	cmd.Dir = path
	return cmd.Run() == nil
}

// GetServiceChanges gets changes specific to a service directory
func (t *Tracker) GetServiceChanges(servicePath string) (*DiffResult, error) {
	gitRoot, err := t.getGitRoot()
	if err != nil {
		return nil, fmt.Errorf("not a git repository: %s", servicePath)
	}

	// Verify we're in a git repository
	if !t.IsGitRepository(gitRoot) {
		return nil, fmt.Errorf("not a git repository: %s", servicePath)
	}

	// Get uncommitted changes for the service
	return GetUncommittedChanges()
}
