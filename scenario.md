# Dockerz Build Scenarios and Testing Matrix

This document provides a comprehensive testing matrix for Dockerz build flags, covering all possible combinations of CLI flags, YAML configuration interactions, service discovery scenarios, smart feature states, and changed services file scenarios.

## Table of Contents

1. [CLI Flags Overview](#cli-flags-overview)
2. [YAML Configuration Options](#yaml-configuration-options)
3. [Service Discovery Scenarios](#service-discovery-scenarios)
4. [Smart Feature States](#smart-feature-states)
5. [Changed Services File Scenarios](#changed-services-file-scenarios)
6. [Testing Matrix](#testing-matrix)
7. [Test Cases](#test-cases)

## CLI Flags Overview

### Core Build Flags
- `--config, -c`: Path to services.yaml (default: services.yaml)
- `--max-processes, -m`: Max parallel processes (0 = auto-detect)
- `--tag`: Global Docker tag (overrides git commit ID)

### GCP/GAR Flags
- `--project`: GCP project ID
- `--region`: GCP region (e.g., us-central1)
- `--gar`: GAR repository name
- `--use-gar`: Enable GAR naming convention
- `--push-to-gar`: Push to GAR after build

### Smart Features Flags
- `--smart`: Enable smart orchestration
- `--git-track`: Enable git change detection
- `--git-track-depth`: Commits to check (default: 2)
- `--cache`: Enable multi-level caching
- `--force`: Force rebuild all services

### Service Discovery Flags
- `--services-dir`: Comma-separated service directories

### Changed Services Files
- `--input-changed-services`: Input file with changed services
- `--output-changed-services`: Output file for changed services

## YAML Configuration Options

### Core Configuration
- `services_dir`: Directories to scan (string or array)
- `project`: GCP project ID
- `gar`: GAR repository name
- `region`: GCP region
- `global_tag`: Default tag for all services
- `max_processes`: Parallel build limit
- `use_gar`: Enable GAR naming
- `push_to_gar`: Auto-push to GAR

### Smart Features Configuration
- `smart`: Enable smart orchestration
- `git_track`: Enable git tracking
- `git_track_depth`: Git check depth
- `cache`: Enable caching
- `force`: Force rebuild
- `input_changed_services`: Input changed services file
- `output_changed_services`: Output changed services file

### Service Definitions
- `services`: Explicit service list with name, image_name, tag

## Service Discovery Scenarios

### 1. Explicit Service Definition
- Services defined in `services` array in YAML
- Each service has: name (path), image_name (optional), tag (optional)
- Overrides auto-discovery

### 2. Auto-Discovery with services_dir
- `services_dir` specifies directories to scan
- Recursively finds Dockerfiles in specified directories
- Service name derived from directory name

### 3. Full Auto-Discovery
- `services_dir` empty or "."
- Scans entire project root for Dockerfiles
- Excludes hidden directories (starting with ".")

### 4. Filtered Discovery
- `--input-changed-services` file filters discovered services
- Only builds services listed in the input file

## Smart Feature States

### Smart Orchestration States
- **Disabled**: All services build regardless of changes
- **Enabled**: Analyzes dependencies and optimizes build order

### Git Tracking States
- **Disabled**: No git change detection
- **Enabled**: Checks git history for file changes
- **Depth**: Number of commits to analyze (default: 2)

### Caching States
- **Disabled**: No caching, always rebuild
- **Enabled**: Multi-level caching (layer, local hash, registry)

### Force Rebuild States
- **Disabled**: Normal smart logic applies
- **Enabled**: Forces all services to rebuild

## Changed Services File Scenarios

### Input Changed Services File
- **None**: No filtering applied
- **Present**: Only builds services listed in file
- **Empty**: No services build
- **Invalid**: Error if file doesn't exist or unreadable

### Output Changed Services File
- **None**: No output file written
- **Present**: Writes list of services that would build
- **Path Error**: Warning if output path invalid

## Testing Matrix

### Flag Combination Categories

#### Basic Build Scenarios
| Scenario | Flags | Expected Behavior |
|----------|-------|-------------------|
| Default Build | `dockerz build` | Auto-discover all services, build in parallel, use git commit as tag |
| Custom Config | `dockerz build -c custom.yaml` | Load from custom config file |
| Parallel Limit | `dockerz build -m 2` | Limit to 2 parallel builds |
| Custom Tag | `dockerz build --tag v1.0.0` | Use v1.0.0 as tag for all services |

#### GCP/GAR Integration Scenarios
| Scenario | Flags | Config | Expected Behavior |
|----------|-------|--------|-------------------|
| Local Build | `dockerz build` | `use_gar: false` | Use local image names (service:tag) |
| GAR Naming | `dockerz build --use-gar` | `use_gar: true` | Use GAR naming (region-docker.pkg.dev/project/gar/service:tag) |
| GAR Push | `dockerz build --use-gar --push-to-gar` | `push_to_gar: true` | Build and push to GAR |
| GAR Override | `dockerz build --project prod --region us-east1` | Override config values |

#### Smart Features Scenarios
| Scenario | Flags | Expected Behavior |
|----------|-------|-------------------|
| Smart Disabled | `dockerz build` | Build all discovered services |
| Smart Enabled | `dockerz build --smart` | Analyze dependencies, optimize build order |
| Git Tracking | `dockerz build --smart --git-track` | Only build services with git changes |
| Git Depth | `dockerz build --smart --git-track --git-track-depth 5` | Check last 5 commits for changes |
| Caching | `dockerz build --smart --cache` | Use multi-level caching to skip unchanged services |
| Force Rebuild | `dockerz build --smart --force` | Force all services to rebuild |

#### Service Discovery Scenarios
| Scenario | Config | Flags | Expected Behavior |
|----------|--------|-------|-------------------|
| Explicit Services | `services: [{name: api}]` | | Build only explicitly defined services |
| Directory Scan | `services_dir: [backend, frontend]` | | Scan specific directories for Dockerfiles |
| Full Auto | `services_dir: []` | | Scan entire project for Dockerfiles |
| Filtered Build | | `--input-changed-services changed.txt` | Only build services listed in file |

#### Changed Services File Scenarios
| Scenario | Input File | Output File | Expected Behavior |
|----------|------------|-------------|-------------------|
| No Files | None | None | Normal discovery and build |
| Input Only | Present | None | Filter services by input file |
| Output Only | None | Present | Write changed services to output file |
| Both Files | Present | Present | Filter by input, write to output |

### Interaction Matrix

#### CLI Flag vs YAML Config Priority
| Flag | YAML Config | Priority | Behavior |
|------|-------------|----------|----------|
| `--project` | `project` | CLI overrides | CLI value used |
| `--smart` | `smart` | CLI overrides | CLI value used |
| `--tag` | `global_tag` | CLI overrides | CLI value used |
| `--use-gar` | `use_gar` | CLI overrides | CLI value used |

#### Smart Feature Interactions
| Git Track | Cache | Force | Result |
|-----------|-------|-------|--------|
| false | false | false | Build all services |
| true | false | false | Build only changed services (git) |
| false | true | false | Build services not in cache |
| true | true | false | Build changed services OR services not in cache |
| false | false | true | Build all services (force) |
| true | false | true | Build all services (force overrides) |
| false | true | true | Build all services (force overrides) |
| true | true | true | Build all services (force overrides) |

#### Service Discovery Interactions
| Services Config | Services Dir | Input Changed | Result |
|----------------|--------------|---------------|--------|
| Defined | Any | None | Build explicit services only |
| Empty | Defined | None | Auto-discover in specified dirs |
| Empty | Empty | None | Auto-discover in project root |
| Empty | Any | Present | Auto-discover, then filter by input file |
| Defined | Any | Present | Build explicit services, ignore input file |

## Test Cases

### Basic Functionality Tests

#### TC-001: Default Build
```bash
# Setup: services.yaml with default config, project with Dockerfiles
dockerz build

# Expected: Auto-discover all services, build in parallel, use git commit as tag
# Verify: All services with Dockerfiles are built
```

#### TC-002: Custom Configuration File
```bash
# Setup: custom.yaml with different settings
dockerz build -c custom.yaml

# Expected: Load configuration from custom.yaml
# Verify: Settings from custom.yaml are applied
```

#### TC-003: Parallel Build Limit
```bash
# Setup: Multiple services, max_processes: 4 in config
dockerz build -m 2

# Expected: Limit parallel builds to 2 processes
# Verify: No more than 2 builds run simultaneously
```

#### TC-004: Custom Global Tag
```bash
# Setup: Default config
dockerz build --tag v1.0.0

# Expected: All images tagged with v1.0.0
# Verify: Built images have tag v1.0.0
```

### GCP/GAR Integration Tests

#### TC-005: Local Build (No GAR)
```bash
# Setup: use_gar: false in config
dockerz build

# Expected: Images use local naming (service:tag)
# Verify: docker build commands use local image names
```

#### TC-006: GAR Naming Convention
```bash
# Setup: Valid GAR config (project, region, gar)
dockerz build --use-gar

# Expected: Images use GAR naming (region-docker.pkg.dev/project/gar/service:tag)
# Verify: docker build commands use GAR image names
```

#### TC-007: GAR Push After Build
```bash
# Setup: Valid GAR config and authentication
dockerz build --use-gar --push-to-gar

# Expected: Build images and push to GAR
# Verify: Images exist in GAR registry
```

#### TC-008: GAR Configuration Override
```bash
# Setup: Default GAR config in YAML
dockerz build --project prod-project --region us-east1 --gar prod-repo

# Expected: Override YAML config with CLI values
# Verify: GAR URLs use CLI-provided values
```

### Smart Features Tests

#### TC-009: Smart Orchestration Disabled
```bash
# Setup: smart: false in config
dockerz build

# Expected: Build all discovered services
# Verify: All services are built regardless of changes
```

#### TC-010: Smart Orchestration Enabled
```bash
# Setup: smart: true in config
dockerz build --smart

# Expected: Analyze dependencies and optimize build order
# Verify: Build order considers service dependencies
```

#### TC-011: Git Change Detection
```bash
# Setup: Git repository with changes in some services
dockerz build --smart --git-track

# Expected: Only build services with git changes
# Verify: Only modified services are built
```

#### TC-012: Git Tracking Depth
```bash
# Setup: Changes in commits beyond default depth
dockerz build --smart --git-track --git-track-depth 3

# Expected: Check last 3 commits for changes
# Verify: Services with changes in last 3 commits are built
```

#### TC-013: Build Caching
```bash
# Setup: Previous build cache exists
dockerz build --smart --cache

# Expected: Skip services with matching cache entries
# Verify: Unchanged services are skipped
```

#### TC-014: Force Rebuild
```bash
# Setup: Cache exists, smart features enabled
dockerz build --smart --force

# Expected: Force rebuild all services
# Verify: All services are built regardless of cache/smart logic
```

### Service Discovery Tests

#### TC-015: Explicit Service Definition
```yaml
# services.yaml
services:
  - name: api
  - name: web
```
```bash
dockerz build

# Expected: Build only api and web services
# Verify: Only api and web directories are processed
```

#### TC-016: Directory-Based Discovery
```yaml
# services.yaml
services_dir: [backend, frontend]
```
```bash
dockerz build

# Expected: Scan backend/ and frontend/ for Dockerfiles
# Verify: Services found in specified directories only
```

#### TC-017: Full Auto-Discovery
```yaml
# services.yaml
services_dir: []
```
```bash
dockerz build

# Expected: Scan entire project root for Dockerfiles
# Verify: All directories with Dockerfiles are discovered
```

#### TC-018: Filtered Service Build
```bash
# Setup: changed_services.txt with "api" and "web"
echo -e "api\nweb" > changed_services.txt
dockerz build --input-changed-services changed_services.txt

# Expected: Only build services listed in input file
# Verify: Only api and web services are built
```

### Changed Services File Tests

#### TC-019: Output Changed Services
```bash
# Setup: Smart features enabled, some services changed
dockerz build --smart --git-track --output-changed-services output.txt

# Expected: Write changed services to output.txt
# Verify: output.txt contains list of services that were built
```

#### TC-020: Input/Output Files Combined
```bash
# Setup: input.txt with service list, smart features
dockerz build --input-changed-services input.txt --output-changed-services output.txt --smart

# Expected: Filter by input.txt, write results to output.txt
# Verify: Only services from input.txt are considered, results in output.txt
```

### Error Condition Tests

#### TC-021: Invalid Configuration File
```bash
dockerz build -c nonexistent.yaml

# Expected: Error loading config file
# Verify: Exit with error code, helpful error message
```

#### TC-022: Missing GAR Configuration
```bash
# Setup: use_gar: true but missing project/region/gar
dockerz build --use-gar

# Expected: Error for missing GAR configuration
# Verify: Exit with error, list required fields
```

#### TC-023: Invalid Changed Services File
```bash
dockerz build --input-changed-services nonexistent.txt

# Expected: Error reading input file
# Verify: Exit with error, helpful error message
```

#### TC-024: No Services Found
```bash
# Setup: Project with no Dockerfiles
dockerz build

# Expected: Error no valid services found
# Verify: Exit with error, suggest checking project structure
```

### Complex Combination Tests

#### TC-025: Full CI/CD Pipeline Simulation
```bash
# Setup: Complete config, git repo, GAR auth, changed services
dockerz build \
  --smart \
  --git-track \
  --cache \
  --use-gar \
  --push-to-gar \
  --input-changed-services changed.txt \
  --output-changed-services built.txt \
  --project my-prod \
  --region us-central1 \
  --tag $(git rev-parse --short HEAD)

# Expected: Complete smart build with all features
# Verify: Only changed services built, pushed to GAR, output file created
```

#### TC-026: Force Override Smart Features
```bash
# Setup: Smart config, but force rebuild
dockerz build --force --smart --cache

# Expected: Force overrides smart/cache logic
# Verify: All services built regardless of smart analysis
```

#### TC-027: Mixed Explicit and Auto-Discovery
```yaml
# services.yaml
services:
  - name: api
services_dir: [backend]
```
```bash
dockerz build

# Expected: Build explicit services + auto-discovered in backend/
# Verify: api service + services in backend/ directory
```

### Edge Cases

#### TC-028: Empty Changed Services File
```bash
# Setup: Empty changed_services.txt
touch changed_services.txt
dockerz build --input-changed-services changed_services.txt

# Expected: No services built
# Verify: Clean exit, no build operations
```

#### TC-029: Single Service Project
```bash
# Setup: Only one service with Dockerfile
dockerz build

# Expected: Single service discovered and built
# Verify: One build operation executed
```

#### TC-030: Deep Directory Structure
```bash
# Setup: Services in deeply nested directories
dockerz build --services-dir=services/microservices/user/api

# Expected: Find Dockerfiles in nested paths
# Verify: Correct service paths discovered
```

This testing matrix covers all major Dockerz build scenarios and should be used for comprehensive testing of the Dockerz tool.