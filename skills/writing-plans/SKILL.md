---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write the plan for a skilled engineer who knows almost nothing about this codebase, its tools or its domain, and not much about test design. Tell them which files each task touches, which tests prove it, which docs to check, and how to run it. Bite-sized tasks. DRY, YAGNI, TDD, frequent commits.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

If the work runs in an isolated worktree, `swisper-superpowers:using-git-worktrees` creates it at execution time.

**Save plans to:** for Fintama products, `plans/<product>/YYYY-MM-DD-<feature-name>.md` in Swisper_Documentation, main only, written with its `tools/docs-save` (never a branch; its README is the rulebook). Elsewhere, `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`. A user's preferred location overrides both.

Work the plan defers, and technical debt it finds, goes to the project's tracker (Fintama: Jira, project SA), not into a backlog section of the plan.

## The plan's weight follows the spec's class

**A Sketch spec gets a task list and one merge gate. A Standard or Programme spec gets the PR decomposition, per-PR authority and merge gates described below.**

- If you are writing "PR-1 (the only PR)" for a Sketch, stop and write the task list.
- If a Sketch seems to need a PR table or phase gates, either the class was under-called at brainstorming (take it back to the user; the class is their call) or the plan is inventing ceremony. Do not upgrade silently.
- If you downgrade, say so in the header with the reason.

Codebase grounding, reference-don't-duplicate, AC-named tests and TDD commit order apply at every weight.

## Reference the spec, don't duplicate it

**The plan sequences the work; the spec describes it.** The plan slices the spec's changes into PRs and tasks, orders them, names the tests and gates the phases. It does not re-derive the design, because a second copy drifts from the first and the plan is what gets pasted into implementer prompts.

Allowed in a task body:

- **Test intent**: two to four lines naming the observation point and the traps. *"Assert at the DB, not the UI. Never a fixed count: the count is the vendor's answer and will change. Stub the client deliberately or you will assert the degraded path."* No full test bodies; the spec's §6 already carries `observed_at`, negative cases and invariants. Up to five inline lines are fine where the assertion is non-obvious (an exact expected value, a positive control).
- **Shell commands** (`pytest …`, `ruff check …`, `git commit …`), each with its expected output.
- **Short snippets (five lines at most)** where prose would leave the sequencing ambiguous.
- **Plan-drift corrections**: a one-line deviation from the spec the implementer must fold in (the spec says `default=[]`, the project convention is `Field(default_factory=list)`).

Not allowed (reference the spec instead):

- source bodies of new code, or re-derived "write the implementation" blocks;
- type signatures, classes or schemas the spec's §3 or the machine-readable contract already declares.

Task-body shape:

```markdown
- [ ] **Step 3: Implement C4 per spec §1 C4 and §2 RULE-1**

  Path: `apps/backend/swisper/agents/data_types/booking_draft.py` (the C4 seam)
  Mechanism: wrap (spec §1 C4)

  Plan-drift corrections to fold in:
  - Spec shows `passengers: list[PassengerData] = []`; use `Field(default_factory=list)` per the project's ruff convention
```

Comments in the code an implementer writes follow `test-driven-development/clean-code.md`. A plan never asks for spec ids, decisions or dates to be copied into code comments.

## Consume the spec's structure

### Always present: §0, §0.1, §0.2 and §1

These are unconditional in every spec, including a half-page Sketch.

- **§0 Business Goals & Value**: one to three goals, each with Goal, Who benefits, Today, Value and Proof (`UBER-AC-n`); plus Non-goals and Rough cost for the chosen approach and the thin baseline.
- **§0.1 Decision Record**: the chosen approach and the thin baseline it beat, with its estimate and the falsifiable reason it lost.
- **§0.2 Constraints** (`HC-n`): instructions that ship with every task.
- **§1 Solution Design**: the changes (`C1`, `C2`, …), each with `today`, `tomorrow`, `seam`, `mechanism`, `call sites`, `pin`, `depends_on`, `atomicity`, and `ux` for screens.

Three rules:

1. **Reference §0; never restate it.** The plan's Goals table lifts §0's fields (see "Plan Document Header"). The goal is the thing you least want two versions of.
2. **PR-1 relates to §0.1's thin baseline, and the plan says how.** See "Sequence by value".
3. **A non-goal is a scope gate.** A task that serves one of §0's Non-goals is cut, not debated: the user ruled on it in writing.

### Triggered: §2–§9

Each is present only when its trigger fired; otherwise the spec carries a one-line N/A with the reason. Absence is normal.

| Section | Plan consumes it for |
|---|---|
| §2 The Logic (`RULE-n`) | the rule each implement step cites; its examples are §6's AC cases |
| §3 Contracts & Data Models | locked deliverables ahead of their consumers; consumer-side contract tests |
| §4 Failure & Ops | each row that names a behaviour becomes a task or a test in the PR that owns its change |
| §5 Delivery | migration / backfill / seed tasks, the migration slot, rollback, the re-runnable AC |
| §6 Acceptance Criteria | AC-named test tasks, each before its implementation |
| §7 Risks & Spikes | mitigation tasks and first-class spike tasks |
| §8 Amendments | where plan-time corrections to the spec are recorded |
| §9 Ownership Boundaries | enforcement artifacts and migration tasks (table below) |

Task bodies cite `[handoff]` sections. §0.1, §7 and §8 are `[review-only]` and stay out of what an implementer reads; a spike task copies only its timebox, stop condition and steps.

Check the trigger, not the section. An N/A is a claim: if §3 says "no boundary crossed" and your task list adds an API route, the spec is wrong. Fix it in the spec and record it in §8; do not compensate in the plan.

Where a section is present, it is authoritative input. Concretely:

1. **Tasks name change IDs.** Every §1 change becomes one or more tasks whose title names the ID ("Task 14 — C14: stub plugin entry"). A change with no task is a coverage gap.
2. **Order follows `depends_on` and `atomicity`.** A dependency is a sequencing edge (or a freeze point, if the spec marks it stubbable); changes that must ship together go in the same PR. `seam` and `anchors` give the file paths, `pin` names the test that must keep passing, `ux` names the mock.
3. **Each AC becomes a named test task before its implementation task.** The test name carries the AC ID verbatim: `test('T-AC-9: healthz returns 200 with body', …)`. The mapping is one-to-one: every test task traces to an AC, a spec invariant or a documented failure mode, and one that traces to none is not added. Before adding one, check that an existing test doesn't already cover it (in prism-indexed repos `prism search "<AC-ID>"` or `prism find-refs "<symbol>"`); extend rather than duplicate.
4. **Each test is planned at the boundary where its promise is received**: the route response, the rendered UI, the persisted state; a business AC with a UI in a real browser. A unit test is planned only for a pure core with too many combinations for the boundary, an invariant, or a failure mode the boundary cannot reach (`test-driven-development` R1–R4). Tag each test task with its altitude.
5. **Contracts are locked deliverables**, listed ahead of every task that consumes them. Changing one mid-plan is a plan update, not a one-line patch.
6. **Risks inform ordering.** Each §7 risk's mitigation becomes a task or a verification milestone early in the PR it protects.
7. **Spikes are first-class tasks**, scheduled before any PR their outcome can invalidate, with timebox and stop condition copied verbatim (see "Spike Tasks").
8. **Ownership boundaries become enforcement artifacts.** For each owned entity in §9, the plan includes the artifacts its enforcement mechanism needs:

   | Spec enforcement mechanism | Required plan artifacts |
   |---|---|
   | Lint rule | the rule's source; CI wiring (pyproject.toml / eslint config); a synthetic-violation test proving it fires on a fixture with a forbidden import |
   | Runtime guard | the guard; tests for its pass and fail paths; a test that it is engaged on the protected entry points |
   | Package boundary | the namespace / workspace config change; a build-time test that forbidden cross-package imports fail to resolve |
   | `AGENTS.md` guidance | the section naming the boundary, read/write contracts and allow-list; a cross-link from `CLAUDE.md` (and `.cursor/rules/` if used); optionally an example of the correct access pattern |
   | Documentation only | escalate to the user before proceeding; acceptable only with their explicit approval, flagged as debt in spec §7 and filed in the tracker |

   Each existing violation §9 names becomes a cutover task, with its shim and rollback path. The task that switches enforcement on (lint from warn to fail) is the last in the migration sequence, so it never blocks the cutover.

Do not fake structure that isn't there. A Sketch has §0–§0.2 and a three-line §1, and that is correct. Record in the plan's Inputs header which sections were present, which the spec declared N/A with what reason, and which N/A claims you checked.

## Scope Check

If the spec covers several independent subsystems, it should have been split during brainstorming. If it wasn't, suggest one plan per subsystem; each should produce working, testable software on its own.

## Sequence by value, not by layer

**PR-1 delivers `G-1`, proven by `UBER-AC-1`, as a thin vertical slice. Not the foundation for it.**

Decomposing by layer (model → service → routes → adapters → UI) produces a tidy graph in which the user sees nothing until the last PR, so over-scope and a misaimed spec stay hidden until the most expensive moment. Decompose by value instead: PR-1 takes the shortest path through every layer for one case (one provider, one entity, one screen state) and ends with something §0's named beneficiary can use. Later PRs widen it: the second provider, the error states, the generalisation.

### PR-1 and §0.1's thin baseline

§0.1 already holds a written, estimated thin baseline and the reason it lost. Check that reason now; do not design a thin version of your own. Then take one of three paths and state it in the header:

1. **The baseline is PR-1.** The rejection reason was false and the spec was cut back; there may be no PR-2.
2. **The baseline lost for a true reason.** PR-1 is the shortest vertical slice through the chosen approach that still delivers `G-1` to its beneficiary.
3. **You find at plan time that the rejection reason is false.** Amend §0.1, shrink the spec to match, record it in §8, and plan against the smaller spec. Do not plan the larger approach anyway: that reason was the whole justification for the spec's size.

### The check is a column

The Goals table's **"First delivered in"** column makes the order visible. If any goal is first delivered later than PR-2, the decomposition is by layer; redo it, or state the reason (self-review check 2).

A vertical slice may be ugly: hardcode the one provider, skip the cache, serve the happy path. Those are follow-up PRs, and they are cheaper to prioritise once the user has seen it working.

**Ship to main by value, too.** Plan a main merge after each goal's first-delivery wave, each with the human's OK. A proven goal is not held back for an unfinished one.

## PR decomposition + branching model (Standard / Programme; a Sketch skips this)

A Sketch plan uses one sub-branch and one merge gate at the end (the PR-K gate below). A Standard or Programme plan is a PR decomposition with explicit branching and merge gates:

```
spec → feature branch (one per spec)
         ├── sub-branch for PR-1 (tasks delivering one logical unit)
         ├── sub-branch for PR-2
         ├── sub-branch for PR-N
         └── final integration → merge the feature branch upstream (per project policy)
```

### Required: PR decomposition table

Near the top, after the Phase 0 contracts and before the task list:

```md
## PR decomposition

**Feature branch:** `feature/<spec-id>` (long-running; integrates this spec end to end)

| PR | Sub-branch | Scope (tasks / changes) | ACs verified | Contracts produced | Contracts consumed | Frontend touched? |
|----|------------|-------------------------|--------------|--------------------|--------------------|-------------------|
| PR-1 | `feature/<spec-id>-pr1-slice` | Tasks 1.1–1.5 (C1, C2, C5) | B-AC-1, T-AC-1 | HealthzResponse | (none) | Yes |
| PR-2 | `feature/<spec-id>-pr2-errors` | Tasks 2.1–2.4 (C3, C4) | T-AC-3..5 | ErrorResponse | HealthzResponse | No |
| PR-N | … | … | … | … | … | … |
```

### Required: per-PR authority (what is mine, and what is not)

A task that lists the files it creates and modifies and says nothing about the rest tells a fresh subagent half of what it needs; concurrent implementers with only a positive file list collide. Every PR carries three-valued authority:

| | Meaning |
|---|---|
| `may_edit` | Yours. Change freely. |
| `may_edit_content` | An approved mock or scaffold. Change data flow, handlers, fetching, state wiring. Do not change component composition, route or design tokens. |
| `must_not_edit` | Another PR owns it in this wave, with the reason. |

**The middle value matters most**: without it `may_edit` grants a free hand over a screen the human already approved. A PR containing any change with a `ux` block bases its branch on a commit that contains the approved mock (`design/mocks/<slug>/` at the SHA the spec pins); on any other base the implementer builds the screen from scratch.

Every handoff carries the standing authority line, verbatim:

> Naming, internal structure, helper decomposition and test fixtures are yours. Everything else in your payload is specified. If you need to change anything outside it — including because it appears impossible — stop and report to the lead with the element id and the goal it fails. Do not deviate: you can see one task, and the lead can see the whole graph.

### Required: contention

Two tasks or PRs in the same wave that can touch the same file are not parallel. List every path touched by more than one PR and how it was resolved:

| path | touched by | resolution |
|---|---|---|
| `src/order/service.ts` | PR-2, PR-4 | **same PR** — PR-4's change folded into PR-2 |

Resolutions are `same PR` · `serialised` · `seam moved` · `extracted`. `must_not_edit` is the same resolution expressed per PR; write it in both places.

Heavy contention is a design signal: if three PRs must serialise on one file, the seams are wrong. Amend spec §1 and record it rather than planning around it.

### Required: waves, freeze points, and the migration slot

- **One PR per wave.** The wave's tasks run in parallel, each in its own worktree and reviewed per task; they merge locally into one wave branch (`--no-ff`, keeping the reviewed history) and CI runs once per wave. Split into separate PRs only when an item must ship to main on its own or needs a different approver. Contention and `must_not_edit` then apply between the wave's tasks.
- **Generated and shared files: once, at the end of the wave PR.** The regenerated OpenAPI spec and its changelog, package CHANGELOGs, version bumps, and architecture pages per `update-documentation` are the wave's last task: never per task, per fix round or in parallel branches, because they conflict on every combine.
- **Every wave states why its tasks are safe together**, in one line naming the fact ("disjoint owned files; both consume the response shape frozen in wave 1").
- **Every dependency the spec marks stubbable gets a freeze point**: the contract is published before the wave that stubs against it, so "B needs A" becomes two PRs running at once. If the spec did not say, assume not stubbable and raise it.
- **One exclusive migration slot per release**, ordered against the PRs that need it. Two PRs writing migrations in one window collide on numbering at merge time.

### Required: four tests a PR can fail

A PR is well-formed when all four hold:

1. It leaves the main line green and releasable, behind a flag if it must be.
2. It delivers at least one complete business promise end to end, or unblocks at least two later PRs. A PR that does neither is a layer, not a slice.
3. One owner, and no file shared with another task or PR in its wave.
4. It is describable in one sentence. If it needs two, it is two PRs.

Don't split for parallelism alone. A split must buy a removed wave boundary, an isolated gate or a genuinely independent owner; the second PR's review, checks and context switch cost more than the wall-clock it saves.

The value check outranks these four: a PR can pass all of them and still deliver nothing until the end. Where they disagree, sequencing by value wins. A PR that touches 30 files is fine if they are one coherent change; one that mixes unrelated changes is not.

### Per-PR merge gate

Each PR's task group ends with its merge gate, declared in the plan. A sub-PR is not marked complete or suggested for merge into the feature branch until every line is green:

```md
### PR-K merge gate

Before suggesting merge of `<sub-branch>` into the feature branch:

- [ ] Every AC the PR claims (column "ACs verified") has a green test
- [ ] Tests are named after the AC ID (`test('T-AC-9: …', …)` / `test('B-AC-1: …', …)`)
- [ ] Tests precede implementation in commit history (the failing-test commit comes first)
- [ ] Every contract the PR produces is exercised by a test on the consumer side, not only by the producer's unit tests
- [ ] If the PR changes frontend behaviour: a front-to-back browser test drives the change from the UI and asserts the back-end effect
- [ ] No new `@ts-ignore` / `eslint-disable` without a reason on the same line
- [ ] The project's quality-bar gates (typecheck, lint, coverage, property tests, benchmarks the spec sets) are green on the sub-branch
- [ ] A non-obvious decision is recorded in the "Why it is like this" block of the architecture page it shaped (date · decision · rejected alternatives · spec link)
- [ ] CHANGELOG.md updated for any user-facing change
- [ ] If the repo has `architecture/tools/impact.py`: `update-documentation` run, each page the diff touches updated or re-verified, `make architecture-check` green

Only then: mark the PR complete and suggest merge into the feature branch.
```

"Suggest merge" is deliberate: the planner does not merge. The implementer or reviewer makes the call once the gate is green, unless project policy lets review tooling auto-merge after it. A merge to main always needs the human's explicit OK.

### Frontend behaviour changes need a front-to-back test

A PR that changes what a user sees or does in the frontend proves it in a real browser and asserts the back-end effect (API response, DB record, downstream call): the shape is in `test-driven-development/proving-acs.md`, "Front to back". Frontend unit tests against a mocked backend do not satisfy this gate. The test command owns the stack it runs against (frontend and backend up on free ports, down when it exits); it never points at the integration rig, which serves a different build. A backend-only PR, or a frontend change with no behaviour change, needs integration and contract tests only.

### Contracts are tested across the consumer boundary

A contract test is not "the producer's unit test passes"; it is a consumer, or a fixture acting as one, using the contract end to end:

- HTTP: the consumer-side SDK calls the producer; the response shape is type-checked and asserted.
- TypeScript interface: a consumer file imports and uses it in a way that fails to compile if the shape changes, and that file is in the test set.
- Database schema: a query runs against it end to end in an integration test.
- Event / SSE / message bus: a real consumer subscribes and asserts the payload shape on a real emission.

## File Structure

Before defining tasks, map which files will be created or modified and what each is responsible for.

- Units with clear boundaries and well-defined interfaces; one responsibility per file.
- Prefer smaller, focused files: you reason better about code you can hold in context, and edits to focused files are more reliable.
- Files that change together live together. Split by responsibility, not by technical layer.
- In an existing codebase, follow its patterns. Don't restructure unilaterally, but a split of a file you are modifying that has grown unwieldy is reasonable.

Where spec §1 names the paths (`seam`, `anchors`, the `ux` graft target), use them. Do not redesign the layout in the plan.

## Bite-Sized Task Granularity

Each step is one action of two to five minutes:

- "Write failing test `T-AC-9: healthz returns 200 with body`"
- "Run `T-AC-9` to verify it fails"
- "Implement C16 (the `/healthz` route) to make `T-AC-9` pass"
- "Run the tests and make sure they pass"
- "Commit"

## Plan Document Header

Every plan starts with this header:

````markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use swisper-superpowers:subagent-driven-development (recommended) or swisper-superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Spec class:** Sketch | Standard | Programme
(If the spec declares no class, say so and name the one you inferred, with the reason.)

## Goals — lifted from spec §0. Reference, do not restate.

| Goal | Who benefits | Value delivered | Proof | First delivered in |
|------|--------------|-----------------|-------|--------------------|
| G-1 [spec §0] | [named role] | [what they gain] | UBER-AC-1 | **PR-1** |
| G-2 [spec §0] | … | … | UBER-AC-2 | PR-2 |

(Sketch: the column reads "this plan", and the task list ends with the beneficiary able to use it.)

**Non-goals (spec §0), lifted verbatim. A task serving one is cut:**
- …

**Thin baseline (spec §0.1):** [what it was] · [its estimate] · [the reason it lost]
→ **PR-1 relationship:** is the baseline / shortest slice through the chosen approach / reason found false → §0.1 amended (§8 AM-n)

**Constraints:** spec §0.2 (HC-1 … HC-n) travel with every task.

**Architecture:** [2-3 sentences about the approach]

**Tech Stack:** [key technologies and libraries]

**Inputs:**
- Spec: `[path/to/spec.md]`
- Sections present and consumed: [e.g. §1 Solution Design, §2 The Logic, §6 ACs]
- Sections declared N/A by the spec, with its stated reason: [list]
- N/A claims I checked: [which, and the verdict]

---
````

## Task Structure

````markdown
### Task N: [Component Name] — [change IDs covered, e.g. C14, C15]

**Phase:** P[N]
**Depends on:** [upstream tasks / change IDs, from §1 depends_on]
**Parallelizable with:** [task numbers, if any]
**ACs verified:** [B-AC-N / T-AC-N satisfied by this task]
**Spec sections consumed:** §1 C<n>, §2 RULE-<k>, §6 T-AC-N

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py` (`path::symbol` from the §1 seam)
- Test: `tests/exact/path/to/test.py`

- [ ] **Step 1: Write the failing test `T-AC-N: <AC summary>`**

Altitude: promise | contract | unit (and why).
Observed at: [§6 observed_at for T-AC-N]. Negative case: [§6].
Traps: [two to four lines of intent, if any].

- [ ] **Step 2: Run the test to verify it fails**

Run: `pytest tests/path/test.py -k T_AC_N -v`
Expected: FAIL with "function not defined" (or `ModuleNotFoundError` if the module doesn't exist yet)

- [ ] **Step 3: Implement C<n> per spec §1 C<n> and §2 RULE-<k>**

Path: `exact/path/to/file.py`
Mechanism: [§1 C<n> mechanism]

Plan-drift corrections to fold in:
- [any deviation the implementer must apply, or "none"]

- [ ] **Step 4: Run the test to verify it passes**

Run: `pytest tests/path/test.py -k T_AC_N -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat(C<n>): <one-line summary> (verifies T-AC-N)"
```
````

Inline code in Step 3 is the exception: only when it is five lines or fewer (a one-line `__all__` extension, a stub) or purely mechanical drop-in code the spec does not describe.

## Phase Gates (Standard / Programme; a Sketch has one phase)

At each phase boundary, insert a gate task that verifies the phase's exit criteria before the next phase begins. If a gate fails, work pauses until it is green. The criteria come from the spec's quality bar; don't invent gates the spec doesn't authorise.

````markdown
### Gate: End of Phase P[N]

**Phase exit criteria** (from spec §[ref]):

- [ ] All P[N] changes implemented and committed
- [ ] All P[N] ACs have passing test tasks
- [ ] Quality bar, each command the CI runs:
  - [ ] typecheck exits 0 (every config the CI checks)
  - [ ] lint exits 0, no new warnings
  - [ ] tests exit 0; coverage thresholds the spec sets are met
  - [ ] property tests for in-scope invariants pass
  - [ ] benchmarks within the spec's tolerance of baseline
- [ ] Non-obvious P[N] decisions recorded in the "Why it is like this" block
- [ ] No new `@ts-ignore` or file-level `eslint-disable` without a reason on the same line
- [ ] CHANGELOG.md updated for user-facing changes
````

## Spike Tasks

For each spike in spec §7, write a real task with its timebox and stop condition copied verbatim:

````markdown
### Spike S1: Verify `chat.params` end-to-end mutation

**Phase:** P[N] (must complete before C<dependent>)
**Timebox:** 0.5 day
**Stop condition:** confirmed yes (proceed) OR confirmed no (re-open the soft-fork question with evidence)

- [ ] **Step 1: Build a minimal plugin that mutates `output.options.thinking`**
- [ ] **Step 2: Run one chat; capture the outbound request (debug logging or a proxy)**
- [ ] **Step 3: Confirm the `thinking` field is in the captured body**
- [ ] **Step 4: Record the outcome** (Fintama: `specs/<product>/spikes/YYYY-MM-DD-S1-<slug>.md` in Swisper_Documentation, via `tools/docs-save`)

Confirmed yes → downstream tasks proceed unchanged.
Confirmed no → follow the spike's stop condition (here: stop and re-open the soft-fork question with the user).
````

## Risk-Mitigation Tasks

Each risk in spec §7 resolves to a change, an AC or a delivery item; give it a concrete task or verification milestone in the PR it protects. Don't bury risks in narrative.

## No Placeholders

Every step contains what the engineer needs, or a precise pointer to where it lives. These are plan failures:

- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" without naming the AC, the altitude and the observation point
- "Similar to Task N" (reference the spec section instead)
- a step that says what to do without saying how or where
- a type, function or method defined in neither the spec, the codebase nor an earlier task

A spec reference is not a placeholder. "Implement C4 per spec §1 C4, path `apps/.../file.py`, with these corrections: […]" is complete.

## Self-Review

This is the plan's gate before the human reads it; no reviewer agent is dispatched. After writing the plan, check it against the spec with fresh eyes.

**1. Run the mechanical check.**

```bash
bash skills/writing-plans/scripts/plan-check.sh <plan.md> <spec.md>
```

Run it unpiped and read the exit code of the bare command: a pipe returns the last command's status, and `${PIPESTATUS[0]}` is empty under zsh. It fails on placeholder markers, a spec change ID or AC ID named in no `- [ ]` step, a missing or late Goals-table delivery cell, missing Non-goals or thin-baseline lines, an implement step carrying a code block, and (with a PR table) missing `may_edit` / `must_not_edit`. An ID that deliberately has no task is declared on one line with its reason, so declining is visible:

```markdown
<!-- plan-check: no-task C9 C10 — Phase 2, spec §7 -->
```

Positive-control it before you trust it: delete the task for one change ID, watch it go red, restore it.

**2. Delivery order.** Read down "First delivered in" and confirm the PR-1 relationship to §0.1 is stated and honest (see "Sequence by value"). A goal first delivered after PR-2 is acceptable only when the plan states the reason: a real dependency forces the order, and each earlier PR is independently useful to a named beneficiary the moment it lands. What fails this check is a plan in which nobody sees anything until the end.

**3. Codebase drift since the spec was written.** Commits land between spec and plan. For every pre-existing path, symbol, import and method the plan names, confirm it still exists where the spec claims (in prism-indexed repos `prism search` / `def` / `find-refs`; else grep and Read). Also check that nothing the plan builds as `ADDED` has landed in the meantime. An empty result is evidence about the pattern, not about absence: widen it before concluding. A hit is a spec bug: amend §1 and record it in §8.

**4. Non-goals scope walk.** Read §0's Non-goals, then the task list. A task serving a non-goal is cut.

**5. Spec contradictions.** Does any task only make sense if a spec claim is false? Did you silently work around something, or assume a shape the spec doesn't declare? Only you know what you had to assume. Every hit is a spec bug: amend the spec and record it in §8, so the next reader and the next plan don't build on the same false claim.

Fix what you find inline. A spec requirement with no task gets a task. Only a change to a goal stops the plan and goes to the user.

## Pre-implementation checklist

Every Standard or Programme plan ends with a short checklist the user can scan before any code is written:

- [ ] Spec approved by the user; no open changes pending
- [ ] Upstream dependencies merged / available
- [ ] Branch policy confirmed (target branch named; sub-PR strategy decided)
- [ ] The base branch is green on every gate, measured (see below)
- [ ] Provider / repo access confirmed
- [ ] Spike outcomes recorded (S1, S2, …)
- [ ] Effort estimate communicated to stakeholders

A Sketch plan keeps two of these lines: the spec-approved line and the base-branch line with its numbers. The base-branch line is owed at every weight.

### The base-branch line carries numbers

Write it so it cannot be ticked from memory:

```
- [ ] Base `<branch>` @ `<sha>` green: tsc 0 · tsc -p tsconfig.test.json 0 ·
      complexity 239/239 · lint 0 new · tests 251 green   ← run these, paste the numbers
```

1. **Enumerate every gate the CI runs, not the ones you remember.** A repo with two typecheck configs has two gates.
2. **A red base gate becomes an explicit task zero, or the plan picks a different base.** Decide it here, where it is a scoped task with an owner, not mid-execution, where it blocks every commit behind it.

`subagent-driven-development` re-runs this as a pre-flight before task 1, because other branches land in between.

## Execution Handoff

After saving the plan, offer the next step:

> "Plan complete and saved to `<filename>`. Two execution options:
>
> **1. Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration.
>
> **2. Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints.
>
> Which approach?"

- **Subagent-Driven:** use `swisper-superpowers:subagent-driven-development` (a fresh subagent per task, one code-quality review after each).
- **Inline Execution:** use `swisper-superpowers:executing-plans` (batch execution with checkpoints).
