# 03: Define the blank-slate billing dashboard contract

**Type:** build

**What to build:** A written contract and a draft report spec for the billing
dashboard, built only on raw billing export. It defines pages, charts, metrics,
dimensions, filters, and the SQL behind every chart.

**Layer:** data contract / report spec

**Blocked by:** 02 (Prove ADC + MCP read-only BigQuery access on raw billing export)

**Non-goals:** Creating the report, visual polish, using `finops_dashboard`, or
designing for multiple clients.

**Invariants touched:** Blank slate, raw billing export only, no cloud resources.

**Verify:** Every chart has SQL that runs via `run_query`; the draft spec is
valid JSON and matches the MCP report-spec shape.

**Status:** done

- [x] Write `docs/specs/billing-dashboard.md` with pages, charts, metrics, filters.
- [x] Write `docs/specs/billing-dashboard.json` as a draft `apply_report_spec` input.
- [x] Cover at least: 3 KPIs, daily trend, top projects, top services, project × service, SKU table.
- [x] Define filters: date range, project, service.
- [x] Validate each chart's SQL with `run_query`; record the expected shape.
- [x] Decide one dashboard for all projects vs one per project; record the choice.
- [x] State explicitly that `finops_dashboard` is not used.

**Minimum chart set:**

| Chart | Type | Grain |
|---|---|---|
| Gross / credits / net | 3 scorecards | period total |
| Spend trend | time series | day |
| Top projects | bar | project |
| Top services | bar | service |
| Project × service | pivot/heatmap | project, service |
| Cost detail | table | project, service, SKU |
