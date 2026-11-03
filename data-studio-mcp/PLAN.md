# Plan

## Goal

Prove that an AI agent can build a **billing dashboard** in free Data Studio
from a blank slate, using the vendored MCP server, with only one manual step
(the one-time Google browser login).

This is a feasibility test. It is **not** a product and **not** client delivery.

## Success criteria (go / no-go)

The test passes if the agent can:

1. Sign in once and then run headless.
2. Build a report from scratch with **at least 6 charts** on raw billing export:
   KPIs, trend, project breakdown, service breakdown, table, filters.
3. Produce a screenshot and a clean `check_report` (no empty or error charts).
4. Do it with **at most one manual intervention**: the browser login.
5. Record wall-clock time, failures, and manual fixes per build.
6. Give a written go/no-go recommendation with evidence.

If any criterion fails, record why. A failed criterion is a valid result.

## Non-goals

- Production hardening, CI, retries, canary tests.
- Client delivery, Pro, Looker enterprise.
- Grafana or any alternative BI tool.
- Multi-tenant generation, scheduling at scale, alerting.
- Perfect visual design. Functional and readable is enough.
- Batch CLI, spec generator, or automation wrappers. **Deferred** until the
  core capability is proven. The MCP tools can be called directly by the agent.

## Fresh-slate assumptions

- The client project will have raw billing export only.
- No pre-existing dashboards, views, or convenience tables.
- Do **not** use `h4-internal.billing_export.finops_dashboard` or any earlier
  dashboard. Build as if the dataset contains only `gcp_billing_export_v1_*`.
- The test project is `h4-internal` only because its billing export is available
  for read-only queries.

## Priority rule

Do only work that moves a success criterion. If a task does not, defer it and
write the reason in the ticket or work log.

Explicitly deferred:

| Deferred | Why |
|---|---|
| Batch CLI (`apply-spec`) | The agent can call MCP tools directly. Not a blocker. |
| Retries / idempotency | Only useful after repeated runs prove a failure rate. |
| Spec generator (Python/Jinja) | One dashboard does not need a generator. |
| Nightly canary | Useful after the capability is proven, not before. |
| Grafana / Cloud Run | Different product. User explicitly skipped it. |
| Production security review | Out of scope. |

## Phases and tickets

| Phase | Ticket | Outcome |
|---|---|---|
| 0. Scaffold | done | Repo, docs, config, vendored MCP |
| 1. Auth feasibility | `01` | One-time Chrome login works; headless reuse proven |
| 2. Data smoke test | `02` | ADC + MCP + raw billing export query works |
| 3. Dashboard contract | `03` | Metrics, dimensions, 6-chart spec defined from raw tables |
| 4. First end-to-end | `04` | One page with 3 KPIs + trend built and verified |
| 5. Full dashboard | `05` | Project + service breakdown, filters, table |
| 6. Measure and decide | `06` | Reliability, effort, go/no-go report |
| 7. Deferred automation | `07` | Only if `06` says repeated builds are needed |

## Decisions needed

1. **Report owner:** team Google account or client account? Free reports are
   owned by the person who signs in.
2. **Scope:** one dashboard for all projects, or one per project?
3. **Login path:** SSH X11 forwarding, VNC, or run the MCP on a laptop?

## Risks

| Risk | Impact | Mitigation |
|---|---|---|
| No Chrome / no display on server | Blocks report creation | X11 forwarding, VNC, or run MCP locally |
| Google UI changes | Selectors break | Small scope; record breakage; defer hardening |
| Free-tier ownership | Reports orphaned if account leaves | Decision 1 above |
| Slow tool calls | Build takes minutes | Accept for feasibility; batch where easy |
| Credits cancel gross | Dashboard looks empty | Show gross, credits, net |

## Definition of done for the experiment

`docs/reports/feasibility.md` exists with:

- What was built (screenshot).
- Time and manual interventions.
- Failures and fixes.
- Go/no-go recommendation.
- What would be needed for production.
