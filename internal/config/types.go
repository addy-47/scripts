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
	ServicesDir  string    `yaml:"services_dir" mapstructure:"services_dir"`
	ProjectID    string    `yaml:"project_id" mapstructure:"project_id"`
	GARName      string    `yaml:"gar_name" mapstructure:"gar_name"`
	Region       string    `yaml:"region" mapstructure:"region"`
	GlobalTag    string    `yaml:"global_tag,omitempty" mapstructure:"global_tag"`
	MaxProcesses int       `yaml:"max_processes,omitempty" mapstructure:"max_processes"`
	UseGAR       bool      `yaml:"use_gar,omitempty" mapstructure:"use_gar"`
	PushToGAR    bool      `yaml:"push_to_gar,omitempty" mapstructure:"push_to_gar"`
	Services     []Service `yaml:"services,omitempty" mapstructure:"services"`

	// Smart features configuration
	SmartEnabled    bool `yaml:"smart_enabled,omitempty" mapstructure:"smart_enabled"`
	GitTracking     bool `yaml:"git_tracking,omitempty" mapstructure:"git_tracking"`
	CacheEnabled    bool `yaml:"cache_enabled,omitempty" mapstructure:"cache_enabled"`
	ForceRebuild    bool `yaml:"force_rebuild,omitempty" mapstructure:"force_rebuild"`
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