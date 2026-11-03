# Playbook: first report (one page)

Goal: build the smallest real dashboard end to end and verify it.

## Preconditions

- Ticket `01` done: Chrome profile signed in, `auth` passes.
- Ticket `02` done: BigQuery reads work.
- Ticket `03` done: chart spec and SQL agreed.
- Writes explicitly enabled for this run:
  `writes.enabled: true` in the config **and** `serve --enable-writes`.

## Steps

1. Start the MCP server headed or headless with writes enabled:

   ```bash
   node build/cli/main.js serve --config ../../config/config.yaml --enable-writes
   ```

2. Create a report on the raw billing table:

   - Tool: `create_report`
   - Name: `h4-billing-feasibility`
   - Source: `gcp_billing_export_v1_014AD3_14A442_FD0334`
   - Keep the data source name explicit.

3. Add three scorecards:

   - Gross spend
   - Credits
   - Net spend

4. Add one time series:

   - Dimension: `DATE(usage_start_time)` from a custom query, or the table's
     date field with a safe granularity.
   - Metrics: gross and net.

5. Verify:

   - `list_components` returns 4 components.
   - `check_report` reports no empty or error charts.
   - `screenshot_report` returns an image.

6. Record wall-clock time and any failed tool calls in `WORK_LOG.md`.

## Pass

- Report URL opens.
- All four charts have data.
- Screenshot saved.
- Time recorded.

## Common failures

| Symptom | Cause | Fix |
|---|---|---|
| "No data" | Wrong field or date range | Check the field type and range |
| "Too many rows" | Raw timestamp used as dimension | Wrap in `DATE(...)` |
| Chart inserted but wrong type | Preset label mismatch | Check `selectors.ts`; undo and retry |
| Login required | Profile not signed in | Redo `docs/auth-and-headless.md` |
