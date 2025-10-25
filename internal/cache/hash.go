package cache

import (
	"crypto/sha256"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
)

// CalculateServiceHash computes SHA256 hash of service directory contents
func CalculateServiceHash(servicePath string) (string, error) {
	hash := sha256.New()

	err := filepath.Walk(servicePath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Skip .git directory and other irrelevant files
		if strings.Contains(path, ".git") || strings.HasSuffix(path, ".tmp") {
			if info.IsDir() {
				return filepath.SkipDir
			}
			return nil
		}

		// Only hash regular files
		if !info.Mode().IsRegular() {
			return nil
		}

		file, err := os.Open(path)
		if err != nil {
			return err
		}
		defer file.Close()

		if _, err := io.Copy(hash, file); err != nil {
			return err
		}

		return nil
	})

	if err != nil {
		return "", fmt.Errorf("failed to calculate hash for service %s: %w", servicePath, err)
	}

	return fmt.Sprintf("%x", hash.Sum(nil)), nil
}

// CalculateLayerHash computes hash of Docker layer contents
func CalculateLayerHash(layerFiles []string) (string, error) {
	hash := sha256.New()

	for _, file := range layerFiles {
		content, err := os.ReadFile(file)
		if err != nil {
			return "", fmt.Errorf("failed to read layer file %s: %w", file, err)
		}
		hash.Write(content)
	}

	return fmt.Sprintf("%x", hash.Sum(nil)), nil
}

// ValidateHash checks if provided hash matches expected format
func ValidateHash(hash string) bool {
	if len(hash) != 64 {
		return false
	}
	for _, r := range hash {
		if !((r >= '0' && r <= '9') || (r >= 'a' && r <= 'f')) {
			return false
		}
	}
	return true
}