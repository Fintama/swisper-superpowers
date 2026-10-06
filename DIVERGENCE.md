# What this fork adds, and how we know it is still here

**`swisper-superpowers` is a tracked fork of the official `superpowers` plugin.**
Tracking means upstream changes get merged in — and **a merge can quietly drop a
local enhancement.** Nothing about a clean merge announces that a section is gone.

This file is the ledger of what we added. **`scripts/divergence-check.sh` reads it
and fails, naming the enhancement, if one has disappeared.**

⚠ **The marker is not decoration — it is the grep.** Each row's marker is a string
that exists **in our copy and not upstream**, so its absence is evidence rather
than noise. Every marker below was verified **in both directions** when it was
added: it hits our tree, and it misses `superpowers@6.3.0`. **A marker present
upstream too proves nothing; a marker absent from our tree makes this file lie in
the safe-looking direction.**

**Baseline measured 2026-08-27 against `superpowers@6.3.0`.**

## Skills that exist only here

Upstream has no version of these at all, so the whole skill is the divergence.

| skill | marker | why it exists |
|---|---|---|
| `respawn-pm` | `CronDelete` | PM self-succession. The cron discipline is the load-bearing part — two PMs answering traffic is the failure it prevents. |
| `respawn-workstream` | `context package` | Succeeding a lane whose context is exhausted, without losing what it knew. |
| `update-program-board` | `Mission Control` | The board is the one surface a decision gets made from. |
| `writing-handovers` | `paste-ready` | A handover a human can paste, rather than a summary they must translate. |
| `running-a-workstream` | `Mission Goals` | A lane judges its own design against the programme's goals, and may not add one. |
| `running-a-programme` | `writing-exec-summaries` | The PM seat — nothing briefed it before. Reports in the agreed shape. |
| `writing-exec-summaries` | `Retrospective` | The five-section report, made portable. It lived only in one machine's project memory. |
| `setup-delivery-program` | `init-programme.sh` | The programme state directory is created, not assumed. Without it the monitoring and messaging tools abort on a missing lane map. |
| `setup-delivery-program` | `seven tests a lane must pass` | Lanes are derived from the architecture, not invented from job titles. |
| `creating-screen-mocks` | `CHIEF EXPERIENCE OFFICER` | DESIGN.md and component docs are direction, not reference — ignoring them overrides a person. |
| `creating-screen-mocks` | `MORE THAN ONE PACKAGE` | A design system is usually several packages; finding one and designing from it invents gaps that do not exist. Count the filesystem, not the registry. |
| `creating-screen-mocks` | `data-testid` | The join key the render gate needs. Without it nothing downstream can be compared. |
| `creating-screen-mocks` | `init-workspace.sh` | The workspace is scaffolded with the review loop already wired. Measured: an agent that hand-wrote it shipped a mock nobody could click. An agent cannot forget a step it never performs. |
| `creating-screen-mocks` | `verify-review-loop.mjs` | The gate that can fail on a missing review loop. Every other verification item passed on an unreviewable mock, so the verify phase was blind to the one omission that matters. |
| `update-documentation` | `RE-VERIFY ONLY` | The per-page decision before a PR: update, re-verify only, new page or nothing. Measured 2026-10-04: without it an agent skipped the re-verify stamp on a bug fix ("WARN mode, I'll record the re-read in the PR text"). |
| `update-documentation` | `page-standard.md` | The page format, the pyramid and the findings entry, summarised for the writer. SKILL.md sends the agent there before any edit, so the file must survive with the prose. |
| `running-a-programme` | `Rule on the property, not the mechanism` | The PM states what must be true plus a failing test; the lane picks the mechanism, and a named mechanism is probed first. Measured 2026-10-05: three unprobed mechanism rulings were wrong, each a fix round plus a re-review. |
| `running-a-programme` | `Ship to main by value` | A proven goal goes to main at once, never held behind an unfinished one. Measured 2026-10-05: goal 1 was proven hours before any of it could reach main. |
| `creating-screen-mocks` | `isTrusted` | `select-client` ignores scripted clicks so automation cannot clobber the reviewer's selection — and an agent that tries one sees nothing and debugs working code. Documented where it is met, not only inside the file. |

## Skills we substantially extended

| skill | marker | what we added |
|---|---|---|
| `brainstorming` | `Business Goals & Value` | §0 — the goal is nailed and agreed **before** any solution is discussed. |
| `brainstorming` | `UBER-AC` | Every goal carries a runnable proof, so a goal can fail. |
| `brainstorming` | `thin baseline` | An honest smallest option is priced and argued against, in writing. |
| `brainstorming` | `Spec Classes` | Sketch / Standard / Programme — the document's weight follows the risk. |
| `writing-plans` | `Reference the spec, don't duplicate it` | The plan sequences; the spec describes. Two sources of truth drift. |
| `writing-plans` | `per-PR authority` | Each PR states what it may and must not edit. |
| `writing-plans` | `may_edit` | The mechanism that makes the previous row checkable. |
| `writing-plans` | `plan-check.sh` | Mechanical coverage checks, so review spends its attention on judgement. |
| `test-driven-development` | `AC-ID test naming` | A test names the criterion it proves, so coverage is greppable. |
| `test-driven-development` | `proving-acs` | A test is asserted at **promise** altitude — what the user receives. Since 2026-10-05 the method for every test, not only B-ACs. |
| `test-driven-development` | `Functional Core, Imperative Shell` | The design rule that makes tests possible instead of a fight. |
| `test-driven-development` | `test tiers` | core / gate / extended, so the inner loop stays fast enough to be used. |
| `test-driven-development` | `Tests prove promises` | R1–R7 (Heiko, 2026-10-05: "I don't want useless tests"): every test names its AC / INV / FM id or is not written; unit tests are the exception; boundary first, **replacing the test pyramid**; strengthen before add; delete what a higher test covers. Measured: Foundry main ~21,500 tests, ~18% naming an AC; a baseline agent wrote 11 untraced unit tests beside 7 route tests for one route. |
| `test-driven-development` | `trace-check.sh` | R8 — the mechanical half of the naming rule: lists new tests whose title names no id, exits 1; `--self-test` is its positive control. The file is checked as well as the prose. |
| `test-driven-development` | `Strengthen before you add` | R6 — a finding or surviving mutant is fixed by strengthening an existing test. Measured 2026-10-05: three findings answered with 8 new tests, 0 strengthened, 0 deleted. |
| `subagent-driven-development` | `mock scaffold` | The approved scaffold is the binding basis for any screen. |
| `subagent-driven-development` | `boundary review` | Review per PR boundary, not per task. |
| `subagent-driven-development` | `strengthened before added` | R9 — the dispatch carries the plan's named test list; fix rounds strengthen; the reviewer's disposition for an untraced test is strengthen or delete; every report counts tests added / strengthened / deleted from `trace-check.sh`. |
| `systematic-debugging` | `observability where it exists` | Use the instrumentation the system already has before adding more. |
| `executing-plans` | `merge gate` | A phase is not done until its gate passes. |
| `brainstorming` | `creating-screen-mocks` | A user-visible surface gets an approved mock BEFORE the spec describes it. |
| `brainstorming` | `GRAFT TARGET` | The spec records which file the mock becomes, so the implementer adapts rather than rebuilds. |
| `subagent-driven-development` | `render-gate.mjs` | Build-vs-mock compared mechanically, not by eye. |
| `finishing-a-development-branch` | `Step 1b: Update the Documentation` | In a repo with an architecture site, `update-documentation` runs before any merge or PR is offered. |
| `writing-plans` | `update-documentation` | Every per-PR merge gate carries the docs check, for repos with an architecture site. |
| `brainstorming` | `Swisper_Documentation` | Specs are saved in the Fintama docs home (`specs/<product>/`, main only, `tools/docs-save`), not `docs/superpowers/specs`. Ruled by Heiko 2026-10-04; an upstream merge restoring the old path would quietly scatter specs again. |
| `writing-plans` | `Swisper_Documentation` | Plans are saved in `plans/<product>/` of the docs home, and deferred work goes to Jira, not a backlog section. Same ruling. |
| `update-documentation` | `Why it is like this` | ADRs are dropped: a non-obvious decision is recorded on the architecture page it shaped. Technical debt goes to Jira with the finding number. Same ruling. |
| `subagent-driven-development` | `update-documentation` | The PR-boundary review runs it, so no PR leaves the boundary with stale architecture pages. |
| `subagent-driven-development` | `no-op draft PR` | Before task 1, prove CI grades PRs into the integration branch and is green. Measured 2026-10-05: three CI round trips came from the base (an ungraded branch, a release-version gate, a test-count floor). |
| `subagent-driven-development` | `Rule on the property, not the mechanism` | Fix rounds and answers state the property and a failing test; a named mechanism is probed first. Same measurement as the `running-a-programme` row. |
| `subagent-driven-development` | `One PR per wave` | Parallel tasks in their own worktrees merge locally (`--no-ff`) into one wave branch; CI runs once per wave. Measured 2026-10-05: 6 PRs later combined into 2, with shared-file conflicts and CI re-runs. |
| `subagent-driven-development` | `once, at the end of the wave PR` | Generated and shared files (OpenAPI spec + changelog, package CHANGELOGs, version bumps, architecture pages) are written once per wave, never per task or fix round. Measured 2026-10-05: ~45 pages re-anchored after every fix round. |
| `subagent-driven-development` | `Helpers stay inside their own worktree` | Helpers keep to their own worktree and scratch dir, never touch shared tool installs, never delete others' files, never print env. Measured 2026-10-05: a shared uv Python overwritten, a peer's screenshots deleted, env tokens printed. The prompt text lives in `implementer-prompt.md` and `code-reviewer.md`; this row guards the SKILL.md pointer to it. |
| `writing-plans` | `One PR per wave` | The plan decomposes by wave, one PR each; split only for an independent ship to main or a different approver. Same measurement as above. |
| `writing-plans` | `once, at the end of the wave PR` | Shared and generated files are the wave's last task. Same measurement as above. |
| `writing-plans` | `Ship to main by value` | A main merge is planned after each goal's first-delivery wave. Same measurement as the `running-a-programme` row. |
| `requesting-code-review` | `at the FIRST push` | Draft PR plus `@codex review` at the first push, so automated findings arrive with the first CI run. Measured 2026-10-05: four helvetiq PRs got valid Codex findings after CI was green; drafts are not auto-reviewed. |
| `subagent-driven-development` | `Senior-engineer pass` | Heiko, 2026-10-06: *"how can I avoid the code being that of a junior developer?"* Right before its first test every implementer reasons in a ≤12-line note — J (the junior anti-patterns for THIS task), S (the senior design: reuse by `path::symbol`, failure modes, limits, compatibility, observability, what it will NOT build), I (invariants → tests) — and puts it in its report. A reasoning step, not a gate: nobody approves it. The template lives in `implementer-prompt.md`; this row guards the SKILL.md section pointing to it. |
| `test-driven-development` | `A junior tests` | The senior-engineer pass picks the tests before the first RED: promise altitude, negative path, the named limit, each dependency failing — mapped to R2 ids, never extra untraced tests. |
| `brainstorming` | `junior would:` | §1's `senior` field: per change, what a junior would build and what the design does instead. It replaced the seam's "obvious alternative it beat" clause; self-review check 7 confirms the rest of the spec carries it. |
| `finishing-a-development-branch` | `gh pr ready` | An existing draft from the first push is marked ready, not duplicated. |

## Rows deliberately NOT in this table

Three candidates were rejected when this ledger was written, and they are recorded
because **the reason is the method**:

| candidate | why it was rejected |
|---|---|
| `review-termination` (brainstorming) | **Absent from our own `SKILL.md`** — it is a separate file. A marker that does not hit our tree makes this ledger fail for the wrong reason, or worse, get "fixed" by deleting the row. |
| `positive control` (verification-before-completion) | **Absent from that skill's `SKILL.md`.** Same failure. |
| `Skill Priority` (using-superpowers) | **Present upstream too.** Not divergence — it would go green forever and prove nothing. |

🔴 **Three of nineteen candidates were wrong, and only the two-direction check
found them.** Grep any new marker in our tree (**must hit**) and in the upstream
cache (**must not**) before adding a row.

## Adding a row

1. Choose a string that is **distinctive to our copy** — a heading or a coined term, not a common word.
2. `/usr/bin/grep -cF '<marker>' skills/<skill>/SKILL.md` → **must be ≥ 1**.
3. `/usr/bin/grep -rcF '<marker>' <upstream>/skills/<skill>/` → **must be 0**.
4. Add the row, then run `bash scripts/divergence-check.sh` and see it still pass.
5. Run `bash scripts/divergence-check-control.sh` — the checker must still be able to **fail**.
