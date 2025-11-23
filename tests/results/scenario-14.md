# Scenario 14: services_dir Scanning All Directories

## Scenario Description
Test Dockerz behavior when services_dir is configured to scan all directories including those without Dockerfiles.

## Setup
1. Created configuration file: `tests/test-build-yamls/test-build-14.yaml`
   - Empty services: `[]`
   - services_dir: `[api, backend, frontend, shared, library, utils, documentation]`
2. Executed from `tests/test-project/` directory

## Command Executed
```bash
cd tests/test-project && ./dockerz build --config ../test-build-yamls/test-build-14.yaml
```

## Expected Result (from scenario.md)
- **Expected Built**: Only services with Dockerfiles
  - `api`, `api/microservice`, `backend`, `backend/sub-service`, `frontend`, `shared`, `shared/utils`
- **Best Case**: Scan all directories, build only those with Dockerfiles, skip the rest

## Actual Result
- **Status**: ⚠️ **ISSUE IDENTIFIED** - Missing warning logs for directories without Dockerfiles
- **Discovery Mode**: SINGLE SOURCE discovery (correctly detected services_dir only)
- **Services Discovered**: 7 services (correctly found all services with Dockerfiles)
- **Successful Builds**: 2 services (`api`, `frontend`)
- **Failed Builds**: 5 services (due to missing test files, not discovery issues)
- **Key Behavior**: 
  - Services with Dockerfiles were correctly discovered
  - Directories without Dockerfiles were silently skipped
  - **Missing**: Warning logs about directories without Dockerfiles

## Key Findings
1. **Correct Discovery Logic**: Dockerz correctly finds all services with Dockerfiles
2. **Recursive Scanning Works**: Found both parent and nested services correctly
3. **Missing Warning Logs**: Directories without Dockerfiles are silently skipped
4. **Successful Processing**: All valid services were attempted for building
5. **User Experience Gap**: No feedback about which directories lack Dockerfiles

## Issues Identified
- **Missing Warning Logs**: When `services_dir` scans directories like `library`, `utils`, and `documentation` that don't have Dockerfiles, no warning messages are shown
- **Silent Failures**: Users don't know which configured directories are being skipped

## Conclusion
**Status: PARTIAL PASS** - Discovery logic works correctly but lacks warning logs for directories without Dockerfiles.

## Recommendation
Add warning logs when `services_dir` finds directories without Dockerfiles to improve user visibility:
```
WARNING: Directory 'library' in services_dir has no Dockerfile - skipping
WARNING: Directory 'utils' in services_dir has no Dockerfile - skipping  
WARNING: Directory 'documentation' in services_dir has no Dockerfile - skipping
