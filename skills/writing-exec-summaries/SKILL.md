---
name: writing-exec-summaries
description: Use when reporting status, progress or findings to the human sponsor of a programme, when they ask "where are we", or when you need a decision from them. Symptoms - you are about to write a long prose status, or to hand them a choice without a recommendation.
---

# Writing exec summaries

**Announce at start:** "I'm using writing-exec-summaries for this report."

The sponsor's job is **taking decisions**. Everything here exists to make that
possible in the time they actually have.

**The test before sending:** could they act on this in 30 seconds? If it needs a
second read, it is too long.

---

## The two registers — same facts, two renderings

🔴 **This is the rule most often broken, and it is broken by relaying.** Findings
arrive from lanes and subagents written in ids and codes — correct for them. Copy
that register upward and the sponsor gets a document they cannot act on.
**Translating is a step you owe, and it is silently skipped because the incoming
report already reads as finished work.**

| Audience | Register |
|---|---|
| **The human sponsor** | Plain language. Zero ids, zero codes, zero internal shorthand. Numbered decisions. |
| **Other agents, status files, PR bodies, commit messages** | Use the codes deliberately — finding ids, AC ids, lane tags, SHAs. They are how work gets routed and credited; stripping them destroys traceability. |

**The self-containment test:** could the sponsor take this decision having read
**only this message**? If a term requires them to remember a prior message, open a
document, or ask what it stands for, it fails.

- ❌ `AC-AF-26 is blocked by the D-4 ruling`
- ✅ "whether a user can see the contents of files an agent is about to commit on
  their behalf"

⚠ **Inventing your own shorthand is worse than using a project code**, because
there is nowhere they could have learned it. If a word would not appear in a
normal business conversation, spell it out in the same sentence or do not use it.
Say "we turned the fix off on purpose to check the problem came back", not "we
positive-controlled it".

---

## The five sections. Always. Even when one is "none".

### 1 · Where we are
What is **now true that wasn't before**, in business terms — value delivered, not
tasks performed. No file names, no symbol names, no ids. If something is
unfinished, say so here rather than burying it.

### 2 · Decisions I need from you
Numbered, so they can answer by number. Each one in the three-part frame below.
**Zero decisions is a valid answer** — say "none" rather than inventing one.

### 3 · Key design decisions to verify
Calls **already made** that they should sanity-check. Present the **logic**, not
the implementation — they are checking the reasoning. One or two sentences each:
what was decided, and why that follows.

⚠ Easy to skip by mistake, and distinct from §2. These are not open questions;
they are places a wrong assumption would already be baked in.

### 4 · Proposed next steps
What happens next, in order, and what each is waiting on.

### 5 · Retrospective — what to LEARN, not what to confess

Two halves:

**a) What went well** — name the *practice*, not the outcome. "The red-first test
caught it" is useful; "the feature works" is not. The point is knowing which
habits to keep paying for.

**b) What went badly, and the SYSTEMIC CAUSE.** Each entry:

| Part | Rule |
|---|---|
| The error | one line, factual, no self-flagellation |
| The systemic cause | the property of the process, architecture or tooling that made it likely |
| The fix | a concrete change that prevents the whole class — ideally mechanical |

🔴 **A cause that reduces to "should have been more careful" is not a systemic
cause.** Discipline does not survive contact with a tired agent at 4am; a gate
does. If the only available fix is vigilance, say so explicitly and mark it an
accepted risk rather than dressing it up as a fix.

**Group by class, not by incident.** Three instances of one problem is ONE
finding with three instances.

**Corrections to earlier claims belong here** — plainly, because each may have
changed a decision they were about to take. A report that never corrects anything
is usually a report that did not check.

---

## The three-part decision frame

Every decision in §2, every time:

```
1 · CONTEXT — what is the problem
    Plain sentences. What is true today, why it is a problem, what it touches.
    Fold the blast radius in here: they read the context to decide whether the
    decision matters to them at all.

2 · OPTIONS — with honest pros and cons
    Genuinely distinct choices, not one real option and two straw men.
    Honest cons on the option you are about to recommend, or the frame is
    decoration.

3 · RECOMMENDATION
    Commit to one. Why, in one or two sentences.
    Never "it depends". Never a menu.
```

**A decision that references a previous decision is not self-contained.**
"Unchanged from my last message" is a failure. Restate it in full every time —
repetition is cheap; a decision taken on half the context is not.

---

## When the subject is architecture or a complex flow

**Do not explain a topology in prose.** Build a page with diagrams and hand them
the link.

**REQUIRED SUB-SKILL:** `artifact-design` before writing it, and
`artifact-diagramming` for the diagrams themselves.

---

## Formatting

Proper markdown. Headings, short bullets, tables for comparisons, bold on the
load-bearing clause. **Never** an unbroken wall of prose — that is the thing this
skill exists to replace. Measurements and tables go underneath the point they
support, or in a file they can open; never stacked three deep in front of it.

Add sections beyond these five when there is genuinely something they would want
and have not asked for. The structure is a floor, not a ceiling.

---

## Red flags

- You are about to send prose paragraphs as a status
- A code, id or acronym survived into the sponsor's copy
- You coined a term mid-report and then leaned on it
- §2 has a menu instead of a recommendation
- §5 lists your mistakes instead of the causes behind them
- You wrote "as discussed previously" instead of restating it
- You are explaining an architecture in words because a diagram felt like effort
