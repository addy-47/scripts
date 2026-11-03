# 05: Complete the billing dashboard

**Type:** build

**What to build:** The full feasibility dashboard from the agreed contract:
project and service breakdowns, a detail table, and working filters, across the
pages defined in ticket 03.

**Layer:** report UI via MCP

**Blocked by:** 04 (Build the first end-to-end page)

**Non-goals:** Sharing, scheduling, delivery, alerting, production hardening,
multiple clients.

**Invariants touched:** Free Data Studio only, raw billing export only, writes
gated.

**Verify:** `check_report` is clean, at least 6 charts render data, filters
change the numbers, and `export_report_spec` produces a spec that can rebuild
the report.

**Status:** ready-for-agent

- [ ] Add top-projects and top-services charts.
- [ ] Add the project × service pivot or heatmap.
- [ ] Add the cost detail table.
- [ ] Add date range, project, and service controls.
- [ ] Confirm filters change chart values.
- [ ] Run `check_report` and `screenshot_report` for each page.
- [ ] Export the spec to `docs/specs/billing-dashboard.json`.
- [ ] Save screenshots under `docs/reports/`.
- [ ] Record total build time and failures in `WORK_LOG.md`.
