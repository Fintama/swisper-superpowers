# The programme bus — how participants talk

Read by `running-a-programme` (PM) and `running-a-workstream` (lanes). One copy,
because a convention restated in two places drifts and then nobody knows which is
current.

---

## The one hard rule

🔴 **Every message identifies its sender, in the message itself.**

```
WS3 2026-08-28 14:05 [ctx:42%] — <message>
PM  2026-08-28 14:11              — <message>
```

**Not because it is tidy.** Two reasons, both measured:

- **Attribution is how a repeat count works.** A problem one lane hits is an
  anecdote; the same problem hit independently by three lanes is a property of the
  system, and that is what earns a fix. Unattributed messages cannot be counted.
- **The transport does not always carry identity you can trust**, and a reader
  who has to work out who is talking pays that cost on every message.

**Lanes also carry `[ctx:<n>%]`** — remaining context — on every message. It is
how the PM sees a succession coming instead of discovering it when a lane stops
mid-task.

---

## Channels, and what each is for

| Channel | For | Not for |
|---|---|---|
| **Direct message** | a decision request, a ruling, an unblock | status nobody asked for |
| **The outbox / bus** | milestones, blockers, "I'm live", context alerts | conversation |
| **The board** | current state anyone can read without asking | anything that needs a reply |
| **Status file** | the lane's own durable record, read at respawn | things the PM must act on now |

**If it needs an answer, send it. If it is state, put it on the board.** A status
update in a direct message costs someone a read and produces nothing; a blocker on
the board waits until someone happens to look.

---

## What a good message looks like

**Short.** Three sentences is usually enough; if it needs more, it is either an
escalation (use the four-part form) or a document with a pointer to it.

**Self-contained.** The reader is holding a different lane's context. "The issue
we discussed" costs them a search. Name the thing.

**One subject.** Two topics in one message means one of them gets answered.

---

## Escalations

Lanes escalate in four parts — context, options with honest pros and cons, a
recommendation, then wait. The full form is in `running-a-workstream`.

**Waiting means waiting.** Do not implement the recommendation while the
escalation is open; if you were going to build it anyway, you did not need a
ruling and should not have asked for one.

---

## Context alerts

A lane at **≤15% remaining** sends a context alert and stops taking new work.
The PM runs `respawn-workstream`.

The PM at **~85% full** runs `respawn-pm` on itself. Do not wait for a good
moment — a PM that runs out mid-decision blocks every lane at once, which is the
only failure that stops the whole programme rather than one lane of it.

---

## Anti-patterns

- **An unsigned message.** Cheap to fix, and it breaks the repeat count.
- **A status broadcast nobody asked for.** That is what the board is for.
- **A problem with no options**, sent upward. It hands work to someone with less
  context than you.
- **Relaying a message unchanged.** Every hop that crosses an audience boundary
  owes a translation — ids and codes between agents, plain language to the human.
- **"As discussed previously."** The reader has slept, compacted, or been
  respawned since. Restate it.
