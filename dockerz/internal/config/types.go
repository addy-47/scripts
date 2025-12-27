package config

import (
	"time"
)

// Service represents a service configuration
type Service struct {
	Name      string `yaml:"name" mapstructure:"name"`
	ImageName string `yaml:"image_name,omitempty" mapstructure:"image_name"`
	Tag       string `yaml:"tag,omitempty" mapstructure:"tag"`
}

// Config represents the main configuration structure
type Config struct {
	ServicesDir  []string  `yaml:"services_dir" mapstructure:"services_dir"`
	Project      string    `yaml:"project" mapstructure:"project"`
	GAR          string    `yaml:"gar" mapstructure:"gar"`
	Region       string    `yaml:"region" mapstructure:"region"`
	GlobalTag    string    `yaml:"global_tag,omitempty" mapstructure:"global_tag"`
	MaxProcesses int       `yaml:"max_processes,omitempty" mapstructure:"max_processes"`
	
	// Resource-aware scheduling configuration
	EnableResourceMonitoring bool    `yaml:"enable_resource_monitoring,omitempty" mapstructure:"enable_resource_monitoring"`
	MaxCPUThreshold         float64 `yaml:"max_cpu_threshold,omitempty" mapstructure:"max_cpu_threshold"`
	MaxMemoryThreshold      float64 `yaml:"max_memory_threshold,omitempty" mapstructure:"max_memory_threshold"`
	MaxDiskThreshold        float64 `yaml:"max_disk_threshold,omitempty" mapstructure:"max_disk_threshold"`
	UseGAR       bool      `yaml:"use_gar,omitempty" mapstructure:"use_gar"`
	PushToGAR    bool      `yaml:"push_to_gar,omitempty" mapstructure:"push_to_gar"`
	Services     []Service `yaml:"services,omitempty" mapstructure:"services"`

	// Smart features configuration
	Smart         bool   `yaml:"smart" mapstructure:"smart"`
	GitTrack      bool   `yaml:"git_track" mapstructure:"git_track"`
	GitTrackDepth int    `yaml:"git_track_depth" mapstructure:"git_track_depth"`
	Cache         bool   `yaml:"cache" mapstructure:"cache"`
	Force         bool   `yaml:"force" mapstructure:"force"`
	InputChangedServices  string `yaml:"input_changed_services" mapstructure:"input_changed_services"`
	OutputChangedServices string `yaml:"output_changed_services" mapstructure:"output_changed_services"`
	
	// BuildKit configuration
	EnableBuildKit bool `yaml:"enable_buildkit,omitempty" mapstructure:"enable_buildkit"`
}

// BuildResult represents the result of a build operation
type BuildResult struct {
	Service     string `json:"service"`
	Image       string `json:"image"`
	Status      string `json:"status"`
	BuildOutput string `json:"build_output,omitempty"`
	PushStatus  string `json:"push_status,omitempty"`
	PushOutput  string `json:"push_output,omitempty"`
	StartTime   time.Time
	EndTime     time.Time
}