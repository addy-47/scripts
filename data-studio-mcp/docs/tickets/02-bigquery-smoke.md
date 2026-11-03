# 02: Prove ADC + MCP read-only BigQuery access on raw billing export

**Type:** build

**What to build:** A reproducible read-only path from the MCP server, using ADC,
to the **raw** billing export table. The agent can list datasets, run a query,
and see gross, credits, and net per project and service.

**Layer:** BigQuery / MCP configuration

**Blocked by:** None (can start immediately)

**Non-goals:** Creating datasets, views, tables, or reports. Using
`finops_dashboard` or any pre-existing view.

**Invariants touched:** Blank slate, raw billing export only, no cloud resource
creation.

**Verify:** `run_query` returns 5 rows from
`h4-internal.billing_export.gcp_billing_export_v1_014AD3_14A442_FD0334` with no
location error, and the scan size is recorded.

**Status:** done

- [x] Confirm `config/config.yaml` uses `project_id: h4-internal` and `location: asia-south1`.
- [x] Prove `list_datasets` sees `billing_export`.
- [x] Run the smoke query from `docs/playbooks/01-smoke-test.md`.
- [x] Confirm gross, credits, and net are separate columns.
- [x] Record rows, bytes scanned, elapsed time, and any error in `WORK_LOG.md`.

**Note:** The location trap is already documented in `docs/pitfalls.md`. Do not
re-discover it.
