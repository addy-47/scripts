---
trigger: model_decision
description: Coding best practices that must be followed after planning stage - this includes implementation rules for frontend. backend. infra. cli execution, modularity, api structure and packaging.
---

## Code Style

### Modularity
- No hardcoding. Constants defined at top of file.
- Shared constants go in config — sensitive values in `.env`, non-sensitive in `config.yaml`
- Modular structure always. One responsibility per module/file
- Never use TypeScript `any` — if types get complex, define them explicitly. `any` is treated the same as a hardcoded secret: flag it, fix it

### Frontend Structure
- All API and external service calls centralized in `src/services/` — never fragmented across components
- Mock data and static UI data live in `src/data/` — never defined inline in components or individual files
- Components consume data; they do not own or fetch it directly
- Global or shared state in `src/context/` — but only for slow-changing state (auth, theme, user preferences, feature flags). Never use context for frequently-updating state — it causes full subtree re-renders
- Reusable stateful logic extracted to `src/hooks/` when the same logic appears in 2+ components, or when effect/state logic inside a component grows complex enough to obscure what the component renders. Components should read as layout + wiring, not logic

### Backend Structure
- Validate all input at the boundary — before it touches business logic. Never trust incoming data
- Never return raw DB errors or stack traces to the client — sanitize all error responses
- Every list endpoint must have pagination — never return unbounded queries
- Any operation spanning multiple tables must use a transaction — not optional
- One shared DB connection pool per service — never a new connection per request
- Graceful shutdown — drain in-flight requests before exiting
- Health check endpoint from day one (`/health` or `/healthz`)
- Structured logging with levels (info / warn / error) — not scattered print statements

### API Standardisation
- Every service has a versioned base path: `/api/v1/<service-name>` (e.g. `/api/v1/orchestrator`)
- Route definitions live in the main entry file (`main.go`, `main.py`, etc.) — just the definitions, not the logic. Handlers and business logic live in their own files
- All endpoints across all services return the same response envelope: `{ data, error, meta }`
- HTTP status codes must be used consistently across all services — pick a convention and document it. Do not mix `400` and `422` for the same class of error across services
- Service names, container names, and route prefixes must match — use the same identifier everywhere. This is non-negotiable in multi-service codebases

### Package Managers & Environments
- Frontend: always use `pnpm`, never `npm`
- Python: always use `venv` for any Python service or script
- Never install packages globally unless explicitly asked
- Never add a new dependency without explicit approval

### CLI
- Long-running or important commands: `cmd 2>&1 | tee process.log` — output visible live and persisted
- Background processes: `cmd > process.log 2>&1 &` — always capture PID with `echo $!`
- Never chain commands with `&&` without confirming the previous step can be trusted to succeed silently — prefer explicit exit code checks for anything consequential
- Build and install output always redirected to a log file — never let it scroll off with no record

### Security Basics
- Never hardcode secrets, API keys, or credentials — not even in test files
- Never commit `.env` files — always provide `.env.example` with placeholder values
- Never log sensitive values even in debug paths
- Every database must be secured — no open instances

**Database credentials:**
- Redis and Qdrant have no auth by default — always configure passwords explicitly
- Never use default Postgres credentials (`postgres`/`postgres`) — always create a named user with a strong password
- Dev passwords: memorable and project-themed is fine (e.g. `@ProjectName2025!!`) — but still in `.env`, never hardcoded
- Production passwords: proper secrets management, not hardcoded anywhere

### Docker
- Always multi-stage builds — separate build and runtime stages
- Always non-root user in the final image
- Runtime image must be minimal — no build tools, no dev dependencies
- **Never choose base images from internal knowledge** — AI training data includes outdated and vulnerable image tags (e.g. `postgres:15` has known CVEs). Web search for the current stable/LTS tag before writing any `FROM` line. This applies to Dockerfiles and any compose files.

### Infra Files
- Docker Compose files, nginx configs, and other infra files live in `infra/`
- Container names in compose files must match the service name used in route prefixes and code — one name, used everywhere

### .gitignore (Required for Every Project)
Every project must have a `.gitignore` that covers its stack from day one. At minimum:

| Stack | Entries |
|-------|---------|
| Python | `venv/`, `__pycache__/`, `*.pyc`, `.env` |
| Node/Frontend | `node_modules/`, `.env`, `dist/`, `.next/` |
| Rust | `target/` |
| General | `*.log`, `.DS_Store`, `*.env*.local` |

Never commit generated build artifacts, dependency directories, secrets, or log files.


---
