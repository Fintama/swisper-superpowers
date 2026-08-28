---
name: update-program-board
description: PM duty — keep Mission Control (:8794) current by hand — status, team roster, UAT board, decision briefs, PR list, screens. Use after any merge, respawn, UAT verdict, new decision, or when Heiko asks for the board to be updated.
---

# Update the program board (Mission Control, :8794)

**Heiko's single surface.** Hand-maintained by the PM — written like a document, not emitted by a generator (that was tried and deliberately removed: adequate-looking tables are worse than a page written with care).

Served by `.handover/board-server.py` (static files + the `/decide` write-back). If :8794 is down: `nohup python3 .handover/board-server.py > /tmp/board-server.log 2>&1 &`. Files live in `docs/superpowers/specs/2026-07-25-generic-agent-and-pdlc-overview-mockups/` — **inside the docs submodule: commit-only, never push; publishing is Heiko-gated.**

## The structure (keep it)

### The index, in this order — the sections and the order are both specified

Heiko set this order; it is not a suggestion, and reordering it is a change to
make deliberately rather than while tidying. **A senior PM or architect who has
not spoken to the PM lane must be able to answer "where are we" from this page
alone** — that is the bar, and it is what each section is for.

1. **Goals + roadmap**, with **milestones per lane** — the goals come from
   `program.yaml`; the roadmap says what is between here and each one.
2. **Goal completion — visual and a percentage.** Both. A bar with no number
   cannot be quoted; a number with no bar is not scannable.
3. **The roster** — names, ids, status, rig ids. From `program.yaml`.
4. **Rig status per lane** — frontend, backend and db URLs, live.
5. **Open PRs to main**, with gate state.
6. **Merges today.**
7. **Per-lane cards** — busy or idle, what is done, what is planned.
   **Clicking a lane card shows that lane's plan and its PR list.**
8. **Outstanding decisions** — see the decision rules below.
9. **Key improvements from retrospectives.**

⚠ **Sections 1-6 are FACTS and go stale silently.** They are hand-maintained by
deliberate ruling (see HC-3 below), so the cost of that ruling is that a wrong
number here looks exactly like a right one. Re-derive them from the source at
each update — `program.yaml` for goals, roster and rigs; `gh` for PRs and merges
— never from the previous version of the page.

### Decision briefs address a senior PM or architect

**Never jargon, never lane shorthand.** Each carries, in this order: **context ·
the problem · the options with pros AND cons · a recommendation.**

🔴 **Options with only pros are not options, they are a recommendation wearing a
costume.** If an option has no cost worth writing down, either it is not a real
alternative or you have not found the cost yet. Say which.

### 🔴 HC-3 — the judgement sections stay HAND-WRITTEN

**Do not add a generator for decisions, lane narrative or recommendations.**
Ruled by Heiko and recorded in the spec as a fatal breach. Generated judgement
reads fluent and is unaccountable; the point of a decision brief is that a person
thought about it and can be asked why.

This applies to the *judgement*, not to the *facts*: pulling the roster out of
`program.yaml` is not generating a decision.

- **`index.html` — the overview.** Status tiles (rig · production · open PRs · next migration — all links using named targets `rig`/`prod`/`gh` so they reuse a tab) · **⚡ Needs you** (decisions, urgency-sorted, each showing what it blocks) · **🧪 UAT board** (blocking first, then open, then passed-with-evidence) · **👥 The team** (canonical names, live/idle, channel: message-driven vs polled) · **🔀 Open PRs** with gate state · **🗺 Roadmap & program docs** · **🎨 Screens** — links to the *existing* detailed pages, never a duplicate list.
- **Detail pages carry the substance** — the deep view stays where it already lives: `09-uat-a-runbook.html` (per-test cases with evidence), `00-index.html` (screen/mock pill-ledger), `design-philosophy.html`.
- **DECISIONS ARE EXPANDABLE CARDS ON THE INDEX — not separate pages** (Heiko, 2026-07-28: separate pages fragmented his attention; a wall of dense table prose was worse). Each is a `<details class="dcard">`: the closed summary shows **title · one-line why · what it blocks · urgency pill**; opening it reveals the FULL brief, always these five headings in this order —
  **Background** (what a reader needs to know before the problem makes sense) · **The problem** (what is wrong, concretely, with the user-visible consequence) · **The options** (table: option · what it means · pros AND cons — every option gets both) · **My recommendation** (green `.rec` box, one clear pick with the reasoning, and an honest note wherever my reasoning runs ahead of the evidence) · **Your call** (the buttons).
  **A card without all five sections is not finished.** No decision may live only as a title with buttons — if Heiko cannot rule from the card alone, the card has failed.
- **Every subpage carries the fixed `◂ Mission Control` back button** (top-left, `.backbtn`) — add it to any new page.
- **`feedback.js`** gives pass/fail/note controls to runbook test cards and screen links; include `<script src="feedback.js"></script>` on any page Heiko should be able to respond from.
- **Mocks belong HERE, never on a lane's own server.** Same directory, permanently numbered `NN-<slug>.html`, registered in the `00-index.html` pill ledger. **An orphan server (a lane spinning up its own port) is a defect — the PM catches it and orders migration.** Full rules, and the doc to point lanes at: `.handover/MOCK-DISCIPLINE.md`.

## When to update (the PM's routine)
| Trigger | What to change |
|---|---|
| PR merged | trunk sha, open-PR list, migration next-free; UAT row if it makes something testable |
| Heiko's UAT verdict | flip the row to passed **with the evidence in the note**, or log the finding |
| Session respawned | team table: canonical name `WS<lane>-<version> <Description>`, channel, status |
| New decision arrives | add to **Needs you**; write a brief if it has real trade-offs, link it, delete it once ruled |
| Decision ruled | remove the card — a stale "needs you" item is worse than none |
| **Heiko asks "where are we"** | that question means the board failed. Answer him, then FIX THE BOARD so the next answer is a link |
| **Anything a lane reports that needs him** | becomes a card immediately, with all five sections — never a note to write it up later |
| A mock is delivered/approved | update the screens links; the ledger itself is the detailed view |

## The standard (Heiko, 2026-07-28 — after repeated failures)

**This board is not a status report; it is the surface Heiko decides from. Its value is entirely in being current, complete and actionable. A board that is 80% right is worse than none, because he acts on it.**

Three failure modes, all observed, all mine:
1. **Stale** — retired session names in the roster (he messaged the wrong lane because of it); a trunk sha four commits old; PRs shown open that had merged; the roadmap board four days behind, describing a phase we had left.
2. **Incomplete** — decisions listed as one-line asks with buttons and no brief, so he could not rule without asking me first. That is the board failing at its only job.
3. **Unactionable** — dense prose crammed into table cells, mixed formatting, some items linking away to other pages. He called it "completely messed up", and he was right.

**The test before you stop editing:** *could Heiko rule on every open item, and know the true state of the programme, from this page alone, without asking me a single question?* If not, it is not done.

**Update it in the same breath as the event** — not "later", not at the next wake-up. Merge a PR → the PR table and trunk change in the same turn. Succeed a session → the roster changes in the same turn. A lane surfaces something needing him → a full card, then and there.

## Rules
- **No prose inside inline JS strings — buttons pass data, not text (hard rule, 27 Jul).** `onclick="pick("Approve B — don't offer it")"` is dead markup: the inner double quotes end the attribute, and an apostrophe kills the single-quote variant the same way. Two of five decision pages shipped with silently dead Approve buttons this way — the failure mode is *no error, nothing happens*, discovered only when Heiko clicks. Write the label ONCE, in an HTML attribute (entities handle quoting there), and read it back:
  ```html
  <button class="opt pick" data-answer="Approve B — state it, don&#39;t offer it" onclick="pick(this)">Approve B — state it, don't offer it</button>
  <script>function pick(el){post(el.dataset.answer,'')}</script>
  ```
  Applies to every `decide(...)`/`pick(...)` button on the index, UAT rows, and decision briefs. After authoring, verify no page has prose-in-onclick: `grep -nE 'onclick="[a-z]+\("' *.html` must return nothing, then click one button whose label contains an apostrophe.
- **Never leave a resolved item on the board.** Same discipline as the runbook: a dead warning on a fixed defect is worse than no warning.
- **Notes carry evidence, not adjectives** ("verified across 5 boots", not "should be fine").
- **Recommendations are honest** — say when reasoning runs ahead of a workstream's detail, and offer "wait for the brief" as a real option.
- The write-back appends to `.handover/outbox-to-pm.md`, which the PM wake-up already reads — **do not invent a second channel.**
- **Buttons everywhere Heiko must answer.** Use the data-attribute handler (`decideEl(this)` reading `data-id`/`data-answer`) — never prose inside the JS call. Every card ends in buttons; a card he cannot answer from is unfinished.
- After editing, verify ALL of: `curl -s -o /dev/null -w "%{http_code}" http://localhost:8794/` · `grep -nE 'onclick="[a-z]+\("' *.html` returns nothing · the roster names match `ws-pulse.py` exactly · the trunk sha matches `git log origin/main` · every open PR on the board is still open and every merged one is gone.
