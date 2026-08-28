# Review Termination — how a review loop stops

Applies to the spec review (`brainstorming` step 9, Gates 1-3) and the plan
review (`writing-plans`, Gates 1-3). Both are MANDATORY; neither said when
to stop, and that is what produced the loop this file exists to close.

## The measurement

Foundry, 2026-07-29, provider-capacity spec:

| Pass | Blocking findings | Genuinely new |
|---|---|---|
| 1 (full review) | 11 | 11 |
| 2 (full review) | 13 | **~3** |

The other **~10 findings in pass 2 were pass-1's own dispositions that had never
been applied to the spec body.** The findings table recorded them as done. They
were not in the file. A senior reviewer spent ~160k tokens and nine minutes
re-deriving *"the thing you wrote down as fixed isn't there"* — and the three
real findings had to compete for attention with that noise.

Two distinct failures, needing two distinct fixes:

1. **The disposition was never verified.** That is not a review problem. It is
   cheap, mechanical, and must never be an agent's job.
2. **The re-review was unbounded.** A full re-read of a large artefact always
   finds *something*, so "review again after fixing" does not terminate.

## Rule 1 — dispositions are machine-checkable

Every finding row carries a **`verify:`** expression alongside its disposition:
a grep, a count, or an assert that is **true only once the fix has landed**.

```
| # | Finding | Disposition | verify: |
|---|---|---|---|
| 5 | `lastSubscriptionTurnAt` absent from the §3 type block | Added to `ProviderCapacity`, per-config | `awk '/interface ProviderCapacity/,/^}/' <spec> \| grep -c lastSubscriptionTurnAt` → ≥1 |
| 8 | grep-enforcement test fails on day one | Enforce on call sites, not the literal | `grep -c 'Enforce on the call site' <spec>` → 1 |
```

Then a **script** proves each fix landed before any reviewer is dispatched.
A disposition with no `verify:` is not done — it is a claim, and *a claim is not
a measurement*. This is `positive-control every gate` applied to prose.

Write the `verify:` expression to match the **fix**, not the finding. `grep -c
"<old wording>" → 0` is weaker than asserting the new wording is present: text
can be deleted without the fix being made.

⚠ **Scope the check to the artefact BODY, excluding the findings table itself.**
The table quotes its own needles in the `verify:` column, so an unscoped run
inflates every count by one and makes every "must be 0" check unsatisfiable.
Measured: the first run of this rule on the Foundry capacity spec failed 9 of
16 checks for exactly this reason, with every fix correctly in place. Cut the
review-record sections first:

```bash
BODY_END=$(grep -n '^## §<first review section>' "$SPEC" | cut -d: -f1)
head -n $((BODY_END-1)) "$SPEC" > /tmp/body.md   # then grep /tmp/body.md
```

A findings table is a review *record*: it is supposed to contain the old
wording it reports on. Only the body must be clean.

⚠ **Two more needle traps, both measured on the same spec:**

1. **Never let a needle span a line wrap.** `grep -c 'DERIVED billing mode'`
   returned 0 against a correct fix, because the phrase wrapped after
   "DERIVED billing". Keep needles short enough to sit on one line, or grep a
   distinctive single token.
2. **Assert the claim holds EVERYWHERE, not that one string appears somewhere.**
   A fix for "the spec states an impossible primary key" landed in §3 and was
   verified there — while §3.5 went on asserting the same impossible key. The
   check passed; the defect survived. Where a claim can appear in more than one
   section, verify with a **negative** check over the whole body (`grep -c
   "<the wrong assertion>"` → 0) *in addition to* the positive one. A positive
   check proves the fix exists; only a negative check proves the defect does
   not.

## Rule 1b — declining is a first-class disposition

A finding may be **declined** or **deferred**, and that must be recordable, not
merely absent. Give it the same row shape:

```
| # | Finding | Disposition | verify: |
|---|---|---|---|
| 7 | No idempotency strategy for the replay path | DECLINED — replay is a non-goal (§0); single consumer, at-most-once is correct here | `grep -c "replay" <spec backlog section>` → ≥1 |
| 9 | Quota panel could also show a historical trend | DEFERRED to backlog — serves no goal in §0 | `grep -c "historical trend" <spec backlog>` → ≥1 |
```

⚠ **Without this shape the gate silently pushes every finding toward
application.** If the only verifiable disposition is "the fix landed", then a
declined finding and a forgotten finding are mechanically identical — so the safe
move is always to apply, and a review that can only apply can only add. The
verify expression for a decline asserts that the *reason was recorded*, which is
exactly as checkable as a fix.

**Declining is the DEFAULT for any Gate 2 finding, spec or plan.** Applying requires
an affirmative answer at Gate 3, not the absence of an objection.

## Rule 2 — Gate 3 is the stop

Both mandatory reviews — the spec review (`brainstorming`) and the plan review
(`writing-plans`) — end at **Gate 3**, which re-asks Gate 1's question against the
merged result. So "review it again after fixing" has an answer built in: the
review is complete when Gate 3 returns PROPORTIONATE.

Another round happens only when Gate 3 blocks:

| Review | Gate 3 blocks when | Meaning |
|---|---|---|
| Spec | `OVER-SCOPED` | the applied findings grew the spec past the shortest route to §0 |
| Plan | `OVER-SCOPED` or `MIS-SEQUENCED` | the applied findings grew the plan, **or pushed a goal's first delivery later** |

That second one is the plan's characteristic failure and it has no analogue on the
spec side: findings add tasks, tasks land in early PRs, and the user's goal slides
right while every check stays green. Gate 3 rebuilds the "First delivered in"
column after the merge and compares it to the one Gate 1 recorded.

A further round is **Gate 3 again over the revised set** — not a fresh Gate 1, not
a fresh Gate 2.

The delta-scoped rule below is the general form. It governs any other mandatory
review that has no Gate 3.

## Rule 2b — re-review is delta-scoped, with an explicit stop

**Round 1:** full review. Unavoidable — the design needs one whole-artefact
architectural read.

**Round N>1:** two bounded passes, neither of them a full review.

1. **Disposition verification** — run the `verify:` expressions. No agent.
2. **Delta review** — dispatch scoped to the diff only. A fix can introduce a
   new defect; that is real and worth catching. Nothing else is in scope.

**Stop when** every disposition verifies present AND the delta review returns
nothing blocking **in changed text**.

**Findings outside the diff do not start another round.** They go to a backlog
section in the artefact itself, where the next reader will see them.

**Severity bar for round ≥2:** only **goal fit**, correctness, contract
violations, and false claims about the codebase block. Recommendations, taste,
and wording never do. Without this bar a large artefact always yields another
round.

⚠ **Goal fit is on that list deliberately, and it was once missing.** An earlier
version of this bar named only the three correctness classes — so from round 2
onward every scope-ADDING finding could block and the single scope-REMOVING one
could not. The rule meant to stop the loop was quietly inverting the priority the
reviewer itself declared. An over-scoped verdict blocks in every round.

**Reset to a full review** on a substantive design change only — a new tier, a
new component, a changed contract. The shape changed, so the whole no longer
coheres the same way. This must be rare and explicit; "I edited several
sections" is not a reset.

## Dispatching a delta review

Use the same reviewer prompt, with the scope replaced:

> **This is a DELTA review, round N.** Round 1's findings and their dispositions
> are in §<X>. Do NOT re-review the whole artefact.
>
> Scope: the diff below / the following changed sections: <list>.
>
> Report only: (a) defects **introduced** by these changes, (b) dispositions
> from §<X> that are recorded as applied but are **not actually present** in the
> body, (c) contradictions the changes create with unchanged sections.
>
> Blocking bar: correctness, contract violations, false claims about the
> codebase. Recommendations and taste are explicitly out of scope this round —
> if you have them, list them under a separate non-blocking heading and expect
> them to be deferred.

## Why this is not a licence to under-review

Round 1 stays full, unbounded, and adversarial. The bar drops only after the
design has had one complete architectural read and the remaining question is
narrower: *did the fixes land, and did they break anything?* That question does
not need seven dimensions.
