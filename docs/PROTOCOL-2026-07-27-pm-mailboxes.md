# PROTOCOL v3 — hybrid bus: message-driven where hosted, polled where panelled (Heiko, 2026-07-27)

> **v3 CHANGE (supersedes the polling rules below for hosted lanes).** Since tmux hosting is proven, the bus is now **hybrid**:
> - **PM → tmux-hosted lane: DIRECT.** `python3 .handover/msg.py WS<N> "text"` types the message straight in; it arrives as a prompt and wakes the session (queues if mid-turn). **Hosted lanes DELETE their poll cron** — no empty-poll cost at all. Every message is still mirrored to the inbox file for audit + successor history.
> - **PM → panel lane: POLLED** (unchanged v2.1 rules below) until that lane's next respawn makes it hosted.
> - **WS → PM: always the outbox file.** The PM cannot be typed into (it lives in Heiko's panel), so it runs **one 30-minute wake-up cron** that reads the outbox, answers via `msg.py`, and thinks one step ahead about routing, blockers and context levels.
> - `python3 .handover/msg.py --status` prints the current channel map. Lane lifecycle, naming and spawning: `.handover/PROTOCOL-2026-07-27-session-lifecycle.md`.

## v2 baseline (still binding for polled lanes)

**A poor-man's poll-based message bus.** Every registered session (PM + workstreams) polls its mailbox every 10 minutes. Empty polls MUST cost near-zero tokens. Long content lives in the shared store; messages carry pointers. All traffic is auditable files.

> **PATCH 3 (WS5-3, 2026-07-28): the awk anchor needs the TRAILING SPACE — `/^PROCESSED-MARKER /`** — and senders must NEVER line-start the literal token in a message body (indent or backtick it; WS1 found four prose lines one column away from swallowing everything above them). The messages most likely to be eaten are precisely the ones about the bus.
> **PATCH 2 (WS2-7, 2026-07-28): the marker is PLAIN TEXT, never bolded.** `**PROCESSED-MARKER**` is invisible to the anchored awk (line starts with `*`); the unanchored fallback then matches marker mentions inside message BODIES and silently swallows everything above (44 lines observed). Format is exactly `PROCESSED-MARKER <timestamp>` at column 0 — no bold, no prefix, one per file, always last.
> **PATCH 2026-07-28 (WS4):** the marker regex MUST be anchored `/^PROCESSED-MARKER/` — the unanchored form let any message whose BODY mentioned the marker silently swallow itself and everything before it. Also: the PM reads the outbox via a byte-cursor (`bash .handover/pm-outbox-read.sh`), never `tail -N` — tail windows lost 3 lane replies on 2026-07-28.

## 1. The polling loop (every workstream session installs ONCE per session)
In-session recurring cron, **cadence 10 min** (pick an off-minute), with EXACTLY this prompt:

> Mailbox poll. Run: `awk '/^PROCESSED-MARKER /{buf=""; next}{buf=buf $0 "\n"} END{printf "%s", buf}' .handover/inbox/WS<N>.md` — if empty output, reply exactly "no message" and STOP (no other tools, no commentary). If entries exist: act on them (they are PM routings/notifications/rulings already decided — never new scope), then update the marker: keep **exactly ONE `PROCESSED-MARKER <timestamp>` line in the file, always as the LAST line** (replace the old marker — never append a second), and continue your queue.

**Marker discipline (v2.1, after WS2+WS4 independently caught the defect):** one marker, always last line, always REPLACED not appended. The awk above prints only what follows the LAST marker, so a missing marker serves the whole file once (correct on first run) and duplicate markers can't replay history.

**Empty-poll discipline is a hard rule:** one tool call, the two words "no message", nothing else. No status musings, no re-reading files.

## 2. Messaging the PM (questions, blockers, milestones)
Append ONE line to `.handover/outbox-to-pm.md`:
`WS<N> <timestamp> [ctx:<remaining%>] — <message, ≤2 sentences; longer content → share/ + pointer>`
The PM polls every 10 min and answers via your inbox. Urgent+Heiko-visible things may ALSO go to Heiko directly as today.

## 3. The shared store — `.handover/share/`
Specs, designs, analyses, handovers >1KB go here; messages reference them as `share/<file>`. Everyone reads the same store; the author owns edits; PM archives at phase boundaries. (Existing .handover root files stay where they are; NEW long docs go to share/.)


## 3b. INBOX ROTATION (added 2026-07-28, from the WS1-5 token audit)

Inboxes are append-only and were never trimmed: WS2's had reached **8.8k tokens** and every session paid it. **Rotate at each lane's succession** (same discipline as the status-file split): move history to `.handover/inbox/archive/WS<N>-archive-<date>.md`, keep the header plus everything after the last `PROCESSED-MARKER`, and tell successors **not to read the archive** — the PM greps it on demand. First rotation 2026-07-28 recovered 6.1k / 8.1k / 3.4k tokens on WS1 / WS2 / WS3.

## 4. Context reporting & the 85% rule (every session)
- **Every outbox message carries `[ctx:<remaining%>]`** (your remaining context estimate).
- **At ≤15% remaining (85% full): send an ALERT immediately** — `WS<N> <ts> [ctx:15%] — CONTEXT ALERT: begin succession` — and start writing your structured handover (LANDED · IN-FLIGHT · NEXT · DECISIONS OWED · NOTES FOR PM) into your status file WITHOUT waiting for a reply.
- The PM then runs the **respawn procedure** (skill `respawn-workstream`): handover verified → spawn prompt written → Heiko spawns `WS<N> <lane> <k+1>` → new session registered in monitoring → old session deregistered and closed.

## 4b. SILENCE IS A SIGNAL (added 2026-07-27, Heiko-directed)

**A stalled lane produces no events, so change-based monitoring cannot see it.** WS5 sat waiting on a fix subagent that had *already finished*; the delta pulse showed nothing because nothing changed, and it only surfaced when Heiko asked directly.

- **PM:** every wake-up runs `python3 .handover/stall-check.py 15` alongside the delta pulse. Any lane silent ≥15 min gets messaged immediately — *"check whether your subagents already finished; report state or resume."* Absence of news is not news.
- **Lanes:** if you are waiting on a subagent, **verify it is still running** rather than assuming. A finished agent will not always wake you. Before reporting "waiting", check; if it has finished, collect the result and continue. **Never sit on a completed agent.**
- **Lanes:** if you are genuinely blocked for more than ~15 minutes, say so on the outbox with the reason. Silence reads identically to progress, and the PM will chase it either way.


## 4c. DELIVERY IS VERIFIED, NOT ASSUMED (2026-07-28 — a message WAS lost)

`tmux send-keys` succeeding means keystrokes reached the terminal. It does **not** mean the session received a prompt. A busy lane redraws constantly (spinner, token counters, subagent rows); a redraw between the typed text and the Enter wipes the input line, and the message vanishes with **no error anywhere**. WS6 lost four messages this way and it surfaced only because Heiko asked the lane directly.

**Two rules follow:**
- **The inbox mirror is written by the SENDER.** It is an audit trail, never evidence of receipt. `msg.py` now reads the pane back, retries once, and reports `⚠️ NOT VERIFIED` when it cannot confirm — **read the exit line, not the mirror.**
- **Lanes keep a cheap fallback.** Direct delivery is no longer assumed infallible: when you finish a task and before going idle, check your inbox tail after the last `PROCESSED-MARKER`. That is one cheap command at a natural boundary, not a poll cron.

Generalises: **any channel that reports "sent" without checking "arrived" is a claim, not a check** — the same defect class as a green suite that asserts nothing.


### 4c.1 The answer to "ack or fire-and-forget?" (Heiko asked, 2026-07-28)

**Fire-and-forget with guaranteed delivery — NOT per-message acks.** We already had the substrate and stopped using it:

- **The inbox is the durable queue and the source of truth.** tmux typing is an *accelerator over it*, never a replacement. That inversion was the bug.
- **The `PROCESSED-MARKER` is already a cumulative ack.** One command tells the PM exactly what each lane has consumed — at **zero token cost to any lane**. It is strictly better than a per-message ack: it reports "drained up to here", not merely "one message seen".
- **Per-message acks are the wrong trade.** They cost every lane a turn of context for every message. Given what context measurably costs (see the WS1-5 audit), a blanket ack protocol would be the most wasteful thing we could add.
- **Explicit acknowledgement is reserved for obligation-carrying messages** — rulings, decommissions, work orders — where the PM needs to know it was *understood*, not just consumed. A handful a day, not every message.

**So the loop is:** sender types and **verifies the pane** → mirrors to the inbox queue regardless → receiver drains at task boundaries and **moves the single marker** → PM reads undrained mail for free via `stall-check.py`. Every layer fails safe: a lost keystroke is caught by the queue, an undrained queue is caught by the marker check.


### 4c.2 SET `MSG_SENDER` — an unattributed message is refusable (PM's own trap, 2026-07-28)

`msg.py` stamps the sender from `MSG_SENDER`; **unset means the message goes out as `UNATTRIBUTED`**, and lanes are correctly instructed to refuse irreversible or binding instructions from an unattributed source. The PM hit this itself: a hardening added by one wake-up was not known to the next, so a batch of rulings went out unattributed and four lanes held them — correctly.

**Always send as:** `MSG_SENDER=PM-2 python3 .handover/msg.py WS<N> "…"` (or `export MSG_SENDER=PM-2` once per session).
**Receivers:** keep refusing. Do every reversible part, hold the irreversible half, and say so — that behaviour was right and is now protocol. When re-sending, the PM should reference something only it could know, not merely re-assert the stamp.

## 5. The PM side
- PM polls on a 10-min cron running `.handover/ws-pulse-delta.py` — prints one line when nothing changed; flags outbox growth, inbox consumption, git/PR movement.
- Deep inspection on demand: `python3 .handover/ws-pulse.py [n]` (all workstreams) or targeted git/gh.
- Registration stays conscious: a session is only polled/monitored once Heiko names it and the PM adds it to the pulse map (the roster).

## 6. What the bus is NOT for
New scope (Heiko decides), emergencies (Heiko pastes), long content (share/ + pointer), cross-WS lane requests (go via PM).

## Bus messages ride a shell — NO BACKTICKS (PM incident, 2026-07-28)
A `msg.py` argument in double quotes is shell input FIRST, message SECOND: zsh executed a backtick-quoted `docker rm …` inside a PM ruling before msg.py ever saw it — the command ran from the PM's shell and the delivered text was mutated (the backtick span replaced by its output). The delivery layer verified the PANE received text; it cannot know the text was garbled. Binding rules: **never use backticks in a bus message**; prefer single-quoted arguments (and then no apostrophes in the text, or use the msgfile route); when a message names a command, spell it in plain words or quote with regular quotes. Same family as the harness-secret shell-substitution pattern and the board inline-onclick trap: content that crosses an execution boundary is code to that boundary, not prose. **Receiver side (WS3, binding fleet-wide): a garbled instruction is a NON-instruction** — visible corruption (holes, dangling words, replaced spans) establishes nothing; refuse and ask, never reconstruct intent — especially when the verb is destructive. "I guessed right about a destructive instruction" is not a process.

## The marker moves in the same act as the outbox write (fleet epidemic, 2026-07-28)
All six lanes had lying markers — 20+ hours stale behind prompt, correct answers — because hosted lanes never poll, so nothing in their loop ever touched the marker: ANSWERING IS WHAT MASKS IT. Structural fix (WS4): every time a lane writes to the outbox, it moves its PROCESSED-MARKER in the same breath — one natural, frequent trigger instead of a discipline nobody has a cue for. WS3's form: the marker moves in the same command that reads the mail; an intention is not a shape. And the check itself must be trustworthy: inline awk inside a shell string is a quoting minefield that can ERROR INTO A FALSE CLEAN (WS1, "undrained: 0" while the truth was 2) — the canonical check lives in a FILE, run with `awk -f`.

## Raw `tmux send-keys` is NOT a substitute for msg.py (PM-3, 2026-07-29)

WS1 stalled 18 minutes with its own next step sitting **unsubmitted** in its input line. The PM tried to clear/submit it with raw `tmux send-keys`: `C-u`, `Escape`, 85× `BSpace`, and `Enter`. **Every one of them was silently ignored** — the pane render never changed and the transcript never moved. `msg.py` to the same pane, seconds later, delivered and woke the session immediately.

So: **the pane accepting keystrokes from `msg.py` tells you nothing about raw `send-keys` working, and vice versa.** Whatever msg.py does (verified read-back plus retry) is load-bearing. Binding rules:
- **Never drive a lane's TUI with raw `send-keys`** — for messages, for clearing a line, or for submitting one. Use `msg.py`, and read its exit line.
- **A stranded input line is a real stall mode** and is invisible to the delta pulse (nothing changes, because nothing is happening). `stall-check.py` catches it; the pane capture explains it. Look at the `❯` line before concluding a lane is merely thinking.
- **Before deciding a stranded line is garbage, find its provenance in the pane scrollback.** WS1's stranded sentence was its OWN recommendation, quoted verbatim from its previous message ("If I were deciding: …") — deleting it would have thrown away the lane's best next step, and submitting it blind would have been acting on an instruction of unknown origin. The scrollback settled it in one grep.

## Stray-`.handover` sweep is a STANDING step, not an if-you-happen-to-look (WS1, 2026-07-29)

Every worktree shadows `.handover/`, so a relative-path append after a `cd` into a worktree writes to a **stray copy that neither end can see** — the lane believes it reported, the PM never receives, and nothing errors. §2b rule 5 already mandates absolute paths; this is the detection half.

WS1 found one such file and recorded exactly how: **not by any check** — it was investigating an unrelated commit divergence and `git status` happened to list `?? .handover/outbox-to-pm.md`. Its conclusion is the rule: **a lane that never inspects its worktrees will never discover it has been talking to itself.**

- **Every lane sweeps its own worktrees at each wave end**, and at succession before writing the handover.
- **The PM sweeps the whole fleet** — the canonical file is the ONLY `outbox-to-pm.md` that may exist:
  `find $PROGRAM_ROOT /private/tmp/claude-501 -name "outbox-to-pm.md"`
  More than one result is a lost-messages incident, not a tidiness issue: **recover the content before deleting the stray.**
- Same sweep applies to `.handover/inbox/` inside a worktree.
- Swept clean 2026-07-29 by PM-3: one result, the canonical file.

## No GitHub artifact in this programme can attribute anything (WS6, 2026-07-29)

Comments, reviews, commit authorship and merged-by **all resolve to the one shared identity**. So *who said this* is never answerable from the platform — only from a channel traceable to a conversation. This is the channel-is-not-author lesson in its third medium (after the bus mirror and the merge notice), and the only one that persists after everyone stops typing.

**It cuts both ways, which is the part that nearly cost us a real review.** WS6 found a PR comment signed "PM-3 review", correctly reasoned that its self-identification proves nothing, and was about to delete it as unattributable. **It was genuine** — PM-3 had written it, and could attribute it from the id `gh` returned at post time (`5101208761`, 07:26:17Z). The platform could not prove authorship; it equally could not disprove it. WS6's own framing of its error is the durable form: *"existence was checkable; authorship never was — a better check would ask what property the artifact can actually prove, not whether it is present."*

**Rules:**
- **The receipt lives with the author, not the artifact.** PM review comments now carry the comment id `gh` returns at post time, so the receipt is inside the comment.
- **Never delete or annotate another actor's artifact on attribution grounds alone** — ask the claimed author first. "Not in my record" and "I did not write it" are different claims, and records here are compaction-lossy.
- An empty `reviewDecision` is expected on every PR (self-approval is refused), so it is never evidence that nothing was reviewed.

## 7. REVERSALS — triage first, and remember that stopping the lane does not stop its agents (Heiko-directed, 2026-07-29)

**The incident.** Heiko ruled "widen the stack menu", PM-3 routed it, WS6 wired it into its plan and agent prompts, and an hour later Heiko reversed it. The hour was **not** lost to message latency — `msg.py` queues and wakes a mid-turn lane within minutes. It was lost to **agents already carrying the old instruction**.

**WS6's finding, kept verbatim because the mechanism is the point:**

> *"Wiring rulings into agents as instructions is what made them land … the same mechanism that stops a ruling being rediscovered also **propagates a wrong one straight into code**. The mitigation isn't to stop wiring them in — it's that a reversal must reach the agents still carrying the old instruction, which is why I went to PR-10 before I answered you."*

WS6 fixed the propagation **before** acknowledging the PM. That priority was correct and is now protocol.

### 7a. Do NOT reflexively interrupt the lane

Halting a lane mid-turn manufactures the exact hazard we diagnosed elsewhere: **an incomplete turn leaves partial work on disk that looks finished** (WS3's mid-response API death, §the traps). A queued message costs one turn. A torn write costs a diagnosis. **Interrupting is the more expensive option for ordinary building work.**

### 7b. The reversal message leads with STOP-AND-TRIAGE, and the lane does it before anything else

1. **Enumerate running subagents and rule on each — kill, or let finish and discard.** Report which, by name. A subagent is not stopped by the lane reading a message.
2. **Find where the old ruling is WIRED IN** — plans, task files, agent prompts, DoD checkboxes — and strike it there, not merely in your understanding. A ruling that lives only in a lane's head was never the problem; one written into a task file rebuilds itself.
3. **Only then** apply the new instruction.
4. **Report the churn cost.** WS6 reported "it cost an hour". A reversal that is never costed looks free, and free reversals get made carelessly.

### 7c. HARD-STOP is correct when the work is IRREVERSIBLE

Interrupt immediately — do not wait for a turn boundary — when the in-flight work is a migration, an opening PR, a deploy, a branch deletion, or anything touching production. There the cost of partial state is **lower** than the cost of the thing landing. Same hold-the-irreversible-half rule as everywhere else; stated here so nobody has to derive it under time pressure.

**The one-line form: triage-first for ordinary building, hard-stop for irreversible work — and always chase the agents, not just the lane.**

## 🔴 NEVER PIPE THE CURSOR READ THROUGH `tail` (PM-3's worst process failure, 2026-07-29)

`pm-outbox-read.sh` advances the byte cursor to EOF **as a side effect of reading**. So `bash .handover/pm-outbox-read.sh | tail -8` **consumes everything and shows you eight lines** — the rest is marked read and silently discarded. There is no error, no warning, and the next run correctly reports NO-UNREAD.

PM-3 did this on **every wake-up for an entire shift.** Measured cost, found only because WS3 checked the cursor byte offset against the file size and reported it:
- **25 messages across five lanes** consumed unseen in one window; a later recovery found **36 lines / 29,018 bytes**.
- **WS5 answered the same question three times** (17:31, 17:39, 18:07) and said so twice before I noticed.
- **WS3 reported "I am between tasks, gate me" FOUR times** (19:05, 19:24, 19:40, 20:02).
- **WS1 had already been given rulings I then re-ruled**, and had reported a running subagent I did not know about.
- Multiple lanes were chased for silence while their reports sat consumed-and-unread.

**Binding:**
```bash
bash .handover/pm-outbox-read.sh > /tmp/pm-backlog.txt 2>&1   # capture ALL of it
wc -l /tmp/pm-backlog.txt                                      # know how much arrived
# then read the file — every line — before answering anyone
```
- **If the backlog is large, that is the signal to slow down, not to skim.** A skimmed backlog is worse than an unread one, because the cursor now says you have seen it.
- **Cross-check the cursor against the file size** when a lane says it is not being heard: `cat .handover/.pm-outbox-cursor` vs `wc -c < .handover/outbox-to-pm.md`. WS3 diagnosed this from the outside in one command; the PM could not see it from the inside at all.
- Generalises: **any read that advances a cursor must never be filtered in the same pipeline.** The filter hides what the cursor already spent.

## Never `git add -A` in the shared docs checkout (PM-3, 2026-07-29 — caught by WS6)

Every lane commits to the **same** `docs/` checkout. `git add -A <dir>` therefore stages **whatever any other lane has uncommitted at that moment**. PM-3's commit `493b91a`, titled *"board: websearch A/B/C escalated"*, also carried **12 lines of WS6's in-progress PR-6 plan**.

**Nothing was lost and no content was wrong — what was damaged is PROVENANCE**, which is the thing this programme has spent the whole day protecting: anyone later asking *"why did PR-6 Task 8 change?"* finds a commit message about a websearch escalation, and the real reason is nowhere.

**Binding:** stage **explicit paths only** — `git add docs/.../index.html` — never `-A`, never `-a`, never a directory, in any shared checkout. Applies to the PM most of all, because the PM commits most often and always to files other lanes are simultaneously editing. Before committing: `git status --porcelain <paths>` and confirm you recognise every line.

## Complex review text goes in a FILE, never in a `--body` argument (PM-3, 2026-07-29)

`gh pr comment 473 --body "…"` failed with *"accepts at most 1 arg(s), received 6"* — the prose crossed a shell boundary and was re-split into positional arguments before `gh` ever saw it. **The comment silently did not post**; only the error line distinguished it from success, and a PM who skimmed would have believed a review was on record when none was.

Same family as the msg.py backtick incident and the inline-`awk` quoting trap: **content that crosses an execution boundary is code to that boundary, not prose.** The programme already answered this for `awk` (`awk -f file`) and for bus messages (single-quote, no shell-active spans); reviews get the same answer.

**Binding:** write the review to a file, then `gh pr comment <n> --body-file <path>`. Applies to any multi-paragraph text containing backticks, quotes, `#`, or `*`. And read the exit line — a failed post looks exactly like a successful one in the transcript except for that.
