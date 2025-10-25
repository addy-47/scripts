package git

import (
	"time"
)

// ChangeType represents the type of change in git
type ChangeType int

const (
	Modified ChangeType = iota
	Added
	Deleted
	Renamed
)

// FileChange represents a single file change
type FileChange struct {
	Path       string
	ChangeType ChangeType
	OldPath    string // For renames
}

// CommitInfo represents git commit information
type CommitInfo struct {
	Hash      string
	Message   string
	Author    string
	Timestamp time.Time
}

// DiffResult represents the result of a git diff operation
type DiffResult struct {
	FilesChanged []FileChange
	CommitFrom   string
	CommitTo     string
	IsClean      bool
}

// Tracker handles git change detection
type Tracker struct {
	lastCommit string
}