package discovery

// DiscoveredService represents a service discovered during directory scanning
type DiscoveredService struct {
	Path         string
	Name         string
	ImageName    string
	Tag          string
	CurrentHash  string
	ChangedFiles []string
	NeedsBuild   bool
}

// DiscoveryResult contains the results of service discovery
type DiscoveryResult struct {
	Services []DiscoveredService
	Errors   []error
}