# Scenario 28: Smart Build with Git Track Depth 1 (Latest Commit Only)

## Scenario Description
Test smart build functionality with git tracking depth 1 (analyze only the latest commit for changes).

## Git Setup
```bash
cd tests/test-project
# Using same git history as Scenario 27:
# - Commit 1: Update dockerz binary
# - Commit 2: Update API v1 (api/app.py)
# - Commit 3: Update backend Dockerfile (backend/Dockerfile)
# - Commit 4: Update frontend (frontend/app.js) <- Latest commit
```

## Command Executed
```bash
cd tests/test-project
./dockerz build --smart --git-track --depth 1 --config ../test-build-yamls/test-build-28.yaml
```

## Expected Result
- **Built Services**: `frontend` only (services changed in latest commit)
- **Reasoning**: With depth 1, should analyze only the latest commit (frontend changes)

## Actual Result
- **Built Services**: `frontend` only (1 service built) ✅
- **Skipped Services**: `api`, `backend`, `microservice`, `sub-service`, `shared`, `utils` (6 services skipped)
- **Git Analysis**:
  - "Git reports no changes for api"
  - "Git reports no changes for backend"
  - "Git changes detected for frontend: 1 files changed"

## Key Findings
✅ **PASS** - Git tracking depth 1 functionality is working correctly
- Expected: Should analyze only the latest commit
- Actual: Correctly analyzed only the latest commit
- Impact: Git change detection properly limited to the most recent commit

## Enhanced Logging Output
The enhanced logging system provided excellent clarity:
- Clear git tracking configuration: `Git tracking: true (depth: 1)`
- Accurate service-by-service git change detection results
- Precise build decisions with clear reasoning
- Detailed build summary with performance metrics

## Status
✅ **PASS** - Git tracking depth 1 functionality works as expected. Only services changed in the latest commit are built.

## Performance Metrics
- Total services: 7
- Built: 1, Skipped: 6, Failed: 0
- Build duration: 620ms
- Cache effectiveness: 100%

## Technical Details
- Git commits analyzed: 1 (latest commit only)
- Services with changes in latest commit: frontend
- Services detected by git tracker: frontend
- Depth 1 implementation is working correctly
