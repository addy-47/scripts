package discovery

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/addy-47/dockerz/internal/config"
)

// NormalizeImageName converts service names to Docker-compatible kebab-case
func NormalizeImageName(serviceName string) string {
	// Convert to lowercase
	name := strings.ToLower(serviceName)

	// Replace underscores and spaces with hyphens
	name = strings.ReplaceAll(name, "_", "-")
	name = strings.ReplaceAll(name, " ", "-")

	// Remove any other invalid characters (keep only alphanumeric, hyphens, periods)
	reg := regexp.MustCompile(`[^a-z0-9.-]`)
	name = reg.ReplaceAllString(name, "-")

	// Remove multiple consecutive hyphens
	reg = regexp.MustCompile(`-+`)
	name = reg.ReplaceAllString(name, "-")

	// Remove leading/trailing hyphens
	name = strings.Trim(name, "-")

	// Ensure it starts with alphanumeric
	if name == "" || !regexp.MustCompile(`^[a-z0-9]`).MatchString(name) {
		name = "service-" + name
	}

	return name
}

// ValidateDockerfile checks if a Dockerfile exists in the service directory
func ValidateDockerfile(servicePath string) error {
	dockerfilePath := filepath.Join(servicePath, "Dockerfile")
	if _, err := os.Stat(dockerfilePath); os.IsNotExist(err) {
		return fmt.Errorf("no Dockerfile found in %s", servicePath)
	}
	return nil
}

// ValidateImageName validates that the image name is Docker-compatible
func ValidateImageName(imageName string) error {
	// Docker image names must be lowercase, alphanumeric, with hyphens, underscores, or periods
	matched, err := regexp.MatchString(`^[a-z0-9][a-z0-9._-]*$`, imageName)
	if err != nil {
		return fmt.Errorf("error validating image name: %w", err)
	}
	if !matched {
		return fmt.Errorf("invalid image name '%s': must be lowercase and contain only alphanumeric, hyphens, underscores, or periods", imageName)
	}
	return nil
}

// isExcludedDirectory checks if a directory should be excluded from service discovery
func isExcludedDirectory(dirName string) bool {
	excludedDirs := map[string]bool{
		// Build and packaging directories
		"debian":     true,
		".debhelper": true,
		"build":      true,
		"dist":       true,
		"target":     true,

		// Dependency directories
		"node_modules": true,
		"vendor":       true,
		"__pycache__":  true,

		// Version control
		".git": true,
		".svn": true,
		".hg":  true,

		// IDE and editor directories
		".vscode": true,
		".idea":   true,
		".vs":     true,

		// OS generated files
		".DS_Store": true,
		"Thumbs.db": true,
	}

	// Exclude any directory starting with a dot (hidden directories)
	if strings.HasPrefix(dirName, ".") {
		return true
	}

	return excludedDirs[dirName]
}

// discoverExplicitServices discovers services explicitly listed in YAML configuration
func discoverExplicitServices(cfg *config.Config, defaultTag string) ([]DiscoveredService, []error) {
	var services []DiscoveredService
	var errors []error

	for _, service := range cfg.Services {
		if service.Name == "" {
			errors = append(errors, fmt.Errorf("service name missing in services list"))
			continue
		}

		if err := ValidateDockerfile(service.Name); err != nil {
			errors = append(errors, err)
			continue
		}

		imageName := service.ImageName
		if imageName == "" {
			imageName = filepath.Base(service.Name)
		}
		// Normalize to kebab-case for Docker/GAR compatibility
		imageName = NormalizeImageName(imageName)

		if err := ValidateImageName(imageName); err != nil {
			errors = append(errors, err)
			continue
		}

		tag := service.Tag
		if tag == "" {
			tag = defaultTag
		}

		discovered := DiscoveredService{
			Path:      service.Name,
			Name:      filepath.Base(service.Name),
			ImageName: imageName,
			Tag:       tag,
		}
		services = append(services, discovered)
	}

	return services, errors
}

// discoverFromDirectories discovers services in specified directories
func discoverFromDirectories(dirs []string, defaultTag string) ([]DiscoveredService, []error) {
	var services []DiscoveredService
	var errors []error

	for _, servicesDirPath := range dirs {
		if _, err := os.Stat(servicesDirPath); os.IsNotExist(err) {
			errors = append(errors, fmt.Errorf("services directory %s does not exist", servicesDirPath))
			continue
		}

		err := filepath.Walk(servicesDirPath, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				errors = append(errors, err)
				return nil
			}

			if info.IsDir() {
				isExcluded := isExcludedDirectory(info.Name())
				// Never exclude the root directory being walked
				if path == servicesDirPath {
					isExcluded = false
				}
				// Skip excluded directories
				if isExcluded {
					return filepath.SkipDir
				}
			}

			// Find Dockerfile (must be a file)
			if !info.IsDir() && info.Name() == "Dockerfile" {
				servicePath := filepath.Dir(path)
				serviceName := filepath.Base(servicePath)

				imageName := NormalizeImageName(serviceName)
				if err := ValidateImageName(imageName); err != nil {
					errors = append(errors, fmt.Errorf("service %s: %w", servicePath, err))
					return nil
				}

				discovered := DiscoveredService{
					Path:      servicePath,
					Name:      serviceName,
					ImageName: imageName,
					Tag:       defaultTag,
				}
				services = append(services, discovered)
			}

			return nil
		})

		if err != nil {
			errors = append(errors, fmt.Errorf("error walking services directory %s: %w", servicesDirPath, err))
		}
	}

	return services, errors
}

// autoDiscoverServices performs auto-discovery in project root
func autoDiscoverServices(defaultTag string) ([]DiscoveredService, []error) {
	var services []DiscoveredService
	var errors []error

	projectRoot := "."
	err := filepath.Walk(projectRoot, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			errors = append(errors, err)
			return nil
		}

		if info.IsDir() {
			isExcluded := isExcludedDirectory(info.Name())
			// Never exclude the root directory being walked
			if path == projectRoot {
				isExcluded = false
			}
			// Skip excluded directories
			if isExcluded {
				return filepath.SkipDir
			}
		}

		// Find Dockerfile (must be a file)
		if !info.IsDir() && info.Name() == "Dockerfile" {
			servicePath := filepath.Dir(path)
			serviceName := filepath.Base(servicePath)

			imageName := NormalizeImageName(serviceName)
			if err := ValidateImageName(imageName); err != nil {
				errors = append(errors, fmt.Errorf("service %s: %w", servicePath, err))
				return nil
			}

			discovered := DiscoveredService{
				Path:      servicePath,
				Name:      serviceName,
				ImageName: imageName,
				Tag:       defaultTag,
			}
			services = append(services, discovered)
		}

		return nil
	})

	if err != nil {
		errors = append(errors, fmt.Errorf("error during auto-discovery in project root: %w", err))
	}

	return services, errors
}

// discoverFromInputFile discovers services listed in an input file with enhanced logging
func discoverFromInputFile(inputFilePath string, defaultTag string) ([]DiscoveredService, []error) {
	var services []DiscoveredService
	var errors []error

	log.Printf("INFO: Reading input file: %s", inputFilePath)

	content, err := os.ReadFile(inputFilePath)
	if err != nil {
		errors = append(errors, fmt.Errorf("failed to read input file %s: %w", inputFilePath, err))
		log.Printf("ERROR: Failed to read input file %s: %v", inputFilePath, err)
		return services, errors
	}

	// Parse service names from file (one per line)
	lines := strings.Split(strings.TrimSpace(string(content)), "\n")

	// Filter out empty lines for counting
	nonEmptyLines := 0
	for _, line := range lines {
		if strings.TrimSpace(line) != "" {
			nonEmptyLines++
		}
	}

	if nonEmptyLines == 0 {
		log.Printf("WARNING: Input file '%s' is empty or contains no valid service paths", inputFilePath)
		return services, errors
	}

	log.Printf("INFO: Found %d service entries in input file", nonEmptyLines)

	for _, line := range lines {
		serviceName := strings.TrimSpace(line)
		if serviceName == "" {
			continue
		}

		log.Printf("INFO: Processing service from input file: %s", serviceName)

		// Validate that the service exists and has a Dockerfile
		if err := ValidateDockerfile(serviceName); err != nil {
			log.Printf("WARNING: Service '%s' from input file is invalid: %v", serviceName, err)
			errors = append(errors, fmt.Errorf("service %s from input file: %w", serviceName, err))
			continue
		}

		// Create service entry
		imageName := NormalizeImageName(filepath.Base(serviceName))
		if err := ValidateImageName(imageName); err != nil {
			log.Printf("WARNING: Service '%s' has invalid image name: %v", serviceName, err)
			errors = append(errors, fmt.Errorf("service %s: %w", serviceName, err))
			continue
		}

		discovered := DiscoveredService{
			Path:      serviceName,
			Name:      filepath.Base(serviceName),
			ImageName: imageName,
			Tag:       defaultTag,
		}
		services = append(services, discovered)
		log.Printf("INFO: Successfully added service '%s' from input file", serviceName)
	}

	if len(services) == 0 {
		log.Printf("WARNING: Input file '%s' contained %d entries but no valid services were found", inputFilePath, nonEmptyLines)
	} else {
		log.Printf("INFO: Successfully discovered %d services from input file", len(services))
	}

	return services, errors
}

// deduplicateServices removes duplicate services based on their path
func deduplicateServices(services []DiscoveredService) []DiscoveredService {
	seen := make(map[string]bool)
	var uniqueServices []DiscoveredService

	for _, service := range services {
		if !seen[service.Path] {
			seen[service.Path] = true
			uniqueServices = append(uniqueServices, service)
		}
	}

	return uniqueServices
}

// DiscoverServices scans directories for services based on configuration
// Uses unified discovery only when multiple sources are provided
func DiscoverServices(cfg *config.Config, defaultTag string, inputFilePath ...string) (*DiscoveryResult, error) {
	var allServices []DiscoveredService
	var allErrors []error

	// Determine which discovery sources are available
	hasExplicitServices := len(cfg.Services) > 0

	// Check if services directories are configured (user explicitly set values)
	// services_dir: [] (empty/not set by user) = no services directories
	// services_dir: ["."] (user explicitly set ".") = services directories
	hasServicesDirectories := len(cfg.ServicesDir) > 0

	hasInputFile := len(inputFilePath) > 0 && inputFilePath[0] != ""

	// Count active sources (auto-discovery only when no other sources are configured)
	numSources := 0
	if hasExplicitServices {
		numSources++
	}
	if hasServicesDirectories {
		numSources++
	}
	if hasInputFile {
		numSources++
	}

	log.Printf("DEBUG: Discovery sources - explicit_services: %v, services_dirs: %v (config: %v), input_file: %v, total_sources: %d",
		hasExplicitServices, hasServicesDirectories, cfg.ServicesDir, hasInputFile, numSources)

	// UNIFIED DISCOVERY: Use when multiple sources are provided
	if numSources > 1 {
		log.Printf("DEBUG: Using UNIFIED discovery (multiple sources)")
		// 1. Collect explicit services from YAML (if any)
		if hasExplicitServices {
			services, errors := discoverExplicitServices(cfg, defaultTag)
			allServices = append(allServices, services...)
			allErrors = append(allErrors, errors...)
		}

		// 2. Collect services from configured directories (if any)
		if hasServicesDirectories {
			services, errors := discoverFromDirectories(cfg.ServicesDir, defaultTag)
			allServices = append(allServices, services...)
			allErrors = append(allErrors, errors...)
		}

		// 3. Auto-discovery (if no explicit config provided)
		if !hasExplicitServices && !hasServicesDirectories && !hasInputFile {
			services, errors := autoDiscoverServices(defaultTag)
			allServices = append(allServices, services...)
			allErrors = append(allErrors, errors...)
		}

		// 4. Collect services from input file (if provided)
		if hasInputFile {
			services, errors := discoverFromInputFile(inputFilePath[0], defaultTag)
			allServices = append(allServices, services...)
			allErrors = append(allErrors, errors...)
		}

		// Remove duplicates to prevent double builds
		allServices = deduplicateServices(allServices)
	} else {
		log.Printf("DEBUG: Using SINGLE SOURCE discovery")
		// SINGLE SOURCE DISCOVERY: Use only the provided source

		if hasExplicitServices {
			// Use explicit services only
			log.Printf("DEBUG: Using explicit services from YAML")
			services, errors := discoverExplicitServices(cfg, defaultTag)
			allServices = append(allServices, services...)
			allErrors = append(allErrors, errors...)
		} else if hasServicesDirectories {
			// Use services directories only
			log.Printf("DEBUG: Using services directories")
			services, errors := discoverFromDirectories(cfg.ServicesDir, defaultTag)
			allServices = append(allServices, services...)
			allErrors = append(allErrors, errors...)
		} else if hasInputFile {
			// Use input file only - with enhanced logging for edge cases
			log.Printf("DEBUG: Using input file only")
			services, errors := discoverFromInputFile(inputFilePath[0], defaultTag)
			allServices = append(allServices, services...)
			allErrors = append(allErrors, errors...)
		} else {
			// No sources configured - fall back to auto-discovery
			log.Printf("DEBUG: No sources configured, falling back to auto-discovery")
			services, errors := autoDiscoverServices(defaultTag)
			allServices = append(allServices, services...)
			allErrors = append(allErrors, errors...)
		}
	}

	log.Printf("DEBUG: Final service count: %d", len(allServices))

	result := &DiscoveryResult{
		Services: allServices,
		Errors:   allErrors,
	}

	if len(result.Services) == 0 {
		return nil, fmt.Errorf("no valid services found to build")
	}

	return result, nil
}

// WriteChangedServicesFile writes the list of changed services to a file
func WriteChangedServicesFile(services []DiscoveredService, outputFilePath string) error {
	var lines []string
	for _, service := range services {
		lines = append(lines, service.Path)
	}

	content := strings.Join(lines, "\n")
	return os.WriteFile(outputFilePath, []byte(content), 0644)
}
