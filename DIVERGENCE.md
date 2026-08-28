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
| `creating-screen-mocks` | `data-testid` | The join key the render gate needs. Without it nothing downstream can be compared. |

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
| `test-driven-development` | `proving-acs` | A business AC is asserted at **promise** altitude — what the user receives. |
| `test-driven-development` | `Functional Core, Imperative Shell` | The design rule that makes tests possible instead of a fight. |
| `test-driven-development` | `test tiers` | core / gate / extended, so the inner loop stays fast enough to be used. |
| `subagent-driven-development` | `mock scaffold` | The approved scaffold is the binding basis for any screen. |
| `subagent-driven-development` | `boundary review` | Review per PR boundary, not per task. |
| `systematic-debugging` | `observability where it exists` | Use the instrumentation the system already has before adding more. |
| `executing-plans` | `merge gate` | A phase is not done until its gate passes. |
| `brainstorming` | `creating-screen-mocks` | A user-visible surface gets an approved mock BEFORE the spec describes it. |
| `brainstorming` | `GRAFT TARGET` | The spec records which file the mock becomes, so the implementer adapts rather than rebuilds. |
| `subagent-driven-development` | `render-gate.mjs` | Build-vs-mock compared mechanically, not by eye. |

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
