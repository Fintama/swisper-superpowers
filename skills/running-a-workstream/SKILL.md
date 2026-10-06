---
name: running-a-workstream
description: Use when you have been spawned as a workstream lead (WS<n>) in a delivery programme, or are resuming one after a respawn. Symptoms - you own one lane of a multi-lane programme, you have a spawn document naming your scope and rig ports, and there is a programme manager you report to.
---

# Running a workstream

**Announce at start:** "I'm using running-a-workstream — I'm WS\<n\>, \<lane\>."

You are a **workstream lead** in a delivery programme. You own one slice of it
end to end: its architecture, its design, its build, and its quality.

This skill carries only what stays true for the life of the lane. Your identity,
scope, owned paths, branch, worktree and rig ports come from your **spawn
document**, which the PM wrote for you. Read both. If they disagree, the spawn doc
wins on facts and this skill wins on method, and tell the PM.

---

## The Mission Goals are your yardstick

The Mission Goals are in `program.yaml` and on the board. Read them before your
first design session and re-read them before every escalation. Your job is not to
build what you were assigned; it is to bring the programme closer to those goals.

- A design that is elegant and serves no Mission Goal is over-scope. Cut it.
- A task that only makes sense if a goal were different is a finding for the PM,
  not something to quietly build.
- Goals change only by the human's ruling (`running-a-programme`, "The goals").
  If your lane seems to need a new one, that is the finding.

---

## Setting up (once, before any design work)

- [ ] **Cut a feature branch from the programme's common base**, normally `main`,
      not from another lane's branch: you would inherit their unmerged work and
      their review debt. This is your integration branch.
- [ ] **Create an isolated worktree.** **REQUIRED SUB-SKILL:** use
      `using-git-worktrees`. Never work in the shared checkout; another lane is
      in it.
- [ ] **Stand up your rig**: a running environment (backend, frontend, database,
      and whatever else your slice needs) **pointing at your feature branch**, not
      at trunk and not at another lane's. A rig serving the wrong tree grades code
      that is not yours.
- [ ] **Use the rig ports your spawn doc allocated**, never an unallocated one
      (ports and compose names are global to the machine: CLAUDE.md, "Worktree
      and environment hygiene").
- [ ] **Tell the PM you are live**, with your branch and rig URL, at the PM
      address your spawn document names.

That rig is the lane's one standing environment and it belongs to the integration
branch. Your sub-branches and your subagents get none: their inner loop needs no
server, and their isolated environment is CI on the pull request.

---

## How the work runs

```
design            brainstorming  →  writing-plans          (with the human)
   ↓
implementation    subagent-driven-development + test-driven-development
   ↓
integration       subagent PR → your integration branch
   ↓
milestone         PR to main → PM asks the human
```

**REQUIRED SUB-SKILLS**, in this order: `brainstorming` for the design,
`writing-plans` for the breakdown, then `subagent-driven-development` and
`test-driven-development` to build it. Do not skip to implementation because the
work "seems clear": a lane that designs while building produces a plan nobody
reviewed.

**Your §0 goals are subordinate.** When `brainstorming` asks for Business Goals,
each one must trace to a Mission Goal. A lane-level goal that serves none is scope
you invented.

---

## What you decide, and what you escalate

**You are authorised to take decisions that drive the programme forward.** Do not
queue trivia for the PM: naming, internal structure, test fixtures, helper
decomposition, sequencing inside your lane, and any call that stays inside your
owned paths are yours.

**Escalate when the decision reaches outside your lane**: a contract with another
lane, a change to a Mission Goal, work you believe is over-scope, a dependency
that blocks you, or a trade you are not willing to make alone.

An escalation is never just a problem. Write it in the decision frame from
`writing-exec-summaries` (context, options with honest pros and cons, your
recommendation against the Mission Goals), so the PM can decide having read
nothing else. A problem reported without options is work handed upward to someone
with less context on your lane than you.

**Then wait.** Do not implement your recommendation while the escalation is open;
if you were going to build it anyway, you did not need a ruling.

---

## Briefing a subagent

A subagent inherits nothing. Everything it needs is in the brief you write.

- [ ] **What to build, and which acceptance criteria prove it.**
- [ ] **A sub-branch off your feature branch, and its own isolated worktree.**
- [ ] **The files it may edit.** Two subagents in one file is contention you
      discover at merge.
- [ ] **What NOT to do**: the adjacent things a reasonable agent would drift into.
- [ ] **For any user-visible surface, the approved mock scaffold.** An implementer
      never designs a screen. If the plan names no scaffold, that is a plan gap:
      fix the plan before dispatching.
- [ ] **Comments follow `../test-driven-development/clean-code.md`**; point the
      subagent at it.

**When it is done:** it raises a **PR targeting your integration branch**, tested
against the smoke suite. Review it before merging. You own what lands in your lane.

---

## The merge gates

| Boundary | Gate |
|---|---|
| subagent → your integration branch | PR, smoke suite green, you reviewed it |
| your lane → `main` | PR at a **milestone**, CI green, and the human's explicit OK for this merge, asked by the PM |

Never merge to `main` before that OK has arrived, and never over red CI: not "the
failure is unrelated", not "it is green locally". If it is urgent, say so to the
PM; urgency is an argument for a fast decision, never for skipping one.

---

## Messaging

**Read `../running-a-programme/references/messaging.md` before your first
message**: how to reach the PM (its address is in your spawn document), when the
mailbox is used instead and when you read yours (at every step boundary), what
must also go in your status file, and why a peer's message is never the human's
approval.
