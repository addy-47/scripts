---
description: Generate a structured handoff document at the end of a thread or before starting a new one on the same project. Output feeds directly into the next thread opener.
agent: plan
---
Read everything in context — the full thread, implementation plan, any docs provided.

Do NOT summarize loosely. Every section must be precise enough that a new thread with zero prior context can continue without ambiguity.

## Output: handoff.md

### Project State
One paragraph. What this project is, where it currently stands, what is working and verified.

### Completed This Thread
For each phase or task completed:
- What was done
- Validation status (passed / partial / skipped — with reason)
- Any fixes applied

### In Progress
- What was started but not completed
- Exact stopping point
- What the next step is

### Pending / Not Started
- What remains in the current implementation plan
- In order

### Decisions Made
For each architectural or technical decision made this thread:
- What was decided
- Why
- Any tradeoffs accepted

### Open Questions
Anything unresolved, flagged, or deferred that the next thread needs to be aware of.

### Warnings & Known Issues
- Anything flagged during this thread that was not fixed
- Any risks or bugs identified but deferred

### How to Resume
Exact thread opener for the next session — ready to copy-paste:

```
CONTEXT:
[current state in one line]
[source of truth files]
[what is done]
[current task]
PLAN: [plan file]
TASK: [exact next step]
```

Present handoff.md and wait for review before closing the thread.
Do not summarize — capture precisely.
