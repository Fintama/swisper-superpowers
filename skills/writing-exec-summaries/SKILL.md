---
name: writing-exec-summaries
description: Use when reporting status, progress or findings to the human sponsor of a programme, when they ask "where are we", or when you need a decision from them. Symptoms - you are about to write a long prose status, or to hand them a choice without a recommendation.
---

# Writing exec summaries

**Announce at start:** "I'm using writing-exec-summaries for this report."

The sponsor's job is taking decisions. Everything here exists to make that
possible in the time they actually have.

**The test before sending:** could they act on this in 30 seconds? If it needs a
second read, it is too long.

This skill is also the home of **the decision frame** (below), used for every
decision put to anyone: a lane escalating to the PM, the PM passing a call to the
human, a decision card on the board.

---

## The two registers: same facts, two renderings

The rule most often broken, and it is broken by relaying. Findings arrive from
lanes and subagents written in ids and codes, which is correct for them. Copy that
register upward and the sponsor gets a document they cannot act on. Translating
is a step you owe, and it is easy to skip because the incoming report already
reads as finished work.

| Audience | Register |
|---|---|
| **The human sponsor** | Plain language. No ids, no codes, no internal shorthand. Numbered decisions. |
| **Other agents, status files, PR bodies, commit messages** | Use the codes deliberately: finding ids, AC ids, lane tags, SHAs. They are how work gets routed and credited. |

**The self-containment test:** could the sponsor take this decision having read
only this message? If a term requires them to remember a prior message, open a
document, or ask what it stands for, it fails.

- ❌ `AC-AF-26 is blocked by the D-4 ruling`
- ✅ "whether a user can see the contents of files an agent is about to commit on
  their behalf"

Inventing your own shorthand is worse than using a project code, because there is
nowhere they could have learned it. If a word would not appear in a normal
business conversation, spell it out in the same sentence or do not use it. Say
"we turned the fix off on purpose to check the problem came back", not "we
positive-controlled it".

---

## The five sections, always, even when one is "none"

### 1 · Where we are
What is now true that wasn't before, in business terms: value delivered, not
tasks performed. No file names, no symbol names, no ids. If something is
unfinished, say so here rather than burying it.

### 2 · Decisions I need from you
Numbered, so they can answer by number. Each one in the decision frame below.
Zero decisions is a valid answer: say "none" rather than inventing one.

### 3 · Key design decisions to verify
Calls already made that they should sanity-check. Present the logic, not the
implementation: they are checking the reasoning. One or two sentences each: what
was decided, and why that follows. These are not open questions (that is §2);
they are places a wrong assumption would already be baked in.

### 4 · Proposed next steps
What happens next, in order, and what each is waiting on.

### 5 · Retrospective: what to learn, not what to confess

**a) What went well**: name the practice, not the outcome. "The red-first test
caught it" is useful; "the feature works" is not.

**b) What went badly, and the systemic cause.** Each entry:

| Part | Rule |
|---|---|
| The error | one line, factual |
| The systemic cause | the property of the process, architecture or tooling that made it likely |
| The fix | a concrete change that prevents the whole class, ideally mechanical |

A cause that reduces to "should have been more careful" is not a systemic cause.
If the only available fix is vigilance, say so and mark it an accepted risk.

Group by class, not by incident: three instances of one problem is one finding
with three instances.

Corrections to earlier claims belong here, plainly, because each may have changed
a decision they were about to take.

---

## The decision frame

Every decision, every time:

```
1 · CONTEXT — what is the problem
    Plain sentences. What is true today, why it is a problem, what it touches.
    Fold the blast radius in here: the reader decides from it whether the
    decision matters to them at all.

2 · OPTIONS — with honest pros and cons
    Genuinely distinct choices, not one real option and two straw men.
    Honest cons on the option you are about to recommend.

3 · RECOMMENDATION
    Commit to one. Why, in one or two sentences, against the goals.
    "It depends" only together with what would tip it; never a bare menu.
```

A decision that references a previous decision is not self-contained.
"Unchanged from my last message" fails. Restate it in full every time.

The register follows the reader: plain language to the human, ids and codes
between agents.

---

## When the subject is architecture or a complex flow

Do not explain a topology in prose. Build a local HTML page with diagrams and
hand them the path (`artifact-diagramming` has the diagram guidance). Publish it
as a claude.ai artifact only if they ask.

---

## Formatting

Proper markdown: headings, short bullets, tables for comparisons, bold on the
load-bearing clause. Never an unbroken wall of prose. Measurements and tables go
underneath the point they support, or in a file they can open, never stacked
in front of it.

Add sections beyond these five when there is genuinely something they would want
and have not asked for. The structure is a floor, not a ceiling.
