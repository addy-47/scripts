---
description: Create a language-agnostic behavioral spec. A spec is a north star for what must be true, never how it's implemented. Detects spec type from the request. Specs live in specs/.
---

A spec is not a plan. A spec is not code. A spec is not an implementation detail.

**The test for every line in a spec:** if this were implemented independently in Go, Python, Node, and Rust, would testing the resulting behavior produce identical results across all four? If a line fails this test, it does not belong in the spec.

---

## Step 1 — Determine the Spec Type

Read the request and classify it. Do not ask the user to specify — infer it, then state your inference.

Common types (not exhaustive — infer the right lane if the request doesn't fit these):
- **Behavior spec** — functional contract: inputs, outputs, states, error conditions, edge cases for a specific capability (e.g. auth, search, payment)
- **Architecture spec** — components, boundaries, data flow, ownership at a conceptual level. No frameworks, no languages, no libraries named.
- **Interface spec** — the shape of a contract between two parts of a system (e.g. what a request/response must contain, conceptually — not the wire format)
- **Data spec** — what entities exist, what they mean, what relationships and constraints hold — not schemas or column types

State the inferred type before writing. If genuinely ambiguous, ask one question — otherwise proceed.

**Stay strictly in that lane.** An auth behavior-spec does not describe database schema. An architecture-spec does not describe error message wording. If the request is trying to cover multiple concerns, split it into multiple specs and say so.

---

## Step 2 — Write the Spec

### Rules
- No code. No function names, class names, framework references, library names, or language-specific constructs.
- No implementation detail — never "how," always "what must be true"
- One concept per spec. If it's getting bloated, it's covering more than one concept — split it.
- Written for a reader with basic technical literacy, not a developer mindset. A product manager or project manager should be able to read this and understand exactly what correct looks like, without needing to know how it's built.
- Concrete and testable — vague statements like "should be secure" are not acceptable. State the actual observable condition: "a request without a valid token must be rejected with an unauthorized result."

### Structure (adapt to spec type, but always include)

**Name & Concept**
One sentence — what single concept this spec governs.

**Purpose**
Why this exists, in plain terms. What problem it solves for the user or system.

**Must Be True**
The core contract. Every statement here must be independently verifiable regardless of implementation language.
- Numbered, concrete, testable statements
- Cover the expected/happy path first, then edge cases, then failure conditions

**Must Not Happen**
Explicit negative constraints — things that would violate this spec even if they weren't caught by the "must be true" list.

**Out of Scope**
What this spec deliberately does not cover — especially anything a reader might assume is included. Point to the sibling spec if one exists or should exist.

**Open Questions**
Anything genuinely undecided that needs a decision before this spec is considered final.

---

## Step 3 — Save

Save to `specs/[name]-spec.md` using a clear, concept-scoped filename (e.g. `specs/auth-spec.md`, `specs/architecture-spec.md`).

Present the spec. Wait for approval before considering it final.

Specs are living documents — if requirements change, the spec is updated first, and everything built against it is re-evaluated against the update. The spec is never quietly out of sync with what was actually built.