# `program.yaml` — the sole owner of programme identity

One file at the programme root. Every skill and script reads it; **the PM lane is
the only writer.**

Before it existed, programme identity was scattered: lane names hard-coded in
`ws-pulse.py`, rig ports in the board HTML and in operators' heads, goals in a
roadmap markdown, and session ids nowhere machine-readable at all. A second
programme could not start without editing scripts.

## Shape

```yaml
program: Swisper Foundry
repo: /Users/you/Projects/swisper_foundry
board:
  dir: .handover/board
  port: 8794

goals:
  - id: G-1
    text: Run the programme end to end without the founder in the room
    proof: UBER-AC-1

lanes:
  - name: WS5                       # what humans call the lane
    id: WS5-6                       # lane + incarnation; changes on respawn
    session: 9f2c1a                 # the agent session actually holding it
    scope: platform tooling
    worktree: /Users/you/wt/ws5
    branch: feature/ws5-thing
    rig:
      frontend: http://localhost:3176
      backend: http://localhost:3177
      db: postgres://localhost:5442/foundry
      project: foundry-ws5          # the compose project name
```

Every field above is **required**. A missing one is an error naming the field and
the lane it belongs to — never a silent default, because a lane that half-exists
is worse than one that does not.

## Why YAML and not JSON

**Humans edit this file.** JSON has no comments, and a roster you cannot annotate
is a roster nobody explains. The trade is a dependency — see below.

## ⚠ It needs PyYAML, and a clean Mac does not have it

macOS ships `python3` **3.9.6 without PyYAML**, and every script here starts
`#!/usr/bin/env python3`. On a machine with no Homebrew Python that resolves to
the system one and **every consumer of `program.yaml` fails**.

```bash
python3 -m pip install pyyaml       # once, per machine
python3 -c "import yaml"            # confirms it
```

Every entry point fails with that remediation rather than a bare `ImportError`.

## Who may write it

Sole writer: **the PM lane** — via `setup-delivery-program` at creation, or a
deliberate PM edit for a respawn, a new lane, or a rig change. Any skill or script
may read it.

That contract is **documentation-only**, and deliberately so: there is exactly one
writer today, and a guard over a set of size one can never fire — it would read as
coverage while proving nothing. 🔴 **The moment a second writer exists, the guard
is due in that same PR.** Whoever adds the second writer owns it.

## Checking it

```bash
python3 scripts/program-yaml-check.py     # T-AC-2: the round trip, plus both negative arms
```

The check reads **the file on disk**, never an in-memory copy — a writer that
never flushed would pass an in-memory comparison.
