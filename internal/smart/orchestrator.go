package smart

import (
	"fmt"
	"log"
	"time"

	"github.com/addy-47/dockerz/internal/cache"
	"github.com/addy-47/dockerz/internal/config"
	"github.com/addy-47/dockerz/internal/discovery"
	"github.com/addy-47/dockerz/internal/git"
)

// Orchestrator handles smart build decisions
type Orchestrator struct {
	config     *SmartConfig
	cacheMgr   cache.CacheManager
	gitTracker *git.Tracker
}

// NewOrchestrator creates a new smart orchestrator
func NewOrchestrator(config *SmartConfig) *Orchestrator {
	var cacheMgr cache.CacheManager
	switch config.CacheLevel {
	case cache.LayerCacheLevel:
		cacheMgr = cache.NewLayerCache(&cache.CacheConfig{
			Enabled: config.CacheEnabled,
			Level:   config.CacheLevel,
			TTL:     config.CacheTTL,
		})
	case cache.RegistryCacheLevel:
		cacheMgr = cache.NewRegistryCache(&cache.CacheConfig{
			Enabled: config.CacheEnabled,
			Level:   config.CacheLevel,
			TTL:     config.CacheTTL,
		})
	default:
		cacheMgr = cache.NewRegistryCache(&cache.CacheConfig{
			Enabled: config.CacheEnabled,
			Level:   config.CacheLevel,
			TTL:     config.CacheTTL,
		})
	}

	return &Orchestrator{
		config:     config,
		cacheMgr:   cacheMgr,
		gitTracker: git.NewTracker(),
	}
}

// OrchestrateBuilds analyzes services and makes smart build decisions
func (o *Orchestrator) OrchestrateBuilds(cfg *config.Config, services []discovery.DiscoveredService) (*OrchestrationResult, error) {
	result := &OrchestrationResult{
		ServiceStates: make([]ServiceState, 0, len(services)),
		Decisions:     make(map[string]BuildDecision),
		TotalServices: len(services),
	}

	if !o.config.Enabled {
		// If smart features are disabled, build everything
		for _, service := range services {
			result.Decisions[service.Name] = ForceBuild
			result.BuildCount++
		}
		return result, nil
	}

	// Analyze each service
	for _, service := range services {
		state, decision := o.analyzeService(service)
		result.ServiceStates = append(result.ServiceStates, state)

		switch decision {
		case SkipBuild:
			result.SkipCount++
		case ForceBuild, ConditionalBuild:
			result.BuildCount++
		}

		result.Decisions[service.Name] = decision
	}

	return result, nil
}

// analyzeService determines if a service needs to be built
func (o *Orchestrator) analyzeService(service discovery.DiscoveredService) (ServiceState, BuildDecision) {
	state := ServiceState{
		ServiceName: service.Name,
	}

	// Calculate current hash
	currentHash, err := cache.CalculateServiceHash(service.Path)
	if err != nil {
		log.Printf("Failed to calculate hash for %s: %v", service.Name, err)
		return state, ForceBuild
	}
	state.CurrentHash = currentHash

	// Check cache first
	if cached, exists := o.cacheMgr.Get(service.Name); exists && cached != nil {
		state.LastBuildHash = cached.ImageHash
		state.LastBuildTime = cached.Timestamp
		state.CacheHit = true

		// If hashes match and not forcing rebuild, skip
		if cached.ImageHash == currentHash && !o.config.ForceRebuild {
			return state, SkipBuild
		}
	}

	// Check git changes if tracking is enabled
	if o.config.GitTracking {
		changedFiles, err := o.gitTracker.GetChangedFiles(service.Path)
		if err != nil {
			log.Printf("Failed to get git changes for %s: %v", service.Name, err)
		} else {
			state.ChangedFiles = changedFiles
			if len(changedFiles) == 0 && !o.config.ForceRebuild {
				return state, SkipBuild
			}
		}
	}

	// Force rebuild if requested or no cache hit
	if o.config.ForceRebuild {
		return state, ForceBuild
	}

	return state, ConditionalBuild
}

// UpdateCache updates the cache with new build results
func (o *Orchestrator) UpdateCache(serviceName, imageHash string) error {
	entry := &cache.CacheEntry{
		ServiceName: serviceName,
		ImageHash:   imageHash,
		Timestamp:   time.Now(),
		TTL:         o.config.CacheTTL,
	}

	return o.cacheMgr.Set(entry)
}

// Cleanup performs cache cleanup
func (o *Orchestrator) Cleanup() error {
	return o.cacheMgr.Cleanup()
}

// GetStats returns orchestration statistics
func (o *Orchestrator) GetStats(result *OrchestrationResult) string {
	return fmt.Sprintf("Smart Orchestration: %d total, %d to build, %d skipped",
		result.TotalServices, result.BuildCount, result.SkipCount)
}