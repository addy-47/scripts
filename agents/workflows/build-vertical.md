---
description: Vertical-slice development mindset for building new systems. Build thin end-to-end capability across every layer before deepening any single layer. Use when starting a new project or major new capability, alongside /create-plan.
---

## Core Objective

Continuous delivery of working end-to-end capability — not completion of isolated layers.

Every milestone must produce a demonstrable flow that traverses the full architecture, even if every layer is minimal. A working full pipeline beats a perfect isolated piece every time.

---

## Before Implementing Anything

Identify every layer this capability must pass through, start to finish. Plan the thinnest possible version of each layer — not the best version, the smallest one that lets the signal pass through to the next layer.

Never fully build one layer while adjacent layers don't exist yet. If a layer isn't ready to receive input from the previous one, that's a sign the current layer is going too deep too early.

---

## Decision Check (Before Every Task)

Before implementing, answer:

- Does this move toward a working end-to-end capability, or does it deepen one layer in isolation?
- Does it preserve existing contracts between layers, or does it require changing how layers talk to each other?
- Does this belong in an existing layer, or is it quietly becoming a new layer, manager, or coordinator?
- Is there a simpler version that still proves the capability works?

If the honest answer to any of these is unfavorable — stop and say so before writing code. Don't proceed and rationalize it after.

---

## Build Order

1. Implement the smallest functional version of each layer needed for this capability
2. Integrate — connect it to the adjacent layers
3. Validate the full path works end to end
4. Only then: expand within a layer (better algorithm, more providers, caching, retries, richer output)
5. Only then: optimize

Performance work never starts before the capability is integrated and validated. Don't optimize something that isn't wired into the pipeline yet.

---

## Layer Contracts Are Load-Bearing

Once a layer exposes an interface to another layer, that interface is stable. Layers depend on each other's contracts, never on each other's internals.

If new functionality seems to require reaching into another layer's internals — that's the signal to extend that layer's contract, not bypass it.

Changing a contract, the system topology, or the ownership boundaries between layers is an architecture change, not a feature. If a feature seems to require this — stop, and flag it as an architecture decision, not proceed as if it's part of the current task.

---

## Prefer Additive

New capability extends what exists rather than replacing it. Another provider, another backend, another rule — yes. Rewriting the pipeline or replacing the orchestration model to fit one new feature — no, unless there's an explicit architectural reason that's been surfaced and approved first.

---

## What Good Looks Like

- Every milestone has something that actually runs end to end, even if minimal
- No layer is significantly more mature than the layers around it
- Contracts between layers haven't changed since the architecture was set
- Depth gets added to layers over time, not all at once, and not before the pipeline as a whole works

## What to Watch For

- A layer growing far beyond what the current milestone needs while adjacent layers are still stubs
- A "temporary" bypass of a layer boundary that becomes permanent
- Optimization work on something not yet proven to work end to end
- A new abstraction appearing because it was convenient, not because an existing layer genuinely couldn't do the job

If you notice any of these mid-task — stop and flag it rather than finishing the task as-is.
