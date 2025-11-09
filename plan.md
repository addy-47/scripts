# Dockerz Smart Features Implementation Plan

## Overview
This document outlines the differences between the current smart feature implementation and the desired logic, along with required changes for proper CI/CD integration.

## 1. Smart Feature Logic Differences

### Current Implementation
- **Skip Logic**: Only skips when Git says "no change" AND local cache hit with matching hash
- **Build Logic**: Builds in most cases, being conservative ("build to be safe")
- **GAR Integration**: None - "RegistryCache" is just local JSON files
- **Git Error Handling**: Falls back to cache check, builds if no cache hit

### Desired Implementation
- **Skip Logic**: Skip whenever Git says "no change" (trust Git above all else)
- **Build Logic**: Only build on --force, --git-track disabled, Git detects changes, or Git fails
- **GAR Integration**: Full registry connectivity checks (configured?, reachable?, has image?)
- **Git Error Handling**: Always build on Git command failure

### Key Changes Needed
- Modify `analyzeService()` in `orchestrator.go` to trust Git over cache
- Add GAR connectivity and image existence checks
- Implement registry API calls for true GAR integration
- Change skip conditions to be Git-centric rather than cache-centric

## 2. Fresh Install Behavior

### Current Behavior
- `dockerz init` creates YAML with smart features disabled
- `dockerz build` (no flags) auto-discovers ALL services and builds them
- Smart orchestration is opt-in via flags

### Desired Behavior
- Same as current - this is correct

## 3. Priority and Filtering Logic

### Current Behavior
- **CLI flags override YAML** for feature toggles ✓
- **Explicit services in YAML take precedence** over auto-discovery ✓
- **Input changed services acts as secondary filter** ✓

### Desired Behavior
- Same as current - this is correct

## 4. Changed Services Files Handling

### Current Implementation
- **Defaults**: Non-empty (`changed_services.txt`) in sample config ❌
- **Validation**: No extension checking ❌
- **Error Handling**: Hard failure if input file missing ❌
- **Paths**: Supports relative/absolute paths ✓

### Desired Implementation
- **Defaults**: Empty strings in sample config
- **Validation**: Only allow `.txt` files with clear error messages
- **Error Handling**: Graceful fallback with warning log when input file missing
- **Paths**: Support full paths (relative/absolute) as before

### Changes Needed
- Update sample config in `config.go`
- Add `.txt` validation function
- Modify `FilterServicesByChangedFile` to return original result on file not found
- Add validation calls in `main.go` and `config.go`

## 5. Implementation Priority

### Phase 1: Changed Services Files (High Priority)
- Fix defaults and validation
- Add graceful error handling

### Phase 2: Smart Logic Overhaul (Medium Priority)
- Rewrite orchestrator logic to match desired table
- Add GAR integration framework

### Phase 3: GAR Integration (Low Priority)
- Implement actual registry API calls
- Add network connectivity checks
- Add image existence verification

## Summary
The current implementation has solid foundations for service discovery and basic smart features, but needs significant changes to:
1. Trust Git as the ultimate source of truth
2. Properly handle changed services files with validation and fallbacks
3. Add real GAR registry integration

The changed services file fixes should be implemented first as they affect CI/CD usability immediately.