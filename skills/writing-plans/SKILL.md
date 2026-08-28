---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** If working in an isolated worktree, it should have been created via the `superpowers:using-git-worktrees` skill at execution time.

**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
- (User preferences for plan location override this default.)

## The plan's weight follows the spec's class

**A Sketch spec gets a task list and one merge gate. A Standard or Programme spec gets the PR decomposition, per-PR authority and merge gates described below.** That is the whole rule.

⚠ **A Sketch spec that gets a PR table with one row in it, three phase gates and a base-branch checklist is the same failure the spec class exists to prevent, one artifact downstream.** If you find yourself writing "PR-1 (the only PR)", stop and write the task list.

**Scope runs the other way too.** If the spec is a Sketch and you are reaching for phase gates, either the class was under-called at brainstorming step 5 — take it back to the user, that is their decision — or the plan is inventing ceremony. **Do not silently upgrade.** And if you are downgrading, say so in the header with the reason, for the same symmetry: an unstated downgrade is how a Programme quietly becomes a Sketch.

Codebase grounding, reference-don't-duplicate, AC-named tests and TDD commit order apply at every weight. Those are correctness, not ceremony.

> **Three named modes (S / A / B) were removed on 2026-08-12.** Measured: 2 of the
> 9 plans written since they were introduced declared one, Mode S was never used
> once, and Mode B's eight roadmap sections produced 4 plans in total, none since
> July. The *weight-follows-class* idea was right; the vocabulary was ignored. A
> multi-stage roadmap is a different artefact wearing this one's name — if the need
> recurs it earns its own skill rather than a mode inside this one.

## Reference the spec, don't duplicate it

**The core principle of this skill:** the plan SEQUENCES the work; the spec DESCRIBES the work. They have different jobs and must not overlap.

A well-written spec (produced by `superpowers:brainstorming`) is the single source of truth for implementation: it carries source bodies for new artifacts, contracts, type signatures, and verified codebase references. The plan's job is to slice that work into PRs and tasks, declare the order, name the tests, and gate phases — NOT to re-derive the implementation.

**The drift mechanism this rule prevents:** when the plan pastes source bodies that the spec already carries, the plan becomes a second source of truth. The plan author often re-types code from memory rather than copying carefully, introducing divergence from the spec AND from the codebase. Implementers then read the plan body (because the plan is what gets pasted into their prompts), inherit the wrong API/signature/import, and burn time discovering and correcting the drift. Eliminating duplication eliminates this entire class of failure.

**What belongs in a plan task body (allowed):**

- **Test INTENT — the observation point and the traps.** Two to four lines, not a body. *"Assert at the DB, not the UI. Never a fixed count — the count is the runtime's answer and will change with the vendor. Stub the OpenCode client deliberately or you will assert the degraded path while believing you tested the healthy one."* That is test-design knowledge, it is not in the AC, and it is the part an implementer genuinely lacks.

  🔴 **Full test bodies were removed on 2026-08-12.** The spec now carries `observed_at`, negative cases, invariants, and one example per rule outcome — it *specifies* the test. A body in the plan is a second encoding of the same assertion, which is the exact drift this section spends forty lines forbidding for source bodies; granting the rule over implementation code and denying it over test code does not hold. It was also the largest block in a typical plan — about a third of it — and under `subagent-driven-development` that block is pasted into **every** dispatch whether or not it is the task at hand. A body pasted by an author who never ran it arrives with the wrong helper name often enough to cost more than it saves.

  **Exception, same as for source bodies:** ≤5 inline lines where the assertion is genuinely non-obvious — an exact expected value, a positive control.
- **Shell commands** — `pytest …`, `ruff check …`, `git add … && git commit -m "…"`, smoke-test invocations. Always show the expected output snippet too.
- **Short illustrative snippets (≤5 lines)** that clarify SEQUENCING when prose alone is ambiguous — e.g., `# In the if-block at line 189, insert above the existing v2 check:` followed by 3 lines of pseudo-context.
- **Plan-drift correction notes** — when the spec has a known bug the plan author has noticed (e.g., spec says `default=BookingOptions()` but the project ruff convention prefers `default_factory=BookingOptions`), call it out as a one-liner the implementer must fold in.

**What does NOT belong in a plan task body (forbidden — reference the spec instead):**

- **Full source bodies of new artifacts** — these live in the spec (typically in §3 Contracts & Data Models or in the artifact-specific section). The plan references them: `Implement A4 (BookingDraft) per spec §3.2.4 verbatim source body.`
- **Re-stated type signatures, class definitions, schemas** that the spec already declares. The plan references the spec location.
- **Re-derived "Step 3: Write the implementation" code blocks** — the spec already contains the body. The plan tells the implementer where to put it and which file path to create.

**Practical task-body shape (use this template):**

```markdown
- [ ] **Step 3: Implement A4 (BookingDraft DataObject) per spec §3.2.4 verbatim source body**

  Path: `apps/backend/swisper/agents/data_types/booking_draft.py`
  Spec source body: see spec §3.2.4 (lines 142-198 of the spec doc)

  Plan-drift corrections to fold in (deviations from spec source body the implementer must apply):
  - Spec shows `passengers: list[PassengerData] = []` — use `Field(default_factory=list)` per project ruff convention
  - Spec omits the `booking_attempted_at` field comment — copy the TR-7b comment verbatim from spec §5
```

This is dramatically shorter than the old "paste the full source body" style, AND it has only one source of truth. If the spec is wrong about the code body, ONE place to fix. If the spec changes during review, the plan doesn't go stale.

**Codebase grounding still applies at plan time.** The plan author MUST verify every claimed file path, import path, and existing-method name the plan references — in prism-indexed repos with `prism search`/`def`/`find-refs` (Grep/Read are blocked there), otherwise grep / Read — even when the spec already grounded these (the spec may have drifted since you read it, or new code may have landed). It is also part of the plan review — the highest-value plan-time check, because it catches drift introduced BETWEEN spec-write and plan-write that no earlier gate could have seen.

---

## Spec-driven planning — consume the spec's structure, don't re-derive

### Always present, at every class — the two sections that aim the plan

**§0 Business Goals & Value** and **§0.1 Decision Record** are unconditional in every spec, including a two-line Sketch. They are the plan's most important inputs and the only ones that decide whether the plan is aimed correctly.

- **§0 Business Goals & Value** — 1-3 goals, each carrying **Goal** (the outcome), **Who benefits** (a named role), **Today** (the current pain), **Value** (what the beneficiary gains and roughly what it's worth) and **Proof** (`UBER-AC-n`, the yes/no test). Plus **Non-goals** and **Rough cost** for both the chosen approach and the thin baseline.
- **§0.1 Decision Record** — the approach chosen, and **the thin baseline it beat**, with its estimate and the falsifiable reason it lost.

Three rules follow, and they matter more than everything in the numbered list below:

1. 🔴 **Reference §0; never restate it.** The plan's Goals table lifts §0's fields — it does not paraphrase them. This skill spends forty lines forbidding the plan from re-typing source bodies because a second source of truth drifts; **the goal is the thing you least want two versions of.** See "Plan Document Header".

2. 🔴 **PR-1 IS the Decision Record's thin baseline** — or the plan says why not. The spec has already written the thin version down, priced it, and recorded a falsifiable reason it lost. ⚠️ **Nothing has independently tested whether that reason is TRUE** — the spec review's Gate 1 was removed on 2026-08-13, so it carries only the author's own check and the user's read. **Test it here** before planning the larger approach: if it turns out false, amend §0.1, shrink the spec, and record it. Do not re-derive a thin version — consume the one that exists. See "Sequence by VALUE".

3. 🔴 **A false rejection reason discovered at plan time is a SPEC bug.** If you find, while planning, that "the scaffold doesn't exist" or "there's no endpoint for this" is untrue, **amend §0.1 and shrink the spec to match**, record it in spec §8, and carry on — do not quietly plan the larger approach anyway. That reason is the entire justification for the spec's size, and the plan is the last cheap moment to falsify it.

**Non-goals are a scope gate, not commentary.** Walk the finished task list against §0's Non-goals. A task that serves a non-goal is **cut, not debated** — the user already ruled on it, in writing, before the design existed.

### Triggered — present only when the spec's trigger fired

Sections 1-5 are conditional in `superpowers:brainstorming`. Their absence is **normal**, not a defect:

| Section | Trigger | Plan consumes it for |
|---|---|---|
| 1 · Artifact Inventory + graph | >1 PR, or >5 artifacts | task decomposition, IDs, phase column, critical path |
| 2 · Requirements + ACs | any user-visible behaviour change | AC-named test tasks, business/technical layering |
| 3 · Contracts & Data Models | a boundary is crossed | locked deliverables, consumer-side contract tests |
| 4 · Ownership Boundaries | new sole owner, or a second writer | enforcement artifacts + migration tasks (table below) |
| 5 · Risks / Spikes / Open Questions | an unknown worth a day | mitigation tasks, first-class spike tasks |

🔴 **Check the trigger, not the section.** When a section is absent, the spec carries a one-line N/A stating why. **That N/A is a claim, and the plan is well placed to falsify it** — if §3 says "no boundary crossed" and your task list adds an API route, that is a **spec bug**, not a missing section. Send it back; do not compensate for it in the plan.

Where a section IS present, the plan **must** consume it as authoritative input. Re-deriving task decomposition from prose is a plan failure — the spec already did that work.

Concretely:

1. **Tasks reference artifact IDs.** Every BUILD/CONFIGURE/CREATE artifact in the inventory becomes one or more plan tasks, and the task title names the ID (e.g., "Task 14 — A14: stub Plugin entry"). If an artifact is missing from the plan, that's a coverage gap; add the task.
2. **Phase ordering is honored.** Tasks inherit the phase from the artifact's `phase` column. The plan groups tasks by phase. PARALLEL_WITH artifacts are flagged as parallelizable; BLOCKED_BY relationships are respected by sequencing.
3. **Each AC becomes a named test task BEFORE its implementation task.** A `T-AC-9: healthz returns 200` becomes a test task (write the failing test, run it, watch it fail) that comes before the implementation task that satisfies it. Test names include the AC ID verbatim: `test('T-AC-9: healthz returns 200 with body', …)`. Same for `B-AC-N`. **The mapping is 1:1 both ways — no orphan test tasks:** every test task must trace to an AC, a spec invariant, or a documented failure mode; a test task tracing to none is bloat — don't add it (coverage is an outcome of the AC + edge-case set, never a target). **Before adding a test task, check an existing test doesn't already cover it** — in prism-indexed repos `prism search "<AC-ID>"` / `prism find-refs "<symbol-under-test>"` surfaces existing coverage (the AC-ID naming convention makes this a reliable lookup); reuse/extend rather than duplicate.
4. **Business ACs → integration / E2E tests; technical ACs → unit / contract / CI-step tests.** The plan tags each test task with its layer. Don't conflate them.
5. **Contracts are locked deliverables.** If §3 of the spec defines a contract (TS interface, DB schema, wire format), the plan lists those contracts as deliverables ahead of any task that consumes them. Changing a contract mid-plan requires a plan update — not a one-line patch.
6. **Risks inform ordering.** A high-severity risk gets a mitigation task or a verification milestone early in the relevant phase. A `medium`-severity risk that the spec says "lockfile pins exact patches" gets a concrete task: "Pin lockfile + wire integration tests."
7. **Spikes are first-class plan items.** Each spike from §5 (Risks, Spikes, Open Questions) is a real task with its timebox and stop condition copied verbatim. The plan does not silently fold the spike into the implementation; the spike's outcome may flip a downstream decision.
8. **Quality-bar / Polis-bar checks are phase gates.** "CI green," "all property tests pass," "perf benchmark within baseline," "ADRs filed" become explicit gate tasks at phase boundaries. A phase isn't "done" until its gate passes.

9. **Ownership-boundary declarations become enforcement artifacts in the plan.** For each owned entity/workflow declared in the spec's Ownership Boundaries section, the plan MUST include concrete artifacts that implement the chosen enforcement mechanism — and they appear in the artifact inventory like any other deliverable:

   | Spec enforcement mechanism | Required plan artifacts |
   |---|---|
   | **Lint rule** | (a) the custom lint plugin/rule source; (b) CI wiring (pyproject.toml / eslint config); (c) a synthetic-violation test that proves the lint fires on a fixture file containing a forbidden import |
   | **Runtime guard** | (a) the guard implementation (decorator, assertion, type wrapper); (b) unit tests for both pass and fail paths; (c) a test confirming the guard is engaged on the protected entry points |
   | **Package boundary** | (a) the namespace package / workspace config change; (b) a build-time test confirming forbidden cross-package imports fail to resolve |
   | **`AGENTS.md` / agent guidance** | (a) the AGENTS.md section addition naming the boundary, the read/write contracts, and the allow-list; (b) a cross-link from `CLAUDE.md` (and `.cursor/rules/` if Cursor is in use); (c) optional: a doctest-style example showing the correct access pattern |
   | **Documentation-only** | The plan must escalate this to the user before proceeding — documentation-only enforcement is acceptable only with explicit user approval and a TDR documenting why automated enforcement isn't feasible |

   The plan must also schedule the **migration tasks** named in the spec's Ownership Boundaries section: each existing violation listed (e.g., "module X currently imports the protected entity") becomes a concrete cutover task in the appropriate phase, with the shim and rollback path called out. The enforcement-activation task (e.g., "enable lint as build-failing instead of warn-only") is the LAST task in the migration sequence — never the first — to avoid blocking the cutover work.

**Never fake structure that isn't there.** A Sketch spec has §0 and §0.1 and nothing else, and that is correct — a plan that reports nine "missing section" gaps against it is reviewing the class, not the spec. Record in the plan's Inputs header which sections were present, which were declared N/A with their stated reason, and which N/A claims you checked.

---

## Plan Review — ONE dispatch, before the task list exists

🔴 **Dispatch when the PR table is written and BEFORE you write the task list.**
Per `plan-document-reviewer-prompt.md`.

This is the point of the whole thing. Resequencing PR-1 is the finding this
reviewer exists to produce, and against a finished plan that finding **is** a
whole-plan rewrite. Against a six-line PR table it costs six lines, and the tasks
are then written once, against an approved sequence.

One agent, three questions: is it aimed at the spec's goals · is it sequenced so
the user sees something first · is it true about the codebase as it is today.
`plan-check.sh` does every mechanical check first, and the reviewer is forbidden
from re-deriving any of it.

⚠ **This reviewer once ran three gates with two agents and thirteen coverage
bullets, and before that twenty-four categories.** Both are recorded in the prompt
file under "why the previous version added scope" — keep that section; it is why
the structure has not grown back.

**Nothing it returns blocks implementation.** Under "the goal is the only fixed
point", a verdict is evidence for the lead, not a gate — except a finding that
puts a goal at risk, which stops and asks the user. A review that can force rounds
is a second decision-maker.

**Why a reviewer at all, given the self-review:** the failure mode is not
sloppiness, it is confidence. On 2026-07-29 an architect review of a Foundry spec
— written the same day, self-reviewed, and believed correct by its author —
returned **eleven blocking issues**, including three that would have changed
production behaviour and three false statements about the existing codebase. One
of those ("this file has no URL synchronisation at all") had been asserted twice,
in writing, after a grep whose empty result was read as absence. No amount of
re-reading by the author would have caught it; a second party running the same
grep did, in minutes.

**Dispositions and stopping — read `review-termination.md`.** Every disposition
carries a `verify:` expression true only once it has landed, proven by a
**script** before anything is re-dispatched. **Declining is a first-class
disposition** with its own verify shape — without one, a declined finding and a
forgotten finding are mechanically identical and the safe move is always to apply,
which is how a review can only ever add. **The lead's disposition is the stopping rule**; another
round happens only when it returns OVER-SCOPED or MIS-SEQUENCED.

**Triage:**

| Finding | Action |
|---|---|
| Verdict not PROPORTIONATE | Resequence the PR table or cut. **Evidence for the lead, not a gate** — record the call either way. |
| Coverage gap `plan-check.sh` found (change ID with no task, AC with no test task, spike buried in prose) | Fix inline — cheap and unambiguous |
| Finding that serves no goal in §0 | **Defer to the plan's backlog section.** Defer is the default. |
| Recommendation that conflicts with an existing project convention | Drop — follow the convention |
| **Finding that invalidates a spec assumption** | **Amend the spec, record it in spec §8, proceed.** Do not paper over it in the plan. |
| **Finding that §0.1's thin-baseline rejection reason is false** | **Amend §0.1 and shrink the spec accordingly**, record it, proceed. The spec's whole size rested on it. |
| **Finding that puts a GOAL at risk** | 🔴 **Stop and ask the user.** The only stop there is. |

The last three rows matter most, and they changed: **implementation never blocks.**
A plan-time discovery that the spec was wrong is a **spec** bug, and the lead fixes
it *in the spec* and keeps going — it does not stop, and it does not compensate in
the plan. Patching it in the plan leaves the spec lying for the next reader, and
leaves the next plan built on the same false claim; stopping for it wastes the one
session that had the whole graph in view.

**The goal is the only thing that stops the run.** See "The goal is the only fixed
point" in `superpowers:brainstorming`, which carries the authority table and the
amendment record shape. Every amendment names the goal that forced it; one that
cannot name a goal is scope, and scope stops.


## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

**Scope runs the other way too.** If the spec is a Sketch and you are reaching for a PR table, phase gates or a base-branch checklist, the plan has outgrown its spec — and one of the two is wrong. Either the class was under-called at brainstorming step 5 (take it back to the user; that is their decision, not yours) or the plan is inventing ceremony. **Do not silently upgrade the mode**; an agent that quietly plans a Sketch as a Programme has re-created exactly the over-scope the class exists to prevent.

## Sequence by VALUE, not by layer — read before decomposing

🔴 **PR-1 delivers `G-1` — the user's first goal, proven by `UBER-AC-1` — as a
thin vertical slice. Not the foundation for it.**

The natural way to decompose is by architectural layer: model → service → routes
→ adapters → UI. It produces a tidy dependency graph and it is almost always
wrong, because **the user sees nothing until the last PR**. Over-scope, wrong
abstractions and a misaimed spec all stay invisible until the most expensive
possible moment to discover them.

Decompose by value instead. PR-1 takes the shortest path through **every** layer
for **one** case — one provider, one entity, one screen state — and ends with
something the **named beneficiary in §0 can actually use**. Later PRs widen it:
the second provider, the error states, the tiering, the generalisation.

### PR-1 is the Decision Record's thin baseline — do not re-derive it

**§0.1 already contains a written, estimated thin baseline** and the reason it
lost. That is your PR-1. Read it, and take one of exactly three paths:

1. **The thin baseline won** (§0.1's rejection reason turned out false, and the
   spec was cut back). PR-1 *is* it, and there may be no PR-2.
2. **The thin baseline lost for a true reason.** PR-1 is the shortest vertical
   slice through the *chosen* approach that still delivers `G-1` to its named
   beneficiary. Ugly is fine (below).
3. **You discover at plan time that the rejection reason is FALSE.** 🔴 **Stop.
   This is a §0.1 bug and it goes back to the spec.** The reason is the entire
   justification for the spec's size; planning the larger approach anyway buries
   a decision that was never actually made. This is the last cheap moment to
   catch it — an implementer will not.

Earlier versions of this skill told the reviewer to *"design the thin version
yourself before judging theirs."* That was re-deriving, blind and with less
information, a decision the author and the user had already made together. The
baseline is written down now. Check it; don't reinvent it.

### The check is a COLUMN, not a habit

Write the Goals table (see "Plan Document Header") and read down **"First
delivered in"**. **If any goal's first delivery is later than PR-2, the
decomposition is by layer and must be redone.**

This used to read *"write the PR table, then read down the ACs-verified column"* —
a thirty-second check that someone had to remember to run. As a required column it
is visible in the artifact: the failure shows up on the page, to anyone, including
the reviewer and you in a week.

⚠ **Measured, Foundry 2026-07-29.** A plan for a provider-telemetry panel
decomposed as model (PR-1) → classifier (PR-2/3) → routes (PR-5) → adapters
(PR-6) → **panel (PR-7)**. `UBER-AC-1` — the operator can see a limit, i.e. the
entire point — was verified by **PR-7 of 10**. A full day of work merged three
PRs of correct, well-tested backend and the user could still see nothing. The
thin vertical slice was one route plus one hook swap, because the panel scaffold
and the vendor endpoint both already existed. Under the Goals table, "First
delivered in: PR-7" would have been on the first page of the plan.

**A vertical slice is allowed to be ugly.** Hardcode the one provider. Skip the
cache. Serve the happy path. Those are follow-up PRs, and they are far cheaper to
prioritise once the user has seen the thing working.

## PR decomposition + branching model (Standard / Programme — a Sketch skips this)

A Standard or Programme plan is not just a task list — it is a **PR decomposition** with explicit branching and merge gates. **A Sketch plan skips this whole section**: one sub-branch, one merge gate at the end, taken from the PR-K gate below. The implementation runs on:

```
spec → feature branch (one per spec)
         ├── sub-branch for PR-1 (group of tasks delivering one logical unit)
         ├── sub-branch for PR-2
         ├── sub-branch for PR-N
         └── final integration → merge feature branch upstream (per project policy)
```

The plan must therefore include — alongside the task list — a **PR decomposition section** that groups tasks into PRs and names each PR's sub-branch, scope, ACs verified, contracts produced/consumed, and merge gate.

### Required: PR decomposition table

Every Standard or Programme plan includes a section like this near the top (after Phase 0 contracts, before the per-phase task list):

```md
## PR decomposition

**Feature branch:** `feature/<spec-id>` (long-running; integrates this spec end-to-end)

| PR | Sub-branch | Scope (tasks / artifacts) | ACs verified | Contracts produced | Contracts consumed | Frontend touched? |
|----|------------|---------------------------|--------------|--------------------|--------------------|-------------------|
| PR-1 | `feature/<spec-id>-pr1-skeleton` | Tasks 1.1–1.5 (A1, A2, N12, N1+N2+N5) | T-AC-1 | (none — workspace skeleton) | (none) | No |
| PR-2 | `feature/<spec-id>-pr2-types` | Tasks 1.6–1.9 (A5, A6, A7, A8) | T-M3, T-AC-14 | HealthzResponse, ErrorResponse, B1Hooks | (none) | No |
| PR-3 | `feature/<spec-id>-pr3-quality-bar` | Tasks 2.1–2.7 (A3, A4, A9, A11, A12, A13, A21) | T-AC-3..7, T-AC-19, T-AC-20 | (none — CI tooling) | (none) | No |
| PR-N | … | … | … | … | … | … |
```

### Required: per-PR authority — what is MINE, and what is NOT

A task that names the files it creates and modifies, and says nothing about the rest, tells a fresh subagent only half of what it needs. **Measured across 153 plans: 14 declare tasks "parallelizable" with each other; 3 of those say what the parallel task may not touch.** The other eleven dispatched concurrent implementers with a positive file list and nothing else — which is a merge conflict with a schedule.

Every PR carries three-valued authority, not two:

| | Meaning |
|---|---|
| `may_edit` | Yours. Change freely. |
| `may_edit_content` | **An approved mock or scaffold.** Change data flow, handlers, fetching, state wiring. **Do not** change component composition, route, or design tokens. |
| `must_not_edit` | Another PR owns it in this wave — with the reason, so it reads as coordination rather than mystery. |

🔴 **The middle value is the one that matters most.** Without it, `may_edit` grants a free hand over a screen a human already approved, and the approval is decorative — the implementer rebuilds the thing the mock phase existed to settle. **A PR containing any change with a `ux` block bases its branch on the mocks branch**, because on any other base the approved scaffold does not exist and the implementer builds the screen from scratch.

**Every handoff also carries the standing authority line, verbatim:**

> Naming, internal structure, helper decomposition and test fixtures are yours. Everything else in your payload is specified. If you need to change anything outside it — including because it appears impossible — stop and report to the lead with the element id and the goal it fails. Do not deviate: you can see one task, and the lead can see the whole graph.

Without it every word of a plan reads as normative, which produces both failure modes at once — implementers asking permission to name a variable, and implementers quietly redesigning an approved screen.

### Required: contention — resolved here, or discovered at 2am

**Two PRs in the same wave that can touch the same file are not parallel.** List every path touched by more than one PR and how it was resolved:

| path | touched by | resolution |
|---|---|---|
| `src/order/service.ts` | PR-2, PR-4 | **same PR** — PR-4's change folded into PR-2 rather than serialising a wave |

Resolutions are: `same PR` · `serialised` · `seam moved` · `extracted`. **`must_not_edit` IS the resolution, expressed per PR** — write it once, in both places, or the two drift.

🔴 **Heavy contention is a DESIGN signal, not a scheduling problem.** If three PRs must serialise on one file, the seams are wrong — amend the spec's §1 and record it, rather than planning around it.

### Required: waves, freeze points, and the migration slot

- **Every wave states why its PRs are safe together** — in one line, naming the fact that makes it true ("disjoint owned files; both consume the response shape frozen in wave 1"). A wave with no stated reason is an assertion of safety with nothing behind it.
- **Every dependency the spec marked stubbable gets a freeze point** — the contract is published before the wave that stubs against it. That is what turns "B needs A" from a wave boundary into two PRs running at once. Only the spec author knows which dependencies are stubbable; if the spec did not say, assume not, and raise it.
- **One exclusive migration slot per release**, ordered against the PRs that need it. Two PRs writing migrations in the same window collide on numbering at merge, not at write time, which is the expensive moment to find out.

### Required: four tests a breakdown can be FAILED by

**A PR is well-formed when all four hold.** Each is answerable yes or no, by anyone, without knowing the domain:

1. **It leaves the main line green and releasable** — behind a flag if it must be.
2. **It delivers at least one complete business promise end to end, OR unblocks at least two later PRs.** A PR that does neither is a layer, not a slice.
3. **One owner, and no file shared with another PR in its wave.**
4. **It is describable in one sentence.** If it needs two, it is two PRs — or one PR with a confused boundary, which is worse.

🔴 **Never split for parallelism alone.** A split must buy a removed wave boundary, an isolated gate, or a genuinely independent owner. **Wall-clock is not a reason:** the overhead of the second pull request — review, checks, quality gates, a reviewer's context switch — reliably exceeds the time the parallelism saves, and you get the merge conflict for free.

⚠ **These four supersede "one logical coherent unit of work, not by line count"**, which was the rule until 2026-08-12 and which no PR has ever failed — there is no reading of it under which a PR is not one coherent unit. A sizing rule that cannot reject anything is not a sizing rule.

**And they are outranked by the value check.** A PR can pass all four and still deliver the user nothing until the end. *"Read down 'First delivered in'"* catches that; these four do not. Where the two disagree, sequencing by value wins.

A PR that touches 30 files is fine if those 30 files are one coherent change. A PR that mixes unrelated changes is not.

### Per-PR merge gate (binding)

A sub-PR is **not** marked complete and **not** suggested for merge into the feature branch until the following are all green. This is the hard gate; the plan must declare it explicitly as the closing step of each PR's task group.

```md
### PR-K merge gate

Before suggesting merge of `<sub-branch>` into the feature branch:

- [ ] All ACs the PR claims to verify (column "ACs verified" above) have green tests
- [ ] Tests are named after the AC ID (`test('T-AC-9: …', …)` / `test('B-AC-1: …', …)`)
- [ ] Tests come BEFORE implementation in commit history (TDD evidence: failing-test commit precedes passing-test commit)
- [ ] All contracts the PR produces (column "Contracts produced") are exercised by at least one test that another component (or test fixture) consumes — not just isolated unit tests of the producer
- [ ] If frontend was touched: Playwright end-to-end test exists that triggers the behavior FROM the GUI and asserts the back-end effect (front-to-back). Unit tests on the front-end alone are not sufficient.
- [ ] No new `// @ts-ignore` / `// eslint-disable` in the diff
- [ ] Project quality-bar gates (typecheck, lint, coverage thresholds, property tests, perf benchmarks per spec quality bar) green on the sub-branch
- [ ] If the PR introduced a non-obvious decision: ADR file added under the project's ADR directory
- [ ] CHANGELOG.md updated for any user-facing change

Only then: mark the PR complete and suggest merge into the feature branch.
```

The phrase "suggest merge" is deliberate: the planner does not auto-merge. The implementer or reviewer makes the merge call after the gate is green. (If the project's review tooling — Review Agent, AI bot, etc. — wants to auto-merge after the gate, that's a project-level policy choice; the plan still produces the gate.)

### Frontend-touching PRs require Playwright E2E

If a PR's diff includes any frontend file (UI component, page, route, asset) — even a one-line text change — the merge gate requires a Playwright (or equivalent E2E framework) test that:

1. Starts the full stack (frontend + backend; for feature-branch work, the test runs against the dev server or a containerized stack the PR can spin up).
2. Drives the browser to the page the change affects.
3. Performs the user action that exercises the change (click, type, navigate).
4. Asserts both the frontend observable result (DOM / visible state) AND the back-end effect (API response, DB record, downstream service call) — front-to-back.

Unit tests on the frontend alone do not satisfy the gate for frontend-touching PRs. The reason: a green frontend unit test against a mocked backend can co-exist with a broken contract; the bug only surfaces when frontend and backend run together. We test contracts, not mocks.

For backend-only PRs (no frontend file in the diff), the gate's Playwright requirement is N/A; standard integration / contract tests are sufficient.

### Contracts are tested across the consumer boundary

Contracts (§3 of the spec) are the things downstream sub-specs and PRs rely on. A contract test is not "the producer's unit test passes" — it is "a consumer (or representative test fixture acting as a consumer) successfully uses the contract end-to-end." Concretely:

- For an HTTP contract: the consumer-side SDK calls the producer; the response shape is type-checked + asserted.
- For a TypeScript interface contract: at least one consumer file imports and uses the interface in a way that would fail at compile time if the shape changed; that file is in the test set.
- For a database schema contract: at least one query against the schema runs end-to-end (read or write) in an integration test.
- For an event / SSE / message-bus contract: a real consumer subscribes and asserts the payload shape on a real emission.

The PR-merge gate's "contracts exercised by a consumer" line is the hard check. If the producer ships without a consumer-side test, downstream PRs may discover contract drift later — which is exactly what the discipline is designed to prevent.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

If the spec's Artifact Inventory already names exact paths, **use them**. Do not re-design the file layout in the plan.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" — step
- "Run it to make sure it fails" — step
- "Implement the minimal code to make the test pass" — step
- "Run the tests and make sure they pass" — step
- "Commit" — step

For AC-mapped tests, the step name is the AC ID:
- "Write failing test `T-AC-9: healthz returns 200 with body`" — step
- "Run `T-AC-9` to verify it fails" — step
- "Implement A16 (Hono `/healthz` route) to make `T-AC-9` pass" — step

## Plan Document Header

**Every plan MUST start with this header:**

````markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Spec class:** Sketch | Standard | Programme  →  **Plan mode:** S | A | B
(If the spec declares no class, say so and name the one you inferred, with the reason.)

## Goals — lifted from spec §0. Reference, do not restate.

| Goal | Who benefits | Value delivered | Proof | First delivered in |
|------|--------------|-----------------|-------|--------------------|
| G-1 [spec §0] | [named role] | [what they gain] | UBER-AC-1 | **PR-1** |
| G-2 [spec §0] | … | … | UBER-AC-2 | PR-3 |

🔴 **Read down "First delivered in". If any goal lands later than PR-2, the
decomposition is by layer — redo it.** (Sketch: the column reads "this plan",
and the check is that the task list ends with the beneficiary able to use it.)

**Non-goals (spec §0) — a task serving one of these is cut, not debated:**
- [lift verbatim from the spec]

**Thin baseline (spec §0.1):** [what it was] · [its estimate] · [the reason it lost]
→ **PR-1 relationship:** is the baseline / shortest slice through the chosen approach / ⚠ reason found FALSE at plan time → back to §0.1

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

**Inputs:**
- Spec: `[path/to/spec.md]`
- Sections present and consumed: [list, e.g. §1 Artifact Inventory, §2 ACs]
- Sections declared N/A by the spec, with the spec's stated reason: [list]
- N/A claims I checked: [which ones, and the verdict — an unchecked N/A is a claim, not a fact]

---
````

## Task Structure

The task template applies the "Reference the spec, don't duplicate it" rule above. Test bodies and shell commands appear inline; implementation source bodies are referenced via spec section.

````markdown
### Task N: [Component Name] — [Artifact IDs covered, e.g. A14, A15]

**Phase:** P[N]
**Depends on:** [list of upstream task numbers / artifact IDs]
**Parallelizable with:** [task numbers, if any]
**ACs verified:** [list of B-AC-N / T-AC-N satisfied by this task]
**Spec sections consumed:** §3.<x>.<y> (source body for A<n>), §2.<z> (AC `T-AC-N` definition)

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

- [ ] **Step 1: Write the failing test `T-AC-N: <AC summary>`**

```python
def test_T_AC_N_AC_summary():
    # Given … When … Then … (verbatim from spec §2.<z>)
    result = function(input)
    assert result == expected
```

(Test bodies belong in the plan — the spec carries ACs in Given/When/Then form, not test code. The plan is the test author.)

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_T_AC_N_AC_summary -v`
Expected: FAIL with "function not defined" (or `ModuleNotFoundError` if the module doesn't exist yet)

- [ ] **Step 3: Implement A<n> per spec §3.<x>.<y> verbatim source body**

Path: `exact/path/to/file.py`
Spec source body: see spec §3.<x>.<y>

Plan-drift corrections to fold in (deviations the implementer must apply on top of the spec body):
- [list any — e.g., "use `default_factory=list` instead of `default=[]` per project ruff convention", or "leave OFF if spec body is byte-correct"]

(DO NOT paste the source body here. It's in the spec. Pasting creates a second source of truth that drifts.)

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_T_AC_N_AC_summary -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat(A<n>): <one-line summary> (verifies T-AC-N)"
```
````

**When is it OK to inline a code block in Step 3?** Only when:
- The artifact is so small (≤5 lines) that a spec reference adds friction without value (e.g., a one-line `__all__` extension, a stub `def x(): pass`), OR
- The change is purely mechanical drop-in code that the spec doesn't carry as a source body (rare — most well-formed specs do carry source bodies).

In both cases, the inline block is the EXCEPTION. The default is reference.

## Phase Gates (Standard / Programme — a Sketch has one phase)

At the boundary between phases, insert a gate task that verifies the phase's success criteria before the next phase begins. A gate is not optional; if a gate fails, work pauses until the gate is green.

Example gate task:

````markdown
### Gate: End of Phase P[N]

**Phase exit criteria** (from spec §[ref]):

- [ ] All P[N] artifacts implemented and committed
- [ ] All P[N] ACs have passing test tasks
- [ ] Quality bar:
  - [ ] `bun run typecheck` exits 0
  - [ ] `bun run lint` exits 0; max-warnings 0
  - [ ] `bun run test` exits 0; coverage thresholds met (90% statements / 85% branches)
  - [ ] Property tests for in-scope invariants pass
  - [ ] Performance benchmarks within ≤10% of baseline
  - [ ] ADRs for non-obvious P[N] decisions are committed
- [ ] No `// @ts-ignore` or file-level `eslint-disable` introduced
- [ ] CHANGELOG.md updated for user-facing changes

If any of the above fail, the phase is **not** complete. Fix and re-verify before opening the gate.
````

The exact gate criteria come from the spec's quality-bar section (Polis-bar, Foundry bar, etc.) and §3.3-style enforcement specifics. Don't invent gates the spec doesn't authorize.

## Spike Tasks — where the spec declares one

For each spike in the spec's §5, write a real task with its timebox and stop condition copied verbatim. Example:

````markdown
### Spike SP1: Verify `chat.params` end-to-end mutation

**Phase:** P[N] (must complete before A<dependent>)
**Timebox:** 0.5 day
**Stop condition:** confirmed yes (proceed) OR confirmed no (re-open soft-fork question with concrete evidence)

- [ ] **Step 1: Build a minimal Polis-shaped plugin that mutates `output.options.thinking`**

[concrete commands and code]

- [ ] **Step 2: Run a chat against Sonnet 4.6; capture outbound HTTPS via DEBUG-level logging or mitm proxy**

[concrete commands]

- [ ] **Step 3: Inspect captured request body; confirm `thinking` field is present**

- [ ] **Step 4: Record outcome in `docs/spikes/SP1-result.md`**

If outcome = confirmed yes → proceed with downstream tasks unchanged.
If outcome = confirmed no → STOP. Escalate to user before continuing; the soft-fork decision must be re-opened.
````

## Risk-Mitigation Tasks — where the spec declares one

For each risk in the spec's §5 with severity ≥ medium, the plan must contain either a concrete mitigation task or a verification milestone. The risk's mitigation column tells you what to do; lift it into a task. Don't bury risks in narrative.

## No Placeholders

Every step must contain the actual content an engineer needs OR a precise pointer to where the content lives. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code — test bodies belong in the plan)
- "Similar to Task N" (either reference the spec section or repeat the test body)
- Steps that describe what to do without saying HOW or pointing to WHERE
- References to types, functions, or methods not defined in the spec, the codebase, or any prior task

**The "reference, don't duplicate" rule is not a placeholder.** A step that reads "Implement A4 per spec §3.2.4 verbatim source body, path `apps/.../file.py`, with these corrections: [list]" is COMPLETE — it tells the implementer exactly what to do, where to put it, and where to read the source. The information density is unchanged; only the source-of-truth is consolidated.

## Remember

- **§0 is referenced, never restated.** The Goals table lifts the spec's fields verbatim. The goal is the thing you least want two versions of.
- **PR-1 delivers G-1 to its named beneficiary**, and is §0.1's thin baseline unless the plan says why not
- Exact file paths always
- Test INTENT, shell commands and short illustrative snippets inline — never a test body
- Implementation source bodies referenced via spec section, NOT pasted (see "Reference the spec, don't duplicate it")
- Exact commands with expected output
- **The plan's weight follows the spec's class**, and the class is the user's call
- **A plan-time discovery that the spec is wrong is fixed IN THE SPEC and recorded** — never compensated for in the plan, and never a reason to stop. Only a goal change stops.
- DRY, YAGNI, TDD, frequent commits

## Self-Review — four checks

After writing the plan, check it against the spec with fresh eyes.

**This list is deliberately short.** It ran to thirteen checks, eight of which duplicated the plan reviewer's own categories — and because the author's pass runs FIRST, those duplicates grew the plan before goal fit was ever judged, contaminating the baseline the review measures against. Everything a reviewer does better has been removed. Everything mechanical is now a script.

**It does NOT replace the plan review.** An author cannot reliably catch a mistake they were confident enough to write — the same reason `superpowers:brainstorming` dispatches a reviewer after its own self-review.

**1. Run the mechanical check — don't read for it.**

```bash
bash skills/writing-plans/scripts/plan-check.sh <plan.md> <spec.md>
```

It fails on placeholder markers, on any spec artifact ID or AC ID with no task, on a test task that comes after the implementation it verifies, and on forbidden code blocks (full source bodies, re-stated type signatures) that should be spec references. It reports the Goals table's "First delivered in" column without judging it — that read is yours, in check 2.

**Positive-control it before you trust it:** delete a task for one artifact ID and watch it go red. A gate never seen failing is a claim, not a measurement.

**2. Read down "First delivered in".** Any goal landing later than PR-2 means the decomposition is by architectural layer — redo it. Then confirm PR-1's relationship to §0.1's thin baseline is stated and honest: it either IS the baseline, or is the shortest vertical slice through the chosen approach, or you found the rejection reason false — in which case **amend §0.1, shrink the spec, record it** rather than planning the larger approach anyway.

This is the only check that catches a plan which is complete, correct, well-tested and delivers nothing anyone can see until the end.

**3. Non-goals scope walk.** Read §0's Non-goals, then read your task list. **A task serving a non-goal is cut, not debated** — the user ruled on it in writing before the design existed. This costs thirty seconds and it is the cheapest scope control the plan has.

**4. Spec contradictions — the check only the author can run.** Walk your tasks and ask: does any of them only make sense if a spec claim is FALSE? Did you silently work around something? Did you assume a shape the spec doesn't declare?

Only you know what you had to assume to make a task work; a reviewer sees the finished plan, where the assumption is invisible. Every hit here is a **spec bug**: amend the spec and record it in §8. Do not let the plan quietly compensate — that leaves the spec lying for the next reader, and the next plan builds on the same false claim.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

**Where the other nine checks went:** spec coverage, artifact-ID coverage, AC-test mapping, type/contract consistency, reference-don't-duplicate, placeholder scan → check 1's script · contracts-locked, risks/spikes allocated, phase gates, PR decomposition + merge gates, business-vs-technical layering → the reviewer's coverage step · codebase grounding → the reviewer's drift step.

## Pre-implementation checklist

Every Standard or Programme plan ends with a "Pre-implementation checklist" — a short list of conditions the user can scan before any code is written. Examples:

A **Sketch** plan keeps exactly two lines of this — the spec-approved line and the base-branch line with its numbers. The rest (branch policy, spike outcomes, stakeholder effort estimates) is Standard/Programme ceremony. **The base-branch line is not optional at any mode**: it is the one item here that has actually cost a day, and it costs the same day on a one-route change.

- [ ] Spec is approved by user; no open changes pending
- [ ] All upstream dependencies merged / available
- [ ] Branch policy confirmed (target branch named; sub-PR strategy decided)
- [ ] **The BASE BRANCH is green on every gate, MEASURED not assumed** — see below
- [ ] Provider / repo access (e.g., GitHub repo `Fintama/polis` exists; org owners briefed)
- [ ] Outstanding spike outcomes recorded (SP1, SP2, …)
- [ ] Effort estimate communicated to stakeholders

### The base-branch line is mandatory, and it carries numbers

A plan whose checklist says "rig healthy" and "isolated test DB" but never asks
whether **the branch being built on already passes its own gates** has left its
largest schedule risk unmeasured. Write the line so it cannot be ticked from
memory — it must record the actual readings:

```
- [ ] Base `<branch>` @ `<sha>` green: tsc 0 · tsc -p tsconfig.test.json 0 ·
      complexity 239/239 · lint 0 new · tests 251 green   ← run these, paste the numbers
```

**Measured 2026-07-29, Foundry provider-capacity.** The spec and plan were sound
and the feature was small. The base branch was not: it carried 3 complexity
violations over an enforced ratchet and a red second typecheck config, neither
of which any checklist asked about. Both were discovered *during* task 1 — one by
a commit being blocked, one by an implementer — and clearing them meant
refactoring three untested functions (27 characterization tests written first)
wedged between the plan and its first task. It dominated the elapsed time and
none of it was the plan's work.

Two rules follow:

1. **Enumerate every gate the CI runs, not the ones you remember.** A repo with
   two typecheck configs has two gates. Checking one and writing "typecheck
   green" is a false claim, and it is the easiest one to make by accident.
2. **A red base gate becomes an explicit task zero in the plan, or the plan
   picks a different base.** Decide it while writing the plan, where it is a
   scoped task with an owner — not mid-execution, where it is an interruption
   that also blocks every commit behind it.

⚠ This is a *planning-time* check. `subagent-driven-development` re-runs it as a
pre-flight before dispatching task 1, because time passes between the two and
other branches land in the gap.

## Execution Handoff

After saving the plan, offer the right next-step.

> "Plan complete and saved to `<filename>`. Two execution options:
>
> **1. Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration.
>
> **2. Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints.
>
> Which approach?"

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:subagent-driven-development
- Fresh subagent per task + two-stage review

**If Inline Execution chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:executing-plans
- Batch execution with checkpoints for review
