# Scenario 20: Smart Build with Git Changes

## Scenario Description
Test smart build behavior when there are git changes - should only build services that have actual changes.

## Command Executed
```bash
cd test-project
echo "# Updated API application" >> api/app.py
git add api/app.py
git commit -m "Update API application"
./dockerz build --smart --git-track --config ../test-build-yamls/test-build-20.yaml
```

## Expected Result
- Only changed services should be built
- `api` service should be built (because api/app.py was modified)
- All other services should be skipped (no changes)

## Actual Result
```
✓ Loaded configuration from: ../test-build-yamls/test-build-20.yaml
2025/11/23 19:36:40 DEBUG: Discovery sources - explicit_services: false, services_dirs: false (config: []), input_file: false, total_sources: 0
2025/11/23 19:36:40 DEBUG: Using SINGLE SOURCE discovery
2025/11/23 19:36:40 DEBUG: No sources configured, falling back to auto-discovery
2025/11/23 19:36:40 DEBUG: Final service count: 7
2025/11/23 19:36:40 Git changes detected for api: 1 files changed
2025/11/23 19:36:40 Git reports no changes for microservice: skipping build
2025/11/23 19:36:40 Git reports no changes for backend: skipping build
2025/11/23 19:36:40 Git reports no changes for sub-service: skipping build
2025/11/23 19:36:40 Git reports no changes for frontend: skipping build
2025/11/23 19:36:40 Git reports no changes for shared: skipping build
2025/11/23 19:36:40 Git reports no changes for utils: skipping build
2025/11/23 19:36:40 Smart Orchestration: 7 total, 1 to build, 6 skipped
2025/11/23 19:36:40 Starting parallel builds for 1 services with max_processes=4
2025/11/23 19:36:40 Building image for api: api:2438bcd
#0 building with "default" instance using docker driver
#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 208B done
#1 DONE 0.0s
#2 [internal] load metadata for docker.io/library/python:3.11-slim
#2 DONE 2.1s
#3 [internal] load .dockerignore
#3 transferring context: 2B done
#3 DONE 0.0s
#4 [internal] load build context
#4 transferring context: 235B done
#4 DONE 0.0s
#5 [1/5] FROM docker.io/library/python:3.11-slim@sha256:193fdd0bbcb3d2ae612bd6cc3548d2f7c78d65b549fcaa8af75624c47474444d
#5 resolve docker.io/library/python:3.11-slim@sha256:193fdd0bbcb3d2ae612bd6cc3548d2f7c78d65b549fcaa8af75624c47474444d 0.0s done
#5 DONE 0.0s
#6 [2/5] WORKDIR /app
#6 CACHED
#7 [3/5] COPY requirements.txt .
#7 CACHED
#8 [4/5] RUN pip install --no-cache-dir -r requirements.txt
#8 CACHED
#9 [5/5] COPY . .
#9 DONE 0.1s
#10 exporting to image
#10 exporting layers 0.0s done
#10 writing image sha256:cd14315446e441bf951f18142f84fa0cb14e85dccf6986469bed28f06ef21b80 done
#10 naming to docker.io/library/api:2438bcd done
#10 DONE 0.1s
2025/11/23 19:36:43 Successfully built api:2438bcd
2025/11/23 19:36:43 
Build Summary:
2025/11/23 19:36:43 Total services: 1
2025/11/23 19:36:43 Successful builds: 1
2025/11/23 19:36:43 Failed builds: 0
```

## Analysis
✅ **PASS** - Smart build correctly detected git changes and only built the changed service:
- Git changes detected for api: 1 files changed
- All 7 services were discovered via auto-discovery
- Only `api` service was built (1 file changed in api/app.py)
- All other 6 services were skipped (no changes detected)
- Smart orchestration summary: 7 total, 1 to build, 6 skipped
- Build completed successfully with 1/1 successful builds

## Build Configuration Used
```yaml
# Smart Build with Git Changes - Empty config for auto-discovery
# This will test that smart build detects git changes and only builds changed services
```

## Git Setup
- Modified api/app.py by adding "# Updated API application"
- Committed changes with message "Update API application"
- Git detected the change and mapped it to the api service
