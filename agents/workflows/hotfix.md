---
description: Emergency fix for something broken in a working system. Abbreviated path — no full planning cycle. Surgical only. Always includes rollback plan.
agent: build
---
This is not a feature. This is not a refactor.
The only goal is to restore correct behavior with minimum surface area change.

## Step 1 — Triage

Before touching anything, answer:
- What is broken and what is the impact
- What is the rollback path if the fix makes things worse
- Can the system be partially reverted or isolated right now while the fix is prepared

If rollback path is unclear — stop and establish it before proceeding. Never hotfix without a known rollback.

## Step 2 — Minimal Fix Plan

- Exact file(s) and line(s) to change
- What the change is
- Why this fixes the issue without side effects
- What this does NOT touch — explicitly

Confidence check:
- 100% confident this is the right change with no regressions? → proceed
- Any doubt? — state it explicitly, present options, wait for decision

Stop here. Wait for approval.

## Step 3 — Apply Fix

- Surgical edit only — minimum lines changed to restore correct behavior
- No cleanup, no refactoring, no improvements alongside the fix
- If you notice something else that should be fixed — log it, do not touch it now

## Step 4 — Verify

Run the specific verification that confirms the broken behavior is resolved:
- State what command or observable outcome confirms the fix
- Run it
- Report result

If verification fails → revert immediately, report, restart from Step 1 with new information.

## Step 5 — Hotfix Report

- What was broken
- What was changed (file, lines, exact diff)
- How it was verified
- Rollback instructions (keep these even after a successful fix)
- Any follow-up work identified during the fix — logged for a proper thread later

Update delta-log.md or implementation plan if this occurred during an active implementation.

Do not close the hotfix until the report is reviewed.
