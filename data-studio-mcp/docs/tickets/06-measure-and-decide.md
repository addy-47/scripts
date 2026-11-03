# 06: Measure reliability and decide go / no-go

**Type:** spike

**What to build:** Evidence for the feasibility decision. Run the build multiple
times and measure what actually happens: time, failures, manual fixes, and
whether the result is repeatable.

**Layer:** process / evaluation

**Blocked by:** 05 (Complete the billing dashboard)

**Non-goals:** Fixing every issue, production hardening, building automation.

**Invariants touched:** Feasibility only, no production work.

**Verify:** `docs/reports/feasibility.md` exists with a metrics table, a failure
log, and a go/no-go recommendation.

**Status:** ready-for-agent

- [ ] Rebuild the report from the exported spec at least 3 times.
- [ ] Record wall-clock time per build.
- [ ] Record every failed tool call, retry, and manual fix.
- [ ] Record Google challenges (consent, re-auth, captcha).
- [ ] Compare the built charts to the agreed SQL results.
- [ ] Write `docs/reports/feasibility.md` with evidence and screenshots.
- [ ] Recommend go or no-go for agent-driven dashboard creation.
- [ ] List the top 3 blockers that production would need to solve.

**Exit:** A clear recommendation, backed by the measured numbers, and a short
list of what would have to change for production use.
