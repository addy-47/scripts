package discovery

import (
	"fmt"
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

// DiscoverServices scans directories for services based on configuration
func DiscoverServices(cfg *config.Config, defaultTag string) (*DiscoveryResult, error) {
	result := &DiscoveryResult{
		Services: make([]DiscoveredService, 0),
		Errors:   make([]error, 0),
	}

	if len(cfg.Services) > 0 {
		// Explicitly listed services
		for _, service := range cfg.Services {
			if service.Name == "" {
				result.Errors = append(result.Errors, fmt.Errorf("service name missing in services list"))
				continue
			}

			if err := ValidateDockerfile(service.Name); err != nil {
				result.Errors = append(result.Errors, err)
				continue
			}

			imageName := service.ImageName
			if imageName == "" {
				imageName = filepath.Base(service.Name)
			}
			// Normalize to kebab-case for Docker/GAR compatibility
			imageName = NormalizeImageName(imageName)

			if err := ValidateImageName(imageName); err != nil {
				result.Errors = append(result.Errors, err)
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
			result.Services = append(result.Services, discovered)
		}
	} else if cfg.ServicesDir != "" {
		// Recursively discover services with Dockerfiles
		servicesDirPath := cfg.ServicesDir
		if _, err := os.Stat(servicesDirPath); os.IsNotExist(err) {
			return nil, fmt.Errorf("services directory %s does not exist", servicesDirPath)
		}

		err := filepath.Walk(servicesDirPath, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				result.Errors = append(result.Errors, err)
				return nil
			}

			if info.IsDir() && filepath.Base(path) == "Dockerfile" {
				return nil // Skip the Dockerfile itself
			}

			if info.Name() == "Dockerfile" {
				servicePath := filepath.Dir(path)
				serviceName := filepath.Base(servicePath)

				imageName := NormalizeImageName(serviceName)
				if err := ValidateImageName(imageName); err != nil {
					result.Errors = append(result.Errors, fmt.Errorf("service %s: %w", servicePath, err))
					return nil
				}

				discovered := DiscoveredService{
					Path:      servicePath,
					Name:      serviceName,
					ImageName: imageName,
					Tag:       defaultTag,
				}
				result.Services = append(result.Services, discovered)
			}

			return nil
		})

		if err != nil {
			return nil, fmt.Errorf("error walking services directory: %w", err)
		}
	} else {
		return nil, fmt.Errorf("either services_dir or services must be specified in configuration")
	}

	if len(result.Services) == 0 {
		return nil, fmt.Errorf("no valid services found to build")
	}

	return result, nil
}

// FilterServicesByChangedFile filters services based on a changed services file
func FilterServicesByChangedFile(result *DiscoveryResult, changedFilePath string) (*DiscoveryResult, error) {
	content, err := os.ReadFile(changedFilePath)
	if err != nil {
		return nil, fmt.Errorf("failed to read changed services file %s: %w", changedFilePath, err)
	}

	// Parse changed services (one per line)
	changedServices := make(map[string]bool)
	lines := strings.Split(strings.TrimSpace(string(content)), "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line != "" {
			changedServices[line] = true
		}
	}

	// Filter services
	var filteredServices []DiscoveredService
	for _, service := range result.Services {
		if changedServices[service.Path] {
			filteredServices = append(filteredServices, service)
		}
	}

	return &DiscoveryResult{
		Services: filteredServices,
		Errors:   result.Errors,
	}, nil
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