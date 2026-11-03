# 04: Build the first end-to-end page

**Type:** build

**What to build:** A real Data Studio report named `h4-billing-feasibility`
with one page: three KPI scorecards plus one time series, all on raw billing
export. This is the first proof that the agent can create a report end to end.

**Layer:** report UI via MCP

**Blocked by:**
- 01 (Prove a one-time Chrome login and headless reuse)
- 03 (Define the blank-slate billing dashboard contract)

**Non-goals:** The full dashboard, sharing, scheduling, delivery, visual polish.

**Invariants touched:** Free Data Studio only, raw billing export only, writes
gated, explicit approval before cloud-visible creation.

**Verify:** The report URL opens; `list_components` shows 4 components;
`check_report` reports no empty or error charts; a screenshot is saved.

**Status:** ready-for-agent

- [ ] Get explicit approval to set `writes.enabled: true` and pass `--enable-writes`.
- [ ] Create `h4-billing-feasibility` from the raw table.
- [ ] Add gross, credits, and net scorecards.
- [ ] Add one time series with a `DATE(...)` dimension.
- [ ] Confirm all four charts have data.
- [ ] Run `check_report` and `screenshot_report`.
- [ ] Record wall-clock time and every failed call in `WORK_LOG.md`.
- [ ] Keep `writes.enabled: true` only for this run; turn it off after.

**Note:** This is the first ticket allowed to create a cloud-visible asset.
