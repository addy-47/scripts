package cache

import (
	"time"
)

// CacheLevel represents different levels of caching
type CacheLevel int

const (
	LayerCacheLevel CacheLevel = iota
	LocalHashCache
	RegistryCacheLevel
	DistributedCacheLevel
)

// CacheEntry represents a cached build result
type CacheEntry struct {
	ServiceName string    `json:"service_name"`
	ImageHash   string    `json:"image_hash"`
	LayerHash   string    `json:"layer_hash,omitempty"`
	RegistryTag string    `json:"registry_tag,omitempty"`
	Timestamp   time.Time `json:"timestamp"`
	TTL         time.Duration `json:"ttl"`
}

// CacheConfig represents cache configuration
type CacheConfig struct {
	Enabled     bool          `yaml:"enabled" mapstructure:"enabled"`
	Level       CacheLevel    `yaml:"level" mapstructure:"level"`
	TTL         time.Duration `yaml:"ttl" mapstructure:"ttl"`
	RegistryURL string        `yaml:"registry_url,omitempty" mapstructure:"registry_url"`
}

// CacheManager interface for different cache implementations
type CacheManager interface {
	Get(serviceName string) (*CacheEntry, bool)
	Set(entry *CacheEntry) error
	Clear(serviceName string) error
	Cleanup() error
}