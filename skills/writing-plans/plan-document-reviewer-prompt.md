# Plan Review — one dispatch, before the task list exists

**Purpose:** decide two things and nothing else. Is the plan aimed at the spec's
business goals and sequenced to deliver them first? And is it true — about the
spec it claims to implement, and about the codebase as it is today?

🔴 **Dispatch when the PR table is written and BEFORE the task list is.**

This is the change that matters most. The review used to run against a finished
plan, so any structural finding — and resequencing PR-1 is the finding this
reviewer exists to produce — meant rewriting a finished document. Reviewing a
six-line PR table and resequencing *that* costs nothing; the tasks are then
written once, against an approved sequence.

**One dispatch, not three.** The plan no longer carries content: the spec's
changes carry `depends_on`, `atomicity`, `seam` and `mechanism`, and
`plan-check.sh` covers every mechanical check. What is left needs judgement, and
it fits in one agent.

---

## Proportionality

A Sketch-class plan is a task list with one merge gate. Reviewing it for a PR
table, phase gates or a contention section is **reviewing the class, not the
plan** — and it is itself a finding against the reviewer.

## Run the script first

```bash
bash skills/writing-plans/scripts/plan-check.sh <plan> <spec>
```

It reports change-ID coverage, AC coverage, the Goals table, placeholders and
forbidden blocks. **Do not re-derive any of it.** Your job is what it cannot
judge. Run it **unpiped** and read `$?` on the bare command — a pipe returns the
last command's status, and `${PIPESTATUS[0]}` is empty under zsh.

## Why the previous version added scope

The old template ran **24 categories** for a task-level plan — three shared,
twenty-one specific — plus a Check 0 for goal fit, on top of a thirteen-check
author self-review. **Thirty-eight finding-generators over one plan.**

Its output format had labelled slots for Critical, Blocking, Spec bugs and
Recommendations — and **no slot for the goal-fit verdict**. Check 0 was declared
to "outrank everything below" and was the only check with nowhere to put its
answer. An agent handed twenty-four labelled categories fills twenty-four
labelled categories; a blank one reads as a shirked job.

Then three gates replaced them, which was better and still too heavy: Gate 2(a)
carried thirteen coverage bullets that re-derived by hand what `plan-check.sh`
already reported, and Gate 1 returned "a resequenced PR-1" as a BLOCKING verdict
against a finished document — a whole-plan rewrite by construction.

Hence, below: **no per-category sections, one dispatch, and the script does the
mechanical half.** Returning nothing is normal.

## The failure this exists to catch

⚠ **Measured, Foundry 2026-07-29.** A telemetry-panel plan ran to 10 PRs and 17
tasks. `UBER-AC-1` — the operator can see a limit, the entire point — was
verified by **PR-7**. The panel scaffold and the vendor's quota endpoint both
already existed, so the real work was one route plus one hook swap. A full day
merged three PRs of correct, well-tested backend and the user could still see
nothing. Three reviews passed the artefacts as good. None asked whether they
were the right artefacts, and none asked *when the user would first see
anything*.

---

# THE DISPATCH

```
Task tool (general-purpose):
  description: "Plan review — aim, sequencing, truth"
  prompt: |
    You are a senior architect reviewing a PR decomposition BEFORE its task list
    is written. Your questions are whether it is aimed at the spec's goals,
    sequenced to deliver them first, and true about the codebase as it is today.

    You are explicitly FORBIDDEN from reporting wording, task granularity,
    "nice to have", architecture opinions, or anything `plan-check.sh` already
    reports. If you notice something outside your three questions, put it under
    OUT-OF-SCOPE OBSERVATIONS, one line, and expect it to be deferred.

    **Plan (PR table):** [PLAN_FILE_PATH]
    **Spec:** [SPEC_FILE_PATH]
    **plan-check.sh output:** [SCRIPT_OUTPUT]
    **What the user originally asked for, verbatim:** [USER_REQUEST]

    ## Step 1 — Restate the spec's §0 in your own words, before reading the plan

    Read ONLY spec §0 Business Goals & Value and §0.1 Decision Record. Write,
    without reading the plan:

      - each goal in one line, with WHO benefits and WHAT they gain
      - the non-goals
      - the thin baseline, its estimate, and the reason it lost

    If §0 cannot support this — a missing field, a beneficiary named as "the
    system", a Value field that says "better" — **STOP and return
    `§0 NOT REVIEWABLE`.** A plan cannot be reviewed for aim against a spec that
    does not state one.

    ## Step 2 — Read down "First delivered in". THE DECISIVE CHECK.

    **If any goal's first delivery is later than PR-2, the decomposition is by
    architectural layer and the user sees nothing until the end.** Name the thin
    vertical slice PR-1 should be instead — through every layer, one case only.

    If the plan has no Goals table, or the column is absent, that is itself the
    finding: a plan whose aim cannot be checked will be aimed by accident.

    **A plan that reports this check firing, with its reason, has NOT failed it.**
    Judge the reason. Sometimes three goals genuinely map to three artefacts with
    real dependencies, and every group is independently useful the moment it
    lands — which is not the failure this check exists to catch. What you are
    looking for is *nobody sees anything until the end*.

    ## Step 3 — PR-1 against §0.1's thin baseline. Do NOT design your own.

    The spec already contains a written, estimated thin baseline and a
    falsifiable reason it lost. Your job is not to invent a cheaper plan; it is
    to check that this one honours a decision already made with the user in the
    room.

      - claims PR-1 **is** the baseline → check that it actually is
      - claims the baseline lost for a true reason → PR-1 must still be the
        SHORTEST vertical slice through the chosen approach that delivers G-1
      - claims the reason is FALSE → the spec should have been amended and
        shrunk, and the amendment recorded in spec §8. Confirm it was.

    ## Step 4 — Non-goals, and what already exists

    Any PR serving a spec non-goal is scope the user ruled out in writing before
    the design existed. List them.

    Then: over-scope hides as "build X" where X exists in another form. Check the
    plan's ADDED work against the codebase and cite `file:line` for each near
    neighbour.

    ## Step 4b — Is each PR well-formed? Four tests, yes or no each

    Not an opinion about size. Four questions with answers:

      1. does it leave the main line green and releasable?
      2. does it deliver ≥1 complete business promise end to end, OR unblock ≥2
         later PRs? (neither = it is a layer, not a slice)
      3. one owner, no file shared with another PR in its wave?
      4. describable in one sentence?

    🔴 **And the one that catches the opposite failure: was anything split ONLY to
    run it in parallel?** A split must buy a removed wave boundary, an isolated
    gate, or a genuinely independent owner. Wall-clock is not a reason — the
    second pull request's overhead exceeds the time saved. A genuinely
    independent split, with a different owner and no shared files, PASSES; this
    is not an anti-split bias.

    ## Step 5 — Sequencing that would WASTE work

    Not "sequencing I would have done differently" — sequencing where work
    already done gets thrown away:

      · a spike whose outcome can invalidate PRs scheduled before it
      · a contract consumed before it is produced
      · a base branch not green on every gate the CI runs, with no task zero.
        **Enumerate the gates the repo actually runs, not the ones you
        remember** — a repo with two typecheck configs has two gates.
      · two PRs in one wave that touch the same path with no resolution recorded
      · an unhappy path with no PR at all: stale data rendered as fresh, partial
        failure, an unexpected payload, concurrent writers, absent-vs-zero

    ## Step 6 — False claims about the codebase AS IT IS TODAY

    The spec may have been grounded days ago; commits land in between. For every
    PRE-EXISTING identifier the plan names, confirm it still exists where claimed
    (`prism search` / `def` / `find-refs` in prism-indexed repos, else grep).

    **This is the highest-value plan-time check**, because it catches drift
    introduced BETWEEN spec-write and plan-write that no earlier gate could see.

    ## Pricing — every finding carries both lines

      **Breaks if shipped without it:** <the concrete failure, and who hits it>
      **Costs to apply:** <what changes, and which PR it lands in>

    🔴 **A finding with no answer to the first line is dropped by YOU, here.** An
    unpriced finding is always locally worth applying, which is exactly how a
    review adds scope.

    🔴 **"Costs to apply" MUST name the PR.** A finding that adds work to PR-1
    pushes the user's first delivery later, and that is this artifact's
    characteristic failure. Re-read the column with your own findings folded in
    before you return them.

    ## Output

    A single flat list. No per-category sections. No counts.

    🔴 **Returning nothing is a normal and successful outcome, and needs no
    explanation.** Do not pad.

    VERDICT: PROPORTIONATE | OVER-SCOPED | MIS-SEQUENCED | §0 NOT REVIEWABLE

    §0 as I read it:        <goals, beneficiaries, value, non-goals>
    First delivered in:     <one line per goal — PR number, pass or fail>
    Well-formedness:        <one line per PR — which of the four tests it fails, or "4/4">
    Split for speed alone:  <which PRs, or "none">
    PR-1 vs thin baseline:  <the plan's claim, and my verdict on it>

    RESEQUENCED PR TABLE — only if MIS-SEQUENCED
    <the six-line table it should be. A TABLE, never a rewritten plan.>

    FINDINGS
    - [PR ref] <what is wrong> — <evidence: file:line or spec §> — <fix>
        Breaks if shipped without: <...>
        Costs to apply: <what, lands in PR-K>

    SPEC BUGS — the lead amends the spec and records it; the plan does not
    compensate
    - [spec §] <the claim the plan cannot honour> — <evidence>

    OUT-OF-SCOPE OBSERVATIONS
    - <one line each, or "none">
```

---

## After the review

**Nothing here blocks implementation.** The lead disposes of each finding and
records what it did:

| Finding | Action |
|---|---|
| Coverage gap the script found | Fix inline — cheap and unambiguous |
| Priced finding serving a goal in §0 | Apply |
| Finding serving no goal in §0 | **Defer to the plan's backlog.** Defer is the default. |
| Conflicts with an existing project convention | Drop — follow the convention |
| SPEC BUG | **Amend the spec, record it in spec §8, proceed.** |
| Puts a GOAL at risk | 🔴 **Stop and ask the user.** The only stop there is. |

🔴 **A review that can force rounds is a second decision-maker.** Under "the goal
is the only fixed point", a verdict is evidence for the lead, not a gate — except
where a goal is at risk. `MIS-SEQUENCED` is the strongest signal this reviewer
produces and it is still the lead's call, recorded either way.

Then read `review-termination.md`: dispositions are verified by a **script**, not
a reviewer, and **declining is a first-class disposition** recorded with its
reason. Without that shape a declined finding and a forgotten one are
mechanically identical, so the safe move is always to apply — and a review that
can only apply can only add.

## Where the old categories went

| Old | Now |
|---|---|
| Check 0 — goal fit | **Step 2**, with the verdict slot it never had |
| Spec alignment · change-ID coverage · AC-test mapping · layer separation · contracts locked · risk mitigation · spikes first-class · phase gates · quality bar · PR decomposition · per-PR merge gate · frontend-touch detection · contract-consumer test | **`plan-check.sh`** — mechanical, and it compares two documents rather than counting strings in one |
| Codebase grounding | **Step 6** — highest value, never skipped |
| Riskiest-first sequencing · simplify / robust (unhappy paths) | **Step 5** |
| Spec-contradiction check | **SPEC BUGS**, plus the author's own self-review |
| Reuse before build | **Step 4** |
| Completeness · placeholders · type/contract name consistency | `plan-check.sh` |
| Buildability · task granularity | **dropped.** An implementer blocked by a vague task says so in seconds, and that signal is cheaper and more accurate than a reviewer predicting it. |
| Gate 2 as a separate agent · Gate 3 as a resumed session | **folded into the one dispatch.** With coverage in the script and the review running before the tasks exist, there is no longer a merged result large enough to need a third pass over it. |
| Mode-awareness | **removed with the modes** (2026-08-12) |
