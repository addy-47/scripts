# Scenario 21.5: Smart with Mixed Changes

## Scenario Description
Test smart build behavior with multiple git changes in different services - should only build services that have actual changes.

## Command Executed
```bash
cd test-project
echo "# Backend update" >> backend/Dockerfile
echo "# Frontend change" >> frontend/Dockerfile
git add .
git commit -m "Update backend and frontend"
./dockerz build --smart --git-track --config ../test-build-yamls/test-build-21.5.yaml
```

## Expected Result
- Only changed services should be built
- `backend` service should be built (because backend/Dockerfile was modified)
- `frontend` service should be built (because frontend/Dockerfile was modified)
- All other services should be skipped (no changes)

## Actual Result
```
✓ Loaded configuration from: ../test-build-yamls/test-build-21.5.yaml
2025/11/23 19:42:38 DEBUG: Discovery sources - explicit_services: false, services_dirs: false (config: []), input_file: false, total_sources: 0
2025/11/23 19:42:38 DEBUG: Using SINGLE SOURCE discovery
2025/11/23 19:42:38 DEBUG: No sources configured, falling back to auto-discovery
2025/11/23 19:42:38 DEBUG: Final service count: 7
2025/11/23 19:42:38 Git reports no changes for api: skipping build
2025/11/23 19:42:38 Git reports no changes for microservice: skipping build
2025/11/23 19:42:38 Git changes detected for backend: 1 files changed
2025/11/23 19:42:38 Git reports no changes for sub-service: skipping build
2025/11/23 19:42:38 Git changes detected for frontend: 1 files changed
2025/11/23 19:42:38 Git reports no changes for shared: skipping build
2025/11/23 19:42:38 Git reports no changes for utils: skipping build
2025/11/23 19:42:38 Smart Orchestration: 7 total, 2 to build, 5 skipped
2025/11/23 19:42:38 Starting parallel builds for 2 services with max_processes=4
2025/11/23 19:42:38 Building image for frontend: frontend:6726c9b
2025/11/23 19:42:38 Building image for backend: backend:6726c9b
#0 building with "default" instance using docker driver
#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 146B 0.0s done
#1 WARN: JSONArgsRecommended: JSON arguments recommended for CMD to prevent OS signals (line 4)
#1 DONE 0.0s
#2 [internal] load metadata for docker.io/library/nginx:alpine
#2 DONE 0.0s
#3 [internal] load .dockerignore
#3 transferring context: 2B done
#3 DONE 0.0s
#4 [internal] load build context
#4 transferring context: 146B done
#4 DONE 0.0s
#5 [1/2] FROM docker.io/library/nginx:alpine
#5 CACHED
#6 [2/2] COPY . /usr/share/nginx/html
#6 DONE 0.1s
#7 exporting to image
#7 exporting layers done
#7 writing image sha256:49dd8e191e0a80e9ba1b5b370743ded7078b8e5d4ee7d767f84fb8f199d1c0b5 done
#7 naming to docker.io/library/frontend:6726c9b 0.0s done
#7 DONE 0.1s
2025/11/23 19:42:38 Successfully built frontend:6726c9b
#2 DONE 1.8s
#3 [internal] load .dockerignore
#3 transferring context: 2B done
#3 DONE 0.0s
#4 [1/5] FROM docker.io/library/node:18-alpine@sha256:8d6421d663b4c28fd3ebc498332f249011d118945588d0a35cb9bc4b8ca09d9e
#4 DONE 0.0s
#5 [internal] load build context
#5 transferring context: 241B done
#5 DONE 0.0s
#6 [2/5] WORKDIR /app
#6 CACHED
#7 [3/5] COPY package*.json ./
#7 CACHED
#8 [4/5] RUN npm install
#8 1.545 npm error code ENOENT
#8 1.546 npm error syscall open
#8 1.546 npm error path /app/package.json
#8 1.547 npm error errno -2
#8 1.547 npm error enoent Could not read package.json: Error: ENOENT: no such file or directory, open '/app/package.json'
#8 1.547 npm error enoent This is related to npm not being able to find a file.
#8 1.547 npm error enoent
#8 1.550 npm error A complete log of this run can be found in: /root/.npm/_logs/2025-11-23T14_12_40_938Z-debug-0.log
#8 ERROR: process "/bin/sh -c npm install" did not complete successfully: exit code: 254
------
 > [4/5] RUN npm install:
1.545 npm error code ENOENT
1.546 npm error syscall open
1.546 npm error path /app/package.json
1.547 npm error errno -2
1.547 npm error enoent This is related to npm not being able to find a file.
1.547 npm error enoent
1.550 npm error A complete log of this run can be found in: /root/.npm/_logs/2025-11-23_14_12_40_938Z-debug-0.log
------
ERROR: failed to build: failed to solve: process "/bin/sh -c npm install" did not complete successfully: exit code: 254
2025/11/23 19:42:42 Failed to build backend:6726c9b
2025/11/23 19:42:42 
Build Summary:
2025/11/23 19:42:42 Total services: 2
2025/11/23 19:42:42 Successful builds: 1
2025/11/23 19:42:42 Failed builds: 1
2025/11/23 19:42:42 Failed builds:
2025/11/23 19:42:42 - backend: backend:6726c9b
```

## Analysis
✅ **PASS** - Smart build correctly detected multiple git changes and only built changed services:
- Git changes detected for backend: 1 files changed (backend/Dockerfile)
- Git changes detected for frontend: 1 files changed (frontend/Dockerfile)
- All 7 services were discovered via auto-discovery
- Only `backend` and `frontend` services were targeted for build (2 changed services)
- All other 5 services were skipped (no changes detected)
- Smart orchestration summary: 7 total, 2 to build, 5 skipped
- Frontend built successfully
- Backend failed due to missing package.json (expected in test environment - does not affect smart build logic)

## Build Configuration Used
```yaml
# Smart with Mixed Changes - Empty config for auto-discovery
# This will test that smart build detects multiple git changes and only builds changed services
```

## Git Setup
- Modified backend/Dockerfile by adding "# Backend update"
- Modified frontend/Dockerfile by adding "# Frontend change"
- Committed both changes with message "Update backend and frontend"
- Git detected both changes and mapped them to respective services