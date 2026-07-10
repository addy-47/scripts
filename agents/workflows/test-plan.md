---
description: Generic testing workflow. Works for any project or stack. Loops until genuinely passing. Stops on real blockers. Testing means understanding and judgment, not running a script and reading exit code 0.
---

## What Testing Is Not

Testing is not: write a script → run it → exit code 0 → report "passed" to the user.
That is execution, not testing. If that's all that was needed, it wouldn't need an agent.

A script that runs without crashing has told you nothing except that it ran without crashing.

## What Testing Actually Is

Before writing a single line of test code, understand the goal:

- What was this implementation actually supposed to achieve?
- What does a genuinely correct result look like — not just "no error," but the right behavior, the right values, the right shape of output?
- What would a wrong-but-not-crashing result look like? (This is the dangerous case — silent wrongness)
- What are the realistic edge cases this needs to survive, given what it actually does?

Write this understanding down before building anything. If you cannot articulate what success looks like, you are not ready to test — go clarify first.

---

## Step 1 — Define Success Before Writing Anything

State explicitly:

- **Goal of this test**: what is being verified, in plain terms
- **Success criteria**: the specific, concrete conditions that mean this actually works — not "no errors," but the real behavior expected
- **Failure signatures**: what wrong output would look like, including subtle wrongness that wouldn't crash anything
- **Test method**: script, manual check, log inspection, or combination — chosen based on what actually proves the goal, not habit

## Step 2 — Build the Test Around the Goal

- The test/script exists to produce evidence toward the success criteria defined above — not to exist for its own sake
- Capture full output and logs, not just pass/fail signals
- If the implementation touches something with observable side effects (files, state, downstream systems) — check those directly, don't infer them from the absence of an error

## Step 3 — Run and Read, Don't Run and Trust

After running:

**Do not accept a clean exit code as success.** Read the actual output.

For every result produced, ask:

- Does this output make logical sense given what was supposed to happen?
- Are the values, shapes, or content actually correct — not just present?
- Is there anything in the logs that is inconsistent, suspicious, or silently wrong even though nothing crashed?
- If this ran multiple times or on multiple cases — is the result coherent across all of them, or does it only look right in the case that was checked?

If output volume is large, still inspect it meaningfully — sample deliberately across cases, not just the first result, and reason about what the full set implies.

**A test only passes when the actual result is verified correct against the success criteria from Step 1 — not when the process completed without throwing an error.**

## Step 4 — Issue Handling

If something is wrong — including subtle wrongness with no crash:

Report:

- What was expected vs. what actually happened
- Where in the logs/output this is visible
- Best hypothesis for the cause

Propose a fix. Apply only after approval. Re-run. Re-evaluate from Step 3 — not just re-check the exit code.

Repeat until the result is genuinely correct, not just non-crashing.

## Step 5 — When to Stop and Escalate (Not Loop Forever)

Stop and report to the user instead of continuing to loop when:

- The same class of issue persists after 2-3 fix attempts with no new hypothesis
- The failure suggests the implementation's actual approach is wrong, not just buggy — this is an architecture question, not a test question
- Fixing the issue would require a decision outside the scope of what was approved (new dependency, behavior change, scope change)
- You are not confident you can define "correct" without more input from the user

When stopping: state exactly what was tried, what the blocker is, and what you need from the user to proceed. Do not keep iterating hoping something changes.

## Step 6 — Final Report

Only after genuine verification:

- What was tested and why that proves the goal
- What was actually observed in output/logs, not just "test passed"
- Any fixes applied during the loop
- Anything borderline that passed but is worth the user's attention
- Explicit confidence statement: how sure are you this is actually correct, and why
