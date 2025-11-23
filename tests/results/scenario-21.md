# Scenario 21: Smart + Input File

## Scenario Description
Test smart build behavior with both input file service filtering and git change detection - should build services that are BOTH in input file AND have git changes.

## Command Executed
```bash
cd test-project
# changed.txt contains all 7 services
./dockerz build --smart --git-track --input-changed-services changed.txt --config ../test-build-yamls/test-build-21.yaml
```

## Expected Result
- Input file: all 7 services (api, api/microservice, backend, backend/sub-service, frontend, shared, shared/utils)
- Git changes: api (from previous commit)
- **Intersection**: api only (services that are BOTH in input file AND have git changes)
- Only api service should be built

## Actual Result
```
✓ Loaded configuration from: ../test-build-yamls/test-build-21.yaml
2025/11/23 19:40:28 DEBUG: Discovery sources - explicit_services: false, services_dirs: false (config: []), input_file: true, total_sources: 1
2025/11/23 19:40:28 DEBUG: Using SINGLE SOURCE discovery
2025/11/23 19:40:28 DEBUG: Using input file only
2025/11/23 19:40:28 INFO: Reading input file: changed.txt
2025/11/23 19:40:28 INFO: Found 7 service entries in input file
2025/11/23 19:40:28 INFO: Processing service from input file: api
2025/11/23 19:40:28 INFO: Successfully added service 'api' from input file
2025/11/23 19:40:28 INFO: Processing service from input file: api/microservice
2025/11/23 19:40:28 INFO: Successfully added service 'api/microservice' from input file
2025/11/23 19:40:28 INFO: Processing service from input file: backend
2025/11/23 19:40:28 INFO: Successfully added service 'backend' from input file
2025/11/23 19:40:28 INFO: Processing service from input file: backend/sub-service
2025/11/23 19:40:28 INFO: Successfully added service 'backend/sub-service' from input file
2025/11/23 19:40:28 INFO: Processing service from input file: frontend
2025/11/23 19:40:28 INFO: Successfully added service 'frontend' from input file
2025/11/23 19:40:28 INFO: Processing service from input file: shared
2025/11/23 19:40:28 INFO: Successfully added service 'shared' from input file
2025/11/23 19:40:28 INFO: Processing service from input file: shared/utils
2025/11/23 19:40:28 INFO: Successfully added service 'shared/utils' from input file
2025/11/23 19:40:28 INFO: Successfully discovered 7 services from input file
2025/11/23 19:40:28 DEBUG: Final service count: 7
2025/11/23 19:40:28 Git changes detected for api: 1 files changed
2025/11/23 19:40:28 Git reports no changes for microservice: skipping build
2025/11/23 19:40:28 Git reports no changes for backend: skipping build
2025/11/23 19:40:28 Git reports no changes for sub-service: skipping build
2025/11/23 19:40:28 Git reports no changes for frontend: skipping build
2025/11/23 19:40:28 Git reports no changes for shared: skipping build
2025/11/23 19:40:28 Git reports no changes for utils: skipping build
2025/11/23 19:40:28 Smart Orchestration: 7 total, 1 to build, 6 skipped
2025/11/23 19:40:28 Starting parallel builds for 1 services with max_processes=4
2025/11/23 19:40:28 Building image for api: api:2438bcd
#0 building with "default" instance using docker driver
#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 208B done
#1 DONE 0.0s
#2 [internal] load metadata for docker.io/library/python:3.11-slim
#2 DONE 0.7s
#3 [internal] load .dockerignore
#3 transferring context: 2B done
#3 DONE 0.0s
#4 [internal] load build context
#4 transferring context: 165B done
#4 DONE 0.0s
#5 [1/5] FROM docker.io/library/python:3.11-slim@sha256:193fdd0bbcb3d2ae612bd6cc3548d2f7c78d65b549fcaa8af75624c47474444d
#5 resolve docker.io/library/python:3.11-slim@sha256:193fdd0bbcb3d2ae612bd6cc3548d2f7c78d65b549fcaa8af75624c47474444d 0.0s done
#5 DONE 0.0s
#6 [2/5] WORKDIR /app
#6 CACHED
#7 [4/5] RUN pip install --no-cache-dir -r requirements.txt
#7 CACHED
#8 [3/5] COPY requirements.txt .
#8 CACHED
#9 [5/5] COPY . .
#9 CACHED
#10 exporting to image
#10 exporting layers done
#10 writing image sha256:cd14315446e441bf951f18142f84fa0cb14e85dccf6986469bed28f06ef21b80 done
#10 naming to docker.io/library/api:2438bcd done
#10 DONE 0.0s
2025/11/23 19:40:30 Successfully built api:2438bcd
2025/11/23 19:40:30 
Build Summary:
2025/11/23 19:40:30 Total services: 1
2025/11/23 19:40:30 Successful builds: 1
2025/11/23 19:40:30 Failed builds: 0
```

## Analysis
✅ **PASS** - Smart build correctly combined input file filtering with git change detection:
- Input file successfully discovered all 7 services from changed.txt
- Git changes detected for api: 1 files changed
- Smart orchestration applied intersection logic: services must be BOTH in input file AND have git changes
- Only `api` service was built (the intersection of input file services and git-changed services)
- All other 6 services were skipped (either not in input file or no git changes)
- Smart orchestration summary: 7 total, 1 to build, 6 skipped
- Build completed successfully with 1/1 successful builds

## Build Configuration Used
```yaml
# Smart + Input File - Empty config for auto-discovery
# This will test smart build with both git changes and input file service filtering
```

## Input File Used (changed.txt)
```
api
api/microservice
backend
backend/sub-service
frontend
shared
shared/utils
```

## Git Setup
- Git changes from previous scenario: api/app.py modified and committed
- Changes detected and mapped to api service
