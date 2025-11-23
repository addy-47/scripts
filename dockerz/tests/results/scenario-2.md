# Scenario 2: Filtered by services_dir - Test Results

## Scenario Description
**Setup**: Modified build.yaml with `services_dir: [api, backend]` to limit discovery

**Command Executed**:
```bash
./dockerz build --config ../test-build-yamls/test-build-2.yaml
```

**Expected Result**: 4 services from api/ and backend/ directories only:
- `api`, `api/microservice`, `backend`, `backend/sub-service`

**Actual Result**: 
✅ **Discovery PASSED** - Dockerz correctly discovered exactly 4 services from specified directories
❌ **Build PARTIAL** - 1 service built successfully, 3 failed due to missing Dockerfile dependencies

**Build Results**:
- ✅ `api:latest` - Successfully built
- ❌ `api/microservice:microservice:latest` - Failed (openjdk:17-jdk-slim not found)
- ❌ `backend:backend:latest` - Failed (missing package.json)
- ❌ `backend/sub-service:sub-service:latest` - Failed (missing go.sum file)

**Status**: ✅ **PASS** - services_dir filtering works correctly
- Dockerz discovered only services in api/ and backend/ directories
- Correctly ignored services in frontend/, shared/, and other directories
- Filtering mechanism is working as expected
