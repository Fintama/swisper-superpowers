---
name: setup-delivery-program
description: Use when the user is aiming at something programme-sized - a new product, a major refactor, a migration, a re-platforming, or any undertaking that spans several components, will take months rather than weeks, and needs more than one team working in parallel. Symptoms - "rebuild", "move X to Y", "from scratch", a goal no single feature could deliver. Not for one feature (brainstorming) and not for succession (respawn-pm / respawn-workstream).
---

# Set up a delivery programme

**Announce at start:** "I'm using setup-delivery-program to stand up the programme."

This skill creates a programme where none exists. It runs once per product,
interactively, with a human in the room. It ends with lanes live and you holding
the PM seat.

**It produces a high-level architecture, not a detailed design.** Building blocks,
boundaries and the first architectural recommendation: yes. Schemas, routes,
components, test plans: no. Those are per lane, through `brainstorming` →
`writing-plans`, by the people who will build them.

**Not for succession.** An existing lane needing a new session is
`respawn-workstream`; the PM succeeding itself is `respawn-pm`.

---

## Before you start

- [ ] **PyYAML.** `python3 -c "import yaml"` must succeed. macOS ships `python3`
      without PyYAML, and every programme script starts `#!/usr/bin/env python3`,
      so on a clean Mac nothing that reads `program.yaml` will run. Fix:
      `python3 -m pip install pyyaml`. Do this first; it fails late and confusingly.
- [ ] **A repo to run the programme on**, and write access to it.
- [ ] **A human available for the whole session.** Phases 1, 3 and 4 are
      conversations. If they are not available, stop: a roster invented without
      them is a guess.

---

## The seven phases, in order

Run them in this order. Grounding stops you designing for a system you imagined;
goals decide the architecture; the architecture decides the lanes. Run them
backwards and you get lanes that own nothing. If a later phase changes an earlier
one (Phase 3 shows a goal is wrong), go back, say so, and redo the phases after it.

---

### 0 · Ground yourself in what already exists

**Brief and high-level, not an audit.** You need to name the core components and
what the system can already do, so that Phase 1's goals are about a real product
and Phase 3's gaps are real gaps.

- If **prism** is available: `architecture`, then `module-map`. One call each.
- Otherwise: the README, the top-level directory layout, and the entry points.

Timebox this. You are looking for the shape, not the contents; a deep read here
burns context you need in Phase 2.

Do not skip it because the user described the system to you. What they describe
is what they intend; what is on disk is what you must extend. Where the two
differ, that difference is usually itself a finding.

---

### 1 · Mission Goals: what must be true to call this delivered

**One to three goals by default**, each with a **runnable proof**: the thing you
would execute to settle whether the goal is met. More only if the human insists,
and each extra one still carries its own proof.

Frame them as outcomes for whoever uses the thing: what will a user of this
product be able to do when the programme is done? Not components, not phases.

**Invoke `brainstorming` and run its §0 for this step.** Its goal gate is the gate.
§0's fields are not summarised here, so that this skill cannot drift from it:
read §0 there.

These goals are the yardstick every lane judges its own design against, for the
life of the programme (the goal rules live in `running-a-programme`, "The goals").

Two failure modes specific to a programme:

- **A goal every lane serves is a slogan.** "Ship quality software" cannot be
  unmet. Ask what measurement goes red if the goal fails while everything else
  works.
- **A goal whose only criteria are infrastructure cannot fail.** If every proof
  tests plumbing (a service is up, a table exists, a job is registered), the goal
  reads green while the thing it exists for has not happened once.

---

### 2 · Deep analysis, and research what you do not know

Now go deep, and only on what the goals actually touch.

- **The existing components and capabilities** the goals depend on, properly this
  time, because Phase 3 subtracts from this.
- **For anything genuinely new, research it** rather than designing from first
  principles what an industry has already solved:
  - **WebSearch** for market practice, architectures, and the failure modes others
    report. Search generously.
  - **GitHub** for projects that solved something close: how they structured it,
    and why.
  - **Context7** for current library and framework documentation, rather than
    recalling an API.

Prefer a known-good shape over an invented one. If you reject a common approach,
be able to say why in one sentence.

---

### 3 · Gap analysis and the first architecture

**What is missing between what exists and what the goals require?** High level:
building blocks and boundaries, not designs.

Produce:

| | |
|---|---|
| **Building blocks** | each marked `new`, `existing` or `extend` |
| **What each owns** | one line |
| **The seams** | which blocks talk, and what crosses |
| **Your recommendation** | the architecture you would take, and the alternative it beat |

`existing` and `extend` matter more than `new`: that is where the reuse question
gets asked while it is still cheap.

**Validate this with the human before going further.** Put the open choices to
them in the decision frame (`writing-exec-summaries`). Everything downstream
inherits this shape, so wait for their agreement.

---

### 4 · The roster: lanes derived from the building blocks

**Derive lanes from Phase 3, so every lane owns something real.** A roster written
first and then matched to work produces a lane whose scope is a job title.

**At most five lanes by default.** The cap is about your context and the human's
decision queue, not about the work: six lanes do not deliver faster than four if
you cannot hold them and the human cannot answer them. Go above five only when the
human accepts that load. Three good lanes beat five contrived ones.

#### The seven tests a lane must pass

Apply all seven. A candidate failing one is not a lane yet: merge it, split it, or
sequence it.

| # | Test | How to apply it |
|---|---|---|
| **1** | **Isolated** | It works within one component or one area of the codebase. |
| **2** | **Enough work** | Months of it, not a task. A lane costs a session, a worktree, a rig and a place in your queue. |
| **3** | **Non-overlapping owned paths** | Write every lane's path list. A path in two lists usually means the split is wrong: fix it now, or name the one lane that owns the shared path and record it. |
| **4** | **Owns an outcome, not a layer** | Name a demo this lane alone can give. "The database layer" fails: it can only be integrated, never demonstrated. |
| **5** | **Seams writable today** | Write its contract to each neighbour, in one or two lines, now. If that needs a design session first, do not split there. |
| **6** | **Failure is contained** | If this lane stalls for a week, do the others keep moving? If everything blocks on it, it is a prerequisite: sequence it before the fan-out. |
| **7** | **Serves a named Mission Goal** | Point each lane at a goal. An orphan lane is over-scope: cut it or defer it. Adding a goal to house it is not a fix (`running-a-programme`, "The goals"). |

#### What each lane carries

| | |
|---|---|
| **name** | `WS<n>-<Name>`; scripts parse it |
| **id** | lane plus incarnation, e.g. `WS5-6`. Changes on respawn; the name does not |
| **session** | the agent session actually holding the lane |
| **address** | that session's name as `ListAgents` shows it, the `SendMessage` address. Changes on respawn |
| **scope** | one line. If it needs two, it is two lanes |
| **owned paths** | what this lane may edit (test 3) |
| **serves** | which Mission Goal (test 7) |
| **worktree · branch** | where it works |
| **rig ports** | frontend, backend, db, compose project name |

Allocate every lane's ports and compose project names here, together (they are
global to the machine: CLAUDE.md, "Worktree and environment hygiene").

---

### 5 · Write it down

- [ ] Write **`program.yaml`** at the programme root, shape in
      `$CLAUDE_PLUGIN_ROOT/docs/program-yaml.md`. It is the sole owner of
      programme identity.
- [ ] Verify: `python3 "$CLAUDE_PLUGIN_ROOT/scripts/program-yaml-check.py"`. A
      missing field is an error naming the field and the lane, never a silent
      default.
- [ ] **Create the programme state directory**; without it the monitoring and
      messaging tools abort, because the lane map they read does not exist yet:

      bash "$CLAUDE_PLUGIN_ROOT/scripts/init-programme.sh"

      It seeds `.handover/` with an empty lane map, its import dependencies, the
      outbox and the inbox directory, then runs the seeded map to prove it works.
      Idempotent, and it never overwrites an existing roster. The stateless tools
      (`msg.py`, `stall-check.py`, `reap-ghosts.sh`, `board-server.py`) stay in
      the plugin and are always invoked from `$CLAUDE_PLUGIN_ROOT/scripts/`; only
      the lane map is programme-owned.
- [ ] **Scaffold the board** with `update-program-board`. Do not invent a layout.
- [ ] **Record your own address** as `pm_address` in `program.yaml`: your
      session's name as `ListAgents` shows it. Every spawn document hands it on.
- [ ] **Register the PM's recurring check.** Write its prompt yourself (there is
      no template). It says: re-read `program.yaml` and the board, run
      `stall-check.py`, and chase any lane that is silent or blocked. It does not
      read mail: lanes reach you by `SendMessage`, which wakes you; it exists
      because a stalled lane sends nothing
      (`../running-a-programme/references/messaging.md`). It carries invariants
      only: no commit SHA, no PR number, no work queue, no dated claim, because a
      recurring prompt is never re-read and a fact in it goes stale silently.

---

### 6 · Stand the lanes up

For **each** lane, in order:

- [ ] **Write its spawn document**, `.handover/SPAWN-<date>-WS<n>-session-1.md`.
      **State only**: identity line, scope, owned paths, the Mission Goals, its
      branch and base, worktree path, allocated rig ports, verified trunk SHA,
      and the PM's address (`pm_address`). Method belongs in
      `running-a-workstream`, which the doc points at; do not restate it. Save it
      the way `.handover/` is saved (`writing-handovers`, "Saving").
- [ ] **Create the lane's worktree.**
- [ ] **Spawn it.** With the human in the room, the default is that they open it
      in a VS Code tab. Hand them the lane's opening card and stop, one card per
      lane:

      ```
      ── WS<n> · <Lane title> ─────────────────────────────
      1. Open a VS Code window on:  <absolute worktree path>
      2. In that window: Cmd-Esc (or ✻ in the status bar) for a Claude tab
      3. Paste, in order, pressing Enter after each:
           /model opus
           /rename WS<n>-1 <Lane title>
           <one-line briefing: read SPAWN-<date>-WS<n>-session-1.md, then use running-a-workstream>
      ```

      **The window must be opened on the worktree.** A Claude tab always runs in
      its window's folder, and a tab opened in the wrong window silently works the
      wrong tree; two lanes sharing one `.git/index` produce silent false greens.
      One window per lane worktree; the tabs live inside it.

      `/model` and `/rename` are the first two lines, not optional: a tab
      inherits the last-saved default model, and nothing else renames it.

      With nobody at the keyboard, `scripts/spawn-lane.sh` stands the lane up
      headlessly in tmux instead, pinning the model and asserting the worktree
      (usage in `respawn-workstream`, step 3).
- [ ] **Wait for the lane to report live** with its branch and rig URL before
      the next one. One at a time: a lane that failed to boot is cheaper to find
      alone.
- [ ] **Capture its session id yourself, and verify where it landed**; do not
      ask the human to read it out:

      ```bash
      claude agents --json | python3 -c '
      import json,sys
      for s in json.load(sys.stdin):
          print(s.get("name"), s.get("sessionId"), s.get("cwd"))'
      ```

      **Assert the `cwd` is the lane worktree before recording anything**; a lane
      in the wrong tree is stopped, not fixed. Then record the lane's `id`,
      `session` and `address` (its name as `ListAgents` shows it; do not assume it
      equals the `/rename` title) in `program.yaml`, and the session id in the
      `ws-pulse.py` lane map.
- [ ] **Verify the model from the transcript**; a typed `/model` is a claim until
      the running session agrees:
      `tail -40 ~/.claude/projects/<slug>/<id>.jsonl | grep -o '"model":"[^"]*"' | tail -1`

---

### 7 · Take the seat

**Invoke `running-a-programme`.** You are the PM from here: rulings, unblocking,
the board, merge readiness, and reporting to the human.

**Then report** the goals, the roster, the board URL, and what each lane is
starting on. **REQUIRED SUB-SKILL:** `writing-exec-summaries`.

---

## Running it again

This skill is idempotent and must stay so. On a second run against an existing
`program.yaml`:

- [ ] **Report the delta and do not overwrite.** Say which fields differ, in both
      directions.
- [ ] **A lane present on disk and absent from your new roster** is either one
      someone added deliberately or one you forgot. Ask; do not silently drop it.
- [ ] Only the human decides which side wins, field by field.
- [ ] **Never re-spawn a lane that is already live.** Two sessions on one lane
      fork it, and both keep working.

Re-running is normal (a new lane, a rig moved, a respawn); it must be safe enough
that nobody avoids it.

---

## Ownership of program.yaml

**The PM lane is the sole writer of `program.yaml`**: through this skill at
creation, or a deliberate PM edit for a respawn, a new lane, or a rig change. Any
skill or script may read it.

That is enforced by documentation only, because a guard over a single writer
could never fire. The moment a second writer exists, the guard is due in that same
PR, built by whoever adds the second writer.

---

## What this skill does NOT do

| Not this | Use |
|---|---|
| Design a feature | `brainstorming` → `writing-plans` |
| Implement anything | `test-driven-development`, `subagent-driven-development` |
| Run the programme afterwards | `running-a-programme` |
| Tell a lane how to work | `running-a-workstream` |
| Replace a lane's session | `respawn-workstream` |
| Replace the PM | `respawn-pm` |
| Decide anything for the human | nothing. Surface it and let them rule |
