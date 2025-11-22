package main

import (
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"github.com/addy-47/dockerz/internal/builder"
	"github.com/addy-47/dockerz/internal/cache"
	"github.com/addy-47/dockerz/internal/config"
	"github.com/addy-47/dockerz/internal/discovery"
	"github.com/addy-47/dockerz/internal/git"
	"github.com/addy-47/dockerz/internal/smart"
	"github.com/fatih/color"
	"github.com/spf13/cobra"
)

var (
	configPath            string
	maxProcesses          int
	gitTrack              bool
	depth                 int
	cacheEnabled          bool
	forceRebuild          bool
	smartEnabled          bool
	project               string
	region                string
	gar                   string
	globalTag             string
	inputChangedServices  string
	outputChangedServices string
	useGAR                bool
	pushToGAR             bool
	servicesDir           string
	version               bool
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
		if version {
			fmt.Println("dockerz version 2.0.0")
			return
		}
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
	Long: `Build Docker images for all services defined in services.yaml.

This command supports parallel processing, smart change detection using git tracking,
multi-level caching (layer, local hash, and registry), and Google Artifact Registry (GAR)
integration for secure image storage and distribution.

Key features:
- Parallel builds with configurable process limits
- Smart orchestration to skip unchanged services
- Git-based change detection for incremental builds
- Multi-level caching for faster rebuilds
- GAR integration for GCP environments
- File-based interfaces for CI/CD integration

All flags can override corresponding settings in the configuration file.`,
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
		if cmd.Flags().Changed("git-track") {
			cfg.GitTrack = gitTrack
			cfg.GitTrackDepth = depth
		}
		if cmd.Flags().Changed("cache") {
			cfg.Cache = cacheEnabled
		}
		if cmd.Flags().Changed("force") {
			cfg.Force = forceRebuild
		}
		if cmd.Flags().Changed("smart") {
			cfg.Smart = smartEnabled
		}
		if cmd.Flags().Changed("project") {
			cfg.Project = project
		}
		if cmd.Flags().Changed("region") {
			cfg.Region = region
		}
		if cmd.Flags().Changed("gar") {
			cfg.GAR = gar
		}
		if cmd.Flags().Changed("global-tag") {
			cfg.GlobalTag = globalTag
		}
		if cmd.Flags().Changed("use-gar") {
			cfg.UseGAR = useGAR
		}
		if cmd.Flags().Changed("push-to-gar") {
			cfg.PushToGAR = pushToGAR
		}
		if servicesDir != "" {
			// Parse comma-separated services directories
			dirs := strings.Split(servicesDir, ",")
			for i, dir := range dirs {
				dirs[i] = strings.TrimSpace(dir)
			}
			cfg.ServicesDir = dirs
		}

		// Handle input/output changed services files with proper priority:
		// CLI flag takes precedence over YAML config, YAML config used when no CLI flag
		var effectiveInputFile string
		if cmd.Flags().Changed("input-changed-services") {
			effectiveInputFile = inputChangedServices
		} else if cfg.InputChangedServices != "" {
			effectiveInputFile = cfg.InputChangedServices
		}

		var effectiveOutputFile string
		if cmd.Flags().Changed("output-changed-services") {
			effectiveOutputFile = outputChangedServices
		} else if cfg.OutputChangedServices != "" {
			effectiveOutputFile = cfg.OutputChangedServices
		}

		// Validate input file extension if provided (either from CLI flag or YAML config)
		if effectiveInputFile != "" {
			if err := config.ValidateTxtFile(effectiveInputFile); err != nil {
				log.Fatalf("Invalid input changed services file: %v", err)
			}
		}

		// Discover services (unified discovery including input file)
		discoveryResult, err := discovery.DiscoverServices(cfg, defaultTag, effectiveInputFile)
		if err != nil {
			log.Fatalf("Failed to discover services: %v", err)
		}

		// Validate output file extension if provided (either from CLI flag or YAML config)
		if effectiveOutputFile != "" {
			if err := config.ValidateTxtFile(effectiveOutputFile); err != nil {
				log.Fatalf("Invalid output changed services file: %v", err)
			}
		}

		// Log any discovery errors
		for _, discoveryErr := range discoveryResult.Errors {
			log.Printf("Discovery error: %v", discoveryErr)
		}

		// Smart orchestration if enabled (disabled by default for basic builds)
		var servicesToBuild []discovery.DiscoveredService
		var changedFiles map[string][]string // Track changed files for output

		if cfg.Smart {
			smartConfig := &smart.SmartConfig{
				Enabled:       cfg.Smart,
				GitTracking:   cfg.GitTrack,
				GitTrackDepth: cfg.GitTrackDepth,
				CacheEnabled:  cfg.Cache,
				CacheLevel:    cache.RegistryCacheLevel, // Default to registry cache
				CacheTTL:      24 * time.Hour,           // 24 hours TTL
				ForceRebuild:  cfg.Force,
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
		} else {
			// For non-smart builds, build all services but check for git changes if requested
			servicesToBuild = discoveryResult.Services

			// If git tracking is enabled but smart is disabled, check for changes
			if cfg.GitTrack {
				changedFiles = make(map[string][]string)
				gitTracker := git.NewTracker()
				for _, service := range servicesToBuild {
					depth := cfg.GitTrackDepth
					if depth == 0 {
						depth = 2
					}
					if files, err := gitTracker.GetChangedFiles(service.Path, depth); err == nil && len(files) > 0 {
						changedFiles[service.Path] = files
					}
				}
			}

			// Mark all as needing build when smart features disabled
			for i := range servicesToBuild {
				servicesToBuild[i].NeedsBuild = true
			}
		}

		// Root feature: Write changed services to file if requested (works with any command)
		if effectiveOutputFile != "" {
			var servicesForOutput []discovery.DiscoveredService

			if cfg.Smart && len(servicesToBuild) < len(discoveryResult.Services) {
				// Smart mode: write only the services that will be built
				servicesForOutput = servicesToBuild
			} else if cfg.GitTrack && len(changedFiles) > 0 {
				// Git track mode: write only services with changes
				for _, service := range servicesToBuild {
					if _, hasChanges := changedFiles[service.Path]; hasChanges {
						servicesForOutput = append(servicesForOutput, service)
					}
				}
			} else {
				// Default: write all services being built
				servicesForOutput = servicesToBuild
			}

			if err := discovery.WriteChangedServicesFile(servicesForOutput, effectiveOutputFile); err != nil {
				log.Printf("Warning: Failed to write changed services file: %v", err)
			} else {
				log.Printf("Changed services written to: %s", effectiveOutputFile)
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

	rootCmd.Flags().BoolVarP(&version, "version", "v", false, "Print version information")

	buildCmd.Flags().StringVarP(&configPath, "config", "c", "services.yaml", "Path to the services.yaml configuration file (default: services.yaml)")
	buildCmd.Flags().IntVarP(&maxProcesses, "max-processes", "m", 0, "Maximum number of parallel build processes (0 = use system default; overrides config file)")
	buildCmd.Flags().StringVar(&project, "project", "", "Google Cloud Platform project ID for GAR integration (overrides config file)")
	buildCmd.Flags().StringVar(&region, "region", "", "GCP region for GAR (e.g., us-central1, europe-west1; overrides config file)")
	buildCmd.Flags().StringVar(&gar, "gar", "", "Name of the Google Artifact Registry repository (overrides config file)")
	buildCmd.Flags().StringVar(&globalTag, "global-tag", "", "Global Docker tag to apply to all built images (overrides config file and git commit ID)")
	buildCmd.Flags().StringVar(&servicesDir, "services-dir", "", "Comma-separated list of directories to scan for service definitions (overrides config file)")
	buildCmd.Flags().StringVar(&inputChangedServices, "input-changed-services", "", "Path to a file containing a newline-separated list of service names to build selectively")
	buildCmd.Flags().StringVar(&outputChangedServices, "output-changed-services", "", "Path to output file where the list of changed services will be written for CI/CD integration")

	buildCmd.Flags().BoolVar(&gitTrack, "git-track", false, "Enable git change tracking")
	buildCmd.Flags().IntVar(&depth, "depth", 2, "Git tracking depth (0 for full history, default 2)")

	buildCmd.Flags().BoolVar(&cacheEnabled, "cache", false, "Enable multi-level build caching (layer, local hash, and registry cache)")
	buildCmd.Flags().BoolVar(&forceRebuild, "force", false, "Force rebuild of all services, ignoring cache and change detection")
	buildCmd.Flags().BoolVar(&smartEnabled, "smart", false, "Enable smart build orchestration with automatic dependency analysis and optimization")
	buildCmd.Flags().BoolVar(&useGAR, "use-gar", false, "Use Google Artifact Registry naming convention for image tags (requires GAR authentication)")
	buildCmd.Flags().BoolVar(&pushToGAR, "push-to-gar", false, "Automatically push built images to Google Artifact Registry after successful builds")
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
