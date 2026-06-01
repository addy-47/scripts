---
description: Root cause analysis for a bug, regression, or unexpected behavior. Investigative and retrospective.
---

Read everything in context:
- What broke or regressed
- Any error output, logs, or symptoms provided
- The implementation plan and recent changes if available

Do NOT attempt a fix yet. Do NOT suggest solutions yet.

## Step 1 — Symptom Definition

State precisely:
- What is the observed behavior
- What was the expected behavior
- When did it start — after which change, deploy, or event if known
- Is it consistent or intermittent

If any of these cannot be answered from context, stop and ask before continuing.

## Step 2 — Investigation

Trace backwards from the symptom:
- What code paths are involved
- What changed recently that touches those paths
- What assumptions in the code could be violated to produce this symptom
- What external factors could cause this (env, config, dependency version, data shape)

**Internal reasoning before writing:**
- Start at the symptom, not at a hypothesis
- Follow the actual execution path — not the intended one
- At each step ask: could this be the source, or is this a consequence?
- Identify where your confidence drops — flag those points explicitly

Use grep, log analysis, or any available tooling to verify — do not reason from memory alone if the codebase can be checked directly.

## Step 3 — Root Cause Report

### Symptom
What broke, exactly.

### Root Cause
What actually caused it. One clear statement.
If multiple contributing causes, rank them.

### Why It Wasn't Caught
- What test, validation, or assumption was missing that allowed this to reach the point of failure

### Confidence
Score 0–100%. If below 80%, state what additional information would close the gap.

---

Stop here. Present the report and wait for confirmation before proposing any fix.

---

## Step 4 — Fix Proposal (only after approval)

- Proposed fix — surgical, minimal
- Files and lines affected
- Why this fix addresses the root cause and not just the symptom
- Regression risk — what else could this touch
- How to verify the fix worked — specific command or observable outcome

## Step 5 — Prevention

After fix is confirmed working:
- What should be added (test, validation, guard) to prevent recurrence
- Update the implementation plan or delta-log if this occurred during an active refactor or implementation