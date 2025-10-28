package config

import (
	"os"
	"path/filepath"
	"time"

	"github.com/spf13/viper"
)

// Config holds the user configuration for the u tool
type Config struct {
	IgnoredDirs    []string      `mapstructure:"ignored_dirs" yaml:"ignored_dirs"`
	TTL            time.Duration `mapstructure:"ttl" yaml:"ttl"`
	MaxFileSize    int64         `mapstructure:"max_file_size" yaml:"max_file_size"`
	MaxTotalSize   int64         `mapstructure:"max_total_size" yaml:"max_total_size"`
	TextFilesOnly  bool          `mapstructure:"text_files_only" yaml:"text_files_only"`
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
	viper.SetDefault("max_file_size", int64(10*1024*1024)) // 10MB
	viper.SetDefault("max_total_size", int64(100*1024*1024)) // 100MB
	viper.SetDefault("text_files_only", true)

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
