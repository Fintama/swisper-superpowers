---
name: update-program-board
description: PM duty — keep Mission Control (:8794) current by hand — status, team roster, UAT board, decision briefs, PR list, screens. Use after any merge, respawn, UAT verdict, new decision, or when Heiko asks for the board to be updated.
---

# Update the program board (Mission Control)

**The human's single surface.** Hand-maintained by the PM and written like a
document, not emitted by a generator: a page written with care beats
adequate-looking generated tables.

**This board is the surface the human decides from.** Its value is in being
current, complete and actionable; a board that is 80% right is worse than none,
because they act on it.

## Where it lives and how it runs

- Files: `.handover/board/` (`board.dir` in `program.yaml`). Save edits the way
  `.handover/` is saved (`writing-handovers`, "Saving").
- Server: `board-server.py` serves the files, takes clicks on `POST /decide`
  (appends to `.handover/outbox-to-pm.md`) and answers `GET /state`. Port:
  `board.port` in `program.yaml`, default 8794. If it is down:
  `nohup python3 "$CLAUDE_PLUGIN_ROOT/scripts/board-server.py" > /tmp/board-server.log 2>&1 &`
- Page script: copy `board.js` from this skill's directory into the board
  directory and load it at the end of `index.html`. It wires the decision buttons,
  the status lines and the tabs described below.
- After any edit: `python3 "$CLAUDE_PLUGIN_ROOT/skills/update-program-board/check-board.py" <board-dir> --url http://localhost:<port>` (see "Before you stop").

## The index

**Three tabs, in this order: `Open` · `Decided` · `Record`.** `Open` carries the
lanes and the decisions still waiting. `Decided` carries everything already ruled
on, with its status line. `Record` carries the settled rulings nobody may
re-litigate.

**The Open tab, in this order.** The sections and their order are specified;
reordering is a deliberate change, never tidying. The bar: a senior PM or
architect who has not spoken to you can answer "where are we" from this page alone.

1. **Goals + roadmap**, with milestones per lane. Goals from `program.yaml`; the
   roadmap says what is between here and each one.
2. **Goal completion, as a visual and a percentage.** A bar with no number cannot
   be quoted; a number with no bar is not scannable.
3. **The team**: canonical session names, ids, live/idle, address (the session name
   `SendMessage` reaches), rig ids. From `program.yaml`.
4. **Rig status per lane**: frontend, backend and db URLs, live; plus status tiles
   (rig · production · open PRs · next migration) whose links use the named
   targets `rig` / `prod` / `gh`, so they reuse a tab.
5. **Open PRs to main**, with gate state.
6. **Merges today.**
7. **Per-lane cards**: busy or idle, what is done, what is planned. Clicking a lane
   card shows that lane's plan and its PR list.
8. **Needs you**: the open decision cards, urgency-sorted, each showing what it
   blocks; then the UAT board (blocking first, then open; passed items carry their
   evidence).
9. **Key improvements from retrospectives.**

Also on the index: **Screens and programme docs** as links to the existing detail
pages, never a duplicate list. Detail pages (a UAT runbook, a screens ledger, design
notes) carry the substance; every subpage has the fixed `◂ Mission Control` back
button (`.backbtn`) top-left. Screen mocks themselves live in the product repo
(`design/mocks/<slug>/`, `creating-screen-mocks`); the board links to them.

**Facts and judgement.** Sections 1–6 are facts and go stale silently: derive them
from `program.yaml` and `gh`, or, where hand-written, re-derive them at each update,
never from the previous version of the page. Decisions, lane narrative and
recommendations stay hand-written: no generator for judgement, because the point of
a brief is that a person thought about it and can be asked why.

## Decision cards

A decision is an expandable card on the index, not a separate page:
`<details class="dcard" data-id="<decision id>">`.

- **Closed**, the summary shows: title · one-line why · what it blocks · urgency pill.
- **Open**, it is the decision frame (`writing-exec-summaries`) for a senior PM or
  architect, no jargon or lane shorthand, under five headings in this order:
  **Background** · **The problem** (concretely, with the user-visible
  consequence) · **The options** (table: option · what it means · pros and cons;
  every option gets both, and an option with no cost worth writing is either not
  real or its cost is not found yet; say which) · **My recommendation** (green
  `.rec` box, one clear pick with the reasoning, and an honest note wherever the
  reasoning runs ahead of the evidence or a lane's detail; "wait for the brief" is
  a real option) · **Your call** (the buttons).
- A card without all five sections is not finished. If the human cannot rule from
  the card alone, the card has failed.
- Every card ends in buttons, and so does every other place the human must answer
  (UAT rows included).
- **Buttons pass data, not text.** Write the label once, in an HTML attribute
  (entities handle the quoting), and let `board.js` read it:
  ```html
  <button data-answer="Approve B — state it, don&#39;t offer it">Approve B — state it, don't offer it</button>
  ```
  Never put prose inside an inline JS call (`onclick="pick("Approve B — don't")"`):
  the inner quote ends the attribute, and the button silently does nothing.
- Each card holds a `<div class="status"></div>` for its status line.
- **Notes carry evidence, not adjectives** ("verified across 5 boots", not "should
  be fine").

## A click must wake the PM, and the answer must come back

**1 · Arm a watch in the same turn you start the server.** The write-back only
appends to the outbox; if nothing watches it, the decision waits until you happen
to look, which from the human's side looks like a broken button. Since the PM's
recurring check no longer reads the outbox, this watch is the only thing that
wakes you on a click. Do not invent a second channel.

```
Monitor(
  command: tail -n 0 -f <programme>/.handover/outbox-to-pm.md | grep --line-buffered "via board",
  description: "<name>'s board decisions",
  persistent: true)
```

`tail -n 0`, or every historical line replays as a fresh event; `--line-buffered`,
or grep holds matches in its buffer and the watch is silently dead. Verify the
watch: click a button and confirm the notification arrives.

**2 · Show the answer and the acknowledgement on load.** `/state` returns
`answers` (from the outbox, last wins per decision) and `acks` (`board/acks.json`,
which you write after acting: `{"<decision id>": {"at": "...", "did": "..."}}`).
`board.js` polls it every 20 s and renders per card:

| state | shown as |
|---|---|
| unanswered | buttons only |
| answered, PM has not acted | 🟡 amber: "You answered X · <when>. The PM has not confirmed acting on it yet." |
| PM acted | ✅ green: the answer, plus what the PM did about it |

**The `did` field says what you did**: "Relayed to WS3 with three conditions: it
must write the key production actually reads…". "Acknowledged" tells the human
nothing and looks like closure.

## Tabs: answered decisions leave the queue by themselves

Author every decision card in the Open panel. `board.js` moves a card to `Decided`
on the next refresh once `/state` has an answer or an ack for its `data-id`;
nobody files cards by hand, and you never move or delete a ruled card yourself.

- **An ack with no answer also moves it** (it was settled off-board), and the card
  says "✅ Answered outside the board · PM acted <when> — <did>", so an ack can
  never quietly make an unanswered question disappear.
- **Headings whose cards have all moved are hidden**, and the tabs carry counts
  (`Open 4`).
- **The empty state is real**: when nothing is open the page says "Nothing waiting
  on you" (`#nothing-open`), not a blank panel.
- Tab choice persists in `localStorage`, every read and write wrapped in
  `try/catch` (a browser with site data blocked throws on the accessor).

Page contract `board.js` relies on: panels `#panel-open`, `#panel-decided`,
`#panel-record`; tab buttons with `data-tab="open|decided|record"`; the decided
container `#decided-cards`; counts `#count-open`, `#count-decided`; the empty
state `#nothing-open`. `board-server.py` needs no change for any of it.

## When to update: in the same turn as the event

| Trigger | What to change |
|---|---|
| PR merged | trunk sha, open-PR list, next free migration number; a UAT row if it makes something testable |
| The human's UAT verdict | the row becomes passed **with the evidence in the note**, or the finding is logged |
| Session respawned | team table: canonical name `WS<lane>-<version> <Description>`, address, status |
| A lane reports something that needs the human | a full five-section card, then and there |
| You acted on an answered decision | write its ack with `did`; the card files itself |
| The human asks "where are we" | the board failed: answer them, then fix the board so the next answer is a link |
| A mock is delivered or approved | update the screens links |

## Before you stop

**The test:** could the human rule on every open item, and know the true state of
the programme, from this page alone, without asking you a question? The three ways
it fails: **stale** (retired session names, an old trunk sha, merged PRs shown
open, a roadmap behind reality), **incomplete** (a decision as a one-line ask
without its brief), **unactionable** (dense prose in table cells, mixed formatting,
items that only link away).

Then verify:

- [ ] `check-board.py` passes: the page answers 200, no prose inside an `onclick`
      call, each `panel-*` id once and in order, the HTML nests (an unclosed
      `<div>` swallows the rest of the page with no error), and it lists the cards
      still OPEN as computed from `/state`. Read that list: it is the measurement,
      not how the page looked in a browser.
- [ ] **Positive-control the sorting**: change one answered card's `data-id` by a
      character, confirm it shows as OPEN (and `check-board.py` warns that an
      answer matches no card), then restore it. The id must match the outbox line
      byte for byte, or the card never moves.
- [ ] Click one button whose label contains an apostrophe.
- [ ] Roster names match `ws-pulse.py` exactly; the trunk sha matches
      `git log origin/main`; every open PR on the board is still open and every
      merged one is gone.
