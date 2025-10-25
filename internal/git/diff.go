package git

import (
	"bufio"
	"fmt"
	"os/exec"
	"regexp"
	"strings"
)

// ParseGitDiff parses git diff output and returns changed files
func ParseGitDiff(diffOutput string) ([]FileChange, error) {
	var changes []FileChange
	scanner := bufio.NewScanner(strings.NewReader(diffOutput))

	changeRegex := regexp.MustCompile(`^([MADRC])\s+(.+)$`)

	for scanner.Scan() {
		line := scanner.Text()
		if matches := changeRegex.FindStringSubmatch(line); matches != nil {
			changeType := parseChangeType(matches[1])
			filePath := matches[2]

			change := FileChange{
				Path:       filePath,
				ChangeType: changeType,
			}

			// Handle renames (C type has additional info)
			if changeType == Renamed {
				// For renames, the format is "C old_path -> new_path"
				if idx := strings.Index(filePath, " -> "); idx != -1 {
					change.OldPath = filePath[:idx]
					change.Path = filePath[idx+4:]
				}
			}

			changes = append(changes, change)
		}
	}

	return changes, scanner.Err()
}

// GetGitDiff executes git diff and returns parsed changes
func GetGitDiff(fromCommit, toCommit string) (*DiffResult, error) {
	cmd := exec.Command("git", "diff", "--name-status", fromCommit, toCommit)
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to execute git diff: %w", err)
	}

	changes, err := ParseGitDiff(string(output))
	if err != nil {
		return nil, fmt.Errorf("failed to parse git diff: %w", err)
	}

	return &DiffResult{
		FilesChanged: changes,
		CommitFrom:   fromCommit,
		CommitTo:     toCommit,
		IsClean:      len(changes) == 0,
	}, nil
}

// GetUncommittedChanges gets changes not yet committed
func GetUncommittedChanges() (*DiffResult, error) {
	cmd := exec.Command("git", "diff", "--name-status")
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to get uncommitted changes: %w", err)
	}

	changes, err := ParseGitDiff(string(output))
	if err != nil {
		return nil, fmt.Errorf("failed to parse uncommitted changes: %w", err)
	}

	return &DiffResult{
		FilesChanged: changes,
		IsClean:      len(changes) == 0,
	}, nil
}

// parseChangeType converts git status character to ChangeType
func parseChangeType(statusChar string) ChangeType {
	switch statusChar {
	case "M":
		return Modified
	case "A":
		return Added
	case "D":
		return Deleted
	case "R", "C":
		return Renamed
	default:
		return Modified // Default to modified for unknown types
	}
}