package cache

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"time"
)

// LayerCache implements CacheManager for layer-based caching
type LayerCache struct {
	cacheDir string
	config   *CacheConfig
}

// NewLayerCache creates a new layer cache instance
func NewLayerCache(config *CacheConfig) *LayerCache {
	cacheDir := filepath.Join(os.TempDir(), "dockerz-layer-cache")
	os.MkdirAll(cacheDir, 0755)
	return &LayerCache{
		cacheDir: cacheDir,
		config:   config,
	}
}

// Get retrieves a cache entry from layer cache
func (l *LayerCache) Get(serviceName string) (*CacheEntry, bool) {
	cacheFile := filepath.Join(l.cacheDir, fmt.Sprintf("%s-layer.json", serviceName))

	data, err := os.ReadFile(cacheFile)
	if err != nil {
		return nil, false
	}

	var entry CacheEntry
	if err := json.Unmarshal(data, &entry); err != nil {
		return nil, false
	}

	// Check if entry is expired
	if time.Since(entry.Timestamp) > entry.TTL {
		l.Clear(serviceName) // Clean up expired entry
		return nil, false
	}

	return &entry, true
}

// Set stores a cache entry in layer cache
func (l *LayerCache) Set(entry *CacheEntry) error {
	cacheFile := filepath.Join(l.cacheDir, fmt.Sprintf("%s-layer.json", entry.ServiceName))

	data, err := json.MarshalIndent(entry, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal cache entry: %w", err)
	}

	return os.WriteFile(cacheFile, data, 0644)
}

// Clear removes a cache entry
func (l *LayerCache) Clear(serviceName string) error {
	cacheFile := filepath.Join(l.cacheDir, fmt.Sprintf("%s-layer.json", serviceName))
	return os.Remove(cacheFile)
}

// Cleanup removes all expired cache entries
func (l *LayerCache) Cleanup() error {
	entries, err := os.ReadDir(l.cacheDir)
	if err != nil {
		return err
	}

	for _, entry := range entries {
		if filepath.Ext(entry.Name()) == ".json" {
			serviceName := entry.Name()[:len(entry.Name())-10] // Remove -layer.json extension
			if cached, exists := l.Get(serviceName); !exists || cached == nil {
				// Entry doesn't exist or is expired, remove file
				os.Remove(filepath.Join(l.cacheDir, entry.Name()))
			}
		}
	}

	return nil
}