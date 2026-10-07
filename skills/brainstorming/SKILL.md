---
name: brainstorming
description: "Use before any creative work on ONE feature or change - creating a feature, building a component, adding functionality, or modifying behavior. Not for programme-sized work spanning multiple components over months and needing more than one team in parallel - that is setup-delivery-program."
---

# Brainstorming Ideas Into Designs

Turn an idea into an agreed design and a written spec through dialogue. Ask one
question at a time: **first nail the objective, only then shape a solution.** The
business goals and their value are established and agreed first; every later detail
is judged by whether it helps achieve them.

## The two gates

1. **Goal gate.** Do not propose approaches, sketch a design or explore solutions until
   §0 Business Goals & Value is written and the user has explicitly agreed it. A design
   discussed against an unstated goal produces a §0 reverse-engineered to fit it.
2. **Design gate.** Do not invoke an implementation skill, write code or scaffold
   anything until the user has approved a design. This holds for small work too; for a
   Sketch the design is one short message the user confirms.

## Checklist

Create a task for each item and complete them in order.

1. **Explore project context**: files, docs, recent commits, and project memory
   (`MEMORY.md` and the handover or pickup files it links) for landmines in the area
   the spec will touch. The spec either avoids each applicable landmine or names the
   workaround in §7 as `Mitigation: <how>`.
2. **Offer the visual companion** if visual questions are ahead (see Visual Companion
   below). The offer is its own message.
3. **Ask clarifying questions until you can write §0** without guessing a field: who
   benefits, what they cannot do today, what the change is worth to them, what is out
   of scope. You are not exploring the solution yet.
4. **Goal gate: present §0 on its own, in its own message**, and ask the user to confirm
   the goals, the value and the non-goals. If the value does not justify a plausible
   cost, say so and offer to stop; "not worth building" is a valid outcome.
5. **Propose 2-3 approaches that differ in size, and agree the spec class.** One is the
   thin baseline (see Exploring approaches). Lead with your recommendation and say why
   the thin one loses; that reason goes into §0.1. In the same message recommend the
   spec class (Sketch / Standard / Programme); **the user picks it**, because an agent
   left to self-assign assigns downward.
6. **Present the design** in sections scaled to their complexity, get approval after
   each, then approval of the whole before writing it up.

   **A user-visible surface gets its mock first, and the mock is its design.** Invoke
   `creating-screen-mocks` and get the mock approved before writing §1 for that surface.
   Do not describe the screen in prose; §1's `ux` field points at the mock's path,
   route and states. The mock lives in the product repo at `design/mocks/<slug>/`,
   never in the docs repo, and the spec links it with the commit it was approved at.
7. **Write the spec.** For Fintama products: `specs/<product>/YYYY-MM-DD-<topic>-design.md`
   in **Swisper_Documentation**, main only, saved with its `tools/docs-save` (its README
   is the rulebook; never a branch, never a hand commit). Elsewhere:
   `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`, then commit. A user's own
   location preference overrides both. §0 goes in exactly as agreed at step 4; if
   writing changed your understanding of a goal, take that back to the user.
8. **Spec self-review**: the seven checks below, run by you. This is the only
   pre-user gate: no reviewing subagent is dispatched, formally or informally (the
   user's standing rule). If a spec later turns out to have specced something that
   already existed, strengthen check 6; do not add a reviewer.
9. **User reviews the written spec.** They agreed §0, so they are the reviewer who can
   answer "is this aimed at the right thing?".
10. **Invoke `swisper-superpowers:writing-plans`.**

**How it ends.** Either writing-plans (step 10) or a stop at the goal gate. During
design the only other skill you invoke is `creating-screen-mocks`, for a surface;
no implementation skill (frontend-design or any other) runs from here.

## The Process

**Understanding the idea**

- Assess scope before detailed questions. If the request spans several independent
  subsystems ("a platform with chat, file storage, billing and analytics"), say so at
  once and help decompose it: the pieces, how they relate, the build order. Brainstorm
  the first one; each gets its own spec, plan and implementation.
- One question per message; multiple choice where it fits.
- Focus on purpose, constraints and success criteria.

**Exploring approaches** (only after §0 is agreed)

- The 2-3 approaches **differ in size, not only in mechanism**; three at the same scale
  is not a scope choice.
- **One is the thin baseline**: the smallest thing that satisfies §0. Reuse what
  exists, serve one case rather than all, generalise nothing, build no seam you don't
  need today. Give it an honest estimate even when you believe it inadequate, and say
  why it loses.

**Presenting the design**

- Each section from a few sentences to 200-300 words; ask after each whether it looks
  right; go back when something doesn't make sense.
- Cover architecture, components, data flow, error handling and testing.
- Design for isolation: units with one purpose, clear interfaces, testable on their own.
  For each, you can say what it does, how it is used and what it depends on.
- In an existing codebase follow its patterns. Include targeted improvements where a
  problem affects the work (a file grown too large, tangled responsibilities); propose
  no unrelated refactoring.

**Codebase grounding.** Every identifier the spec names (import paths, classes,
signatures, base-class contracts, env vars, lint rule ids, file paths) is either
verified against the code and anchored, or marked new as an `ADDED` change in §1 (with
its reuse check; a new sole owner also gets §9). Never name a symbol from memory.
Verify what is easy to assume: the real signature, that the symbol exists, that a
"setting" is a Settings field and not an `os.getenv` read, whether a base class is an
ABC and which members are abstract. In prism-indexed repos use `prism search` / `def` /
`body` / `deps` (Grep and Read are blocked there); elsewhere grep and read. A claim you
cannot verify is either a gap to escalate or new infrastructure to mark; never paper
over it with aspirational code. Self-review checks 6 and 7 are the bar.

**Anchors** are `path::symbol` (they survive edits). Use `path:line` only for a spot no
symbol names.

## Spec Classes

Every project gets a recorded design decision; the document's weight follows the risk.
You recommend the class and the user confirms it at step 5, in one sentence: *"That
makes this a Standard spec: §0, the Decision Record, §1 changes, §2 logic and ACs."*

| Class | When | Owes |
|---|---|---|
| **Sketch** | one seam, one existing owner, no new contract, no new sole-owner entity | §0, §0.1, §0.2, §1. Half a page; §1 is three lines, not a table |
| **Standard** | several files, one to a few PRs, no new sole-owner entity | the above, plus §2 and §6; §3-§5 by trigger |
| **Programme** | a new subsystem, a new sole owner, a cross-component contract, or more than 3 PRs | all of the above, plus §7 and §9 |

**§0, §0.1, §0.2 and §1 are owed at every class** and are never N/A. §2-§9 are owed when
their trigger fires; otherwise write the single N/A line below. An N/A line is a claim
the user or an implementer may check: "No boundary crossed" against a design that adds
an API route is false.

**Label every section `[handoff]` or `[review-only]`.** `[review-only]` sections (§0's
Who / Today / Value / cost, §0.1, §7, §8) are excluded from an implementer's payload by
construction, never by judgement: one reading rejected alternatives will build one,
one reading risks will hedge. §0's goal lines with their `UBER-AC` proofs, and §0.2, are
`[handoff]`, because an agent cannot serve a goal it cannot see. An unlabelled section
counts as `[review-only]`.

| Section | Trigger | If absent, write |
|---|---|---|
| 1 · Solution Design | always owed (three lines for one seam) | — |
| 2 · The Logic | conditional behaviour with more than one outcome | "No rules — plumbing: `<one line>`." |
| 3 · Contracts & Data Models | a boundary is crossed (fe↔be, plugin↔host, svc↔svc, producer↔consumer) | "No boundary crossed — internal to `<module>`." |
| 4 · Failure & Ops | the change depends on anything that can be unavailable | "No external dependency — `<X>` is in-process." |
| 5 · Delivery | the change must reach state that already exists | "Code-only; no existing state to reach." |
| 6 · Acceptance Criteria | any user-visible behaviour change | "No behaviour change — refactor of `<X>`, covered by existing tests." |
| 7 · Risks & Spikes | an unknown you would actually spend a day on | "No spike needed." |
| 8 · Amendments | accumulates during the run | — |
| 9 · Ownership Boundaries | a new sole-owner entity, or a second writer to an existing one | "No ownership change — `<X>` remains sole owner." |

### §0 · Business Goals & Value

The first thing nailed and approved (step 4), and the yardstick every later section,
task, test and review is measured against. Write it so a stranger could use it to
**reject** a proposed feature.

One to three goals. More than three usually means two specs: split it, or say in §0.1
why not. Each goal carries five fields, all required:

- **`G-n` · Goal**: the outcome in one line, in the user's words. An outcome, not a
  mechanism: if it names a table, route, service, class or file, it is a requirement.
- **Who benefits**: the named role that ends up measurably better off ("the operator",
  "an RM onboarding a client", "whoever adds the next provider"). Not "the system", "the
  codebase" or "us". If no one can be named, it is not a business goal.
- **Today**: the concrete current pain, with a number or a specific incident, and how
  you know (`verified_by: read | executed | pinned | none_exists`). "Slow" is not a pain;
  "the operator learns the plan is exhausted only when a turn fails, about three times a
  week, and misreads it as a broken credential" is. §0's Today is what the beneficiary
  experiences; §1's `today` is what the code does. Write one in each.
- **Value**: what the beneficiary can now do, stop doing or stop paying for, and roughly
  what that is worth (time, money, risk retired, a decision they can now make). Value
  over cost is what makes "the most effective way" judgeable.
- **Proof, `UBER-AC-n`**: one yes/no test anyone can run after it ships without insider
  knowledge: a grep, a metric, a file check, a user test. Keep goal and proof as two
  lines; merging them pulls the goal toward mechanism. Examples:
  - "p95 latency for `GET /api/products/:id` drops from 800ms (baseline 2026-03-01) to under 400ms."
  - "A new user can sign up, configure one provider and dispatch a working agent in under 5 minutes without reading docs."
  - "`PROVIDER_ID_MAP` in `opencode-providerid-map.ts` is deleted; downstream code reads `cfg.apiSchema` directly."

Then, once for the spec:

- **Non-goals**: what this explicitly does not do, especially the adjacent things a
  reader would expect. Anything you discover that deserves building goes here, marked
  as needing its own spec.
- **Rough cost**: an honest size for the chosen approach and for the thin baseline.

**The goals are the user's goals; nothing else may be one.** Every later section is
aligned against these lines, so a goal the user never asked for gets faithfully served.
Admission tests, all must pass:

- **Provenance.** You can point at what the user said that this goal serves. A goal from
  your own analysis is a non-goal with a note. A defect you discover while writing is a
  finding to report and, if worth building, its own spec, never a seat next to the
  user's goal.
- **A goal, not an invariant.** "The operator can see a limit before it bites" is a goal.
  "An unmeasured provider never renders as healthy" is a correctness invariant: a T-AC.
- **An outcome, not a mechanism** (see Goal above).

**§0.1 Decision Record.** Three or four lines each for the chosen approach and the thin
baseline: estimate, and the specific reason the baseline loses. The reader then has one
sharp question, *was that reason true?*, instead of re-deriving a cheaper design blind.
The reason must be falsifiable: "the panel scaffold doesn't exist yet" can be checked in
thirty seconds; "it doesn't scale", "we'll need more later" and "it's less complete" are
not reasons.

**§0.2 Constraints** `[handoff]`. The short list of things that make the feature fail if
violated, written as instructions to the builder and repeated into every implementer's
payload:

```
HC-1  Do not add a synchronous call to profile-service inside the order path;
      the p95 budget is 200ms end to end.        source: NFR-07   breach: fatal
```

Each one: the instruction, its source, and whether a breach is fatal or needs a
decision. Keep it short; a rule about how this change works belongs in §2.

### §1 · Solution Design `[handoff]`

How it should work, and how today's system becomes that. Without it a spec is a finish
line with no route.

**The unit is a change in behaviour, not a file**: one entry per change in what the
system does, at the size a reviewer would accept or reject on its own. Not "add a field"
(too fine), not "implement suitability" (too coarse).

```
C2 · MODIFIED · one line of behaviour

today        what the code does now · anchors: path::symbol
             verified_by:  read | executed | pinned | none_exists
tomorrow     the MUSTs that share this seam (1-3). Two seams ⇒ two changes.
logic        → §2 RULE-n  +  evaluated_at · inputs bind from · recomputed · writes
seam         path::symbol — why HERE
senior       junior would: <the obvious build> · senior does: <the reuse,
             and the failure mode / limit / compatibility it handles>
mechanism    in_place | wrap | sprout | extract_interface |
             branch_by_abstraction | strangler | delete | fill_scaffold
call sites   every site this is reachable from — enumerated, not estimated
pin          what must not move + which test holds it, or "none, because …"
             required on MODIFIED and REMOVED
ux           mock path · route · states · fixtures to replace ·
             GRAFT TARGET: the file this mock becomes, or "new: <path>"
                                                           (screens only)
depends_on   C1 (data, not stubbable) · C3 (contract, stubbable)
atomicity    must ship with C4 — reason
```

- **Ids are `A1`, `C1`, `N1`**; `plan-check.sh` matches them against the plan's tasks.
- **`kind` is `ADDED | MODIFIED | REMOVED`, and `MODIFIED` is the default suspicion.** An
  `ADDED` change against a screen the mocks already approved has thrown the mock away.
- **`today` is the baseline, and the code is its only oracle.** `verified_by` makes "I
  read it" and "I ran it" visibly different. On a `MODIFIED` change against behaviour you
  depend on, `read` should be rare and say why it wasn't run.
- **`senior`** names the obvious alternative concretely: what a junior would most likely
  build here (a second path beside this seam, a new store beside the owner, a hard-coded
  value, a per-message check for a per-session rule, no timeout or cap), and what this
  design does instead: the existing piece it reuses and the failure mode, limit or
  compatibility it handles. It feeds `seam` and `mechanism`, and the implementer's
  senior-engineer pass starts from it. A seam with no junior alternative is a file path,
  not a decision.
- **`mechanism`** is how we get there; `wrap` and `in_place` give different diffs from the
  same `tomorrow`. Leave it unsaid and the implementer improvises.
- **Every field is an instruction to an implementer holding only this change.** Never
  "see C5": that edge goes in `depends_on`, where the plan can act on it.
- **Links point outward from the thing that depends.** ACs, contracts and delivery items
  name their changes; a change never points back. One direction, one place to maintain.
- **Ground every change** (Codebase grounding above; checks 6 and 7). `call sites` come
  from `find-refs` on the symbol and `prism deps` → `depended_on_by`, never from a
  call-shaped grep: a dependency passed as a value is invisible to one. Where the repo is
  not prism-indexed, say so; a grep-built call-site list is a weaker claim.
- **Every change serves a goal** (check 4). An orphan is over-scope: cut it or spec it
  separately.

### §2 · The Logic `[handoff]`

The rule bodies. Prose only for an invariant (one outcome by definition); everything else
takes a shape: decision table, state machine, sequence, formula. A table can be checked
for a hole; prose cannot.

```
RULE-1 · Catalogue staleness on config entry          shape: decision table

inputs                          (closed domains, or the table can't be checked)
  lastRefreshedAt   timestamp | null    null = no stored rows for this config
  refreshInFlight   true | false

several rows match →  first match wins

  #   when                                then
  1   refreshInFlight = true              nothing — the batch path de-dupes
  2   lastRefreshedAt is null             refresh
  3   now − lastRefreshedAt > threshold   refresh
  4   otherwise                           do not refresh

unknown
  null means "we have never stored rows for this config" — NOT "the copy is
  fresh". It refreshes. Reading null as fresh reproduces the staleness bug on
  every new config.

outcome
  refresh → stored rows render immediately, updated in place       → C1, C4

boundaries
  the threshold is ONE constant, shared with the query's staleTime.

examples                                        → become AC cases in §6
  stored 3h ago → exactly one refresh · stored 30s ago → none
  no stored rows → refresh · refresh fails → rows still listed + marker
```

- Closed domains on every input, or completeness cannot be computed.
- **Every input that can be absent gets an `unknown` line saying what unknown means**, not
  only what to do. It is the decision an engineer otherwise makes silently.
- One example per distinct outcome; §6 lifts them as AC cases.
- Classification and decision are two rules: what this thing is, and what that permits.
- A rule that already holds in the code is still written, marked existing, and pinned.
- The change points at the rule; the rule never points back.
- Data fields: only those a rule reads, as `name · type · domain (closed) · what unknown
  means`. Permissions, only when authz is in play: `actor · action · condition · what a
  denial does`.

### §3 · Contracts & Data Models `[handoff]`

Every contract that crosses a component boundary, every persisted or shared data model,
every wire format (request/response shapes, table schemas with types, constraints and
indexes, event/SSE payloads, serialization, versioning). A small worked example for each
non-trivial contract. Each entry carries `change_kind` (ADDED / MODIFIED / REMOVED),
whether it is breaking, and the change that produces it. Reference the machine-readable
contract; do not paste it.

### §4 · Failure & Ops `[handoff]`

Answer each question; "Not applicable, because …" is a complete answer, silence is not.
Every row names the changes it belongs to.

| Question | |
|---|---|
| What happens when each dependency is unavailable or degraded? | required |
| Which errors retry, which are poison, which page a human? | required |
| What is the idempotency / delivery semantic on each boundary? | required |
| What can race, and what enforces ordering? | before merge |
| What still works when this feature is broken? | before merge |
| How does an operator know it works, and know it is in use? | before merge |

### §5 · Delivery `[handoff]`

A code-only change reaches no existing instance. If a default, a seeded row, a stored
value or an existing user's state is involved, name the channel (migration, backfill,
seed, config), say whether it is idempotent and which AC proves it re-runnable. Then
rollout, rollback, and the point of no return.

### §6 · Acceptance Criteria `[handoff]`

Both business and technical ACs are required.

- **Business ACs (`B-AC-n`)** say what users can do, in user terms: "User can switch focus
  from the Lead session to a subagent and converse with it directly."
- **Technical ACs (`T-AC-n`)** say what must be true for developers: "TypeScript strict
  mode enforced in CI", "the API returns 401 on missing auth".

Both use MUST / SHOULD / MAY / NFR language and Given / When / Then form, numbered, each
mapping to a future test:

```
| B-AC-1 | Given a Lead is mid-task and the user has switched focus to a running subagent
         | When the user asks the subagent "what are you doing?"
         | Then the subagent replies in chat without terminating its task; the Lead's
           tool call is still pending; the subagent continues toward its Result. |

| T-AC-1 (serves B-AC-1) | Given the service is running and Bearer auth is valid
         | When client calls GET /healthz
         | Then response is 200 with body {"status":"ok"}. |
```

- **Every MUST has at least one AC. Every B-AC is served by at least one T-AC**, and each
  T-AC names the B-AC it serves (`T-AC-4 (serves B-AC-2)`), so an unserved B-AC is visible
  by scanning a column and a T-AC that serves nothing stands out.
- **Lean, not voluminous.** Each AC proves a distinct slice of value and maps to a real risk;
  every AC spawns a test downstream. The right number is the minimum that proves the MUSTs
  plus their important edge and failure cases. If you can't say what breaks in production
  when an AC fails, cut it.
- **Scaffolding specs** with no direct user-facing behaviour have non-regression business
  ACs ("workflow X still works") and name the sub-specs where the user value lands.
- **`observed_at`**: where the assertion is made, e.g. "the HTTP response at the
  order-service boundary and the `suitability_decision` row, not the rule engine's return
  value". An AC asserted on the function that computes the answer proves the function, not
  the behaviour. No observation point, no test.
- **`negative_cases`**: at least one per AC, the input that must not trigger it.
- **`invariants`**: what must hold regardless ("no Order reaches `accepted` without a
  `suitability_decision` row"), asserted by every relevant test.
- Each AC names the changes it verifies (`T-AC-3 → C3`), here and only here.
- Lift the cases from §2's examples rather than inventing edge cases.

### §7 · Risks & Spikes `[review-only]`

Each risk has a concrete mitigation that resolves to a change, AC or delivery item; a risk
that changes nothing about sequencing or gating is noise. Each spike has a timebox, a stop
condition and what it blocks.

### §8 · Amendments `[review-only]`

What changed after the spec was agreed, and which goal forced it. Accumulates during the
run; never written up front. See The goal is the only fixed point.

### §9 · Ownership Boundaries `[handoff]`

Owed when the design names data, state or a workflow that is, or should be, owned by
exactly one module. It prevents "two writers, no router": two modules writing the same
data without coordination. Four lines:

```
### Ownership: person resolution + loading
- Sole owner:      swisper/agents/memory/
- Read contract:   state.resolved_persons[id] (preferred) OR resolve_person tool
- Write contract:  memory subsystem internals (load_full_person service)
- Enforcement:     ruff lint SW001 (no_person_outside_memory) + AGENTS.md section
```

Enforcement names a real mechanism: a lint rule, a runtime guard, a package boundary, or
`AGENTS.md` guidance paired with one of those. Documentation-only is a last resort and is
listed in §7 as debt (and filed in Jira where the project uses it). If violations exist
today, name them and the cutover path.

## The goal is the only fixed point

Once §0 is agreed the goals are fixed. Everything else in the spec, and the whole plan,
bends to them, on the record. A spec is the current best understanding of how to reach
the goals; when it turns out wrong mid-run, amend it rather than comply with it.

| Who | May change | On finding the spec wrong |
|---|---|---|
| **The user** | anything | — |
| **The lead session** (holds the goals and the whole graph) | §0.1-§9 and the whole plan, with no gate or approval round | amend · record · proceed |
| **An implementer** (holds one task) | nothing outside its own task's internals | stop and report the element id and the goal it fails |
| **Anyone** | a goal | stop and ask the user; the only stop there is |

The lead can judge a change safe because it sees the other tasks. Naming, internal
structure, helper decomposition and test fixtures are always the implementer's.

**§8 record shape:**

```
AM-1 · 2026-08-12 · lead · during PR-2

target    §1 C2 seam
said      CopilotTab.tsx — the page
did       a shared hook at src/hooks/useCatalogueFreshness.ts
because   the roster quick-edit popover reaches the same surface without going
          through either page; a page-level trigger misses it
goal      G-1 — still met, and more completely than as specified
folded    §1 C2 rewritten · §2 RULE-1 unchanged · plan PR-2 authority widened
```

- **`because` names a goal.** An amendment that cannot is scope: stop and ask.
- Implementation never waits on the record; it is memory, not permission.
- Fold the change back in the same run, not later.
- Amend in place and record it, so a wrong claim cannot be silently deleted.

## Spec Self-Review — seven checks

Run them after writing, with fresh eyes. Fix what you find inline and move on; there is
no re-review.

1. **Run `anchor-check.sh`.**

   ```bash
   bash skills/brainstorming/scripts/anchor-check.sh <spec.md> <repo-root>
   ```

   Every `path:line` resolves to a real file and line; every `path::symbol` names a symbol
   present in that file. It checks existence only. Positive-control it before trusting
   it: break one anchor, see it go red, restore.

2. **Read it once, end to end, for contradictions.** Do two sections disagree? Does §1's
   `today` match what you saw in the code? Could a requirement be built two ways? Then
   pick one and say so.

3. **§0 completeness.** Per goal: an outcome, a named beneficiary, a Today with a number or
   incident, a Value with rough worth, a Proof a stranger could run. Plus non-goals, both
   costs, and §0.1's falsifiable reason. Then: is "would skipping this spec be cheaper?"
   clearly no? If not, §0 is incomplete, and the user at step 9 has nothing to review
   against but taste.

4. **Goal alignment, one direction.** For each §1 change: which goal does it serve, through
   which part of that goal's Value? An orphan is over-scope: cut it or spec it separately.
   **Never resolve an orphan by adding a goal**; goals come from the user. An orphan you
   believe essential is a finding for the user. A deletion is exempt (negative scope
   cannot be over-scope) but owes a named reason.

5. **Memory landmines.** Re-read the relevant `MEMORY.md` entries and the handover files
   they link. Each landmine that applies (e.g. "TYPE_CHECKING strings break
   `get_type_hints`", "agent_description is rendered into the planner prompt") is either
   avoided or named in §7 as `Mitigation: <how>`.

6. **Reuse before build: try to disprove every `ADDED` change.** For each, name the search
   you ran and the nearest existing thing it found: in prism-indexed repos
   `prism check "<what it would do>"` then `prism search "<concept>"`; otherwise grep, and
   name the binary if your shell aliases it. Paste what came back. An empty result is
   evidence about the pattern, not about absence: widen before concluding. An `ADDED`
   change without a recorded reuse check is not admissible: it becomes `MODIFIED` against
   the neighbour, or the spec says which neighbour it beat and why reuse doesn't fit. You
   are the worst reader of your own "this is new", so make the check mechanical.

7. **Codebase reality: every `today` and every anchor.** Check 1 proved anchors exist; this
   asks whether the code there does what `today` says. Open each one. Confirm the seam
   with `find-refs` (callers that reach the behaviour without passing through it mean the
   wrong seam), and that the call-site list is enumerated, not estimated. Then each
   `senior` line: the reuse it names appears in `seam` or `anchors`, and the limit or
   failure mode it names reaches §2 or an AC. Carry it or cut it.

`scripts/mock-cross-check.sh <spec.md> <mock.tsx…>` is a tool, not a gate: when a mock
exists, it lists interactive `data-testid`s the spec never mentions, and empty table cells.

## User Review Gate

After the self-review, ask:

> "Spec written to `<path>`. Please review it and tell me what to change before we write the implementation plan."

Wait. If they ask for changes, make them and re-run the self-review. Proceed only on
approval, then invoke `swisper-superpowers:writing-plans`.

## Key Principles

- **The objective first.** Goals and value are agreed before any solution.
- **One question at a time**, multiple choice where possible.
- **YAGNI over the document as well as the design.** A section this spec's class does not
  owe is scope, like a feature nobody asked for.
- **Approaches differ in size**, and the thin one is written down and argued against.
- **Incremental validation**: approval per section, then for the whole.
- **A spec does not prescribe code comments.** A decision's reason belongs on the
  architecture page's "Why it is like this" block; code follows
  `test-driven-development/clean-code.md`.
- **When you change this skill, say what comes out**, not only what goes in.

## Visual Companion

A browser page for showing diagrams, flows and visual options during brainstorming. A tool,
not a mode: accepting it does not send every question through the browser.

**Offer it once**, when you expect visual questions, as a message containing only this:

> "Some of what we're working on might be easier to explain if I can show it to you in a web browser. I can put together diagrams, comparisons, and other visuals as we go. This feature is still new and can be token-intensive. Want to try it? (Requires opening a local URL)"

Wait for the answer; if they decline, continue in text. If they accept, read
`skills/brainstorming/visual-companion.md` before using it.

The companion answers questions; it never designs a real screen. Once the question is how
a user-visible surface should look, that is `creating-screen-mocks`.
