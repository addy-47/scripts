# Billing dashboard contract

## Scope
- One dashboard for all projects in `h4-internal.billing_export`.
- Data source: raw `gcp_billing_export_v1_014AD3_14A442_FD0334` only.
- `finops_dashboard` and any prior dashboard/view are **not** used.
- Currency: INR.
- `cost` is gross. Credits are negative. Net = gross + credits.
- Show gross, credits, and net separately. Default chart metric is gross.

## Data source SQL (row-level)
```sql
SELECT
  usage_start_time,
  DATE(usage_start_time) AS usage_date,
  project.id AS project_id,
  project.name AS project_name,
  service.description AS service,
  sku.description AS sku,
  location.location AS location,
  cost AS gross,
  (SELECT IFNULL(SUM(c.amount), 0) FROM UNNEST(credits) c) AS credits,
  cost + (SELECT IFNULL(SUM(c.amount), 0) FROM UNNEST(credits) c) AS net,
  currency
FROM `h4-internal.billing_export.gcp_billing_export_v1_014AD3_14A442_FD0334`
```

## Default filters
- Date range: last 7 days.
- Project: all.
- Service: all.
- Region/location: optional control.

## Page 1 — Overview
1. Scorecard: gross spend.
2. Scorecard: credits.
3. Scorecard: net spend.
4. Time series: daily gross and net by `usage_date`.
5. Bar: top 10 projects by gross.
6. Bar: top 10 services by gross.
7. Pivot/heatmap: project × service by gross.

## Page 2 — Project drill-down
1. Project filter.
2. Service breakdown for selected project.
3. SKU table.
4. Daily trend.

## Page 3 — Service drill-down
1. Service filter.
2. Project distribution.
3. Top SKUs.
4. Daily trend.

## Chart SQL validation
All queries below ran successfully via `run_query` on the raw table.

| Chart | Grain | Expected shape |
|---|---|---|
| Gross / credits / net | period total | 1 row, 3 numeric columns |
| Daily trend | day | 31 rows for last 30 days, `usage_date`, gross, credits, net |
| Top projects | project | 5 projects in current data, gross, credits, net |
| Top services | service | 10 services, gross, credits, net |
| Project × service | project, service | 25 rows in last 30 days, project, service, gross |
| SKU table | project, service, SKU | 20 rows, gross, credits, net |

## Controls
- Date range on `usage_date`.
- Project drop-down on `project_name`.
- Service drop-down on `service`.
- Optional location drop-down on `location`.

## Decisions
- One dashboard for all projects.
- Report name: `h4-billing-feasibility`.
- Owner/viewer: `adhbhut.gupta@hypr4.io`.
- Default date range: last 7 days.
- Default chart metric: gross.

## Notes
- No views, datasets, or tables are created.
- No `finops_dashboard` or prior dashboard is used.