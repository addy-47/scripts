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

	// Force rebuild takes highest priority
	if o.config.ForceRebuild {
		return state, ForceBuild
	}

	// If git tracking is disabled, always build
	if !o.config.GitTracking {
		return state, ConditionalBuild
	}

	// Git tracking is enabled - trust Git over cache
	depth := o.config.GitTrackDepth
	if depth == 0 {
		depth = 2 // Default depth
	}
	changedFiles, err := o.gitTracker.GetChangedFiles(service.Path, depth)
	if err != nil {
		log.Printf("Failed to get git changes for %s: %v", service.Name, err)
		// Git failed - always build
		return state, ConditionalBuild
	}

	state.ChangedFiles = changedFiles
	if len(changedFiles) > 0 {
		log.Printf("Git changes detected for %s: %d files changed", service.Name, len(changedFiles))
		// Git detected changes - build
		return state, ConditionalBuild
	}

	// Git says no changes - skip build (trust Git over cache)
	log.Printf("Git reports no changes for %s: skipping build", service.Name)
	return state, SkipBuild
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

// GAR Integration Framework (Phase 3 placeholders)

// CheckGARConnectivity checks if GAR registry is configured and reachable
func (o *Orchestrator) CheckGARConnectivity(serviceName string) (configured, reachable bool) {
	// TODO: Phase 3 - Implement actual GAR connectivity checks
	// For now, return placeholders
	log.Printf("GAR connectivity check for %s: placeholder implementation", serviceName)
	return false, false
}

// CheckGARImageExists checks if the service image exists in GAR
func (o *Orchestrator) CheckGARImageExists(serviceName, imageHash string) bool {
	// TODO: Phase 3 - Implement actual GAR image existence checks
	// For now, return placeholder
	log.Printf("GAR image existence check for %s: placeholder implementation", serviceName)
	return false
}

// UpdateGARState updates the service state with GAR information
func (o *Orchestrator) UpdateGARState(state *ServiceState, serviceName string) {
	state.GARConfigured, state.GARReachable = o.CheckGARConnectivity(serviceName)
	if state.GARConfigured && state.GARReachable {
		state.GARImageExists = o.CheckGARImageExists(serviceName, state.CurrentHash)
	}
}
