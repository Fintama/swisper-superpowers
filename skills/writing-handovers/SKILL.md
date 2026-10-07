---
name: writing-handovers
description: Use when a session is ending, context is running low (~80%), or work must pass to another session — produces the handover document, updates the plan to match reality, and gives the human a paste-ready drop-in prompt
---

# Writing Handovers

## Overview

A handover has one job: **the next session starts as if it had been here.**

It is not a summary of what you did. It is the briefing you wish you had been
given, including the things that would embarrass you. A git log is not a briefing.

**The deliverable is three artefacts:**
1. The **handover document**, a file, saved (see "Saving").
2. The **plan and spec, updated to match reality**: changed, not described.
3. A **paste-ready drop-in prompt**, printed **in the chat**, never only in a file.

Miss any one and the handover has failed.

## When to Use

- Context reaches **~80%**, not 95%: a handover written at 95% is rushed and
  wrong. A programme session (PM or lane) uses the thresholds in
  `../running-a-programme/references/messaging.md` instead.
- The session is ending for any reason.
- Work passes to another session, agent, or person.
- A long-running session crosses a natural boundary (a phase completes, a goal lands).

## Write as you go

Start the handover file early, and append when you measure, not when you
remember. A handover written only at the end is accurate but thin: the findings
that cost the most to discover (the dead ends, the near-misses, "I assumed X and
X was false") are the ones forgotten first.

Create the file at the first significant finding. Append a line each time you
measure something that surprised you. At handover time you are editing, not
recalling.

## The Ten Sections

Every handover carries these. A successor reads top-down and stops when it thinks
it has enough, so the most decision-changing content goes first.

### 1. Where things stand, in one paragraph
The honest headline. If zero goals are delivered, say so in the first sentence.

### 2. Context and goals
What we are building and why. Name the uber-ACs / goals and mark each
delivered / partial / not started.

### 3. What has been achieved, and what has NOT
Both halves. "Six PRs complete" without "zero merged" is a lie by omission.

### 4. References: spec and plan, with what changed in them
Point at the spec and plan by path. Name every amendment made this session and
what it changed.

### 5. The plan is updated, not described *(gate below)*

### 6. Next steps: concrete, ordered, with the first action named
Not "continue the work": "Task #1: fix X, here is the design, here is the success
test." Order them. Say what blocks what.

### 7. Open decisions, separated from open work
Work can proceed; decisions block. For each: what it blocks, then the decision
frame (`writing-exec-summaries`: context, options with pros and cons, a
recommendation). Mark resolved ones **CLOSED**: an omitted decision looks
unresolved and gets re-litigated.

### 8. Landmines, with evidence attached
"Never do X" gets ignored; "X took production down at 14:20, here is the error"
does not. Include what was tried and did not work, with the measurement.

### 9. What NOT to do
Ruled-out work, deferred work, and anything a successor would plausibly "tidy up"
that must be left alone.

### 10. What the author got wrong
Unvarnished. The pattern matters more than the incidents: name it in one
sentence. Also state **corrections to earlier handovers** explicitly; handovers
inherit each other's errors unless you break the chain.

### Plus two state sections
- **Verification state**: which gates are trustworthy, which are known-broken, what "green" means today.
- **Environment state**: what is running, what is dirty, what must be cleaned before work starts.

## The Plan-Update Gate

A handover that describes drift instead of fixing it has failed: the next session
reads the plan as the source of truth, and two contradicting documents leave no
way to tell which won.

Before writing the drop-in prompt:

- [ ] Every amendment ruled this session is **in the plan/spec**, not only in the handover
- [ ] Task states reflect reality: done / blocked / not started
- [ ] Ordering constraints discovered this session are in the plan's own ordering section
- [ ] Any AC found defective is corrected in the spec, with the measurement
- [ ] Anything ruled CLOSED is marked closed in the plan, so it is not re-raised
- [ ] The plan's own checker passes (`plan-check.sh`, or the project's equivalent)

## Saving

Save the handover, plan and spec where they live, the way that place requires:

- **Fintama documents** (specs, plans, handovers; helvetiq's `.handover/` is a link
  into it): Swisper_Documentation, `main` only, saved only with
  `~/Projects/swisper-docs/tools/docs-save -m "<what>" <paths>`. Never branch,
  commit, push, stash or reset that checkout by hand.
- **Anywhere else**: commit and push it in its own repo.

## The Drop-In Prompt

**Printed in the chat, not only in a file.** The human copies it into a fresh session.

It must be self-contained enough to bootstrap and short enough to paste. Structure:

```
Read <handover path> end to end before doing anything.
Then read <previous handover> — its landmines are still true.

You are <role>. <Branch / environment facts that prevent immediate mistakes.>

TASK #1 — <the single most important thing>. <Why. The design. The success test.>
<Any warning about attempting it in the wrong conditions.>

THEN <the next block of work>, with the ordering constraints stated.

<Unblocked work and what changed to unblock it.>

RULES THAT COST REAL TIME TO LEARN:
- <landmine, with its consequence>
- <landmine, with its consequence>

<Irreversible-damage warnings: data, production, shared state.>

<How the human wants to be communicated with.>
```

**Rules for the prompt:**
- Lead with the single next action, not with context. Context is in the file.
- Every landmine carries its consequence: the reason, not the rule.
- Name what must never be touched (data, production, shared state) explicitly.
- Carry the human's communication preferences into it.
- No SHAs that will be stale by the time it is pasted: name branches and files instead.

## Verification Checklist

Before declaring the handover done:

- [ ] Handover file written and saved (see "Saving")
- [ ] Plan updated and its checker passes; spec updated if any AC changed
- [ ] Drop-in prompt printed in the chat
- [ ] Every goal / uber-AC stated as delivered / partial / not started
- [ ] Every open decision has options and a recommendation; every closed one is marked CLOSED
- [ ] Landmines carry evidence, not just instructions
- [ ] "What I got wrong" is present and names the pattern; corrections to earlier handovers are explicit
- [ ] Environment state is accurate right now: re-measure, do not recall
- [ ] No running background agents left mid-task without a checkpoint instruction

## Handing Over Running Work

If agents or long jobs are still running:

- Do not wait for multi-hour work; it wastes the remaining context.
- Tell each one to reach a clean checkpoint: commit what is coherent, push, and
  describe anything left uncommitted file by file.
- Record in the handover exactly which lanes are mid-flight and where their state
  lives. Worktrees and branches survive a session; uncommitted, undescribed work
  is what is lost.

## Integration with other skills

- `writing-plans`: the plan you are updating; its checker is the gate
- `brainstorming`: the spec you are correcting when an AC is found defective
- `verification-before-completion`: re-measure environment state; do not report it from memory
- `respawn-pm` / `respawn-workstream`: when the handover is to a spawned successor rather than a human
