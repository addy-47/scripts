package main

// Small change to trigger CI/CD pipeline
// Another small change for testing
// Third comment for pipeline testing

import (
	"fmt"
	"log"
	"os"
	"time"

	"github.com/addy-47/dockerz/internal/builder"
	"github.com/addy-47/dockerz/internal/cache"
	"github.com/addy-47/dockerz/internal/config"
	"github.com/addy-47/dockerz/internal/discovery"
	"github.com/addy-47/dockerz/internal/smart"
	"github.com/fatih/color"
	"github.com/spf13/cobra"
)

var (
	configPath            string
	maxProcesses          int
	gitTrack              bool
	cacheEnabled          bool
	forceRebuild          bool
	smartEnabled          bool
	projectID             string
	region                string
	garName               string
	globalTag             string
	changedServicesFile   string
	outputChangedServices string
)

// PrintDockerzBanner prints the ASCII art banner with colors
func PrintDockerzBanner() {
	// Define colors
	lightBlue := color.New(color.FgHiCyan).Add(color.Bold)
	darkBlue := color.New(color.FgBlue).Add(color.Bold)
	LightGrey := color.New(color.FgHiWhite)

	// ASCII art for "dockerz"
	fmt.Println()
	lightBlue.Println(`     _            _                    `)
	lightBlue.Println(`  __| | ___   ___| | _____ _ __ ____  `)
	lightBlue.Println(` / _' |/ _ \ / __| |/ / _ \ '__|_  /  `)
	darkBlue.Println(`| (_| | (_) | (__|   <  __/ |   / /   `)
	darkBlue.Println(` \__,_|\___/ \___|_|\_\___|_|  /___|  `)
	fmt.Println()

	LightGrey.Println("\nThe ultimate Docker companion tool making container management effortless")
	fmt.Println()
}

var rootCmd = &cobra.Command{
	Use:   "dockerz",
	Short: "Dockerz - Build and push multiple Docker images in parallel",
	Long:  `Dockerz is a tool for building and pushing multiple Docker images in parallel based on a services.yaml configuration file.`,
	Run: func(cmd *cobra.Command, args []string) {
		PrintDockerzBanner()
		fmt.Println("Welcome to Dockerz!")
		fmt.Println("Use 'dockerz --help' to see available commands.")
	},
}

var initCmd = &cobra.Command{
	Use:   "init",
	Short: "Initialize a new project with sample configuration",
	Long:  `Create a sample services.yaml configuration file in the current directory.`,
	Run: func(cmd *cobra.Command, args []string) {
		if err := config.SaveSampleConfig("services.yaml"); err != nil {
			log.Fatalf("Failed to create sample config: %v", err)
		}
		fmt.Println("✓ Created sample services.yaml")
		fmt.Println("\nNext steps:")
		fmt.Println("1. Edit services.yaml to configure your services")
		fmt.Println("2. Run 'dockerz build' to build your images")
	},
}

var buildCmd = &cobra.Command{
	Use:   "build",
	Short: "Build Docker images based on services.yaml configuration",
	Long:  `Build Docker images for all services defined in services.yaml, with support for parallel processing and Google Artifact Registry.`,
	Run: func(cmd *cobra.Command, args []string) {
		// Load configuration
		cfg, err := config.LoadConfig(configPath)
		if err != nil {
			log.Fatalf("Failed to load config: %v", err)
		}

		// Validate GAR settings if use_gar is True
		if cfg.UseGAR {
			if err := builder.CheckGARAuth(); err != nil {
				log.Fatalf("GAR authentication not set up. Run 'gcloud auth configure-docker %s-docker.pkg.dev'.", cfg.Region)
			}
		}

		// Get default tag (short Git commit ID) if global_tag is not specified
		defaultTag := cfg.GlobalTag
		if defaultTag == "" {
			defaultTag = builder.GetGitCommitID()
		}

		// Override config with CLI flags if provided
		if gitTrack {
			cfg.GitTracking = gitTrack
		}
		if cacheEnabled {
			cfg.CacheEnabled = cacheEnabled
		}
		if forceRebuild {
			cfg.ForceRebuild = forceRebuild
		}
		if smartEnabled {
			cfg.SmartEnabled = smartEnabled
		}
		if projectID != "" {
			cfg.ProjectID = projectID
		}
		if region != "" {
			cfg.Region = region
		}
		if garName != "" {
			cfg.GARName = garName
		}
		if globalTag != "" {
			cfg.GlobalTag = globalTag
		}

		// Discover services
		discoveryResult, err := discovery.DiscoverServices(cfg, defaultTag)
		if err != nil {
			log.Fatalf("Failed to discover services: %v", err)
		}

		// Filter services based on changed services file if provided
		if changedServicesFile != "" {
			discoveryResult, err = discovery.FilterServicesByChangedFile(discoveryResult, changedServicesFile)
			if err != nil {
				log.Fatalf("Failed to filter services by changed file: %v", err)
			}
		}

		// Log any discovery errors
		for _, discoveryErr := range discoveryResult.Errors {
			log.Printf("Discovery error: %v", discoveryErr)
		}

		// Smart orchestration if enabled
		var servicesToBuild []discovery.DiscoveredService
		if cfg.SmartEnabled {
			smartConfig := &smart.SmartConfig{
				Enabled:      cfg.SmartEnabled,
				GitTracking:  cfg.GitTracking,
				CacheEnabled: cfg.CacheEnabled,
				CacheLevel:   cache.RegistryCacheLevel, // Default to registry cache
				CacheTTL:     24 * time.Hour,           // 24 hours TTL
				ForceRebuild: cfg.ForceRebuild,
			}

			orchestrator := smart.NewOrchestrator(smartConfig)
			result, err := orchestrator.OrchestrateBuilds(cfg, discoveryResult.Services)
			if err != nil {
				log.Fatalf("Failed to orchestrate builds: %v", err)
			}

			log.Printf("%s", orchestrator.GetStats(result))

			// Filter services that need building
			for i, service := range discoveryResult.Services {
				if decision, exists := result.Decisions[service.Name]; exists && decision != smart.SkipBuild {
					servicesToBuild = append(servicesToBuild, service)
					// Update service with smart info
					if i < len(result.ServiceStates) {
						state := result.ServiceStates[i]
						servicesToBuild[len(servicesToBuild)-1].CurrentHash = state.CurrentHash
						servicesToBuild[len(servicesToBuild)-1].ChangedFiles = state.ChangedFiles
						servicesToBuild[len(servicesToBuild)-1].NeedsBuild = true
					}
				}
			}

			// Output changed services to file if requested
			if outputChangedServices != "" {
				if err := discovery.WriteChangedServicesFile(servicesToBuild, outputChangedServices); err != nil {
					log.Printf("Warning: Failed to write changed services file: %v", err)
				} else {
					log.Printf("Changed services written to: %s", outputChangedServices)
				}
			}
		} else {
			servicesToBuild = discoveryResult.Services
			// Mark all as needing build when smart features disabled
			for i := range servicesToBuild {
				servicesToBuild[i].NeedsBuild = true
			}
		}

		// Create new discovery result with filtered services
		filteredResult := &discovery.DiscoveryResult{
			Services: servicesToBuild,
			Errors:   discoveryResult.Errors,
		}

		// Build images in parallel
		maxProcs := maxProcesses
		if maxProcs == 0 {
			maxProcs = cfg.MaxProcesses
		}

		_, summary := builder.BuildImages(cfg, filteredResult, maxProcs)

		// Exit with error code if there were build failures
		if summary.FailedBuilds > 0 {
			os.Exit(1)
		}
	},
}

func init() {
	// Set custom help function for root command
	rootCmd.SetHelpFunc(func(cmd *cobra.Command, args []string) {
		PrintDockerzBanner()
		// Get the default help template and execute it
		cmd.Println(cmd.UsageString())
	})

	rootCmd.AddCommand(initCmd)
	rootCmd.AddCommand(buildCmd)

	buildCmd.Flags().StringVarP(&configPath, "config", "c", "services.yaml", "Path to services.yaml configuration file")
	buildCmd.Flags().IntVarP(&maxProcesses, "max-processes", "m", 0, "Maximum number of parallel builds (overrides config file)")
	buildCmd.Flags().StringVar(&projectID, "project-id", "", "GCP project ID (overrides config file)")
	buildCmd.Flags().StringVar(&region, "region", "", "GCP region (overrides config file)")
	buildCmd.Flags().StringVar(&garName, "gar-name", "", "Google Artifact Registry name (overrides config file)")
	buildCmd.Flags().StringVar(&globalTag, "tag", "", "Global tag for all images (overrides config file)")
	buildCmd.Flags().StringVar(&changedServicesFile, "changed-services-file", "", "Path to file containing list of changed services to build")
	buildCmd.Flags().StringVar(&outputChangedServices, "output-changed-services", "", "Path to output file for list of changed services")
	buildCmd.Flags().BoolVar(&gitTrack, "git-track", false, "Enable git change tracking for smart builds")
	buildCmd.Flags().BoolVar(&cacheEnabled, "cache", false, "Enable build caching")
	buildCmd.Flags().BoolVar(&forceRebuild, "force", false, "Force rebuild all services")
	buildCmd.Flags().BoolVar(&smartEnabled, "smart", false, "Enable smart build orchestration")
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
