# Playbook: full billing dashboard

Goal: complete the feasibility dashboard. Raw billing export only.

## Preconditions

- Ticket `04` done: first page verified.
- `docs/specs/billing-dashboard.md` approved.

## Target pages

### Page 1 — Overview

- 3 KPI scorecards: gross, credits, net.
- Daily trend: gross vs net.
- Top projects by gross (bar).
- Top services by gross (bar).
- Project × service heatmap or pivot table.

### Page 2 — Project drill-down

- Project filter.
- Service breakdown for the selected project.
- SKU table.
- Daily trend.

### Page 3 — Service drill-down

- Service filter.
- Project distribution.
- Top SKUs.
- Daily trend.

## Controls

- Date range.
- Project.
- Service.
- Region (optional).

## Steps

1. Build page by page. Verify each page before moving on.
2. Prefer `apply_report_spec` or `apply_actions` for batches.
3. After each page: `check_report` + `screenshot_report`.
4. When done: `export_report_spec` and save the JSON under `docs/specs/`.
5. Update the ticket acceptance criteria and `WORK_LOG.md`.

## Pass

- At least 6 charts.
- All charts populated.
- Filters change the numbers.
- Exported spec round-trips.
- Screenshot saved under `docs/reports/`.

## Rules

- Do not use `finops_dashboard`.
- Do not add sharing, scheduling, or delivery. Out of scope.
- Do not "fix" the vendored MCP unless the ticket says so.
