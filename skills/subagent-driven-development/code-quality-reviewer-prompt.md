# Code Quality Reviewer Prompt Template

Use this template when dispatching a code quality reviewer subagent.

**Purpose:** Verify implementation is well-built (clean, tested, maintainable)

**This is the only per-task review** (the spec-compliance review was cut — see SKILL.md "Match the review to the task").

```
Task tool (general-purpose):
  Use template at requesting-code-review/code-reviewer.md

  DESCRIPTION: [task summary, from implementer's report — include its senior-engineer pass note, as context]
  PLAN_OR_REQUIREMENTS: Task N from [plan-file]
  BASE_SHA: [commit before task]
  HEAD_SHA: [current commit]
```

**In addition to standard code quality concerns, the reviewer should check:**
- Does each file have one clear responsibility with a well-defined interface?
- Are units decomposed so they can be understood and tested independently?
- Is the implementation following the file structure from the plan?
- Did this implementation create new files that are already large, or significantly grow existing files? (Don't flag pre-existing file sizes — focus on what this change contributed.)
- **Comments follow `test-driven-development/clean-code.md`?** Docstring = contract, comment = non-obvious why. History, spec ids as explanation, line numbers, 🔴/⚠️ and internal ids in error messages are Minor findings each — Important when they dominate a file the task added.
- **Did it reimplement something that already exists?** For each new helper / util / service the change adds, confirm there isn't an existing equivalent it should have reused.

**Tests — check the list, not the count** (`test-driven-development` R1–R7):
- **Against the plan:** every test the plan names for this task exists, at its altitude. A missing AC test is Important.
- **Untraced or mechanism-only tests are Important findings:** a title with no AC / INV / FM id; a unit test re-proving what a boundary test already proves; mock-call counts, constants, `typeof`, source greps, "stays removed". Run `trace-check.sh <BASE_SHA>..<HEAD_SHA>` and cite its UNTRACED lines.
- **Disposition is *strengthen* or *delete*** — "keep" is not available for an untraced test. A gap you find (or a mutant that survives) goes back as "strengthen `<test>` so it fails on X". Request a new test only when no test sits at the right altitude, and name the id it proves.
- **Never praise a count.** "18 tests" is not a strength; "each AC proved at the route" is.

**Use prism for these checks** (indexed repos — Grep/Glob blocked there; `prism --help`): `prism outline <file>` to judge single-responsibility, `prism module-map <dir>` to compare structure against the plan, and `prism check "<intent>"` / `prism search "<concept>"` to catch functionality that duplicates something already in the repo. The full prism navigation workflow is in the referenced `code-reviewer.md`.

**Code reviewer returns:** Strengths, Issues (Critical/Important/Minor), Assessment
