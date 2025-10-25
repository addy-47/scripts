package builder

import (
	"time"

	"github.com/addy-47/dockerz/internal/config"
)

// BuildTask represents a single build task
type BuildTask struct {
	ServicePath string
	ImageName   string
	Tag         string
	Config      *config.Config
	CurrentHash string
	ChangedFiles []string
	NeedsBuild   bool
}

// BuildResult represents the result of a build operation
type BuildResult struct {
	Service     string    `json:"service"`
	Image       string    `json:"image"`
	Status      string    `json:"status"`
	BuildOutput string    `json:"build_output,omitempty"`
	PushStatus  string    `json:"push_status,omitempty"`
	PushOutput  string    `json:"push_output,omitempty"`
	StartTime   time.Time `json:"-"`
	EndTime     time.Time `json:"-"`
}

// Summary represents the build summary
type Summary struct {
	TotalServices    int
	SuccessfulBuilds int
	FailedBuilds     int
	FailedPushes     int
	Duration         time.Duration
}