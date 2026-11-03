# 07: Deferred — batch CLI for spec-driven builds

**Type:** build

**What to build:** A CLI command that reads a report spec and builds it without
an LLM in the loop, so repeated builds can run from a script or cron.

**Layer:** CLI

**Blocked by:** 06 (Measure reliability and decide go / no-go)

**Non-goals:** A general automation platform, retries, canary tests, a web UI.

**Invariants touched:** Feasibility scope, write gating.

**Verify:** `apply-spec <file.json>` creates a verified report from the spec.

**Status:** deferred — do not start until 06 recommends repeated builds.

- [ ] Add the command to the vendored CLI.
- [ ] Reuse the existing `apply_report_spec` use case; do not duplicate logic.
- [ ] Keep the writes gate and audit log.
- [ ] Prove it builds the exported feasibility spec.
- [ ] Document it in the project README, not in the vendored README.

**Why deferred:** The agent can call MCP tools directly. This is only useful
after the core capability is proven and repeated runs are actually needed.
