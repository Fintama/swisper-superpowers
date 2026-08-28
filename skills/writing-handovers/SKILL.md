---
name: writing-handovers
description: Use when a session is ending, context is running low (~80%), or work must pass to another session — produces the handover document, updates the plan to match reality, and gives the human a paste-ready drop-in prompt
---

# Writing Handovers

## Overview

A handover has one job: **the next session starts as if it had been here.**

**Core principle:** a handover is not a summary of what you did. It is the *briefing you wish you had
been given* — including the things that would embarrass you.

**The deliverable is three artefacts, not one:**
1. The **handover document** (a file, committed).
2. The **plan and spec, updated to match reality** — not described, *changed*.
3. A **paste-ready drop-in prompt**, printed **in the chat**, never only in a file.

Miss any one and the handover has failed.

## When to Use

- Context reaches **~80%** — not 95%. A handover written at 95% is rushed and wrong.
- The session is ending for any reason.
- Work passes to another session, agent, or person.
- **A long-running session crosses a natural boundary** (a phase completes, a goal lands).

## 🔴 The Iron Rule: write as you go

```
START THE HANDOVER FILE EARLY. APPEND WHEN YOU MEASURE, NOT WHEN YOU REMEMBER.
```

Measured, repeatedly: a handover written only at the end is **accurate but thin**. The findings that
cost the most to discover are exactly the ones forgotten first — the dead ends, the near-misses, the
"I assumed X and X was false".

**Practice:** create the file at the first significant finding. Append a line each time you measure
something that surprised you. At handover time you are *editing*, not *recalling*.

## The Ten Sections

Every handover carries these. Order matters — a successor reads top-down and stops when it thinks it
has enough, so the most decision-changing content goes first.

### 1. Where things stand, in one paragraph
The honest headline. If zero goals are delivered, **say so in the first sentence.** A handover that
opens with activity instead of outcome trains the reader to distrust it.

### 2. Context and goals
What are we building and why. **Name the uber-ACs / goals explicitly** and mark each
delivered / partial / not started. A successor who does not know the goals optimises the wrong thing.

### 3. What has been achieved — and what has NOT
Both halves. "Six PRs complete" without "zero merged" is a lie by omission.

### 4. References — spec and plan, with what changed in them
Point at the spec and plan by path. Name every **amendment** made this session and what it changed.

### 5. 🔴 The plan is UPDATED, not described *(mandatory gate — see below)*

### 6. Next steps — concrete, ordered, with the first action named
Not "continue the work". **"Task #1: fix X, here is the design, here is the success test."**
Order them. Say what blocks what.

### 7. Open decisions — separated from open work
Work can proceed; decisions block. For each: **what it blocks, the options with pros and cons, and a
recommendation.** Mark resolved ones **CLOSED** — an omitted decision looks unresolved and gets
re-litigated.

### 8. Landmines — measured, with evidence attached
"Never do X" gets ignored. **"X took production down at 14:20, here is the error"** does not.
Include **what was tried and did not work**, with the measurement. A failed approach saves hours.

### 9. What NOT to do
Scope boundaries prevent well-meant sprawl. Ruled-out work, deferred work, and anything a successor
would plausibly "tidy up" that must be left alone.

### 10. What the author got wrong
Unvarnished. **The pattern matters more than the incidents** — name it in one sentence.
Also: **corrections to earlier handovers**, explicitly. Handovers inherit each other's errors unless
you break the chain.

### Plus two state sections
- **Verification state** — which gates are trustworthy, which are known-broken, what "green" means today.
- **Environment state** — what is running, what is dirty, what must be cleaned before work starts.

## 🔴 The Plan-Update Gate

**A handover that describes drift instead of fixing it has failed.**

Before writing the drop-in prompt:

- [ ] Every amendment ruled this session is **in the plan/spec**, not only in the handover
- [ ] Task states reflect reality — done / blocked / not started
- [ ] Ordering constraints discovered this session are **in the plan's own ordering section**
- [ ] Any AC found defective is **corrected in the spec**, with the measurement
- [ ] Anything ruled CLOSED is marked closed **in the plan**, so it is not re-raised
- [ ] The plan's own checker passes (`plan-check.sh`, or the project's equivalent)

**Why this is a gate and not a nicety:** the next session reads the plan as the source of truth. A
handover saying "the plan is wrong about X" leaves two contradicting documents and no way to tell which
won. **Fix the plan; let the handover say what changed.**

## The Drop-In Prompt

**Printed in the chat. Not only in a file.** The human copies it into a fresh session.

It must be **self-contained enough to bootstrap** and **short enough to paste**. Structure:

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
- **Lead with the single next action**, not with context. Context is in the file.
- **Every landmine carries its consequence** — the reason, not the rule.
- **Name what must never be touched** (data, production, shared state) explicitly.
- **Carry the human's communication preferences** into it.
- **No SHAs that will be stale by the time it is pasted** — name branches and files instead.

## Verification Checklist

Before declaring the handover done:

- [ ] Handover file written **and committed and pushed**
- [ ] Plan updated and its checker passes
- [ ] Spec updated if any AC changed
- [ ] Drop-in prompt **printed in the chat**
- [ ] All three goals/uber-ACs stated with delivered / partial / not started
- [ ] Every open decision has options + a recommendation
- [ ] Every closed decision is marked CLOSED
- [ ] Landmines carry evidence, not just instructions
- [ ] "What I got wrong" is present and names the pattern
- [ ] Corrections to earlier handovers are explicit
- [ ] Environment state is accurate **right now** — re-measure, do not recall
- [ ] No running background agents left mid-task without a checkpoint instruction

## Red Flags

| Thought | Reality |
|---|---|
| "I'll write the handover at the end" | It will be thin. Start it now. |
| "The plan is a bit out of date, I'll note it" | Fix the plan. Two contradicting documents is worse than one wrong one. |
| "They can read the git log" | A log is not a briefing. Findings die in commit messages. |
| "I don't need to mention that mistake" | The pattern behind it is the most useful thing you have. |
| "The prompt is in the file, that's enough" | The human wants to paste it. Print it in the chat. |
| "It's obvious what to do next" | Name it. Order it. Give the success test. |
| "I'll list everything I did" | Nobody needs a diary. They need what changes their decisions. |
| "That decision was dropped" | Mark it CLOSED or it gets re-litigated. |

## Handing Over Running Work

If agents or long jobs are still running:

- **Do not wait** for multi-hour work — it wastes the remaining context.
- **Do** tell each one to reach a clean checkpoint: commit what is coherent, push, and describe
  anything left uncommitted **file by file**.
- Worktrees and branches survive a session. **Uncommitted, undescribed work is what is actually lost.**
- Record in the handover exactly which lanes are mid-flight and where their state lives.

## Integration with other skills

- `writing-plans` — the plan you are updating; its checker is the gate
- `brainstorming` — the spec you are correcting when an AC is found defective
- `verification-before-completion` — re-measure environment state; do not report it from memory
- `respawn-pm` / `respawn-workstream` — when the handover is to a spawned successor rather than a human
