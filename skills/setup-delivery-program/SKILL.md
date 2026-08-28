---
name: setup-delivery-program
description: Use when the user is aiming at something programme-sized - a new product, a major refactor, a migration, a re-platforming, or any undertaking that spans several components, will take months rather than weeks, and needs more than one team working in parallel. Symptoms - "rebuild", "move X to Y", "from scratch", a goal no single feature could deliver. Not for one feature (brainstorming) and not for succession (respawn-pm / respawn-workstream).
---

# Set up a delivery programme

**Announce at start:** "I'm using setup-delivery-program to stand up the programme."

This skill creates a programme where none exists. It runs **once per product**,
interactively, with a human in the room. It ends with lanes live and you holding
the PM seat.

⛔ **It produces a high-level architecture, never a detailed design.** Building
blocks, boundaries and the first architectural recommendation: yes. Schemas,
routes, components, test plans: no — those are per-lane, through `brainstorming`
→ `writing-plans`. **A programme that designs its features at setup time has
skipped the people who will build them.**

⛔ **Not for succession.** An existing lane needing a new session is
`respawn-workstream`; the PM succeeding itself is `respawn-pm`.

---

## Before you start

- [ ] **PyYAML.** `python3 -c "import yaml"` must succeed. ⚠ macOS ships
      `python3` **3.9.6 without PyYAML**, and every programme script starts
      `#!/usr/bin/env python3` — on a clean Mac that resolves to the system
      interpreter and **nothing that reads `program.yaml` will run.**
      Fix: `python3 -m pip install pyyaml`. Do this first; it fails late and
      confusingly.
- [ ] **A repo to run the programme on**, and write access to it.
- [ ] **A human available for the whole session.** Phases 1, 3 and 4 are
      conversations. If they are not available, stop — a roster invented without
      them is a guess with a filename.

---

## The seven phases, in this order and no other

**The order is the argument.** Grounding stops you designing for a system you
imagined. Goals decide the architecture; the architecture decides the lanes.
**Run them backwards and you get lanes that own nothing** — the failure this
ordering exists to prevent.

---

### 0 · Ground yourself in what already exists

**Brief and high-level. Not an audit.** You need to be able to name the core
components and what the system can already do, so that Phase 1's goals are about
a real product and Phase 3's gaps are real gaps.

- If **prism** is available: `architecture`, then `module-map`. One call each.
- Otherwise: the README, the top-level directory layout, and the entry points.

⏱ **Timebox this.** You are looking for the shape, not the contents. A deep read
here burns the context you will need in Phase 2, and it is the wrong depth
anyway — you do not yet know which parts matter.

🔴 **Do not skip it because the user described the system to you.** What they
describe is what they intend; what is on disk is what you must extend. Where the
two differ, that difference is usually itself a finding.

---

### 1 · Mission Goals — what must be true to call this delivered

**1 to 3 goals. Never more.** Each carries a **runnable proof** — the thing you
would execute to settle whether the goal is met.

Frame them as outcomes for whoever uses the thing: *what will a user of this
product be able to do when the programme is done?* Not components, not phases.

🔴 **Invoke `brainstorming` and run its §0 for this step.** Its goal gate is the
gate; do not proceed past it here.

⚠ **Deliberately not summarised.** An earlier draft listed §0's fields in one
line as a convenience. That is the drift this constraint exists to stop — a
summary ages the moment `brainstorming` changes, and a reader who trusts it never
opens the real thing. **Read §0 there.**

**These become the yardstick every lane judges its own design against**, for the
life of the programme. That is why there are at most three and why they are worth
an hour.

Two failure modes specific to a *programme*:

- **A goal every lane serves is not a goal, it is a slogan.** "Ship quality
  software" cannot be unmet. Ask what measurement goes red if the goal fails while
  everything else works.
- 🔴 **A goal whose only criteria are infrastructure cannot fail.** If every proof
  tests plumbing — a service is up, a table exists, a job is registered — the goal
  reads green while the thing it exists for has not happened once.

---

### 2 · Deep analysis, and research what you do not know

**Now** go deep, and only on what the goals actually touch.

- **The existing components and capabilities** the goals depend on — properly this
  time, because Phase 3 subtracts from this.
- **For anything genuinely new, research it.** Do not design from first
  principles what an industry has already solved:
  - **WebSearch** for market practice, architectures, and the failure modes others
    report. Search generously — this is the cheapest hour in the programme.
  - **GitHub** for projects that solved something close. Read how they structured
    it, and why.
  - **Context7** for current library and framework documentation, rather than
    recalling an API.

🔴 **Prefer a known-good shape over an invented one.** A programme that invents
what it could have adopted pays for it in every lane, and the cost surfaces late
as "this is harder than we thought". If you reject a common approach, be able to
say why in one sentence.

---

### 3 · Gap analysis and the first architecture

**What is missing between what exists and what the goals require?** High level —
building blocks and boundaries, not designs.

Produce:

| | |
|---|---|
| **Building blocks** | each marked `new`, `existing` or `extend` |
| **What each owns** | one line |
| **The seams** | which blocks talk, and what crosses |
| **Your recommendation** | the architecture you would take, and the alternative it beat |

`existing` and `extend` matter more than `new` — that is where the reuse question
gets asked while it is still cheap, and it is the difference between a programme
that extends a product and one that quietly rebuilds it.

🔴 **Validate this with the human before going further.** Not "here is the
architecture" — put the open choices to them as questions with options and a
recommendation, the way any decision is put. **Everything downstream inherits
this shape**, so a wrong call here is the most expensive one available. Wait for
their agreement.

---

### 4 · The roster — lanes derived FROM the building blocks

🔴 **Derive lanes from Phase 3, so every lane owns something real.** A roster
written first and then matched to work produces a lane whose scope is a job title.

**Maximum 5.** The cap is about **your context and the human's decision queue**,
not about the work. Six lanes do not deliver faster than four if you cannot hold
them and the human cannot answer them. **Three good lanes beat five contrived
ones.**

#### The seven tests a lane must pass

Apply all seven. A candidate failing any one is not a lane — merge it, split it,
or sequence it.

| # | Test | How to apply it |
|---|---|---|
| **1** | **Isolated** | It works within one component or one area of the codebase. |
| **2** | **Enough work** | Months of it, not a task. Spinning up a lane costs a session, a worktree, a rig and a place in your queue. |
| **3** | **Non-overlapping owned paths** | Write every lane's path list. **If any path appears twice, the split is wrong.** Fix it now, not at the first merge conflict. |
| **4** | **Owns an outcome, not a layer** | Name a demo this lane alone can give. "The database layer" fails — it can only be integrated, never demonstrated. This is what stops you slicing horizontally. |
| **5** | **Seams writable today** | Write its contract to each neighbour, in one or two lines, now. If that needs a design session first, do not split there — you would move an unresolved argument into integration, where it costs more. |
| **6** | **Failure is contained** | If this lane stalls for a week, do the others keep moving? If everything blocks on it, it is not a peer — it is a prerequisite. **Sequence it before the fan-out**, not alongside it. |
| **7** | **Serves a named Mission Goal** | Point each lane at a goal. An orphan lane is over-scope: cut it or defer it. 🔴 **You may not fix an orphan by adding a goal** — that is how a programme acquires a purpose nobody asked for. |

#### What each lane carries

| | |
|---|---|
| **name** | `WS<n>-<Name>` — load-bearing; scripts parse it |
| **id** | lane plus incarnation, e.g. `WS5-6`. Changes on respawn; the name does not |
| **session** | the agent session actually holding the lane |
| **scope** | one line. If it needs two, it is two lanes |
| **owned paths** | what this lane may edit — test 3 |
| **serves** | which Mission Goal — test 7 |
| **worktree · branch** | where it works |
| **rig ports** | frontend, backend, db, compose project name |

⚠ **Ports and compose project names are global to the machine, not to the
programme.** Allocate them here, together, or two lanes collide weeks from now
and lose a day to it.

---

### 5 · Write it down

- [ ] Write **`program.yaml`** at the programme root — shape in
      `docs/program-yaml.md`. It becomes the **sole owner** of programme identity.
- [ ] Verify: `python3 "$CLAUDE_PLUGIN_ROOT/scripts/program-yaml-check.py"`. **A
      missing field is an error naming the field and the lane**, never a silent
      default.
- [ ] **Create the programme state directory** — without it the monitoring and
      messaging tools abort, because the lane map they read does not exist yet:

      bash "$CLAUDE_PLUGIN_ROOT/scripts/init-programme.sh"

      It seeds `.handover/` with an empty lane map, its import dependencies, the
      outbox and the inbox directory, then **runs the seeded map to prove it
      works**. Idempotent, and it never overwrites an existing roster. The
      stateless tools (`msg.py`, `stall-check.py`, `reap-ghosts.sh`,
      `board-server.py`) stay in the plugin and are always invoked from
      `$CLAUDE_PLUGIN_ROOT/scripts/` — only the lane map is programme-owned.
- [ ] **Scaffold the board** — use `update-program-board` for the structure. Do
      not invent a layout here.
- [ ] **Register the PM's recurring check.** Write its prompt yourself — there is
      no template, and one pointing at a file that does not exist is worse than
      none. It should say: re-read `program.yaml` and the board, check each lane
      is live and unblocked, and act on anything waiting.
      ⛔ **It carries invariants only** — no commit SHA, no PR number, no work
      queue, no dated claim. State goes stale; a recurring prompt does not get
      re-read, so a fact baked into it is wrong forever and silently.

---

### 6 · Stand the lanes up

For **each** lane, in order:

- [ ] **Write its spawn document** — `SPAWN-<date>-WS<n>-session-1.md`.
      **State only**: identity line, scope, owned paths, the Mission Goals, its
      branch and base, worktree path, allocated rig ports, and verified trunk SHA.
      **Method belongs in `running-a-workstream`, which the doc points at** — do
      not restate it. A brief that mixes state and method rots at the first
      re-scope and nobody can tell which half aged.
- [ ] **Spawn and name the session.** `bash scripts/spawn-lane.sh WS<n> "<Lane>" 1`
      — it pins the model, strips the inherited child-session variable that
      silently disables transcript writing, and names the tab. **Read its header
      before first use**; every guard in it cost someone an afternoon.
- [ ] **Point it at the spawn doc and at `running-a-workstream`** in its first
      message. Nothing else — it reads the rest itself.
- [ ] **Wait for it to report live** with its branch and rig URL before spawning
      the next. A lane that failed to boot is cheaper to find one at a time.

---

### 7 · Take the seat

**Invoke `running-a-programme`.** You are the PM from here: rulings, unblocking,
the board, merges, and reporting to the human.

**Then report** — the goals, the roster, the board URL, and what each lane is
starting on. **REQUIRED SUB-SKILL:** `writing-exec-summaries`.

---

## Running it again

**This skill is idempotent and must stay so.** On a second run against an existing
`program.yaml`:

- [ ] **Report the delta and do not overwrite.** Say which fields differ, in both
      directions.
- [ ] **A lane present on disk and absent from your new roster is the interesting
      case** — either one someone added deliberately or one you forgot. Ask. Do
      not silently drop it.
- [ ] Only the human decides which side wins, field by field.
- [ ] **Never re-spawn a lane that is already live.** Two sessions on one lane
      fork it, and both keep working.

⚠ **Re-running is normal** — a new lane, a rig moved, a respawn. It must be safe
enough that nobody avoids it.

---

## Ownership, which is the part people break

**The PM lane is the sole writer of `program.yaml`** — through this skill at
creation, or a deliberate PM edit for a respawn, a new lane, or a rig change. Any
skill or script may read it.

That is enforced by **documentation only**, and deliberately: there is exactly one
writer, and a guard over a set of size one can never fire — it would read as
coverage while proving nothing.

🔴 **The moment a second writer exists, the guard is due in that same PR.**
Whoever adds the second writer owns building it.

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
