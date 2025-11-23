# Scenario 15: Explicit Service Names in YAML with Non-Dockerfile Paths

## Scenario Description
Test Dockerz behavior when YAML configuration includes explicit services that point to directories without Dockerfiles.

## Setup
1. Created configuration file: `tests/test-build-yamls/test-build-15.yaml`
   - Explicit services: `[api, library/math, utils/string-processing, frontend]`
   - Empty services_dir: `[]`
2. Executed from `tests/test-project/` directory

## Command Executed
```bash
cd tests/test-project && ./dockerz build --config ../test-build-yamls/test-build-15.yaml
```

## Expected Result (from scenario.md)
- **Expected Built**: Only services with actual Dockerfiles
  - `api` ✓, `frontend` ✓
  - `library/math` ❌, `utils/string-processing` ❌ (no Dockerfiles)
- **Best Case**: Skip services in YAML that don't have Dockerfiles, build only valid ones

## Actual Result
- **Status**: ✅ **PASS** - Good error handling but could use warning vs error clarity
- **Discovery Mode**: SINGLE SOURCE discovery (correctly detected explicit services only)
- **Services Discovered**: 2 services (only valid ones processed)
- **Valid Services Built**: `api` ✓, `frontend` ✓
- **Invalid Services Skipped**: 
  - `library/math` ❌ (logged as error: no Dockerfile found)
  - `utils/string-processing` ❌ (logged as error: no Dockerfile found)
- **Key Logs**: 
  - `Discovery error: no Dockerfile found in library/math`
  - `Discovery error: no Dockerfile found in utils/string-processing`

## Key Findings
1. **Perfect Validation**: Dockerz correctly identifies explicit services without Dockerfiles
2. **Error Handling Works**: Invalid services are properly detected and skipped
3. **Successful Processing**: Only valid services are built (2 out of 4)
4. **Clear Error Messages**: Users see exactly which services lack Dockerfiles
5. **Logging Level**: Uses "error" logs instead of "warning" logs

## Analysis
- **Error Handling**: ✅ Excellent - clear error messages for missing Dockerfiles
- **Graceful Degradation**: ✅ Good - continues processing despite invalid entries
- **User Experience**: ✅ Good - users see which services are invalid
- **Logging Level**: ⚠️ Could be improved - errors vs warnings for non-critical issues

## Conclusion
**Status: PASS** - Dockerz handles explicit services with non-Dockerfile paths excellently with clear error messages. The only improvement needed is potentially using warning logs instead of error logs for non-critical Dockerfile missing issues.

## Recommendation
Consider using WARNING level instead of ERROR level for missing Dockerfiles in explicit services, as these are configuration issues rather than system errors.
