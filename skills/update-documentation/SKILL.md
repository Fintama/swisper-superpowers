---
name: update-documentation
description: Use before opening a pull request, or finishing a branch, in a repo that has an architecture/ documentation site - and whenever impact.py or make architecture-gates names a page, or a change touches a contract, data model, flow, permission, config default or user-visible behaviour that a page may describe.
---

# Updating the documentation

## Overview

The architecture site (`architecture/` in the product repo) must say what the code does **after your PR merges**. Most PRs change none of what it says, so the work is a **decision per page**, then only the edits that decision demands, then proof.

**Applies when** `[ -f architecture/tools/impact.py ]` at the repo root. No site → skip this skill.

**A bug fix is a reason to write no new prose. It is never a reason to skip the re-read or the verify stamp.** Heiko's rule ("only when relevant: not when this is a code change or a bug fix", 2026-10-04) is about *content*.

## 1 · Find the candidates — a lead, not the verdict

```bash
cd architecture/tools && uv run python impact.py origin/<base>..HEAD   # base = the PR's base branch
make architecture-gates BASE=origin/<base>                              # completeness + staleness
```

- **Exit 0 proves nothing.** The gates run in WARN mode until PR-10. Read the report.
- **impact.py sees only `covers:`.** It cannot see a page that *states* something your diff changed in a file the page does not cover. Measured: lowering `DELEGATION_BUDGET_SECONDS` in `core/config.py` → impact.py "0 pages", while E.2 says "90 seconds by default". So also grep the pages for every name and value the diff changes (setting, default, route, field, table, status): `git grep -n -e '<name>' -e '<old value>' -- architecture/`.

## 2 · Decide, per page

| Verdict | When | Do |
|---|---|---|
| **UPDATE** | The PR changes something a reader relies on: a contract or API, the data model, a flow or sequence, ownership, a permission or security property, configuration, a flag or a default, a user-visible behaviour, a new concept or component | Edit the text, table or hand-drawn diagram. Re-read the rest of the page. Then verify. |
| **RE-VERIFY ONLY** | Covered code changed and every statement is still true. The usual case for bug fixes, refactors, renames inside a unit, performance work, test-only changes | Re-read **every** claim against HEAD — prose, tables, captions, the rules grid's `src:` lines and the `::: dev` block's `file:line` anchors (refactors move lines; fix any that moved). Leave `FINDINGS.md` evidence alone: it is pinned to `first_seen`. Then verify. |
| **NEW PAGE** | A genuinely new component or concept the outline lacks | Write it to the standard (§3). A new route, table or field is **not** a new page: add it to the `covers:` of the page that explains it. |
| **NOTHING** | No page covers the change, no page states anything it changed (grep), no new inventory item | Say so in the PR, with the evidence. |

**Verify** = `make architecture-verify PAGE=<id>`, or, skipping the npm and model fetch: `cd architecture/tools && uv run python gates.py verify <id>`. It means "I re-read it at HEAD and it is true". Run it **after** your last code commit, then commit the page.

**Findings** (`architecture/FINDINGS.md`):
- PR **fixes** a finding → `status: fixed`, `fixed_by: #<PR>` (open the PR, then push that one line), append "done: `file:line` at `<sha>`" to `fix:`. Keep the entry, keep it in the page's `findings:` (it renders struck through), drop it from the page's `assessment:` strip.
- PR **reveals** a flaw → add a finding in the page's chapter range: category, severity, evidence (`file:line`), consequence, impact, fix, cost. `suspected` until a second read.
- "New items no page covers yet" → add each to the `covers:` of the page that explains it (the completeness gate counts it).
- A finding that will be worked later, or any technical debt the PR leaves behind → a ticket in the backlog tracker (Fintama: Jira, project SA). Put the finding number (F-xxx) in the ticket, and the ticket key in the finding's `fix:` line. There are no TDR documents.

**Decisions** (there are no ADRs; Heiko, 2026-10-04): if the PR makes a non-obvious choice between alternatives, record it on the page it shapes, under a `## Why it is like this` heading. Use one entry per decision: the date, the decision in one sentence, the alternatives rejected and why, and a link to the spec (Swisper_Documentation `specs/<product>/…`). A changed decision edits its entry; it does not append a contradicting one. Specs and plans themselves never go in the product repo.

## Rationalizations (from the baseline runs)

| Excuse | Reality |
|---|---|
| "Bug fix — Heiko said no docs" | No new prose. The re-read and the stamp are still owed: covered code changed, and the page's badge now counts changes since verified. |
| "The gate is WARN-only, I'll record the re-read in the PR text" | PR text is gone after merge; the page keeps showing drift, and PR-10 turns it red on someone else's PR. Stamp it. |
| "Verify edits the page and needs the deps install" | Editing the page is the point. `uv run python gates.py verify <id>` skips the npm and model fetch. |
| "Bump `verified` now, docs in a follow-up PR" | A stamp on a false page is the worst state: it looks checked. Fix it in this PR. |
| "impact.py says 0 pages, docs done" | It only reads `covers:`. Grep the pages for what you changed. |
| "A refactor has nothing to document" | Usually true for the prose. The `::: dev` anchors are claims at `verified.sha`; moved lines make them false. |
| "Lines moved, so I re-anchor the findings' evidence too" | Evidence is `file:line` **at `first_seen`**. Re-anchoring it to HEAD breaks the record. Only page anchors follow HEAD. |
| "I edited one line, the gate is satisfied" | Any edit clears the staleness gate for the whole page. If covered code changed, re-read all of it and verify. |

## 3 · Write to the standard

Before any UPDATE or NEW PAGE, read `page-standard.md` in this directory: the page format, the pyramid, pictures, assessment and findings. Gotchas the writers hit (each measured):

- **Prettier 3.9.6 only.** `pnpm exec prettier --version` must print 3.9.6; a stale checkout had 2.8.8, which formats differently. CI runs `prettier --check architecture`.
- **Run `prettier --write <the files you changed>` after verify.** `gates.py verify` writes double-quoted values; prettier's `singleQuote` rewrites them, so an unformatted stamp fails CI.
- **A blank line between a table and a closing `:::`.** Without it prettier folds `:::` into the table as a row `| ::: |`.
- **YAML strings single-quoted** (double only when the value holds an apostrophe) — in page front matter only. **`FINDINGS.md` is not YAML:** one `key: value` per line, unquoted (`fixed_by: #2503`); its parser keeps quotes as literal text.
- **Screenshot captions never say "Captured"** — the build appends "Captured …" from `captured:`.
- **The register cross-check is strict, both ways:** a finding's `pages:` and each page's `findings:` must name each other.
- **No mermaid.** Generated directives (`{{graph: …}}`, `{{er: …}}`) for whatever the code fully defines; hand-drawn SVG in the E.2 style for the rest.

## 4 · Prove it

1. `make architecture-check` green (build, schemas, links, register cross-check, assessments, SVG lint).
2. `pnpm exec prettier --check architecture` clean.
3. Re-run step 1: every listed page edited or verified, 0 new uncovered items — read the report.
4. The PR description carries a **Documentation** section that names each page and why the others needed nothing:

```md
## Documentation
- Updated: E.2 — the request table lists `device_kind` (contract change). Re-read in full, verified at <sha>.
- Re-verified, unchanged: 0.3 — bug fix inside the turn runner; every claim re-read at HEAD; two dev anchors moved.
- Findings: F-001 fixed (fixed_by #<PR>).
- Nothing else: impact.py listed only these; `git grep DELEGATION_BUDGET_SECONDS architecture/` finds no other page.
- Checks: make architecture-check green; prettier --check architecture clean.
```

A check you could not run is reported as not run, never as green.
