# Work log

Append-only. One bullet per task boundary. Format:

`- YYYY-MM-DD | agent | ticket-id | what changed | next`

- 2026-11-02 | agent | scaffold | Created project dir, vendored `looker-studio-mcp` at upstream `efee11b`, removed nested `.git`, added local Node 20 under `tools/` | Write docs and tickets
- 2026-11-02 | agent | scaffold | Verified vendored MCP: `npm ci`, `npm run build`, 188/188 tests pass, 58 MCP tools register | Keep build as smoke check
- 2026-11-02 | agent | 02 | Verified ADC token works; listed `h4-internal` datasets; confirmed `billing_export` in `asia-south1` | Use raw tables only
- 2026-11-02 | agent | 02 | MCP `list_datasets` and `run_query` work with ADC after setting `location: asia-south1` | Record location trap
- 2026-11-02 | agent | 03 | Confirmed raw billing export columns and that credits cancel gross (net ≈ 0) | Dashboard must show gross, credits, net
- 2026-11-02 | agent | decision | Excluded `finops_dashboard` and all prior dashboards; fresh-slate raw billing export only | Enforce in tickets
- 2026-11-02 | agent | 01 | Found Chrome not installed and `DISPLAY` unset; MCP `login` has no remote flag | Decide X11 / VNC / local MCP
- 2026-11-02 | agent | 01 | Confirmed gcloud remote flow: `--no-browser` then run the printed `--remote-bootstrap` command on the laptop | Document in auth guide
- 2026-11-02 | agent | scaffold | Added `AGENTS.md`, `PLAN.md`, `docs/context.md`, `docs/pitfalls.md`, `docs/auth-and-headless.md`, and three playbooks | Write tickets
- 2026-11-02 | agent | 01 | `auth --config config/config.yaml` returns: Google APIs token OK (`adhbhut.gupta@hypr4.io`), Chrome missing at `/opt/google/chrome/chrome` | Install Chrome or run login elsewhere
- 2026-11-02 | agent | tickets | Created tickets 01–07 with blockers and verify steps; 07 deferred | Start 02 (no browser needed)
- 2026-11-02 | agent | 01 | Verified SSH X11 login: `auth` OK for both credentials, headless `list_reports` returns "No reports yet."; profile set to 700 | Start 02 and 03
- 2026-11-02 | agent | handoff | Handoff after ticket 01. Frontier is 02 (BQ smoke) and 03 (dashboard contract). Writes remain off. No cloud resources created. | Next agent starts 02, then 03
- 2026-11-02 | agent | 01 | Probed ADC for report auth: web app HTML is byte-identical with/without Bearer; asset API 403 (quota/disabled, no create method); ADC lacks `datastudio` scope | Keep separate Chrome login; CDP reuse is optional, not a fix
- 2026-11-02 | agent | 02 | MCP list_datasets sees billing_export; smoke query returned 5 rows with gross, credits, net (51.9 MB scanned, 5.19s); location asia-south1 works | Write dashboard contract (ticket 03)
- 2026-11-02 | agent | 03 | Wrote billing dashboard contract and JSON spec; validated daily trend, top projects, top services, pivot, SKU SQL; one dashboard for all projects; no finops_dashboard | Enable writes and build ticket 04
