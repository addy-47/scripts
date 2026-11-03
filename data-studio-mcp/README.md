# Looker / Data Studio agent feasibility

A small, time-boxed experiment. Goal: find out whether an AI agent can build a
billing dashboard in **free Data Studio** (formerly Looker Studio) end to end,
with the vendored MCP server, instead of a human doing it by hand.

This is **not** a product, **not** client delivery, and **not** production work.

## Layout

```
AGENTS.md                 agent rules and context map
PLAN.md                   phases, priorities, deferred work
WORK_LOG.md               append-only task log
docs/
  context.md              products, repo facts, environment
  pitfalls.md             known traps
  auth-and-headless.md    ADC, remote gcloud login, Chrome login on a headless server
  playbooks/              step-by-step recipes
  tickets/                vertical-slice tickets, dependency ordered
mcp/looker-studio-mcp/    vendored upstream MCP server (MIT)
tools/node20/             local Node 20 runtime (gitignored)
```

## Quick start

```bash
export PATH="$PWD/tools/node20/bin:$PATH"
cd mcp/looker-studio-mcp
npm ci
npm run build
npm run test:run
```

## Read first

1. `AGENTS.md`
2. `PLAN.md`
3. `docs/context.md`
4. `docs/pitfalls.md`
