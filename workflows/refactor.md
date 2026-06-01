---
description: Large-scale refactor workflow , Type 1 : and type 2 - Preserves all business logic and behavioral contracts. HITL at every stage. CLI-first. No rewrites. Use at the start of a refactor thread.
---

Read everything in context:
- Architecture plan and any existing docs are source of truth
- Refactor by definition means zero business logic change
- If business logic must change, stop and flag it — that is a feature, not a refactor

---

## Core Principles

- **Strangler Fig pattern** — new structure grows around existing behavior, never replacing it until the old is fully verified dead
- **Zero rewrite rule** — code is moved, clipped, or edited in-place. It is never read and rewritten from memory.
- **CLI-first** — all moves and clips are expressed as shell commands. Agent runs them or human runs them. No exceptions.
- **HITL is not optional** — stopping for human verification is the workflow, not an interruption to it
- **Phase boundary = verified invariant** — a phase is not done when work is done. It is done when the verification command proves nothing changed behaviorally.

---

## Step 1 — Snapshot (before touching anything)

Generate `snapshot.md` in the workspace.

### snapshot.md must contain:

**UX Behavior Contracts**
For every user-facing flow in scope:
- Trigger → exact observable outcome
- Edge cases and error states
- Any timing or ordering dependencies

**Internal Contracts**
For every module/file in scope:
- What it owns
- What calls it and what it calls
- Inputs → outputs → side effects
- Any shared state, IPC, file I/O, network calls

**Verification Commands**
For each contract above, provide the CLI command that can verify it is still true after any change:
- `grep` for symbol existence and location
- `cargo check` / `pnpm build` for compilation
- specific test commands if applicable
- manual steps where CLI cannot cover it

---

Stop here. Present `snapshot.md` to human for validation.
Do NOT proceed until snapshot is explicitly approved.
If human corrects anything, update snapshot and re-present.

---

## Step 2 — Refactor Map

Generate `refactor-map.md` in the workspace.

Each phase must be defined by its **verification gate**, not by its work scope.

### Phase structure:

#### Phase N — [Name]

**Type:** (choose one)
- `in-place edit` — surgical changes within existing file
- `clip-and-relocate` — function or block moves to new location
- `file-relocate` — whole file moves, minimal edits after
- `skeleton-introduce` — new file created with structure only, no logic copied in yet

**What changes:**
- Exact files
- Exact line ranges where known
- What the operation is (edit / clip / move / new skeleton)

**What does NOT change:**
- Explicitly list

**CLI plan:**
Write the exact commands before approval. No vague descriptions.
```bash
# example — verify clip before cutting
sed -n '200,500p' src/old/module.rs

# example — relocate file
cp src/old/module.rs src/new/module.rs

# example — surgical edit
# lines 1-5 replace import path — agent applies via str_replace
```

**Confidence check:**
- 100% confident this clip/move is clean? → agent proceeds with CLI
- Any doubt about deps, partial blocks, shared state, lifetimes? → STOP, hand operation to human with exact line ranges

**Verification gate:**
```bash
# exact command(s) to run after this phase
# exact expected output
# if output differs → rollback and report
```

---

Stop after presenting `refactor-map.md`. Wait for approval before Phase 1 begins.

---

## Step 3 — Execution (per phase, strictly sequential)

Before each phase:
- State which phase is starting
- Restate its verification gate
- Confirm no unapproved changes are pending

### Operation rules:

| Operation | Who executes | How |
|-----------|-------------|-----|
| Surgical in-place edit (surgical, ≤ ~20 lines) | Agent | `str_replace` with exact line numbers |
| Clip function/block to new file | Agent identifies lines, runs `sed -n 'X,Yp'` to show human exactly what will move, human confirms, then agent clips or human does it | CLI only |
| Relocate whole file | Agent gives `cp`/`mv` command → human runs it | CLI only |
| New file | Agent creates skeleton — imports, signatures, no logic | Agent only |
| Copy logic into new file | **Forbidden for agent** — human copies, agent edits only the delta after | Human always |

### After each operation:
- Report exactly what changed (file, lines, operation)
- Run verification gate command
- Show output
- If output matches expected → proceed to next operation
- If output differs → STOP. Do not continue. Report diff. Wait for instruction.

### After each full phase:
- Run full snapshot verification (all commands from `snapshot.md`)
- Present phase completion report
- Wait for explicit go-ahead to next phase

---

## Step 4 — Final Verification

After all phases complete:

- Run every verification command in `snapshot.md` in sequence
- For any that fail: stop, report, do not declare done
- For manual steps: list them explicitly for human to verify
- Present final report:
  - All contracts verified ✅ or ⚠️ with details
  - Full delta summary from `delta-log.md`
  - Anything deferred or handed to human

Do not declare the refactor complete until human gives final approval.