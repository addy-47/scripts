---
description: Refactor that intentionally replaces existing architecture or logic. New structure, new patterns, new data flow. Old behavior is deliberately superseded. HITL at every stage. CLI-first.
---

Read everything in context:
- The scope and goal of this refactor
- What the current architecture is
- What the target architecture is

**Refactor-arch means: old behavior is intentionally replaced by new behavior. The goal is not to preserve — it is to migrate correctly with no uncontrolled regressions.**

If the target architecture is not clearly defined in context — stop and ask before proceeding. You cannot plan a migration without knowing the destination.

---

## Core Principles

- **Strangler Fig** — new architecture grows alongside old. Old is not removed until new is verified covering it completely. Both coexist during migration. Never cut the old before the new is proven.
- **Zero rewrite rule** — code is moved, clipped, or edited in-place. Never read and rewritten from memory.
- **CLI-first** — every move and clip is a shell command, run by agent or human. No exceptions.
- **200-300 line rule** — any function, block, or component over ~200-300 lines is never rewritten from memory. Mandatory CLI clip. Agent identifies start/end lines, human confirms, then clip executes.
- **Phase boundary = verified migration step** — a phase is complete when a verification command proves the new architecture is correctly handling what it is supposed to handle at this stage. Not when the work looks done.
- **HITL is the workflow** — stopping for human verification is not an interruption. It is the process.

---

## Step 0 - Logic and functionality snapshot

Generate `logic-snapshot.md` before touching anything.

This is the file that is agnostic of language , framework and stack. This is the blueprint of what needs to be implemented.
Think like if user was telling you to implement something how would they exaplin that , that must be recorded in thsi in plain english ,no jargon and no implementation details. Only what the system should do.
for example - "when user clicks on X -> Y should happen -> Z should run in bacgorund -> R should be presented in ui"  like that , clearly and concisely.

this is the file that remains as ground truth of the codebase and a feature.
creating this file should be considered as the most important thing in the entire refactor process and `state-snapshot.md` will be a byproduct of this 

this is the file you must use to validate whether refactored phase or logic passes or not. This is the holy grail of the entire codebase, if you do not have this file the entire refactor process would be a waste of time and you will end up creating bugs instead of fixing them.

Stop. Present `logic-snapshot.md` for human validation.
Do not proceed until explicitly approved.
If human corrects anything — update and re-present.

---

## Step 1 — Before-State Snapshot

Generate `state-snapshot.md` after use validates `logic-snapshot.md`.

This is the reference for what existed — not a lock, but a map of what must be deliberately and completely replaced.

**Current Behavior Inventory**
For every flow, feature, and data path in scope:
- What it does now
- How it does it (current pattern, current data flow)
- What depends on it

**Current Internal Contracts**
For every file/module in scope:
- What it owns
- What calls it and what it calls
- Inputs → outputs → side effects
- Shared state, IPC, file I/O, network calls

**Migration Checklist**
For each item above, a corresponding entry:
- What replaces it in the new architecture
- Status: `pending` / `in progress` / `migrated` / `dead and removed`

This checklist is updated at every phase. Nothing is done until every item is `migrated` or `dead and removed`.

---

## Step 2 — Target Architecture Spec

Before planning phases, define the destination clearly.

Document in `refactor-map.md`:

**Target State**
- New structure, new patterns, new data flow
- What the new architecture owns and how it is organised
- What the old architecture's responsibilities map to in the new one

**Coexistence Strategy**
- How old and new will live alongside each other during migration
- How to prevent old and new from conflicting mid-migration
- What the boundary looks like at each phase (what is old, what is new, what is the seam)

**Exit Criteria**
- The exact conditions that mean the old architecture is fully dead and safe to remove
- How each condition is verified

---

Stop. Present target spec for human approval before planning phases.

---

## Step 3 — Migration Map

Plan phases in `refactor-map.md` under the target spec.

Phases are defined by their verification gate — what is provably migrated after this phase, not what work gets done.

### Phase structure:

#### Phase N — [Name]

**Migration goal:** what moves from old to new in this phase

**Coexistence state after this phase:**
- What is still old
- What is now new
- Where the seam is

**Type:**
- `skeleton-introduce` — new structure created alongside old, no migration yet
- `clip-and-relocate` — logic moves to new location via CLI clip
- `in-place edit` — surgical changes within existing file
- `cutover` — old removed, new takes full ownership
- `file-relocate` — whole file moves, edits after

**What does NOT change this phase:** explicitly listed

**CLI plan:** exact commands written before execution
```bash
# verify clip before cutting
sed -n '200,500p' src/old/store.ts
# introduce new file skeleton
# agent creates — signatures only, no logic yet
# cutover — remove old after new is verified
rm src/old/store.ts
```

**Confidence check:**
- 100% confident this migration step is clean? → agent proceeds
- Any doubt about deps, partial coverage, shared state? → STOP, hand to human with exact details

**Verification gate:**
```bash
# exact command + exact expected output
# proves new architecture is correctly handling this phase's scope
# if output differs → rollback and report
```

---

Stop. Present full `refactor-map.md` and wait for approval before Phase 1 begins.

---

## Step 4 — Execution

Before each phase: state what is starting, restate its verification gate, confirm nothing unapproved is pending.

| Operation | Who | How |
|-----------|-----|-----|
| In-place edit ≤ ~20 lines | Agent | `str_replace` with exact line numbers |
| Clip block/function to new file | Agent shows lines via `sed -n 'X,Yp'`, human confirms, then clip executes | CLI only |
| Relocate whole file | Agent gives `cp`/`mv` command, human runs it | CLI only |
| New file | Agent creates skeleton — signatures and imports only, no logic | Agent only |
| Copy logic into new file | **Forbidden for agent.** Human copies. Agent edits delta only after. | Human always |
| Remove old file/code | Only after verification gate confirms new is fully covering it. Agent proposes `rm` command, human runs it. | Human always |

After each operation:
- Report what changed (file, lines, operation)
- Run verification gate, show output
- Update migration checklist in `state-snapshot.md`
- Match → continue. Differ → STOP, report diff, wait for instruction.

After each full phase:
- Run full verification gate for this phase
- Update migration checklist — mark items migrated or dead
- Present phase report: what moved, what coexists, what remains old
- Wait for explicit go-ahead

**Never remove old code speculatively.** Old is only removed when:
1. New is verified covering it completely
2. Verification gate passes
3. Human explicitly approves removal

---

## Step 5 — Final Verification

- Run all verification gates from every phase in sequence
- Confirm migration checklist: every item is `migrated` or `dead and removed` — nothing left as `pending`
- Any failure → stop, report, do not declare done
- Manual steps → list explicitly for human
- Present final report:
  - Migration checklist complete ✅ or items still pending ⚠️
  - Full delta summary
  - Anything deferred or handed to human
- Do not declare complete until human approves
