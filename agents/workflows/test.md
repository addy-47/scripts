---
description: Test the just-completed phase or step before proceeding. Updates the implementation plan with test details. Loops until passing. Use after each phase report.
agent: build
---
Read from context:

- The implementation plan — what this phase was supposed to deliver
- The phase report — what was actually implemented

Do NOT proceed to next phase. Do NOT write tests yet.

## Step 1 — Test Plan

Report back:

### What This Phase Was Supposed to Deliver

One sentence from the implementation plan.

### Test Approach

Answer each:

- **Scope:** What exactly is being verified? (match to phase goal, not individual functions)
- **Type:** Unit / integration / manual / CLI / external script — and why
- **File changes needed:** Does any existing file need modification to make it testable? List them.
- **Test location:** Internal (calls internal functions directly) or external script (black-box)? Why?
- **Success looks like:** Exact observable outcome that confirms the phase goal is met

---

Stop here. Wait for approval before writing or running any tests.

---

## Step 2 — Run Tests

Write and run the approved tests.

Report back:

### Test Results

- [ ] Pass / Fail
- What passed
- What failed — exact error, affected file, likely cause

### Issues Identified

For each issue:

| # | Issue | Affected File | Likely Cause | Proposed Fix |
| --- | ----- | ------------- | ------------ | ------------ |

---

If all tests pass → go to Step 4.
If any test fails → stop here. Wait for approval on proposed fixes.

---

## Step 3 — Fix Loop (repeat until clean)

After approval:

- Apply only the approved fix
- Re-run tests
- Report results in same format as Step 2

Repeat Step 3 until all tests pass.
Do not batch multiple fixes. One fix → test → report → approval.

---

## Step 4 — Final Report

### Phase Validation: [Phase Name]

- What was tested
- What passed
- Any fixes applied during the loop (summary)
- Remaining warnings or observations (do not suppress these)

---

## Step 5 — Update Implementation Plan

Update the original implementation plan:

- Mark this phase's validation checklist items as complete
- Add a `[TESTED]` note under the phase with a one-line summary of what was verified
- If any fixes were applied, add them as `[FIX APPLIED]` steps under the phase

Do not proceed to the next phase. Wait for explicit go-ahead.
