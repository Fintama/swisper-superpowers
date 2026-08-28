---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
---

# Requesting Code Review

Dispatch a code reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation — never your session's history. This keeps the reviewer focused on the work product, not your thought process, and preserves your own context for continued work.

**Core principle:** Review early, review often.

## When to Request Review

**Mandatory:**
- After each task in subagent-driven development
- After completing major feature
- Before merge to main

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing complex bug

## How to Request

**1. Get git SHAs:**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main, or the feature branch's HEAD when the sub-branch was created
HEAD_SHA=$(git rev-parse HEAD)
```

**2. Dispatch code reviewer subagent (template at `code-reviewer.md`):**

Use Task tool with `general-purpose` type. Reviewer evaluates plan alignment, AC coverage with AC-named tests, contract integrity, code quality, architecture, production readiness, frontend Playwright if applicable.

**Placeholders for code-reviewer.md:**
- `{DESCRIPTION}` - Brief summary of what you built
- `{PLAN_OR_REQUIREMENTS}` - What it should do
- `{BASE_SHA}` - Starting commit
- `{HEAD_SHA}` - Ending commit

**3. After code review feedback is applied, dispatch maintainability reviewer subagent (template at `maintainability-reviewer.md`):**

Maintainability review runs in sequence after code review (NOT in parallel — it benefits from seeing post-code-review state). Reviewer evaluates structural consistency, public/internal API discipline, naming consistency, dead code / debt markers, ADR debt, cross-component drift.

**Additional placeholders for maintainability-reviewer.md:**
- `{QUALITY_BAR}` - The project's quality-bar text, lifted verbatim (e.g., the Polis-bar §3.1 + concrete enforcement §3.3 from a Foundation-on-Polis spec)

**4. Act on feedback:**
- Fix Critical / High issues immediately (blocks merge)
- Fix Important / Medium issues before proceeding
- Note Minor / Low issues for follow-up
- Push back if reviewer is wrong (with technical reasoning per `superpowers:receiving-code-review`)

## Example

```
[Just completed Task 2: Add verification function]

You: Let me request code review before proceeding.

BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)

[Dispatch code reviewer subagent]
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
  PLAN_OR_REQUIREMENTS: Task 2 from docs/superpowers/plans/deployment-plan.md
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Important: Missing progress indicators
    Minor: Magic number (100) for reporting interval
  Assessment: Ready to proceed

You: [Fix progress indicators]
[Continue to Task 3]
```

## Integration with Workflows

**Subagent-Driven Development:**
- Review after EACH task
- Catch issues before they compound
- Fix before moving to next task

**Executing Plans:**
- Review after each task or at natural checkpoints
- Get feedback, apply, continue

**Ad-Hoc Development:**
- Review before merge
- Review when stuck

## Red Flags

**Never:**
- Skip review because "it's simple"
- Ignore Critical issues
- Proceed with unfixed Important issues
- Argue with valid technical feedback

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification

See templates:
- `requesting-code-review/code-reviewer.md` — code review (plan alignment, ACs, contracts, quality, architecture, production readiness)
- `requesting-code-review/maintainability-reviewer.md` — maintainability review (structural consistency, API discipline, naming, debt, ADR debt, cross-component drift)
