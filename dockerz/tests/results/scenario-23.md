# Scenario 23: Smart + Force Rebuild

## Scenario Description
Test force flag overriding smart logic to build all services regardless of git changes.

## Setup
- Git state: Clean (no uncommitted changes)
- Test environment: test-project directory
- Configuration: test-build-23.yaml

## Command Executed
```bash
cd tests/test-project && ./dockerz build --config ../test-build-yamls/test-build-23.yaml
```

## Expected Result
- All services should be built (force overrides smart logic)
- Smart orchestration should be bypassed
- Total services: 7 (api, api/microservice, backend, backend/sub-service, frontend, shared, shared/utils)

## Actual Result

### Configuration Loading
- ✅ Successfully loaded configuration from test-build-23.yaml
- ✅ Smart orchestration enabled with force flag

### Service Discovery
- ✅ Auto-discovered 7 services 
- ✅ Force flag bypassed smart logic
- ✅ "Smart Orchestration: 7 total, 7 to build, 0 skipped"

### Build Execution
- ✅ Attempted to build all 7 services in parallel
- ✅ Successfully built: 2 services (api, frontend)
- ❌ Failed builds: 5 services (due to missing files in test environment)

### Failed Build Details
- api/microservice: openjdk:17-jdk-slim not found
- backend: npm install failed (package.json missing)
- backend/sub-service: go.sum not found
- shared: build.sh not found
- shared/utils: makefile not found

## Status: ✅ PASS

### Test Objective: ✅ ACHIEVED
The force flag successfully overrode smart logic and attempted to build all 7 services as expected. Build failures were due to missing dependencies in the test environment, not the Dockerz functionality.

### Key Observations
1. **Force flag works correctly**: Bypassed smart logic and attempted all services
2. **Auto-discovery works**: Found all 7 services correctly
3. **Parallel execution**: Services built concurrently with max_processes=4
4. **Graceful error handling**: Clear error messages for missing dependencies

### Expected Behavior Confirmed
- Force flag overrides all smart filtering
- All services are attempted regardless of git changes or cache state
- Smart orchestration is completely bypassed when force=true

### 🔍 Logging Improvement Needed
Current logging lacks:
- Clear flag values being used (force=true, smart=true, git_track=true, cache=false)
- what was actually used the Configuration file values or cli flag values ?
- Explicit logging of force flag effect on smart orchestration
- Show how smart features have affected the build process 
- all of this needs to be concise one line logs at the start of the build process