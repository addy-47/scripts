# Pitfalls

Known traps. Add one line when a new one is found.

## Auth

- **ADC cannot create reports.** It only powers BigQuery. Report tools need the
  Chrome profile from `looker-studio-mcp login`.
- **ADC cannot replace the browser login.** The Data Studio web app returns the
  same HTML with or without an ADC Bearer token. It authenticates with cookies.
  The asset API has no create method. See `docs/auth-and-headless.md`.
- **Google refuses sign-in in automated browsers.** The MCP logs in with plain
  Chrome first, then reuses the profile with Playwright. Do not try to sign in
  from the Playwright window.
- **The gcloud CLI login and ADC are separate.** The CLI can be expired while
  ADC still works. Refresh ADC only when BigQuery calls fail.
- **Chrome is not installed on this server.** The `login` command will fail
  until it is. See `docs/auth-and-headless.md`.

## BigQuery

- **Location mismatch.** The dataset is `asia-south1`. A config with the default
  `US` fails with "Dataset ... was not found in location US". Set
  `location: asia-south1`.
- **Net spend is zero here** because credits cancel gross. Charts that plot only
  `net` look empty. Use gross, credits, and net.
- **`finops_dashboard` is off-limits.** It is a pre-existing convenience view.
  A fresh client project will not have it. Use raw billing export tables.
- **Billing export is not real-time.** Check the latest `usage_start_time`
  before trusting a chart.
- **`cost` is gross.** Sum `credits[].amount` separately; do not assume `cost`
  is already net.

## Report automation

- **Selectors are English UI labels.** The editor opens with `hl=en`. A Google
  redesign can break the 695-line selector file.
- **One browser at a time.** A single persistent profile means no parallel
  report creation.
- **Each tool call is slow** (roughly 20–50 s). Batch with `apply_actions` or
  `apply_report_spec` where possible.
- **Field chips match display names.** Rename fields only after the setup that
  uses them.
- **Time series need a date or date-time dimension.** A raw timestamp can cause
  "Too many rows"; use a `DATE(...)` column.
- **Custom queries need `source_name`** and explicit casts for ambiguous types.
- **Free-tier reports belong to the signed-in person**, not the GCP project.
  They are orphaned if that account leaves.
- **Some actions need a visible window.** Sharing and link changes are refused
  from headless Chrome.

## Scope

- No Pro, no Looker enterprise, no Grafana.
- No cloud resource creation without approval.
- Do not harden for production unless a ticket proves it is needed.
