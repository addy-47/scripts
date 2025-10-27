package smart

import (
	"time"

	"github.com/addy-47/dockerz/internal/cache"
)

// BuildDecision represents the decision made by the smart orchestrator
type BuildDecision int

const (
	SkipBuild BuildDecision = iota
	ForceBuild
	ConditionalBuild
)

// SmartConfig represents smart build configuration
type SmartConfig struct {
	Enabled         bool          `yaml:"enabled" mapstructure:"enabled"`
	GitTracking     bool          `yaml:"git_tracking" mapstructure:"git_tracking"`
	CacheEnabled    bool          `yaml:"cache_enabled" mapstructure:"cache_enabled"`
	CacheLevel      cache.CacheLevel `yaml:"cache_level" mapstructure:"cache_level"`
	CacheTTL        time.Duration `yaml:"cache_ttl" mapstructure:"cache_ttl"`
	ForceRebuild    bool          `yaml:"force_rebuild" mapstructure:"force_rebuild"`
}

// ServiceState represents the current state of a service
type ServiceState struct {
	ServiceName   string
	CurrentHash   string
	LastBuildHash string
	ChangedFiles  []string
	LastBuildTime time.Time
	CacheHit      bool
}

// OrchestrationResult represents the result of smart orchestration
type OrchestrationResult struct {
	ServiceStates []ServiceState
	Decisions     map[string]BuildDecision
	TotalServices int
	SkipCount     int
	BuildCount    int
}