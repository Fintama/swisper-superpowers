# Code Quality Reviewer Prompt Template

Use this template when dispatching the per-task code-quality reviewer. It is the only per-task review (see SKILL.md "Match the review to the task").

```
Task tool (general-purpose):
  Use template at requesting-code-review/code-reviewer.md

  DESCRIPTION: [task summary, from implementer's report — include its senior-engineer pass note, as context]
  PLAN_OR_REQUIREMENTS: Task N from [plan-file]
  BASE_SHA: [commit before task]
  HEAD_SHA: [current commit]
  TIER: [declarative | logic/contract | user-visible — assigned at extraction]
  GATES: [the ledger line recorded for HEAD_SHA — read it; don't re-run the suite]
```

**In addition to standard code quality concerns, the reviewer checks:**
- Does each file have one clear responsibility with a well-defined interface?
- Are units decomposed so they can be understood and tested independently?
- Does the implementation follow the file structure from the plan?
- Did this change create files that are already large, or significantly grow existing ones? (Judge what this change contributed, not pre-existing sizes.)
- **Comments follow `test-driven-development/clean-code.md`.** A comment in the wrong home is a Minor finding; Important when such comments dominate a file the task added. A `# comment-ok: <reason>` is judged on its reason.
- **Did it reimplement something that already exists?** For each new helper / util / service, confirm there isn't an existing equivalent it should have reused.

**Tests: check the list, not the count** (`test-driven-development` R1–R7):
- **Against the plan:** every test the plan names for this task exists, at its altitude. A missing AC test is Important.
- **Untraced or mechanism-only tests are Important findings:** a title with no AC / INV / FM id; a unit test re-proving what a boundary test already proves; mock-call counts, constants, `typeof`, source greps, "stays removed". Run `trace-check.sh <BASE_SHA>..<HEAD_SHA>` and cite its UNTRACED lines.
- **Disposition is *strengthen* or *delete*;** "keep" is not available for an untraced test. A gap you find (or a mutant that survives) goes back as "strengthen `<test>` so it fails on X". Request a new test only when no test sits at the right altitude, and name the id it proves.
- **At logic/contract tier, run the mutation sweep** on the property the task protects, in your own worktree checked out at HEAD_SHA (never in the implementer's tree). Report each survivor as "strengthen `<test>` so this mutant dies".
- **Never praise a count.** "18 tests" is not a strength; "each AC proved at the route" is.

**Use prism for these checks** (indexed repos; Grep/Glob are blocked there; `prism --help`): `prism outline <file>` to judge single responsibility, `prism module-map <dir>` to compare structure against the plan, and `prism check "<intent>"` / `prism search "<concept>"` to catch functionality that duplicates something already in the repo. The full prism workflow is in `code-reviewer.md`.

**Code reviewer returns:** Strengths, Issues (Critical/Important/Minor), Assessment
