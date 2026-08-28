# Code Quality Reviewer Prompt Template

Use this template when dispatching a code quality reviewer subagent.

**Purpose:** Verify implementation is well-built (clean, tested, maintainable)

**Only dispatch after spec compliance review passes.**

```
Task tool (general-purpose):
  Use template at requesting-code-review/code-reviewer.md

  DESCRIPTION: [task summary, from implementer's report]
  PLAN_OR_REQUIREMENTS: Task N from [plan-file]
  BASE_SHA: [commit before task]
  HEAD_SHA: [current commit]
```

**In addition to standard code quality concerns, the reviewer should check:**
- Does each file have one clear responsibility with a well-defined interface?
- Are units decomposed so they can be understood and tested independently?
- Is the implementation following the file structure from the plan?
- Did this implementation create new files that are already large, or significantly grow existing files? (Don't flag pre-existing file sizes — focus on what this change contributed.)
- **Did it reimplement something that already exists?** For each new helper / util / service the change adds, confirm there isn't an existing equivalent it should have reused.

**Use prism for these checks** (indexed repos — Grep/Glob blocked there; `prism --help`): `prism outline <file>` to judge single-responsibility, `prism module-map <dir>` to compare structure against the plan, and `prism check "<intent>"` / `prism search "<concept>"` to catch functionality that duplicates something already in the repo. The full prism navigation workflow is in the referenced `code-reviewer.md`.

**Code reviewer returns:** Strengths, Issues (Critical/Important/Minor), Assessment
