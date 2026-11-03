# Playbook: BigQuery smoke test

Goal: prove ADC + MCP can read the raw billing export. No resources created.

## Preconditions

- `config/config.yaml` has `project_id: h4-internal` and
  `location: asia-south1`.
- ADC works: `gcloud auth application-default print-access-token >/dev/null`.

## Steps

1. Set Node 20:

   ```bash
   export PATH="/opt/sandobx/looker-agent-feasibility/tools/node20/bin:$PATH"
   cd /opt/sandobx/looker-agent-feasibility/mcp/looker-studio-mcp
   ```

2. Start the MCP server with the project config:

   ```bash
   node build/cli/main.js serve --config ../../config/config.yaml
   ```

3. From an MCP client, call `list_datasets` with `project_id: h4-internal`.
   Expect `billing_export`.

4. Call `run_query` with a read-only query on the **raw** table:

   ```sql
   SELECT
     project.id AS project_id,
     service.description AS service,
     ROUND(SUM(cost), 2) AS gross,
     ROUND(SUM((SELECT SUM(c.amount) FROM UNNEST(credits) c)), 2) AS credits,
     ROUND(SUM(cost + (SELECT IFNULL(SUM(c.amount), 0) FROM UNNEST(credits) c)), 2) AS net
   FROM `h4-internal.billing_export.gcp_billing_export_v1_014AD3_14A442_FD0334`
   WHERE DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 3 DAY)
   GROUP BY 1, 2
   ORDER BY gross DESC
   LIMIT 5
   ```

5. Record: rows returned, bytes scanned, elapsed time.

## Pass

- No location error.
- Rows returned.
- `finops_dashboard` was not used.

## Fail

- `Dataset ... was not found in location US` → fix `location` in the config.
- `403` → refresh ADC or check BigQuery permissions.
