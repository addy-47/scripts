package config

import (
	"fmt"
	"os"
	"strconv"

	"github.com/spf13/viper"
	"gopkg.in/yaml.v3"
)

// LoadConfig loads configuration from file and environment variables
func LoadConfig(configPath string) (*Config, error) {
	// Set up viper
	viper.SetConfigFile(configPath)
	viper.SetConfigType("yaml")

	// Enable environment variable binding
	viper.AutomaticEnv()

	// Bind specific environment variables
	viper.BindEnv("use_gar", "USE_GAR")
	viper.BindEnv("push_to_gar", "PUSH_TO_GAR")

	// Read config file
	if err := viper.ReadInConfig(); err != nil {
		return nil, fmt.Errorf("failed to read config file %s: %w", configPath, err)
	}

	var config Config
	if err := viper.Unmarshal(&config); err != nil {
		return nil, fmt.Errorf("failed to unmarshal config: %w", err)
	}

	// Override with environment variables if set
	if useGARStr := os.Getenv("USE_GAR"); useGARStr != "" {
		if useGAR, err := strconv.ParseBool(useGARStr); err == nil {
			config.UseGAR = useGAR
		}
	}

	if pushToGARStr := os.Getenv("PUSH_TO_GAR"); pushToGARStr != "" {
		if pushToGAR, err := strconv.ParseBool(pushToGARStr); err == nil {
			config.PushToGAR = pushToGAR
		}
	}

	// Set defaults
	if config.MaxProcesses == 0 {
		config.MaxProcesses = 4 // Default to 4 parallel processes
	}

	// Validate required fields for GAR if enabled
	if config.UseGAR {
		if config.ProjectID == "" || config.GARName == "" || config.Region == "" {
			return nil, fmt.Errorf("missing required fields for GAR: project_id, gar_name, region")
		}
	}

	return &config, nil
}

// SaveSampleConfig creates a sample services.yaml file
func SaveSampleConfig(filename string) error {
	sampleConfig := Config{
		ServicesDir:  "./services",
		ProjectID:    "my-gcp-project",
		GARName:      "my-artifact-registry",
		Region:       "us-central1",
		GlobalTag:    "v1.0.0",
		MaxProcesses: 4,
		UseGAR:       true,
		PushToGAR:    true,
		Services: []Service{
			{
				Name:      "services/service-a",
				ImageName: "service-a-image",
				Tag:       "v1.0.1",
			},
			{
				Name: "services/service-b",
			},
			{
				Name: "subdir/service-c",
			},
		},
		// Smart features enabled by default
		SmartEnabled: true,
		GitTracking:  true,
		CacheEnabled: true,
		ForceRebuild: false,
	}

	data, err := yaml.Marshal(&sampleConfig)
	if err != nil {
		return fmt.Errorf("failed to marshal sample config: %w", err)
	}

	if err := os.WriteFile(filename, data, 0644); err != nil {
		return fmt.Errorf("failed to write sample config file: %w", err)
	}

	return nil
}