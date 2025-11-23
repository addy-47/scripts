package config

import (
	"fmt"
	"os"
	"strings"

	"github.com/spf13/viper"
)

// ValidateTxtFile validates that the file path has a .txt extension
func ValidateTxtFile(filePath string) error {
	if filePath == "" {
		return nil // Empty is allowed
	}
	if !strings.HasSuffix(strings.ToLower(filePath), ".txt") {
		return fmt.Errorf("file '%s' must have a .txt extension", filePath)
	}
	return nil
}

// LoadConfig loads configuration from file and environment variables
func LoadConfig(configPath string) (*Config, error) {
	// Validate that the config file exists
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		return nil, fmt.Errorf("config file %s does not exist", configPath)
	}

	// Set up viper
	viper.SetConfigFile(configPath)
	viper.SetConfigType("yaml")

	// Environment variables not supported - use CLI flags instead

	// Read config file
	if err := viper.ReadInConfig(); err != nil {
		return nil, fmt.Errorf("failed to parse config file %s: %w", configPath, err)
	}

	// Log successful config file loading
	fmt.Printf("✓ Loaded configuration from: %s\n", configPath)

	var config Config
	if err := viper.Unmarshal(&config); err != nil {
		return nil, fmt.Errorf("failed to unmarshal config: %w", err)
	}

	// Handle backward compatibility for services_dir (can be string or []string)
	if servicesDirRaw := viper.Get("services_dir"); servicesDirRaw != nil {
		switch v := servicesDirRaw.(type) {
		case string:
			// Handle comma-separated string or single directory
			if v != "" {
				// Split by comma and trim spaces
				dirs := strings.Split(v, ",")
				for i, dir := range dirs {
					dirs[i] = strings.TrimSpace(dir)
				}
				config.ServicesDir = dirs
			}
		case []interface{}:
			// Already a slice, convert to []string
			dirs := make([]string, len(v))
			for i, item := range v {
				if str, ok := item.(string); ok {
					dirs[i] = str
				}
			}
			config.ServicesDir = dirs
		}
	}

	// No environment variable overrides for use_gar and push_to_gar - use CLI flags instead

	// Set defaults
	if config.MaxProcesses == 0 {
		config.MaxProcesses = 4 // Default to 4 parallel processes
	}

	// Set default services_dir to "." for auto-discovery only if no explicit services and no services_dir specified
	if len(config.Services) == 0 && len(config.ServicesDir) == 0 {
		config.ServicesDir = []string{"."}
	}

	// Ensure smart features are disabled by default for basic builds
	if !config.Smart {
		config.Smart = false
	}

	// Validate required fields for GAR if enabled
	if config.UseGAR {
		if config.Project == "" || config.GAR == "" || config.Region == "" {
			return nil, fmt.Errorf("missing required fields for GAR: project, gar, region")
		}
	}

	// Validate changed services file paths
	if err := ValidateTxtFile(config.InputChangedServices); err != nil {
		return nil, fmt.Errorf("invalid input_changed_services: %w", err)
	}
	if err := ValidateTxtFile(config.OutputChangedServices); err != nil {
		return nil, fmt.Errorf("invalid output_changed_services: %w", err)
	}

	return &config, nil
}

// SaveSampleConfig creates a sample build.yaml file
func SaveSampleConfig(filename string) error {
	sampleYAML := `# Dockerz Configuration File
# This file configures how Dockerz builds and manages your microservices.
# All paths are relative to the project root unless specified as absolute paths.

# Directory to scan for services (leave empty for auto-discovery of all subdirectories)
# Can be overridden with --services-dir flag (supports comma-separated paths)
# Example: --services-dir=backend,frontend/src,api/services
# Note: Auto-discovery excludes common build/dependency directories like debian/, node_modules/, .git/, etc.
services_dir:

# ===== GOOGLE CLOUD CONFIGURATION =====
# Configure your Google Cloud Platform settings for Artifact Registry

# Your GCP project ID (required when using Google Artifact Registry)
# Override with --project flag
project: my-gcp-project

# Name of your Google Artifact Registry repository
# Override with --gar flag
gar: my-artifact-registry

# GCP region where your Artifact Registry is located
# Override with --region flag
region: us-central1

# ===== BUILD CONFIGURATION =====

# Global Docker tag applied to all services (defaults to Git commit hash if not set)
# Common values: 'latest', 'v1.0.0', or leave empty for auto-generated tags
# Override with --tag flag
global_tag: latest

# Maximum number of parallel Docker builds (0 = use CPU core count / 2)
# Override with --max-processes flag
max_processes: 4

# Whether to use Google Artifact Registry for image naming and pushing
# When true: images use GAR naming (region-docker.pkg.dev/project/gar/service:tag)
# When false: images use local naming (service:tag)
# Override with --use-gar flag
use_gar: true

# Whether to push built images to Google Artifact Registry after building
# Only effective when use_gar is true
# Override with --push-to-gar flag
push_to_gar: true

# ===== SMART BUILD FEATURES (v2.0) =====
# Advanced features for optimizing CI/CD pipelines - disabled by default

# Enable smart build orchestration (analyzes dependencies and build order)
# Use --smart flag to enable in CI/CD
smart: false

# Enable git change detection to only rebuild modified services
# Requires git repository - tracks file changes between commits
# Use --git-track flag to enable
git_track: false

# Git tracking depth: how many recent commits to analyze for changes
# Default: 2 (checks last 2 commits: HEAD and HEAD~1)
# Can be set with --depth <number>
git_track_depth: 2

# Enable build caching to speed up rebuilds of unchanged services
# Use --cache flag to enable
cache: false

# Force rebuild all services regardless of smart features
# Useful for clean builds or when cache is corrupted
# Use --force flag to enable
force: false

# ===== CHANGE DETECTION FILES =====
# File paths for storing lists of changed services (used with git_track)

# Input file containing list of services that have changed (for CI/CD input)
# Used when you want to specify changed services externally
input_changed_services:

# Output file where Dockerz will write the list of detected changed services
# Useful for subsequent CI/CD steps or debugging
output_changed_services:

# ===== SERVICE DEFINITIONS =====
# Explicitly define services to build (leave empty for auto-discovery)
# Auto-discovery scans services_dir for directories containing Dockerfiles
#
# Behavior depends on git_track setting:
# - If services is empty AND git_track is false: Builds all services with Dockerfiles
# - If services is empty AND git_track is true: Builds only changed services from last commit
#   (if no changes detected, logs clear message to user)
# - If services is defined: Only builds the explicitly listed services
#
# Auto-discovery excludes common directories: debian/, node_modules/, .git/, internal/, vendor/, etc.
# This prevents conflicts in CI/CD where you can't modify this config file
#
# Each service can have:
# - name: Path to service directory (relative to project root)
# - image_name: Custom Docker image name (optional, defaults to service name)
# - tag: Service-specific tag (optional, overrides global_tag)

services:
  # Examples (uncomment and modify as needed):

  # - name: services/api
  #   image_name: my-api-service    # Optional custom image name
  #   tag: v1.0.0                   # Optional service-specific tag

  # - name: services/web-frontend
  #   image_name: my-web-app        # Optional custom image name

  # - name: microservices/user-service

# ===== USAGE EXAMPLES =====
#
# Basic build (auto-discover all services):
#   dockerz build
#
# Build with custom settings:
#   dockerz build --project my-prod-project --region us-east1 --tag v2.1.0
#
# Smart build with git tracking (CI/CD):
#   dockerz build --smart --git-track --cache --output-changed-services changed.txt
#
# Build specific services only:
#   dockerz build --services-dir=backend,frontend
#
# Force rebuild everything:
#   dockerz build --force
`

	if err := os.WriteFile(filename, []byte(sampleYAML), 0644); err != nil {
		return fmt.Errorf("failed to write sample config file: %w", err)
	}

	return nil
}
