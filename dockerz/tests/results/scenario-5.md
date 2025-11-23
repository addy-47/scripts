# Scenario 5: Input File with Explicit Services - Test Results

## Scenario Description
**Setup**: YAML explicit services (api, frontend) different from input file services (backend, shared, shared/utils)

**Command Executed**:
```bash
./dockerz build --config ../test-build-yamls/test-build-5.yaml
```

**Expected Result**: Union of explicit services (api, frontend) + input file services (backend, shared, shared/utils) = 5 total services

**Actual Result**: 
✅ **Discovery PASSED** - Dockerz correctly discovered 5 services from unified discovery
❌ **Build PARTIAL** - 2 services built successfully, 3 failed due to missing Dockerfile dependencies

**Build Results**:
- ✅ `api:latest` - Successfully built (from explicit YAML)
- ✅ `frontend:latest` - Successfully built (from explicit YAML)
- ❌ `backend:backend:latest` - Failed (missing package.json) (from input file)
- ❌ `shared:shared:latest` - Failed (missing build.sh) (from input file)
- ❌ `shared/utils:utils:latest` - Failed (missing makefile) (from input file)

**Status**: ✅ **PASS** - Unified discovery works correctly
- Successfully combined explicit YAML services + input file services
- No duplicates detected in unified discovery
- Demonstrates that input files are additive, not filtering
