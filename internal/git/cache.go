package git

import (
	"fmt"
	"sync"
	"time"

	"github.com/addy-47/dockerz/internal/logging"
)

// GitCache caches git operation results to avoid redundant calls
type GitCache struct {
	logger      *logging.Logger
	mu          sync.RWMutex
	statusCache map[string]GitStatusCacheEntry
	diffCache   map[string]GitDiffCacheEntry
}

// GitStatusCacheEntry represents cached git status results
type GitStatusCacheEntry struct {
	files      []string
	timestamp  time.Time
	validUntil time.Time
}

// GitDiffCacheEntry represents cached git diff results
type GitDiffCacheEntry struct {
	files      []string
	timestamp  time.Time
	validUntil time.Time
}

// NewGitCache creates a new git cache instance
func NewGitCache() *GitCache {
	return &GitCache{
		statusCache: make(map[string]GitStatusCacheEntry),
		diffCache:   make(map[string]GitDiffCacheEntry),
	}
}

// SetLogger sets the logger for the git cache
func (gc *GitCache) SetLogger(logger *logging.Logger) {
	gc.logger = logger
}

// GetCachedStatus retrieves cached git status results
func (gc *GitCache) GetCachedStatus(servicePath string, depth int) ([]string, bool) {
	gc.mu.RLock()
	defer gc.mu.RUnlock()

	cacheKey := fmt.Sprintf("%s-status-%d", servicePath, depth)
	if entry, exists := gc.statusCache[cacheKey]; exists {
		if time.Now().Before(entry.validUntil) {
			if gc.logger != nil {
				gc.logger.Debug(logging.CATEGORY_GIT, fmt.Sprintf("Git status cache hit for %s (depth: %d)", servicePath, depth))
			}
			return entry.files, true
		}
	}
	return nil, false
}

// CacheStatus stores git status results in cache
func (gc *GitCache) CacheStatus(servicePath string, depth int, files []string, ttl time.Duration) {
	gc.mu.Lock()
	defer gc.mu.Unlock()

	cacheKey := fmt.Sprintf("%s-status-%d", servicePath, depth)
	gc.statusCache[cacheKey] = GitStatusCacheEntry{
		files:      files,
		timestamp:  time.Now(),
		validUntil: time.Now().Add(ttl),
	}

	if gc.logger != nil {
		gc.logger.Debug(logging.CATEGORY_GIT, fmt.Sprintf("Cached git status for %s (depth: %d, files: %d)", servicePath, depth, len(files)))
	}
}

// GetCachedDiff retrieves cached git diff results
func (gc *GitCache) GetCachedDiff(servicePath string, depth int) ([]string, bool) {
	gc.mu.RLock()
	defer gc.mu.RUnlock()

	cacheKey := fmt.Sprintf("%s-diff-%d", servicePath, depth)
	if entry, exists := gc.diffCache[cacheKey]; exists {
		if time.Now().Before(entry.validUntil) {
			if gc.logger != nil {
				gc.logger.Debug(logging.CATEGORY_GIT, fmt.Sprintf("Git diff cache hit for %s (depth: %d)", servicePath, depth))
			}
			return entry.files, true
		}
	}
	return nil, false
}

// CacheDiff stores git diff results in cache
func (gc *GitCache) CacheDiff(servicePath string, depth int, files []string, ttl time.Duration) {
	gc.mu.Lock()
	defer gc.mu.Unlock()

	cacheKey := fmt.Sprintf("%s-diff-%d", servicePath, depth)
	gc.diffCache[cacheKey] = GitDiffCacheEntry{
		files:      files,
		timestamp:  time.Now(),
		validUntil: time.Now().Add(ttl),
	}

	if gc.logger != nil {
		gc.logger.Debug(logging.CATEGORY_GIT, fmt.Sprintf("Cached git diff for %s (depth: %d, files: %d)", servicePath, depth, len(files)))
	}
}

// ClearCache clears the git cache
func (gc *GitCache) ClearCache() {
	gc.mu.Lock()
	defer gc.mu.Unlock()
	
	gc.statusCache = make(map[string]GitStatusCacheEntry)
	gc.diffCache = make(map[string]GitDiffCacheEntry)

	if gc.logger != nil {
		gc.logger.Debug(logging.CATEGORY_GIT, "Git cache cleared")
	}
}

// GetCacheStats returns statistics about the git cache
func (gc *GitCache) GetCacheStats() map[string]interface{} {
	gc.mu.RLock()
	defer gc.mu.RUnlock()

	return map[string]interface{}{
		"status_entries": len(gc.statusCache),
		"diff_entries":   len(gc.diffCache),
	}
}