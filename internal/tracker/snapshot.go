package tracker

import (
	"crypto/sha256"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"time"
	"unicode/utf8"

	"u/internal/config"
)

// Snapshot represents a snapshot of file state before command execution
type Snapshot struct {
	Path    string
	Mtime   time.Time
	Size    int64
	Hash    string // For text files only
	IsText  bool
}

// CapturePreSnapshot captures the state of all relevant files before command execution
func CapturePreSnapshot(workingDir string, cfg *config.Config) ([]Snapshot, error) {
	var snapshots []Snapshot

	err := filepath.Walk(workingDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil // Skip files we can't access
		}

		// Skip ignored directories
		for _, ignored := range cfg.IgnoredDirs {
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

		// Check file size limit
		if cfg.MaxFileSize > 0 && info.Size() > cfg.MaxFileSize {
			return nil
		}

		isText := isTextFile(path)
		var hash string

		// Calculate hash for text files
		if isText {
			h, err := calculateFileHash(path)
			if err == nil {
				hash = h
			}
		}

		snapshot := Snapshot{
			Path:   path,
			Mtime:  info.ModTime(),
			Size:   info.Size(),
			Hash:   hash,
			IsText: isText,
		}

		snapshots = append(snapshots, snapshot)
		return nil
	})

	return snapshots, err
}

// DetectChanges compares pre and post snapshots to detect file changes
func DetectChanges(before, after []Snapshot) []string {
	beforeMap := make(map[string]Snapshot)
	for _, s := range before {
		beforeMap[s.Path] = s
	}

	var changed []string

	// Check for modified files
	for _, afterSnap := range after {
		if beforeSnap, exists := beforeMap[afterSnap.Path]; exists {
			if afterSnap.Mtime.After(beforeSnap.Mtime) ||
			   afterSnap.Size != beforeSnap.Size ||
			   (afterSnap.IsText && afterSnap.Hash != beforeSnap.Hash) {
				changed = append(changed, afterSnap.Path)
			}
		} else {
			// New file created
			changed = append(changed, afterSnap.Path)
		}
	}

	// Check for deleted files
	for _, beforeSnap := range before {
		found := false
		for _, afterSnap := range after {
			if afterSnap.Path == beforeSnap.Path {
				found = true
				break
			}
		}
		if !found {
			changed = append(changed, beforeSnap.Path)
		}
	}

	return changed
}

// isTextFile determines if a file is a text file (simplified version)
func isTextFile(filePath string) bool {
	ext := strings.ToLower(filepath.Ext(filePath))
	textExts := map[string]bool{
		".txt": true, ".md": true, ".go": true, ".py": true, ".js": true, ".ts": true,
		".json": true, ".yaml": true, ".yml": true, ".xml": true, ".html": true,
		".css": true, ".scss": true, ".sh": true, ".bash": true, ".zsh": true,
		".fish": true, ".sql": true, ".csv": true,
	}

	if textExts[ext] {
		return true
	}

	// Check content (first 512 bytes)
	file, err := os.Open(filePath)
	if err != nil {
		return false
	}
	defer file.Close()

	buf := make([]byte, 512)
	n, err := file.Read(buf)
	if err != nil && n == 0 {
		return false
	}

	return utf8.Valid(buf[:n])
}

// calculateFileHash calculates SHA256 hash of a file
func calculateFileHash(filePath string) (string, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return "", err
	}
	defer file.Close()

	hash := sha256.New()
	if _, err := io.Copy(hash, file); err != nil {
		return "", err
	}

	return fmt.Sprintf("%x", hash.Sum(nil)), nil
}