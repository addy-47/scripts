# Scenario 3: Explicit Service List in YAML - Test Results

## Scenario Description
**Setup**: Modified build.yaml with explicit service list in services field (api, frontend, shared)

**Command Executed**:
```bash
./dockerz build --config ../test-build-yamls/test-build-3.yaml
```

**Expected Result**: 3 explicit services only:
- `api`, `frontend`, `shared` (note: NOT `api/microservice` because only `api` is explicitly listed)

**Actual Result**: 
✅ **Discovery PASSED** - Dockerz correctly discovered exactly the 3 explicitly listed services
❌ **Build PARTIAL** - 2 services built successfully, 1 failed due to missing Dockerfile dependencies

**Build Results**:
- ✅ `api:latest` - Successfully built
- ✅ `frontend:latest` - Successfully built
- ❌ `shared:shared:latest` - Failed (missing build.sh)

**Status**: ✅ **PASS** - Explicit service listing works correctly
- Dockerz built only the explicitly defined services
- Correctly excluded nested services (api/microservice was not built because only api was listed)
- Discovery logic properly handles explicit service definitions
