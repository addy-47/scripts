package config

import (
	"os"
	"path/filepath"
	"time"

	"github.com/spf13/viper"
)

// Config holds the user configuration for the u tool
type Config struct {
	IgnoredDirs []string      `mapstructure:"ignored_dirs" yaml:"ignored_dirs"`
	TTL         time.Duration `mapstructure:"ttl" yaml:"ttl"`
}

// LoadConfig loads the configuration from ~/.u/config.yaml with sensible defaults
func LoadConfig() (*Config, error) {
	configDir := filepath.Join(os.Getenv("HOME"), ".u")
	configPath := filepath.Join(configDir, "config.yaml")

	viper.SetConfigFile(configPath)
	viper.SetConfigType("yaml")

	// Set defaults
	viper.SetDefault("ignored_dirs", []string{".cache", ".git", "node_modules", "venv", "/tmp", "/proc", "/sys"})
	viper.SetDefault("ttl", 24*time.Hour)

	// Try to read config file
	if err := viper.ReadInConfig(); err != nil {
		// If file doesn't exist, use defaults (this is expected)
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return nil, err
		}
	}

	var config Config
	if err := viper.Unmarshal(&config); err != nil {
		return nil, err
	}

	return &config, nil
}
