package mapping

import (
	_ "embed"
	"gopkg.in/yaml.v3"
)

//go:embed u-map.yaml
var uMapYAML []byte

// UndoMapping represents a single undo mapping
type UndoMapping struct {
	Undo        string `yaml:"undo"`
	Safe        bool   `yaml:"safe"`
	Description string `yaml:"description"`
}

// CategoryMappings represents mappings for a category
type CategoryMappings map[string]UndoMapping

// UndoMap represents the entire undo mapping structure
type UndoMap struct {
	Version string                      `yaml:"version"`
	FileSystem      CategoryMappings    `yaml:"file_system"`
	PackageManagers CategoryMappings    `yaml:"package_managers"`
	Git             CategoryMappings    `yaml:"git"`
	Docker          CategoryMappings    `yaml:"docker"`
	System          CategoryMappings    `yaml:"system"`
	Cloud           CategoryMappings    `yaml:"cloud"`
	Database        CategoryMappings    `yaml:"database"`
	Misc            CategoryMappings    `yaml:"misc"`
}

// LoadUndoMap loads and parses the embedded u-map.yaml file
func LoadUndoMap() (*UndoMap, error) {
	var undoMap UndoMap
	if err := yaml.Unmarshal(uMapYAML, &undoMap); err != nil {
		return nil, err
	}
	return &undoMap, nil
}

// GetMapping retrieves a specific undo mapping by category and command
func (um *UndoMap) GetMapping(category, command string) (*UndoMapping, bool) {
	var mappings CategoryMappings
	switch category {
	case "file_system":
		mappings = um.FileSystem
	case "package_managers":
		mappings = um.PackageManagers
	case "git":
		mappings = um.Git
	case "docker":
		mappings = um.Docker
	case "system":
		mappings = um.System
	case "cloud":
		mappings = um.Cloud
	case "database":
		mappings = um.Database
	case "misc":
		mappings = um.Misc
	default:
		return nil, false
	}

	mapping, exists := mappings[command]
	if !exists {
		return nil, false
	}
	return &mapping, true
}