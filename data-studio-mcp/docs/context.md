# Context

## Products

| Product | Cost | Report-creation API | Used here |
|---|---|---|---|
| **Data Studio** (renamed from Looker Studio, April 2026) | Free | **None** | **Yes** |
| Data Studio Pro | $9/user/project/month | None | No |
| Looker (enterprise) | Paid contract | Yes (Looker API + LookML) | No |
| Grafana | Free / paid | Yes (provisioning) | No (explicitly skipped) |

Free Data Studio has no API to create or edit reports. The only official
programmatic path is the Linking API, which clones a pre-built template. The
MCP server in this repo drives the real editor with Playwright instead.

## Vendored MCP

- Path: `mcp/looker-studio-mcp/`
- Upstream: `https://github.com/JhostinAleck/looker-studio-mcp`
- Upstream commit: `efee11bd98256f135d4aa9c5392c8b94015f9415` (2026-10-26)
- License: MIT
- Size: ~17,900 LOC TypeScript, 58 MCP tools
- Tests: 188 unit tests, 22 files. They cover domain logic, **not** the browser
  UI layer. The UI adapter is ~8,100 lines with no automated tests.
- Build: `npm ci && npm run build`
- Test: `npm run test:run`

Architecture is hexagonal: `authentication`, `bigquery`, `reports`, `mcp`,
`shared-kernel`, `cli`. All Looker Studio labels and selectors live in
`src/contexts/reports/infrastructure/ui/selectors.ts`.

## Environment (test only)

| Item | Value |
|---|---|
| ADC | `~/.config/gcloud/application_default_credentials.json`, type `authorized_user` |
| Project | `h4-internal` |
| Dataset | `billing_export`, region **`asia-south1`** |
| Billing account | `014AD3-14A442-FD0334` |
| Currency | **INR** |
| Raw tables | `gcp_billing_export_v1_014AD3_14A442_FD0334` (active), `gcp_billing_export_v1_011296_C68E5D_D7BA3C` (no recent rows) |
| Node 20 | `tools/node20/bin/` (Node 18 is the system default; the MCP needs ≥20) |
| Chrome | **Not installed on the server** |

### Do not use

`h4-internal.billing_export.finops_dashboard` is a pre-existing view. **Do not
build on it, and do not reference it in tickets or specs.** The client project
will not have it. Treat only the raw `gcp_billing_export_v1_*` tables as the
source of truth, as a fresh project would.

The existing dashboards, views, and prior analysis from earlier exploration are
out of scope. This is a blank-slate feasibility test.

## Data facts that affect the dashboard

- `cost` is gross. `credits[].amount` is negative. Net = `cost + SUM(credits)`.
- In this environment credits cancel gross almost exactly, so **net is ~0**.
  A dashboard that shows only net will look empty. Show gross, credits, and net
  separately, and default to gross.
- Standard billing export fields include project, service, SKU, location,
  labels, tags, transaction type, and consumption model.
- Data is current; rows exist for the last 7 days.

## Key commands

```bash
export PATH="/opt/sandobx/looker-agent-feasibility/tools/node20/bin:$PATH"
cd mcp/looker-studio-mcp
npm run build
npm run test:run

# MCP server with the project config
node build/cli/main.js serve --config ../../config/config.yaml
```

## Auth model

| Need | Credential |
|---|---|
| BigQuery queries, datasets, views | ADC |
| Data Studio report read/write | Persistent Chrome profile from `login` |

ADC **cannot** create reports. See `docs/auth-and-headless.md`.
