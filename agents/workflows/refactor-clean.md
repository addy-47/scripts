---
description: Refactor that preserves all existing behavior. Cleanup, decoupling, modularisation, dead code removal. Zero logic change. HITL at every stage. CLI-first.
agent: build
---
Read everything in context:
- The scope and goal of this refactor
- Existing docs and architecture as source of truth

**Refactor-clean by definition: behavior in = behavior out. If any logic must change, stop and flag it — that is refactor-arch or a feature, not this.**

---

## Core Principles

- **Strangler Fig** — new structure grows around existing behavior. Old code stays live until new location is verified. Never pull the rug.
- **Zero rewrite rule** — code is moved, clipped, or edited in-place. Never read and rewritten from memory.
- **CLI-first** — every move and clip is a shell command, run by agent or human. No exceptions.
- **200-300 line rule** — any function, block, or component over ~200-300 lines is never rewritten from memory. Mandatory CLI clip. Agent identifies start/end lines, human confirms, then clip executes.
- **Phase boundary = verified invariant** — a phase is complete when a verification command proves behavior is unchanged. Not when the work looks done.
- **HITL is the workflow** — stopping for human verification is not an interruption. It is the process.

---

## Step 1 — Snapshot

Generate `snapshot.md` before touching anything.

**UX Behavior Contracts**
For every user-facing flow in scope:
- Trigger → exact observable outcome
- Edge cases and error states
- Timing or ordering dependencies

**Internal Contracts**
For every file/module in scope:
- What it owns
- What calls it and what it calls
- Inputs → outputs → side effects
- Shared state, IPC, file I/O, network calls

**Verification Commands**
For each contract, the exact CLI command that proves it is still true after any change:
- grep for symbol existence and location
- build commands for compilation
- test commands if applicable
- manual steps where CLI cannot cover it

---

Stop. Present `snapshot.md` for human validation.
Do not proceed until explicitly approved.
If human corrects anything — update and re-present.

---

## Step 2 — Refactor Map

Generate `refactor-map.md`.

Phases are defined by their verification gate, not by their work scope.

### Phase structure:

#### Phase N — [Name]

**Type:**
- `in-place edit` — surgical changes within existing file
- `clip-and-relocate` — function or block moves to new location
- `file-relocate` — whole file moves, minimal edits after
- `skeleton-introduce` — new file created, structure only, no logic yet

**What changes:** exact files, line ranges, operation
**What does NOT change:** explicitly listed

**CLI plan:** exact commands written before execution

**Confidence check:**
- 100% confident clip/move is clean? → agent proceeds
- Any doubt about deps, partial blocks, shared state? → STOP, hand to human with exact line ranges

**Verification gate:**
- exact command + exact expected output
- if output differs → rollback and report

---

Stop. Present `refactor-map.md` and wait for approval before Phase 1 begins.

---

## Step 3 — Execution

Before each phase: state what is starting, restate its verification gate, confirm nothing unapproved is pending.

| Operation | Who | How |
|-----------|-----|-----|
| In-place edit ≤ ~20 lines | Agent | str_replace with exact line numbers |
| Clip block/function to new file | Agent shows lines via sed, human confirms, then clip executes | CLI only |
| Relocate whole file | Agent gives cp/mv command, human runs it | CLI only |
| New file | Agent creates skeleton — signatures and imports only, no logic | Agent only |
| Copy logic into new file | **Forbidden for agent.** Human copies. Agent edits delta only after. | Human always |

After each operation:
- Report what changed (file, lines, operation)
- Run verification gate, show output
- Match → continue. Differ → STOP, report diff, wait for instruction.

After each full phase:
- Run full snapshot verification
- Present phase report
- Wait for explicit go-ahead

---

## Step 4 — Final Verification

- Run every verification command in `snapshot.md`
- Any failure → stop, report, do not declare done
- Manual steps → list explicitly for human
- Present final report: contracts verified or not, full delta summary
- Do not declare complete until human approves
