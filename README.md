# swisper-superpowers

Engineering discipline for Claude Code, as installable skills.

A fork of [`superpowers`](https://github.com/anthropics/claude-plugins-official)
carrying the practices we actually run at [Swisper](https://github.com/Fintama):
how a vague idea becomes an agreed spec, how a spec becomes a sequenced plan,
how a screen gets designed before anyone implements it, and how a multi-lane
delivery programme is run by agents without a human in the room.

```bash
claude plugin marketplace add Fintama/swisper-superpowers
claude plugin install swisper-superpowers@swisper-superpowers
```

Then **restart your session** — a session builds its skill table at startup.
Full details, verification and migration notes: **[INSTALL.md](INSTALL.md)**.

---

## What's in it

**From idea to shipped change**

| skill | what it's for |
|---|---|
| `brainstorming` | Turn a vague ask into an agreed spec. Business goals first, each with a runnable proof, before any solution is discussed. |
| `creating-screen-mocks` | Design a user-visible surface as real, typechecked React composing the real design system — the mock *is* the spec. |
| `writing-plans` | Decompose a spec into PRs with explicit per-PR authority and merge gates. |
| `executing-plans` · `subagent-driven-development` | Work the plan, one bounded task at a time, reviewed at PR boundaries. |
| `test-driven-development` | RED-GREEN-REFACTOR, plus AC-ID naming, test tiers and a toolchain matrix per language. |
| `systematic-debugging` | Find the cause before changing anything; use the observability the system already has. |
| `requesting-code-review` · `receiving-code-review` | Review prompts that produce findings rather than compliments. |
| `verification-before-completion` · `finishing-a-development-branch` | Prove it works before saying it does. |

**Running a delivery programme**

| skill | what it's for |
|---|---|
| `setup-delivery-program` | Derive workstreams from the architecture — seven tests a lane must pass — and spawn them. |
| `running-a-programme` · `running-a-workstream` | The PM seat and the lane seat: what each owns, what it may never decide alone. |
| `respawn-pm` · `respawn-workstream` | Succeed a session whose context is exhausted, without losing what it knew. |
| `update-program-board` · `writing-exec-summaries` · `writing-handovers` | The surfaces a decision actually gets made from. |

**Working on the skills themselves**

`writing-skills` · `using-superpowers` · `using-git-worktrees` · `dispatching-parallel-agents`

Plus the tooling the programme skills call: a message bus (`scripts/msg.py`),
session monitoring (`scripts/ws-pulse.py`), the Mission Control board
(`scripts/board-server.py`), lane spawning (`scripts/spawn-lane.sh`), and ghost
reaping (`scripts/reap-ghosts.sh`).

---

## Two rules that outrank every skill here

**1 · A claim is not a measurement.** A recorded fix, a green gate, a "sent"
message — all are claims until measured against the source of truth.
Positive-control anything that gates: break it on purpose, watch the expected
red, restore it.

**2 · An empty grep is evidence about the pattern, not about absence.** Widen
the pattern before concluding something is missing. A code comment is a lead,
never evidence.

Most of what follows is these two rules applied to a specific situation.

---

## This is a fork, and it tracks upstream

Of the skills shared with upstream `superpowers`, **none are byte-identical** —
every one carries local changes. That makes merging from upstream the failure
mode this repo is most exposed to: a clean merge that silently deletes one of
our additions, and nothing about a clean merge announces it.

**[`DIVERGENCE.md`](DIVERGENCE.md) is the ledger of what we added**, and
`scripts/divergence-check.sh` reads it and fails, naming the enhancement, when
one goes missing.

```bash
bash scripts/divergence-check.sh
```

It refuses to pass on an empty ledger — a predicate over an empty set is
vacuously true, and a checker that verified nothing must not report success.

---

## Using it outside Swisper

Nothing here is Swisper-specific by design, but the examples are ours. Where a
rule cites a measurement — *"7 running environments, 25 containers, 7.9 GB for 2
active lanes"* — that number is why the rule exists, and it is kept deliberately:
a rule without its evidence is just an opinion with formatting.

Programme identity (lane names, repo root, ports, goals) belongs in a
`program.yaml` at your programme root, never hard-coded in a script. See
**[docs/program-yaml.md](docs/program-yaml.md)**.

---

## Licence

Apache 2.0, inherited from upstream `superpowers`. See [LICENSE](LICENSE).
