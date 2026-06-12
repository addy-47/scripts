# SOURCE_MAP.md — Agent Directory File Origins

## agents/rules/

| File | Source |
|------|--------|
| `code-style-guide.md` | `projects/scripts/rules/code-style-guide.md` |
| `finetune.md` | `projects/scripts/rules/finetune.md` |
| `global-rules.md` | `projects/scripts/rules/global-rules.md` |
| `system-architect.md` | `projects/scripts/rules/system-architect.md` |

## agents/workflows/

| File | Source | Notes |
|------|--------|-------|
| `ask-classifier.md` | `.gemini/config/global_workflows/ask.md` | Question-classification workflow (gemini) |
| `create-plan.md` | `.config/opencode/commands/create-plan.md` | Identical in opencode commands and gemini global_workflows |
| `handoff.md` | `.config/opencode/commands/handoff.md` | Identical in opencode commands and gemini global_workflows |
| `hotfix.md` | `.config/opencode/commands/hotfix.md` | Identical in opencode commands and gemini global_workflows |
| `modify-plan.md` | `.config/opencode/commands/modify-plan.md` | Identical in opencode commands and gemini global_workflows |
| `rca.md` | `.config/opencode/commands/rca.md` | Identical body to gemini rca.md |
| `refactor-arch.md` | `.gemini/config/global_workflows/refactor-arch.md` | Gemini version has Step 0 (logic snapshot) — more complete |
| `refactor-clean.md` | `.config/opencode/commands/refactor-clean.md` | Identical in opencode commands and gemini global_workflows |
| `report.md` | `.config/opencode/commands/report.md` | Identical in opencode commands and gemini global_workflows |
| `review.md` | `.config/opencode/agents/review.md` | opencode version has more frontmatter detail |
| `test.md` | `.config/opencode/commands/test.md` | Virtually identical to gemini test-plan.md |

## agents/primary_agents/

| File | Source |
|------|--------|
| `ask.md` | `.config/opencode/agents/ask.md` (mode: primary) |
| `build.md` | `.config/opencode/agents/build.md` (mode: primary) |
| `plan.md` | `.config/opencode/agents/plan.md` (mode: primary) |

## agents/sub_agents/

| File | Source |
|------|--------|
| `rca.md` | `.config/opencode/agents/rca.md` (mode: subagent) |
| `research.md` | `.config/opencode/agents/research.md` (mode: subagent) |
| `review.md` | `.config/opencode/agents/review.md` (mode: subagent) |
| `validate.md` | `.config/opencode/agents/validate.md` (mode: subagent) |
| `skills/ui-ux-pro-max/SKILL.md` | `.config/opencode/skills/ui-ux-pro-max/SKILL.md` |

## What was removed (deduplication)

The following duplicates were removed during cleanup:

- `rules/ask.md`, `rules/build.md`, `rules/plan.md` — duplicated `primary_agents/`
- `rules/rca.md`, `rules/research.md`, `rules/review.md`, `rules/validate.md` — duplicated `sub_agents/`
- `workflows/ask-agent.md` — duplicated `primary_agents/ask.md`
- `workflows/refactor.md` — outdated, only existed in old scripts/workflows/
- `workflows/provide-analysis-report.md` — outdated, only existed in old scripts/workflows/
- `workflows/validate.md` — duplicated `sub_agents/validate.md`
