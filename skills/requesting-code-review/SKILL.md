---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
---

# Requesting Code Review

Dispatch a code reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation, never your session's history: that keeps it on the work product, and keeps your own context for the work.

**Core principle:** Review early, review often.

## When to Request Review

**Always**, including when the change seems simple:
- After each task in subagent-driven development (executing-plans: after each task or at natural checkpoints)
- After completing a major feature
- Before merge to main

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing a complex bug

## The automated PR reviewer — at the FIRST push, not after green

**Open the PR as a draft at the first push and request the automated reviewer then**,
so its findings arrive alongside the first CI run instead of one cycle after green.
GitHub with the Codex connector: comment `@codex review` on the draft, then confirm it
fired (👀 reaction, then a "Codex Review Summary" comment naming the commit).
- A draft is not reviewed on its own; Codex reviews on "PR opened" (non-draft) or
  "Draft marked ready". Treat the comment trigger as unconfirmed until you see it fire.
- Marking the draft ready later re-reviews the final diff on its own.

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

Run it after code review, not in parallel: code-review fixes resolve some maintainability concerns and create others. Reviewer evaluates structural consistency, public/internal API discipline, naming consistency, dead code / debt markers, Comments in the wrong home (per `test-driven-development/clean-code.md`), unrecorded decisions, cross-component drift.

**Additional placeholder for maintainability-reviewer.md:**
- `{QUALITY_BAR}` - The project's quality-bar text, lifted verbatim (the spec's quality section, or the repo's coding rules such as `.cursor/rules/`)

**4. Act on feedback.** Both reviewers use one scale:
- Critical: fix immediately; blocks merge
- Important: fix before proceeding
- Minor: note for follow-up (a Jira ticket when it is real debt)
- Reviewer wrong? Push back with technical reasoning, show the code or tests that prove it works, or ask for clarification (`swisper-superpowers:receiving-code-review`)

## Example

```
[Just completed Task 2: Add verification function]

You: Let me request code review before proceeding.

BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)

[Dispatch code reviewer subagent]
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
  PLAN_OR_REQUIREMENTS: Task 2 from plans/swisper/2026-10-05-deployment-plan.md (Swisper_Documentation)
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

## Templates

- `requesting-code-review/code-reviewer.md` — code review (plan alignment, ACs, contracts, quality, architecture, production readiness)
- `requesting-code-review/maintainability-reviewer.md` — maintainability review (structural consistency, API discipline, naming, debt, decision records, cross-component drift)
