# Dockerz Real-World Testing Scenarios

This document provides **practical test scenarios** using the `test-project` directory structure. Each scenario is designed to be immediately testable and shows the exact behavior of Dockerz with different flag combinations.

## Test Project Structure

```
test-project/
├── changed.txt                    # Pre-defined service list for testing
├── services.yaml                  # Main configuration file
├── api/                           # Service: "api"
│   ├── Dockerfile                 # ✓ Has Dockerfile
│   ├── app.py
│   ├── requirements.txt
│   └── microservice/              # Service: "api/microservice"
│       └── Dockerfile             # ✓ Has Dockerfile
├── backend/                       # Service: "backend"
│   ├── Dockerfile                 # ✓ Has Dockerfile
│   └── sub-service/               # Service: "backend/sub-service"
│       └── Dockerfile             # ✓ Has Dockerfile
├── frontend/                      # Service: "frontend"
│   └── Dockerfile                 # ✓ Has Dockerfile
├── shared/                        # Service: "shared"
│   ├── Dockerfile                 # ✓ Has Dockerfile
│   └── utils/                     # Service: "shared/utils"
│       └── Dockerfile             # ✓ Has Dockerfile
├── library/                       # ❌ No Dockerfile (edge case testing)
│   └── math/
│       ├── calculator.py
│       └── functions.py
├── utils/                         # ❌ No Dockerfile (edge case testing)
│   ├── string-processing/
│   │   └── formatter.py
│   └── date-helpers/
│       └── date_utils.py
└── documentation/                 # ❌ No Dockerfile (edge case testing)
    └── README.md
```

**Total Auto-Discoverable Services**: 7 services (directories with Dockerfiles)
- `api`
- `api/microservice`
- `backend`
- `backend/sub-service`
- `frontend`
- `shared`
- `shared/utils`

**Non-Dockerfile Directories** (for edge case testing):
- `library/math/` - Python modules without Dockerfile
- `utils/string-processing/` - String utilities without Dockerfile
- `utils/date-helpers/` - Date utilities without Dockerfile
- `documentation/` - Documentation only, no Dockerfile

## Scenario Testing Framework

Each scenario follows this pattern:
1. **Setup**: Git commits/changes (if needed)
2. **Command**: Exact `dockerz build` command to run
3. **Expected Built**: List of services that will actually build
4. **Best Case**: What should happen in an ideal world
5. **Current Behavior**: What actually happens (based on latest code analysis)

---

## Basic Discovery Scenarios

### Scenario 1: Pure Auto-Discovery
**Setup**: Fresh test-project with no special config
```bash
cd test-project
# Ensure services.yaml has default config (empty services, empty services_dir)
```

**Command**:
```bash
dockerz build
```

**Expected Built**: All 7 services
- `api`, `api/microservice`, `backend`, `backend/sub-service`, `frontend`, `shared`, `shared/utils`

**Best Case**: Auto-discover all 7 services and build them in parallel
**Current Behavior**: ✅ **CORRECT** - Auto-discovery works properly for empty services.yaml

### Scenario 2: Filtered by services_dir
**Setup**: Modify test-project/services.yaml to specify directories
```yaml
services_dir: [api, backend]
```

**Command**:
```bash
dockerz build
```

**Expected Built**: 4 services (from api/ and backend/ only)
- `api`, `api/microservice`, `backend`, `backend/sub-service`

**Best Case**: Only discover and build services in specified directories
**Current Behavior**: ✅ **CORRECT** - services_dir filtering works

### Scenario 3: Explicit Service List in YAML
**Setup**: Modify test-project/services.yaml
```yaml
services:
  - name: api
  - name: frontend
  - name: shared
```

**Command**:
```bash
dockerz build
```

**Expected Built**: 3 explicit services
- `api`, `frontend`, `shared` (note: NOT `api/microservice` because only `api` is explicitly listed)

**Best Case**: Build only the explicitly listed services
**Current Behavior**: ✅ **CORRECT** - Explicit services work as expected

---

## Input File Scenarios

### Scenario 4: Input File with Auto-Discovery
**Setup**: Use existing changed.txt (has all 7 services listed)
```bash
cd test-project
# changed.txt contains: api, api/microservice, backend, backend/sub-service, frontend, shared, shared/utils
```

**Command**:
```bash
dockerz build --input-changed-services changed.txt
```

**Expected Built**: All 7 services (from changed.txt)
- `api`, `api/microservice`, `backend`, `backend/sub-service`, `frontend`, `shared`, `shared/utils`

**Best Case**: Build all services listed in input file
**Current Behavior**: ✅ **CORRECT** - Input file filtering works with auto-discovery

### Scenario 5: Input File with Explicit Services
**Setup**: 
1. Modify test-project/services.yaml for explicit services
```yaml
services:
  - name: api
  - name: frontend
```

2. changed.txt contains different services:
```
backend
shared
shared/utils
```

**Command**:
```bash
dockerz build --input-changed-services changed.txt
```

**Expected Built**: 2 explicit services (api, frontend)
- BUT input file lists: backend, shared, shared/utils

**Best Case**: Union of explicit services (api, frontend) + input file services (backend, shared, shared/utils) = 5 total services
**Current Behavior**: ❌ **CURRENTLY BROKEN** - Only builds explicit services (api, frontend), ignores input file services (backend, shared, shared/utils)

### Scenario 6: Input File with services_dir
**Setup**:
1. Modify test-project/services.yaml
```yaml
services_dir: [api, backend]
```

2. changed.txt contains services outside specified directories:
```
frontend
shared
shared/utils
```

**Command**:
```bash
dockerz build --input-changed-services changed.txt
```

**Expected Built**: Services from intersection of services_dir discovery and input file
- services_dir finds: `api`, `api/microservice`, `backend`, `backend/sub-service`
- input file contains: `frontend`, `shared`, `shared/utils`
- **Intersection**: `None` (no overlap)

**Best Case**: Build intersection = no services (logical behavior)
**Current Behavior**: ❌ **CURRENTLY BROKEN** - Only builds from services_dir, ignores input file completely

### Scenario 7: Auto-Discovery with Non-Dockerfile Directories
**Setup**: Default test-project with no changes
```bash
cd test-project
# Ensure services.yaml has default config (empty services, empty services_dir)
```

**Command**:
```bash
dockerz build
```

**Expected Built**: All 7 services with Dockerfiles
- `api`, `api/microservice`, `backend`, `backend/sub-service`, `frontend`, `shared`, `shared/utils`

**Best Case**: Auto-discovery finds 7 services, ignores non-Dockerfile directories (`library/`, `utils/`, `documentation/`)
**Current Behavior**: ✅ **CORRECT** - Should skip directories without Dockerfiles

### Scenario 8: services_dir Pointing to Non-Dockerfile Directories
**Setup**: Modify test-project/services.yaml to scan non-Dockerfile directories
```yaml
services_dir: [library, utils, documentation]
```

**Command**:
```bash
dockerz build
```

**Expected Built**: No services (0 services)
- `library/math/` - No Dockerfile ❌
- `utils/string-processing/` - No Dockerfile ❌
- `utils/date-helpers/` - No Dockerfile ❌
- `documentation/` - No Dockerfile ❌

**Best Case**: Scan directories, find no Dockerfiles, build no services
**Current Behavior**: ❓ **NEEDS VERIFICATION** - Should handle gracefully

### Scenario 9: Mixed Dockerfile and Non-Dockerfile in services_dir
**Setup**: Modify test-project/services.yaml for mixed directories
```yaml
services_dir: [api, library, utils, frontend]
```

**Command**:
```bash
dockerz build
```

**Expected Built**: Only services with Dockerfiles from specified directories
- `api` ✓, `api/microservice` ✓, `frontend` ✓
- `library/` ❌, `utils/` ❌ (no Dockerfiles)

**Best Case**: Build 3 services from directories that have Dockerfiles, skip those that don't
**Current Behavior**: ❓ **NEEDS VERIFICATION** - Mixed discovery should work

---

## Smart Features Scenarios

### Scenario 10: Smart Build with No Changes
**Setup**: Ensure clean git state (no uncommitted changes)
```bash
cd test-project
git add .
git commit -m "Initial test setup"
```

**Command**:
```bash
dockerz build --smart --git-track
```

**Expected Built**: No services (nothing changed in git)

**Best Case**: Detect no changes, skip all builds
**Current Behavior**: ❌ **UNEXPECTED** - May still try to build based on implementation

### Scenario 11: Smart Build with Git Changes
**Setup**: Make changes and commit
```bash
cd test-project
# Make changes to some files
echo "# Updated" >> api/app.py
git add api/app.py
git commit -m "Update API application"
```

**Command**:
```bash
dockerz build --smart --git-track
```

**Expected Built**: Only changed services
- `api` (because api/app.py was modified)

**Best Case**: Build only services that have git changes
**Current Behavior**: ✅ **CORRECT** - Git change detection works

### Scenario 12: Smart with Mixed Changes
**Setup**: Multiple changes in different services
```bash
cd test-project
echo "# Backend update" >> backend/Dockerfile
echo "# Frontend change" >> frontend/Dockerfile
git add .
git commit -m "Update backend and frontend"
```

**Command**:
```bash
dockerz build --smart --git-track
```

**Expected Built**: Only changed services
- `backend`, `frontend`

**Best Case**: Build only services with git changes
**Current Behavior**: ✅ **CORRECT** - Multiple service change detection works

---

## Combined Smart Features Scenarios

### Scenario 13: Smart + Input File
**Setup**:
1. Make changes in git (commit some changes)
2. changed.txt contains both changed and unchanged services
```bash
cd test-project
echo "# API change" >> api/app.py
git add .
git commit -m "Update API"

# changed.txt currently has all 7 services
```

**Command**:
```bash
dockerz build --smart --git-track --input-changed-services changed.txt
```

**Expected Built**: Services that are BOTH in input file AND have git changes
- Input file: all 7 services
- Git changes: `api`
- **Intersection**: `api` only

**Best Case**: Build intersection of input file and git-changed services
**Current Behavior**: ❌ **UNEXPECTED** - Current implementation order unclear

### Scenario 14: Smart + Force Rebuild
**Setup**: Any git state
```bash
cd test-project
```

**Command**:
```bash
dockerz build --smart --git-track --force
```

**Expected Built**: All services (force overrides smart logic)
- All 7 services should build

**Best Case**: Force flag overrides all smart logic
**Current Behavior**: ✅ **CORRECT** - Force flag typically overrides other flags

### Scenario 15: Smart + Caching
**Setup**: Previous build exists
```bash
cd test-project
# Assume a previous dockerz build was done
```

**Command**:
```bash
dockerz build --smart --git-track --cache
```

**Expected Built**: Services that are either git-changed OR not in cache
- Depends on cache state and git changes

**Best Case**: Use cache for unchanged services, build only if needed
**Current Behavior**: ✅ **CORRECT** - Caching implementation works

---

## Edge Cases and Error Conditions

### Scenario 16: Empty Input File
**Setup**: Create empty input file
```bash
cd test-project
touch empty.txt
```

**Command**:
```bash
dockerz build --input-changed-services empty.txt
```

**Expected Built**: No services (empty input file = no services to build)

**Best Case**: Clean exit, no builds
**Current Behavior**: ✅ **CORRECT** - Empty file handling works

### Scenario 17: Non-existent Input File
**Setup**: No special setup
```bash
cd test-project
```

**Command**:
```bash
dockerz build --input-changed-services nonexistent.txt
```

**Expected Built**: Error - file not found

**Best Case**: Clear error message about missing file
**Current Behavior**: ✅ **CORRECT** - File validation works

### Scenario 18: Invalid Service Path in Input
**Setup**: Input file with non-existent service
```bash
cd test-project
echo -e "api\nnonexistent\nfrontend" > bad-input.txt
```

**Command**:
```bash
dockerz build --input-changed-services bad-input.txt
```

**Expected Built**: Only valid services from input file
- `api`, `frontend` (skip nonexistent)

**Best Case**: Skip invalid service names, build valid ones
**Current Behavior**: ❌ **NEEDS VERIFICATION** - Invalid service handling unclear

### Scenario 19: Input File with Non-Dockerfile Directories
**Setup**: Input file referencing non-existent Dockerfiles
```bash
cd test-project
echo -e "api\nlibrary/math\nutils/string-processing\nfrontend" > edge-case.txt
```

**Command**:
```bash
dockerz build --input-changed-services edge-case.txt
```

**Expected Built**: Only services with actual Dockerfiles
- `api` ✓, `frontend` ✓
- `library/math` ❌, `utils/string-processing` ❌ (no Dockerfiles)

**Best Case**: Build only services that exist and have Dockerfiles
**Current Behavior**: ❌ **NEEDS VERIFICATION** - Should handle gracefully

### Scenario 20: services_dir Scanning All Directories
**Setup**: services_dir scanning everything including non-Dockerfile dirs
```yaml
# test-project/services.yaml
services_dir: [api, backend, frontend, shared, library, utils, documentation]
```

**Command**:
```bash
dockerz build
```

**Expected Built**: Only services with Dockerfiles
- `api`, `api/microservice`, `backend`, `backend/sub-service`, `frontend`, `shared`, `shared/utils`

**Best Case**: Scan all directories, build only those with Dockerfiles, skip the rest
**Current Behavior**: ❓ **NEEDS VERIFICATION** - Full directory scan should work

### Scenario 23: Explicit Service Names in YAML with Non-Dockerfile Paths
**Setup**: YAML with explicit service pointing to non-Dockerfile directory
```yaml
# test-project/services.yaml
services:
  - name: api
  - name: library/math
  - name: utils/string-processing
  - name: frontend
```

**Command**:
```bash
dockerz build
```

**Expected Built**: Only services with actual Dockerfiles
- `api` ✓, `frontend` ✓
- `library/math` ❌, `utils/string-processing` ❌ (no Dockerfiles)

**Best Case**: Skip services in YAML that don't have Dockerfiles, build only valid ones
**Current Behavior**: ❌ **NEEDS VERIFICATION** - Should handle gracefully

---

## Output File Scenarios

### Scenario 21: Output File with Smart Build
**Setup**: Git changes exist
```bash
cd test-project
echo "# Update" >> backend/app.py
git add .
git commit -m "Update backend"
```

**Command**:
```bash
dockerz build --smart --git-track --output-changed-services output.txt
```

**Expected Built**: Only changed services (`backend`)
**output.txt should contain**: `backend`

**Best Case**: Output file lists services that were built
**Current Behavior**: ✅ **CORRECT** - Output file generation works

### Scenario 22: Output File with Input File
**Setup**: Input file with service list
```bash
cd test-project
# Assume changed.txt has 3 services
```

**Command**:
```bash
dockerz build --input-changed-services changed.txt --output-changed-services output.txt
```

**Expected Built**: Services from input file
**output.txt should contain**: Same as input file content

**Best Case**: Output mirrors input (when no smart filtering)
**Current Behavior**: ✅ **CORRECT** - Simple input/output file flow works

---

## Critical Issues Summary

### Current Implementation Problems:

1. **Exclusive Service Sources** (Scenario 5):
   - **Issue**: When explicit services are defined in YAML, input file is completely ignored
   - **Should**: Union of explicit services + input file services
   - **Impact**: Users can't combine explicit config with external change detection

2. **services_dir + Input File** (Scenario 6):
   - **Issue**: services_dir discovery ignores input file completely
   - **Should**: Filter discovered services by input file
   - **Impact**: Limited flexibility in CI/CD scenarios

3. **Input File Validation** (Scenario 18):
   - **Issue**: Unclear handling of invalid service names in input file
   - **Should**: Skip invalid services, warn user
   - **Impact**: May cause unexpected behavior

4. **Non-Dockerfile Directory Handling** (Scenarios 7, 8, 9, 19, 20, 23):
   - **Issue**: Unknown behavior when scanning directories without Dockerfiles
   - **Should**: Gracefully skip directories without Dockerfiles, log warnings
   - **Impact**: May cause confusing error messages or crashes

5. **Mixed Valid/Invalid Service Names** (Scenario 19, 23):
   - **Issue**: Input files or YAML may reference non-existent services
   - **Should**: Build only valid services, warn about invalid ones
   - **Impact**: Partial builds or complete failures

### Recommended Fixes:

1. **Unified Service Discovery**:
   - Always collect from ALL sources (explicit YAML + auto-discovery + input file)
   - Remove duplicates
   - Apply smart filtering to final set

2. **Input File as Union**:
   - Input file services should be ADDED to discovered services, not used for filtering
   - This enables external change detection to supplement explicit config

3. **Robust Dockerfile Validation**:
   - After service discovery, verify each service has a valid Dockerfile
   - Skip services without Dockerfiles with clear warnings
   - Enable discovery to work with mixed service/non-service directories

4. **Better Error Handling**:
   - Clear messages for invalid service paths
   - Warnings for services in input file that don't exist
   - Graceful handling of directories without Dockerfiles

---

## Testing Instructions

For each scenario, run the commands in the test-project directory:

```bash
cd test-project
# Follow setup steps for the scenario
dockerz build [specific flags for scenario]
# Verify which services actually get built
```

**Verification**: Check Docker images to confirm only expected services were built:
```bash
docker images | grep -E "(api|backend|frontend|shared)" | head -20
```

This comprehensive testing approach ensures all Dockerz features work correctly and identifies current implementation issues that need fixing.