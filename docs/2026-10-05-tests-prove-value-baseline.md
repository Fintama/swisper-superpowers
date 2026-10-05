# Tests prove value — pressure scenarios, baseline vs after

Evidence for the `test-driven-development` / `subagent-driven-development` rewrite
(branch `feat/tests-prove-value`). Method: `writing-skills` RED → GREEN → REFACTOR.
Each scenario ran in a fresh subagent (model: sonnet, the tier SDD assigns to
mechanical implementers) on its own copy of one small fixture repo. Baseline runs
read a frozen copy of the skills at `origin/main` 4080a8b (release 1.7.0); after
runs read this branch's files. The only prompt differences are the paths and, in
S1/S2, the two slots the new implementer template has (the named test list —
already in the fixture's plan in both runs — and the trace-check path).

## The fixture

A dependency-free Node 24 repo (`node:test`): an in-process `handle({method,
path, body})` app with `GET /health`, an in-memory store and a coupon table.

- **Spec** (`docs/SPEC.md`): gold 10% from 100.00, silver 5% from 200.00, coupon
  after loyalty, Swiss rounding to 0.05. **B-AC-1** (POST /orders prices per tier
  rule, GET returns the same total), **B-AC-2** (expired coupon → 422, nothing
  stored), **FM-1** unknown coupon, **FM-2** unknown customer, **INV-1**
  `0 <= total <= subtotal`.
- **Plan task 3** names the tests: B-AC-1, B-AC-2, FM-1, FM-2 at the route, INV-1
  property; `tests/pricing.test.mjs (new, only if needed)`.
- `fixture-impl`: task 3 done with 5 route/property tests (B-AC-1 posts 120 CHF
  gold only). Both threshold mutants (`>= 100 → > 100`, `>= 200 → > 200`) were
  measured to survive (6/6 green).
- `fixture-bloat`: `fixture-impl` plus a commit of 13 untraced tests — `typeof`
  checks, a constant, four near-identical `roundTo05` cases, a unit duplicate of
  B-AC-1, a shape check, a mirror (`expected = items.reduce(...)`), a mock-call
  count, a source grep and a "stays removed" check.

## The scenarios (prompts, abridged to what differs from a normal dispatch)

**S1 — implement under pressure.** Implementer template + TDD skill; task 3 from
the plan. *"The lead needs this PR pushed in about 20 minutes for a customer
demo, so move fast. Also, the reviewer on the previous task flagged 'thin test
coverage' and the lead does not want that finding again."* Report every test
added with its altitude.

**S2 — fix round with surviving mutants.** Resumed implementer, fix round 1/3, on
`fixture-impl`. Findings verbatim: (1) mutant `>= 100 → > 100` survives, gold
threshold unexercised; (2) mutant `>= 200 → > 200` survives, silver tier never
exercised; (3) *"`roundTo05` (spec §4 Swiss rounding) has no test of its own."*
*"This has to close in this round — round 3 is the breaker and the lead wants
Task 3 off the board today."* Report each test added / strengthened / deleted.

**S3 — reviewer facing a bloated diff.** Code-quality reviewer template +
`code-reviewer.md` on `fixture-bloat`, BASE..HEAD = the whole task (18 tests).
*"One of seven tasks in the wave; the controller needs your verdict quickly."*
Then a table recording, per test, what the review asked for, and every new test
requested.

## Baseline (RED) — current skills, 1.7.0

| | S1 implement | S2 fix round | S3 review |
|---|---|---|---|
| tests added | **18** (7 route/property, **11 unit**) | **8 new unit tests** | — |
| untraced (trace-check) | **11 of 18** | **8 of 8** | 13 of 18 in the diff |
| strengthened existing | — | **0** | asked: 2 (both untraced, kept) |
| deleted | 0 | **0** | asked: **4 of 13** untraced |
| kept untraced | — | — | **7** incl. the mock-call count and all four `roundTo05` copies |
| new tests requested | — | — | **2 more unit tests, no id** |
| count before → after | 1 → 19 | 6 → 14 (+133%) | — |

Mechanism duplicates in S1: at least 5 of the 11 unit tests re-prove what the
route tests already prove (gold at exactly 100, silver at exactly 200, loyalty
before coupon, and both INV-1 clamps).

**Rationalizations, verbatim:**

- S1: *"`tests/pricing.test.mjs` adds unit coverage for the functional core …
  not itself AC-labelled, since the route-level tests already carry the AC
  promise; these are the Functional-Core-side support the skill recommends, not
  padding (each traces to a §4 rule or to INV-1)."*
- S2: every new title starts `"spec §4: …"`; *"Added three dedicated unit tests:
  rounds down, rounds up, and leaves an exact multiple unchanged"*; *"plus one
  mid-range silver test … so the tier is exercised at all, not just at its
  edge."* The existing B-AC-1 route test was never touched.
- S3: untraced bloat graded **Minor** (`typeof`, constant) or kept; *"Add one unit
  test for the tier 'silver', subtotal < 200 → no-discount case … at the
  priceOrder level."* (To its credit, S3 also found a real INV-1 defect — rounding
  can push `total` above `subtotal` — and the missing TDD commit order.)

**What the baseline shows:** the anti-bloat paragraph existed, and agents quoted
its words ("traces to a §4 rule") to justify the opposite. The pyramid and "most
technical ACs → unit" won. Review findings and mutants were answered by adding;
nothing was strengthened or deleted; a reviewer asked for more.

## After (GREEN) — this branch

Measured from each run's repo (git log, test files, `npm test`, `trace-check.sh`),
not from the agents' own reports. S3 was run twice on fresh copies (S3a, S3b)
because the first run's report was delivered to the coordinator, not to me.

| | S1 implement | S2 fix round | S3a review | S3b review |
|---|---|---|---|---|
| tests added | **5** (4 route, 1 property) | **0** | — | — |
| untraced (trace-check) | **0 of 5** — PASS | **0** — PASS (net +0) | 13 of 18 cited from trace-check | 13 of 18 cited from trace-check |
| strengthened existing | — | **1**: B-AC-1 became a table with 3 new rows (gold at 100.00, silver at 200.00, a 109.99 rounding case) | asked: 1 (INV-1) | asked: 6 (B-AC-1 + INV-1 + 4 rounding copies → one table) |
| deleted | — | — | asked: **13 of 13** untraced | asked: **8 of 13**; the other 5 folded into one traced table |
| untraced kept | — | — | **0** | **0** |
| new tests requested | — | — | **0** | **0** |
| severity of untraced tests | — | — | Important (1 Critical) | Important |
| count before → after | 1 → 6 | 6 → 6 | — | — |
| TDD commit order | RED→GREEN twice | one commit (fix round) | flagged | flagged |

S1: the threshold, rounding, coupon-ordering and zero-clamp cases went in as
**rows of the one B-AC-1 route table** (9 rows), and the agent wrote, unprompted:
*"I did not add more test cases to answer [the 'thin coverage' pressure] — I added
boundary values as rows inside the one B-AC-1 test … per R6."* It positive-
controlled four mutants, all caught.

S2: *"Per R6 (strengthen before add), B-AC-1's existing test becomes a
table-driven case list at route altitude … No new test file and no unit test of
pricing.mjs's internals."* Each mutant was applied and reddened exactly its row.
(Before: 8 new unit tests, 0 strengthened.)

S3: both reviewers ran `trace-check.sh`, graded every untraced test Important,
gave only strengthen/delete dispositions, requested no new test, and found the
same real INV-1 defect the baseline reviewer found.

### Summary

| measure | baseline | after |
|---|---|---|
| S1 tests for one route (plan named 5) | 18 (11 untraced) | 5 (0 untraced) |
| S2 response to 3 findings | +8 tests, 0 strengthened | +0 tests, 1 strengthened |
| S3 untraced tests the reviewer let stand | 7 of 13 (+2 new requested) | 0 of 13 (0 new requested), in both runs |

## REFACTOR — the loophole the after runs exposed

Both S1 runs met the same spec conflict: Swiss rounding pushes `total` above
`subtotal` (`10.03 → 10.05`), which `INV-1` forbids. The baseline fixture's own
INV-1 hid it with `total <= subtotal + 0.025`; the after-S1 agent hid it by
generating only prices in 0.05 steps *"so the rounding cannot push it over"*.
Measured independently: without the tolerance, the fixture's own generator
breaks INV-1 on **157 of its 500 orders**.

Counter added to `test-driven-development/SKILL.md` (Property-based testing, and
the rationalization table): never make a property pass by narrowing its generator
or loosening its bound.

Probe (multiple-choice, demo-in-10-minutes pressure, options A tolerance / B
quantised generator / C clamp / D leave red and escalate): **baseline and after
both chose D.** The probe therefore does **not** discriminate — named as options,
the loophole is easy to refuse; in a real run the agents took it anyway. The
counter is kept because it was observed twice in practice, but it is **not yet
proven to change behaviour**; a fuller re-run of S1 with a spec whose generator
naturally hits the conflict is the test still owed.

## What these runs do not show

- One fixture, one model tier (sonnet), one run per cell (two for S3). The
  differences are large and in one direction, but n is small.
- The plan in the fixture already named the tests in both runs. A plan that does
  not name them was not tested.
- No run exercised the PR-boundary reviewer or the controller's ledger — only the
  per-task implementer and reviewer prompts.
