package cache

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/addy-47/dockerz/internal/logging"
)

// RegistryCache implements CacheManager for registry-based caching
type RegistryCache struct {
	cacheDir string
	config   *CacheConfig
	logger   *logging.Logger
}

// NewRegistryCache creates a new registry cache instance
func NewRegistryCache(config *CacheConfig) *RegistryCache {
	cacheDir := filepath.Join(os.TempDir(), "dockerz-registry-cache")
	os.MkdirAll(cacheDir, 0755)
	return &RegistryCache{
		cacheDir: cacheDir,
		config:   config,
		logger:   nil, // Will be set by caller
	}
}

// SetLogger sets the logger for the cache
func (r *RegistryCache) SetLogger(logger *logging.Logger) {
	r.logger = logger
}

// Get retrieves a cache entry from registry cache
func (r *RegistryCache) Get(serviceName string) (*CacheEntry, bool) {
	cacheFile := filepath.Join(r.cacheDir, fmt.Sprintf("%s.json", serviceName))

	data, err := os.ReadFile(cacheFile)
	if err != nil {
		if r.logger != nil {
			r.logger.Debug(logging.CATEGORY_CACHE, fmt.Sprintf("Cache miss for %s: file not found", serviceName))
		}
		return nil, false
	}

	var entry CacheEntry
	if err := json.Unmarshal(data, &entry); err != nil {
		if r.logger != nil {
			r.logger.Debug(logging.CATEGORY_CACHE, fmt.Sprintf("Cache miss for %s: invalid cache data", serviceName))
		}
		return nil, false
	}

	// Check if entry is expired
	if time.Since(entry.Timestamp) > entry.TTL {
		if r.logger != nil {
			r.logger.Debug(logging.CATEGORY_CACHE, fmt.Sprintf("Cache miss for %s: expired (age: %v)", serviceName, time.Since(entry.Timestamp)))
		}
		r.Clear(serviceName) // Clean up expired entry
		return nil, false
	}

	if r.logger != nil {
		r.logger.Info(logging.CATEGORY_CACHE, fmt.Sprintf("Cache hit for %s (age: %v)", serviceName, time.Since(entry.Timestamp)))
	}
	return &entry, true
}

// Set stores a cache entry in registry cache
func (r *RegistryCache) Set(entry *CacheEntry) error {
	cacheFile := filepath.Join(r.cacheDir, fmt.Sprintf("%s.json", entry.ServiceName))

	data, err := json.MarshalIndent(entry, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal cache entry: %w", err)
	}

	if r.logger != nil {
		r.logger.Debug(logging.CATEGORY_CACHE, fmt.Sprintf("Cache set for %s (hash: %s)", entry.ServiceName, entry.ImageHash))
	}

	return os.WriteFile(cacheFile, data, 0644)
}

// Clear removes a cache entry
func (r *RegistryCache) Clear(serviceName string) error {
	cacheFile := filepath.Join(r.cacheDir, fmt.Sprintf("%s.json", serviceName))
	return os.Remove(cacheFile)
}

// Cleanup removes all expired cache entries
func (r *RegistryCache) Cleanup() error {
	entries, err := os.ReadDir(r.cacheDir)
	if err != nil {
		return err
	}

	for _, entry := range entries {
		if filepath.Ext(entry.Name()) == ".json" {
			serviceName := entry.Name()[:len(entry.Name())-5] // Remove .json extension
			if cached, exists := r.Get(serviceName); !exists || cached == nil {
				// Entry doesn't exist or is expired, remove file
				os.Remove(filepath.Join(r.cacheDir, entry.Name()))
			}
		}
	}

	return nil
}