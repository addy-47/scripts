package cache

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/addy-47/dockerz/internal/logging"
)

// DistributedCache implements a more efficient caching mechanism
type DistributedCache struct {
	cacheDir string
	config   *CacheConfig
	logger   *logging.Logger
	mu       sync.RWMutex
	inMemoryCache map[string]*CacheEntry
}

// NewDistributedCache creates a new distributed cache instance
type DistributedCacheConfig struct {
	CacheDir string
	Config   *CacheConfig
}

func NewDistributedCache(config *CacheConfig) *DistributedCache {
	cacheDir := filepath.Join(os.TempDir(), "dockerz-distributed-cache")
	os.MkdirAll(cacheDir, 0755)
	
	return &DistributedCache{
		cacheDir: cacheDir,
		config:   config,
		logger:   nil, // Will be set by caller
		inMemoryCache: make(map[string]*CacheEntry),
	}
}

// SetLogger sets the logger for the cache
func (d *DistributedCache) SetLogger(logger *logging.Logger) {
	d.logger = logger
}

// Get retrieves a cache entry from distributed cache
func (d *DistributedCache) Get(serviceName string) (*CacheEntry, bool) {
	// First check in-memory cache
	d.mu.RLock()
	if entry, exists := d.inMemoryCache[serviceName]; exists {
		// Check if entry is expired
		if time.Since(entry.Timestamp) > entry.TTL {
			d.mu.RUnlock()
			d.Clear(serviceName) // Clean up expired entry
			return nil, false
		}
		d.mu.RUnlock()
		
		if d.logger != nil {
			d.logger.Info(logging.CATEGORY_CACHE, fmt.Sprintf("In-memory cache hit for %s (age: %v)", serviceName, time.Since(entry.Timestamp)))
		}
		return entry, true
	}
	d.mu.RUnlock()

	// Fallback to file-based cache
	cacheFile := filepath.Join(d.cacheDir, fmt.Sprintf("%s.json", serviceName))

	data, err := os.ReadFile(cacheFile)
	if err != nil {
		if d.logger != nil {
			d.logger.Debug(logging.CATEGORY_CACHE, fmt.Sprintf("Cache miss for %s: file not found", serviceName))
		}
		return nil, false
	}

	var entry CacheEntry
	if err := json.Unmarshal(data, &entry); err != nil {
		if d.logger != nil {
			d.logger.Debug(logging.CATEGORY_CACHE, fmt.Sprintf("Cache miss for %s: invalid cache data", serviceName))
		}
		return nil, false
	}

	// Check if entry is expired
	if time.Since(entry.Timestamp) > entry.TTL {
		if d.logger != nil {
			d.logger.Debug(logging.CATEGORY_CACHE, fmt.Sprintf("Cache miss for %s: expired (age: %v)", serviceName, time.Since(entry.Timestamp)))
		}
		d.Clear(serviceName) // Clean up expired entry
		return nil, false
	}

	// Add to in-memory cache for faster future access
	d.mu.Lock()
	d.inMemoryCache[serviceName] = &entry
	d.mu.Unlock()

	if d.logger != nil {
		d.logger.Info(logging.CATEGORY_CACHE, fmt.Sprintf("File cache hit for %s (age: %v)", serviceName, time.Since(entry.Timestamp)))
	}
	return &entry, true
}

// Set stores a cache entry in distributed cache
func (d *DistributedCache) Set(entry *CacheEntry) error {
	// Update in-memory cache
	d.mu.Lock()
	d.inMemoryCache[entry.ServiceName] = entry
	d.mu.Unlock()

	// Persist to file system
	cacheFile := filepath.Join(d.cacheDir, fmt.Sprintf("%s.json", entry.ServiceName))

	data, err := json.MarshalIndent(entry, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal cache entry: %w", err)
	}

	if d.logger != nil {
		d.logger.Debug(logging.CATEGORY_CACHE, fmt.Sprintf("Cache set for %s (hash: %s)", entry.ServiceName, entry.ImageHash))
	}

	return os.WriteFile(cacheFile, data, 0644)
}

// Clear removes a cache entry
func (d *DistributedCache) Clear(serviceName string) error {
	// Remove from in-memory cache
	d.mu.Lock()
	delete(d.inMemoryCache, serviceName)
	d.mu.Unlock()

	// Remove from file system
	cacheFile := filepath.Join(d.cacheDir, fmt.Sprintf("%s.json", serviceName))
	return os.Remove(cacheFile)
}

// Cleanup removes all expired cache entries
func (d *DistributedCache) Cleanup() error {
	d.mu.Lock()
	defer d.mu.Unlock()

	entries, err := os.ReadDir(d.cacheDir)
	if err != nil {
		return err
	}

	for _, entry := range entries {
		if filepath.Ext(entry.Name()) == ".json" {
			serviceName := entry.Name()[:len(entry.Name())-5] // Remove .json extension
			if cached, exists := d.inMemoryCache[serviceName]; !exists || cached == nil {
				// Entry doesn't exist or is expired, remove file
				os.Remove(filepath.Join(d.cacheDir, entry.Name()))
			}
		}
	}

	return nil
}

// GetCacheStats returns statistics about the cache
func (d *DistributedCache) GetCacheStats() map[string]interface{} {
	d.mu.RLock()
	defer d.mu.RUnlock()

	return map[string]interface{}{
		"in_memory_entries": len(d.inMemoryCache),
		"cache_dir":        d.cacheDir,
	}
}