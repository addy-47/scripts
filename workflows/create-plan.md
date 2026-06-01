---
description: Create a detailed "how" implementation plan from the architecture plan provided in context. Use only at the start of a new thread before any implementation begins.
---

---

Read everything in context:

- ROLE defines your constraints and behavior
- CONTEXT tells you current project state and source of truth
- PLAN is the architecture/"what" plan — your primary input
- TASK defines the scope

Your job is to produce a detailed "how" implementation plan.

## Rules

- Plan only. No code. No implementation.
- No assumptions — if something is not in the provided docs or plan, flag it explicitly.
- If anything is ambiguous and would block planning, stop and ask before continuing.
- Do not invent architecture, infer file structures, or guess at behavior.

## Output

### Implementation Plan: [Task/Phase Name]

**Objective**
One sentence. What this plan delivers when complete.

**Source of Truth Used**
List every doc/file you referenced from context to build this plan.

**Assumptions Made**
If none: state "None". If any: flag each one explicitly — do not bury them.

---

**Phases**

#### Phase N — [Name]

**Goal:** What this phase achieves in isolation.

Steps:

1. [File or system] — [exactly what changes and why]
2. ...

Validation before proceeding to Phase N+1:

- [ ] [specific check: build / test / manual / lint]
- [ ] ...

---

_(repeat for each phase)_

---

**Ordering Constraints**

- Dependencies between phases that cannot be parallelized
- Anything that must be true before a later phase can start

**Risks & Regressions**

- What could break and in which system
- Any step with high uncertainty — flag with ⚠️

**Out of Scope**

- Explicitly list what this plan does NOT touch

---

Do not begin implementation.
Present this plan to user , use the **Ordering Constraints** , **Risks & Regressions** and **Out of Scope** naturally as a extension of the report to user , they are not strict ouput formats they are structure fo your thought process
