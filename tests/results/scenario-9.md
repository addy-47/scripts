# Scenario 9: Mixed Dockerfile and Non-Dockerfile in services_dir - Test Results

## Scenario Description
**Setup**: services_dir configured with mix of Dockerfile and non-Dockerfile directories (api, library, utils, frontend)

**Command Executed**:
```bash
./dockerz build --config ../test-build-yamls/test-build-9.yaml
```

**Expected Result**: Only services with Dockerfiles from specified directories:
- `api` ✓, `api/microservice` ✓, `frontend` ✓ (from api/, frontend/ directories)
- `library/` ❌, `utils/` ❌ (no Dockerfiles in these directories)

**Actual Result**: 
✅ **Discovery PASSED** - Dockerz correctly discovered exactly 3 services with Dockerfiles, ignoring non-Dockerfile directories
❌ **Build PARTIAL** - 2 services built successfully, 1 failed due to missing Dockerfile dependencies

**Build Results**:
- ✅ `api:latest` - Successfully built (from services_dir api/)
- ✅ `frontend:latest` - Successfully built (from services_dir frontend/)
- ❌ `api/microservice:microservice:latest` - Failed (openjdk:17-jdk-slim not found) (nested in api/)
- `library/` - Correctly ignored (no Dockerfile)
- `utils/` - Correctly ignored (no Dockerfile)

**Status**: ✅ **PASS** - Mixed services_dir discovery works correctly
- Successfully filtered only directories with Dockerfiles
- Correctly excluded non-Dockerfile directories (library/, utils/)
- Properly handles nested services within included directories
- Selective discovery based on Dockerfile presence
