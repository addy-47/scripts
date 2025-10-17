package backup

import (
	"archive/tar"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"syscall"
	"time"
	"unicode/utf8"

	"github.com/klauspost/compress/zstd"
	"u/internal/config"
)

// BackupManager handles file backup and restore operations
type BackupManager struct {
	baseDir string
	config  *config.Config
}

// FileInfo represents information about a file for backup decisions
type FileInfo struct {
	Path string
	Size int64
	IsText bool
}

// NewBackupManager creates a new backup manager
func NewBackupManager() *BackupManager {
	home := os.Getenv("HOME")
	cfg, _ := config.LoadConfig() // Load config, use defaults if error
	return &BackupManager{
		baseDir: filepath.Join(home, ".u", "backups"),
		config:  cfg,
	}
}

// CreateBackup creates a compressed backup of the specified files
func (bm *BackupManager) CreateBackup(files []string, timestamp string) error {
	if len(files) == 0 {
		return nil
	}

	// Filter files based on config
	filteredFiles, err := bm.filterFilesForBackup(files)
	if err != nil {
		return fmt.Errorf("failed to filter files: %w", err)
	}

	if len(filteredFiles) == 0 {
		return nil // No files to backup after filtering
	}

	// Check disk space
	if err := bm.checkAvailableSpace(filteredFiles); err != nil {
		return fmt.Errorf("insufficient disk space: %w", err)
	}

	// Ensure backup directory exists
	if err := os.MkdirAll(bm.baseDir, 0755); err != nil {
		return fmt.Errorf("failed to create backup directory: %w", err)
	}

	backupPath := filepath.Join(bm.baseDir, fmt.Sprintf("%s.tar.zst", timestamp))

	// Create the compressed tar file
	file, err := os.Create(backupPath)
	if err != nil {
		return fmt.Errorf("failed to create backup file: %w", err)
	}
	defer file.Close()

	// Create zstd encoder
	encoder, err := zstd.NewWriter(file)
	if err != nil {
		return fmt.Errorf("failed to create zstd encoder: %w", err)
	}
	defer encoder.Close()

	// Create tar writer
	tarWriter := tar.NewWriter(encoder)
	defer tarWriter.Close()

	// Add files to tar
	for _, filePath := range filteredFiles {
		if err := bm.addFileToTar(tarWriter, filePath); err != nil {
			// Log error but continue with other files
			fmt.Fprintf(os.Stderr, "Warning: failed to backup %s: %v\n", filePath, err)
		}
	}

	return nil
}

// addFileToTar adds a single file to the tar archive
func (bm *BackupManager) addFileToTar(tarWriter *tar.Writer, filePath string) error {
	file, err := os.Open(filePath)
	if err != nil {
		return err
	}
	defer file.Close()

	stat, err := file.Stat()
	if err != nil {
		return err
	}

	// Create tar header
	header := &tar.Header{
		Name:    strings.TrimPrefix(filePath, string(filepath.Separator)),
		Size:    stat.Size(),
		Mode:    int64(stat.Mode()),
		ModTime: stat.ModTime(),
	}

	if err := tarWriter.WriteHeader(header); err != nil {
		return err
	}

	// Copy file content
	_, err = io.Copy(tarWriter, file)
	return err
}

// RestoreBackup restores files from a backup archive
func (bm *BackupManager) RestoreBackup(timestamp string) error {
	backupPath := filepath.Join(bm.baseDir, fmt.Sprintf("%s.tar.zst", timestamp))

	file, err := os.Open(backupPath)
	if err != nil {
		return fmt.Errorf("failed to open backup file: %w", err)
	}
	defer file.Close()

	// Create zstd decoder
	decoder, err := zstd.NewReader(file)
	if err != nil {
		return fmt.Errorf("failed to create zstd decoder: %w", err)
	}
	defer decoder.Close()

	// Create tar reader
	tarReader := tar.NewReader(decoder)

	// Extract files
	for {
		header, err := tarReader.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return fmt.Errorf("failed to read tar header: %w", err)
		}

		// Create full path
		targetPath := filepath.Join("/", header.Name) // Assuming absolute paths in backup

		// Ensure directory exists
		dir := filepath.Dir(targetPath)
		if err := os.MkdirAll(dir, 0755); err != nil {
			return fmt.Errorf("failed to create directory %s: %w", dir, err)
		}

		// Create file
		outFile, err := os.Create(targetPath)
		if err != nil {
			return fmt.Errorf("failed to create file %s: %w", targetPath, err)
		}

		// Copy content
		if _, err := io.Copy(outFile, tarReader); err != nil {
			outFile.Close()
			return fmt.Errorf("failed to write file %s: %w", targetPath, err)
		}
		outFile.Close()

		// Restore permissions and mod time
		if err := os.Chmod(targetPath, os.FileMode(header.Mode)); err != nil {
			fmt.Fprintf(os.Stderr, "Warning: failed to restore permissions for %s: %v\n", targetPath, err)
		}
		if err := os.Chtimes(targetPath, time.Now(), header.ModTime); err != nil {
			fmt.Fprintf(os.Stderr, "Warning: failed to restore mod time for %s: %v\n", targetPath, err)
		}
	}

	return nil
}

// CleanupOldBackups removes backups older than the specified TTL
func (bm *BackupManager) CleanupOldBackups(ttl time.Duration) error {
	entries, err := os.ReadDir(bm.baseDir)
	if err != nil {
		if os.IsNotExist(err) {
			return nil // No backups directory yet
		}
		return fmt.Errorf("failed to read backup directory: %w", err)
	}

	cutoff := time.Now().Add(-ttl)

	for _, entry := range entries {
		if strings.HasSuffix(entry.Name(), ".tar.zst") {
			// Extract timestamp from filename
			name := strings.TrimSuffix(entry.Name(), ".tar.zst")
			backupTime, err := time.Parse("2006-01-02T15-04-05", name)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Warning: invalid backup filename %s: %v\n", entry.Name(), err)
				continue
			}

			if backupTime.Before(cutoff) {
				path := filepath.Join(bm.baseDir, entry.Name())
				if err := os.Remove(path); err != nil {
					fmt.Fprintf(os.Stderr, "Warning: failed to remove old backup %s: %v\n", path, err)
				}
			}
		}
	}

	return nil
}

// ListBackups returns a list of available backup timestamps
func (bm *BackupManager) ListBackups() ([]string, error) {
	entries, err := os.ReadDir(bm.baseDir)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to read backup directory: %w", err)
	}

	var backups []string
	for _, entry := range entries {
		if strings.HasSuffix(entry.Name(), ".tar.zst") {
			name := strings.TrimSuffix(entry.Name(), ".tar.zst")
			backups = append(backups, name)
		}
	}

	return backups, nil
}

// filterFilesForBackup filters files based on config (size, type, etc.)
func (bm *BackupManager) filterFilesForBackup(files []string) ([]string, error) {
	var filtered []string

	for _, filePath := range files {
		info, err := bm.getFileInfo(filePath)
		if err != nil {
			continue // Skip files we can't access
		}

		// Check file size limit
		if bm.config != nil && bm.config.MaxFileSize > 0 && info.Size > bm.config.MaxFileSize {
			fmt.Fprintf(os.Stderr, "Warning: skipping %s (size %d > limit %d)\n", filePath, info.Size, bm.config.MaxFileSize)
			continue
		}

		// Check if text files only
		if bm.config != nil && bm.config.TextFilesOnly && !info.IsText {
			continue // Skip binary files
		}

		filtered = append(filtered, filePath)
	}

	return filtered, nil
}

// getFileInfo gets information about a file for backup decisions
func (bm *BackupManager) getFileInfo(filePath string) (*FileInfo, error) {
	stat, err := os.Stat(filePath)
	if err != nil {
		return nil, err
	}

	isText := bm.isTextFile(filePath)

	return &FileInfo{
		Path:   filePath,
		Size:   stat.Size(),
		IsText: isText,
	}, nil
}

// isTextFile determines if a file is a text file
func (bm *BackupManager) isTextFile(filePath string) bool {
	// Check file extension first
	ext := strings.ToLower(filepath.Ext(filePath))
	textExts := map[string]bool{
		".txt": true, ".md": true, ".go": true, ".py": true, ".js": true, ".ts": true,
		".json": true, ".yaml": true, ".yml": true, ".xml": true, ".html": true,
		".css": true, ".scss": true, ".sh": true, ".bash": true, ".zsh": true,
		".fish": true, ".sql": true, ".csv": true, ".log": true,
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

// checkAvailableSpace checks if there's enough disk space for the backup
func (bm *BackupManager) checkAvailableSpace(files []string) error {
	if bm.config == nil {
		return nil // No config, skip check
	}

	var totalSize int64
	for _, filePath := range files {
		if stat, err := os.Stat(filePath); err == nil {
			totalSize += stat.Size()
		}
	}

	var stat syscall.Statfs_t
	home := os.Getenv("HOME")
	if err := syscall.Statfs(home, &stat); err != nil {
		return fmt.Errorf("failed to get disk space: %w", err)
	}

	available := stat.Bavail * uint64(stat.Bsize)
	required := uint64(totalSize * 2) // 2x safety margin

	if available < required {
		return fmt.Errorf("insufficient disk space: need %d bytes, have %d bytes", required, available)
	}

	return nil
}
