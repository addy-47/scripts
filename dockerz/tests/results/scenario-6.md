# Scenario 6: Input File with services_dir - Test Results

## Scenario Description
**Setup**: services_dir configured for [api, backend] but input file contains services outside these directories (frontend, shared, shared/utils)

**Command Executed**:
```bash
./dockerz build --config ../test-build-yamls/test-build-6.yaml
```

**Expected Result**: Services from both services_dir (api, api/microservice, backend, backend/sub-service) and input file (frontend, shared, shared/utils) = 7 total services

**Actual Result**: 
✅ **Discovery PASSED** - Dockerz correctly discovered 7 services from both sources
❌ **Build PARTIAL** - 2 services built successfully, 5 failed due to missing Dockerfile dependencies

**Build Results**:
- ✅ `api:latest` - Successfully built (from services_dir)
- ✅ `frontend:latest` - Successfully built (from input file)
- ❌ `api/microservice:microservice:latest` - Failed (openjdk:17-jdk-slim not found) (from services_dir)
- ❌ `backend:backend:latest` - Failed (missing package.json) (from services_dir)
- ❌ `backend/sub-service:sub-service:latest` - Failed (missing go.sum file) (from services_dir)
- ❌ `shared:shared:latest` - Failed (missing build.sh) (from input file)
- ❌ `shared/utils:utils:latest` - Failed (missing makefile) (from input file)

**Status**: ✅ **PASS** - Unified discovery with services_dir and input file works correctly
- Successfully combined services_dir discovery + input file services
- No intersection filtering - all services from both sources included
- Demonstrates additive behavior across all discovery methods
