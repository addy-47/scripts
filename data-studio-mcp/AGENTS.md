# AGENTS.md

## Mission

Prove that an AI agent can build a Data Studio (free, formerly Looker Studio)
billing dashboard end to end with the vendored MCP server. This is a
**feasibility test only**. It is not a product, not client delivery, and not
production.

## Hard constraints

- **Free Data Studio only.** No Pro, no Looker enterprise, no Grafana.
- **Blank slate.** Do not reuse or depend on existing dashboards, views, or
  prior analysis. Assume a fresh client project with raw billing export only.
- **No cloud resource creation** without explicit approval.
- **No production hardening** unless a ticket proves it is needed.
- **ADC is for BigQuery only.** It cannot create reports.
- **Report creation needs a signed-in Chrome profile.**

## Context map

Load only what the task needs. Do not read everything up front.

| Need | Read |
|---|---|
| Priority and phases | `PLAN.md` |
| Product, repo, and environment facts | `docs/context.md` |
| Known traps | `docs/pitfalls.md` |
| ADC and headless Chrome login | `docs/auth-and-headless.md` |
| Step-by-step recipes | `docs/playbooks/` |
| Work items and blockers | `docs/tickets/` |
| History and handoffs | `WORK_LOG.md` |

## Work log rule (mandatory)

After **every task boundary**, append one concise bullet to `WORK_LOG.md`.
A task boundary is: a ticket finished, a blocker found, a decision made, a
state-changing command, or a handoff.

Format:

```
- YYYY-MM-DD | agent | ticket-id | what changed | next
```

Append only. Do not rewrite history.

## Workflow

1. Read `PLAN.md` and pick the frontier ticket: all blockers are done.
2. Do only that ticket. Respect its **Non-goals**.
3. Verify with the ticket's **Verify** line.
4. Append the `WORK_LOG.md` bullet.
5. Commit in small increments.
6. Tick the ticket's acceptance criteria and set its status.
7. Stop at the boundary. Do not start the next ticket without approval.

## Repo facts

- Vendored MCP: `mcp/looker-studio-mcp/`, upstream commit `efee11b`, MIT.
- Node 20: `tools/node20/bin/`. Export it before building.
- Build and test commands: `docs/context.md`.
- Do not edit the vendored MCP unless a ticket requires it.

## Definition of done

- The ticket's **Verify** line passes.
- A `WORK_LOG.md` bullet is added.
- A commit is made.
- No unapproved cloud resources were created.
