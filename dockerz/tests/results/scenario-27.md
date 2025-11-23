# Scenario 27: Smart Build with Git Track Depth 0 (All Commits)

## Scenario Description
Test smart build functionality with git tracking depth 0 (analyze entire git history for changes).

## Git Setup
```bash
cd tests/test-project
git add .
git commit -m "Initial setup"

echo "# Change 1" >> api/app.py
git add api/app.py
git commit -m "Update API v1"

echo "# Change 2" >> backend/Dockerfile
git add backend/Dockerfile
git commit -m "Update backend Dockerfile"

echo "# Change 3" >> frontend/app.js
git add frontend/app.js
git commit -m "Update frontend"
```

## Command Executed
```bash
cd tests/test-project
./dockerz build --smart --git-track --depth 0 --config ../test-build-yamls/test-build-27.yaml
```

## Expected Result
- **Built Services**: `api`, `backend`, `frontend` (all services with changes in ANY commit)
- **Reasoning**: With depth 0, should analyze entire git history

## Actual Result
- **Built Services**: `frontend` only (1 service built)
- **Skipped Services**: `api`, `backend`, `microservice`, `sub-service`, `shared`, `utils` (6 services skipped)
- **Git Analysis**:
  - "Git reports no changes for api"
  - "Git reports no changes for backend"
  - "Git changes detected for frontend: 1 files changed"

## Key Findings
❌ **CRITICAL ISSUE**: `--depth 0` is NOT working correctly
- Expected: Should analyze ALL commits in git history
- Actual: Only analyzes the latest commit (behaving like `--depth 1`)
- Impact: Git change detection fails for commits older than the most recent

## Enhanced Logging Output
The enhanced logging system provided excellent transparency:
- Clear git tracking configuration: `Git tracking: true (depth: 0)`
- Service-by-service git change detection results
- Detailed build decisions with reasoning
- Comprehensive build summary with metrics

## Status
❌ **FAIL** - Git tracking depth 0 functionality is broken. System analyzes only latest commit instead of entire history.

## Performance Metrics
- Total services: 7
- Built: 1, Skipped: 6, Failed: 0
- Build duration: 737ms
- Cache effectiveness: 100%

## Technical Details
- Git commits in history: 4 total
- Services with changes in history: api, backend, frontend
- Services detected by git tracker: frontend only
- This indicates a bug in depth 0 implementation
