---
name: update-program-board
description: PM duty — keep Mission Control (:8794) current by hand — status, team roster, UAT board, decision briefs, PR list, screens. Use after any merge, respawn, UAT verdict, new decision, or when Heiko asks for the board to be updated.
---

# Update the program board (Mission Control, :8794)

**Heiko's single surface.** Hand-maintained by the PM — written like a document, not emitted by a generator (that was tried and deliberately removed: adequate-looking tables are worse than a page written with care).

Served by `board-server.py` (static files + the `/decide` write-back). If :8794 is down: `nohup python3 "$CLAUDE_PLUGIN_ROOT/scripts/board-server.py" > /tmp/board-server.log 2>&1 &`. Files live in `docs/superpowers/specs/2026-07-25-generic-agent-and-pdlc-overview-mockups/` — **inside the docs submodule: commit-only, never push; publishing is Heiko-gated.**

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
8. **Outstanding decisions** — see the decision rules below. 🔴 **Only the OPEN ones appear here.
   Answered decisions live in the `Decided` tab and move there by themselves** — see
   *"Answered decisions must leave the queue by themselves"* below. Sections 1-9 are the layout of
   the **`Open` tab**; the other two tabs carry history, not status.
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

- **`index.html` — the overview.** Status tiles (rig · production · open PRs · next migration — all links using named targets `rig`/`prod`/`gh` so they reuse a tab) · **⚡ Needs you** (decisions, urgency-sorted, each showing what it blocks) · **🧪 UAT board** (blocking first, then open, then passed-with-evidence) · **👥 The team** (canonical names, live/idle, address — the session name `SendMessage` reaches) · **🔀 Open PRs** with gate state · **🗺 Roadmap & program docs** · **🎨 Screens** — links to the *existing* detailed pages, never a duplicate list.
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

## 🔴 A DECISION CHANNEL THAT ONLY WRITES A FILE IS HALF A CHANNEL

**Added 2026-08-30, Helvetiq, after Heiko clicked three decisions and then had to ask
"can you check whether you can see it?" — and took a screenshot to be sure.** He was right:
*"otherwise the board is only half useful."*

Both halves below are mandatory when you stand a board up. Neither is optional polish.

### 1 · A click must WAKE the PM, not just land in a file

The write-back appends to the outbox and stops. **If nothing is watching that file, the decision sits
there until the PM happens to look** — which, from Heiko's side, is indistinguishable from the button
being broken. Arm a watch **in the same turn you start the server**:

```
Monitor(
  command: tail -n 0 -f <programme>/.handover/outbox-to-pm.md | grep --line-buffered "via board",
  description: "<name>'s board decisions",
  persistent: true)
```

⚠ **`tail -n 0`** — without it every historical line replays as a fresh event on arming.
⚠ **`--line-buffered`** — without it grep holds matches in its buffer and the watch is silently dead.

**Verify the watch, do not assume it:** click a button and confirm the notification arrives. A watch
that cannot fire looks exactly like a quiet afternoon.

### 2 · The board must show the ANSWER and the ACKNOWLEDGEMENT, on load

A static page loses the answer on reload, so Heiko cannot tell what he has already ruled on — and he
never learns whether the PM acted. Serve a `/state` endpoint returning **`answers`** (parsed back out
of the outbox, last-wins per decision) and **`acks`** (`board/acks.json`, written by the PM *after*
acting: `{"<decision id>": {"at": "...", "did": "..."}}`), and render per card:

| state | shown as |
|---|---|
| unanswered | buttons only |
| answered, PM has not acted | 🟡 **amber** — *"You answered X · <when>. The PM has not confirmed acting on it yet."* |
| PM acted | ✅ **green** — the answer, plus **what the PM actually did about it** |

Poll `/state` every ~20s so an acknowledgement reaches a page that is already open.

### 3 · 🔴 ANSWERED DECISIONS MUST LEAVE THE QUEUE BY THEMSELVES — tabs, not tidying

**Ruled by Heiko 2026-09-02**, after the Swisper Platform board reached fifteen decision cards of
which eleven were already answered: *"move all past decisions into a decisions tab so they don't
pollute the main board."*

**Three tabs, in this order — `Open` · `Decided` · `Record`.** `Open` carries the lanes and the
decisions still waiting. `Decided` carries everything already ruled on, with its status line.
`Record` carries the settled rulings nobody may re-litigate.

🔴 **The placement is DERIVED FROM `/state`, never hand-filed.** This is the whole point and it is
the difference between this rule and the old one. Rule 150 has always said *"never leave a resolved
item on the board"* — and boards kept silting up anyway, because obeying it meant a human
remembering to move a card on the same day they were busy answering it. **Moving cards by hand is
the failing instrument; derive the placement instead** (R-k: change the instrument, not the
discipline). A card answered at 12:17 leaves the Open tab on the next 20-second tick with nobody
editing the file.

Author **every** decision card in the Open panel. On each refresh:

```js
function placeCards(answers, acks){
  var sink = document.getElementById('decided-cards');
  document.querySelectorAll('.dec').forEach(function(card){
    var decided = !!answers[card.dataset.id] || !!acks[card.dataset.id];
    if (decided && card.parentNode !== sink) sink.appendChild(card);
  });
  // A heading whose cards have all moved would otherwise sit over nothing.
  document.querySelectorAll('#panel-open h2').forEach(function(h){
    var n = h.nextElementSibling, live = false;
    while (n && n.tagName !== 'H2'){
      if (n.classList.contains('dec') || n.classList.contains('grid')) { live = true; break; }
      n = n.nextElementSibling;
    }
    h.hidden = !live;
  });
  document.getElementById('count-open').textContent =
    document.querySelectorAll('#panel-open .dec').length;
  document.getElementById('count-decided').textContent = sink.querySelectorAll('.dec').length;
}
```

**Four details that are each a defect if skipped:**

| | |
|---|---|
| **An ACK with no answer also moves it** | It was settled off-board — in the terminal, usually. If only `answers` moves cards, a question the human already answered sits in the queue looking unasked, and they answer it twice. |
| **…but say so on the card** | Render *"✅ Answered outside the board · PM acted &lt;when&gt; — &lt;did&gt;"*. 🔴 Otherwise acking becomes a way for the PM to make an unanswered question disappear. With the line, doing that is **a lie in writing**, which is a different act. |
| **Hide headings that empty out** | Cards move; their `<h2>` does not. A heading over nothing reads as a rendering bug and costs trust in the whole page. |
| **Counts on the tabs** | `Open 4` is the number the human actually wants, and it is the only part of the board readable without scrolling. |

**Tab state persists in `localStorage`, and every read and write is wrapped in `try/catch`** — a
browser with site data blocked throws on the *accessor*, not on a missing key, and an exception
there takes the whole script down with it, including the status lines.

**The empty state is a real state:** when nothing is open, say *"Nothing waiting on you"* rather
than rendering a blank panel. A blank panel is indistinguishable from a page that failed to load.

⚠ **`board-server.py` needs no change for any of this** — it already returns `answers` and `acks`
from `/state`. The tabs are entirely client-side, so this costs one page and no new endpoint.

🔴 **The `did` field is the point, and it is not a receipt.** *"Relayed to WS3 with three conditions:
it must write the key production actually reads…"* tells Heiko his decision had consequences and what
they were. *"Acknowledged"* tells him nothing and is worse than silence, because it looks like closure.

**The general rule this is an instance of: a channel needs a return path, or the sender cannot
distinguish "delivered" from "broken".** Same defect class as a guard that cannot fail — the success
and failure states are indistinguishable from where the user stands.

## Rules
- **No prose inside inline JS strings — buttons pass data, not text (hard rule, 27 Jul).** `onclick="pick("Approve B — don't offer it")"` is dead markup: the inner double quotes end the attribute, and an apostrophe kills the single-quote variant the same way. Two of five decision pages shipped with silently dead Approve buttons this way — the failure mode is *no error, nothing happens*, discovered only when Heiko clicks. Write the label ONCE, in an HTML attribute (entities handle quoting there), and read it back:
  ```html
  <button class="opt pick" data-answer="Approve B — state it, don&#39;t offer it" onclick="pick(this)">Approve B — state it, don't offer it</button>
  <script>function pick(el){post(el.dataset.answer,'')}</script>
  ```
  Applies to every `decide(...)`/`pick(...)` button on the index, UAT rows, and decision briefs. After authoring, verify no page has prose-in-onclick: `grep -nE 'onclick="[a-z]+\("' *.html` must return nothing, then click one button whose label contains an apostrophe.
- **Never leave a resolved item in the Open tab.** Same discipline as the runbook: a dead warning on a fixed defect is worse than no warning. 🔴 **Do not obey this by hand — it is enforced by `placeCards` (§3 above), which derives placement from `/state` on every refresh.** This rule predates that mechanism and was routinely broken while it was a matter of discipline; a board reached eleven answered cards in the Open list on 2026-09-02. A rule that depends on someone tidying up on their busiest day is not a rule.
- **Notes carry evidence, not adjectives** ("verified across 5 boots", not "should be fine").
- **Recommendations are honest** — say when reasoning runs ahead of a workstream's detail, and offer "wait for the brief" as a real option.
- The write-back appends to `.handover/outbox-to-pm.md` — **do not invent a second channel.** ⚠ But see
  **A click must WAKE the PM** below: since 2026-10-01 the PM's recurring check no longer reads the
  outbox at all, so the `Monitor` watch is the only thing that wakes the PM on a click.
- **Buttons everywhere Heiko must answer.** Use the data-attribute handler (`decideEl(this)` reading `data-id`/`data-answer`) — never prose inside the JS call. Every card ends in buttons; a card he cannot answer from is unfinished.
- After editing, verify ALL of: `curl -s -o /dev/null -w "%{http_code}" http://localhost:8794/` · `grep -nE 'onclick="[a-z]+\("' *.html` returns nothing · the roster names match `ws-pulse.py` exactly · the trunk sha matches `git log origin/main` · every open PR on the board is still open and every merged one is gone.
- 🔴 **Also verify the tabs actually sort, by computing it rather than by looking at the page.** The
  page renders correctly in a browser you may not have open, and "it looked fine" is not a
  measurement:
  ```bash
  curl -s http://localhost:8794/state | python3 -c "
  import json,sys,re
  st=json.load(sys.stdin); ans=st['answers']; acks=st['acks']
  cards=re.findall(r'class=\"dec[^\"]*\" data-id=\"([^\"]+)\"', open('index.html').read())
  op=[c for c in cards if c not in ans and c not in acks]
  print('OPEN (%d):'%len(op)); [print('   -',c) for c in op]
  print('DECIDED: %d'%(len(cards)-len(op)))"
  ```
  **Positive-control it:** the id in `data-id` must match the id in the outbox line **byte for
  byte**, so change one card's `data-id` by a character and confirm it jumps back to OPEN. A
  mismatched id fails silently — the card simply never moves and never shows its status, which
  looks exactly like a decision nobody has answered.
- **Validate the HTML nesting after any structural edit** — panels are nested `<div>`s and an
  unclosed one swallows the rest of the page with no error:
  `python3 -c "from html.parser import HTMLParser; ..."` walking a tag stack, or any parser that
  reports mismatches. Confirm each `panel-*` id appears exactly once and in order.
