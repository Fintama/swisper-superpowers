---
name: respawn-pm
description: PM self-succession — when the PM session's own context runs low (~85% full) or quality degrades, prepare the handover and spawn/register the successor PM (hosted in tmux via the spawn script, or hand Heiko a paste-ready kickoff), then decommission this session.
---

# Respawn the PM (self-succession)

**Trigger:** you reach the PM context threshold
(`../running-a-programme/references/messaging.md`, "Context thresholds"), your
recall of programme facts degrades, or the human asks.

**Canonical spec** for naming, the context package, spawning, registration and
decommission: `${CLAUDE_PLUGIN_ROOT}/docs/PROTOCOL-2026-07-27-session-lifecycle.md`.
This skill is the PM-specific sequence on top of it.

Do it before quality degrades. Auto-compaction is a safety net, not a plan: a fresh
session with a verified handover beats a compacted one.

## 1. Freeze and verify
Finish or safely park in-flight actions (never mid-merge). Verify live state from git/gh (trunk sha, open PRs, the next free migration number where the product has one, each lane's branch, PR and context level), never from conversational memory.

## 2. Write the handover: `.handover/PM-HANDOVER-<date>-<slug>.md`
Contents, in this order: one-paragraph state · read-these-in-order · monitoring tooling and the **current ws-pulse session-id map** · per-lane state, owed items and context levels · the human's open decisions · standing rules that were tested, including mistakes made · immediate duties · **a paste-ready kickoff for the successor as the final section**. Save it as `writing-handovers` ("Saving") says.

## 3. List the session-bound losses explicitly
They die with this session and the successor must recreate them in its first minutes:
- **Crons**: the PM's recurring check, with its cadence and the exact prompt text, verbatim. It exists for silence and board drift, not for reading mail (lanes reach the PM by `SendMessage`). If an old handover lists an outbox-reading poll, it is retired; do not recreate it.
- **The board's `Monitor` watch** on `outbox-to-pm.md` (`update-program-board`); without it the human's clicks wake nobody.
- **tmux hosts**: run `tmux ls`; name each session and which lane it carries.
- Any background watchers or unfinished monitors.

## 4. Update the durable stores
Project memory: point the programme memories at the new handover as CURRENT, correct anything stale, keep the MEMORY.md index hooks accurate.

## 5. Spawn the successor
Two routes:

**Hosted in tmux**, with the same script `respawn-workstream` uses (it pins the model, strips the inherited child-session marker, sends type and Enter separately, and asserts the cwd):
```bash
git -C <repo> worktree add --detach <repo>/.worktrees/pm-<k+1>
bash "$CLAUDE_PLUGIN_ROOT/scripts/spawn-lane.sh" PM "Program Manager — coordination, routing, merges" <k+1> \
  <repo>/.worktrees/pm-<k+1> --session pm-<k+1>
```
The script refuses (exit 70) a directory a live session holds and a tmux session name that already exists, and you hold both: your own directory, and tmux session `pm` if you were hosted this way. So the successor gets its own worktree root (the first line) and its own tmux session, `pm-<k+1>`; without `--session` the tmux session is `pm`, which works only when none exists. The session is renamed `PM-<k+1> Program Manager — …`. If the script still refuses, use the panel route. Afterwards, as for a lane: send the one-line briefing pointing at the handover (type and Enter as separate `send-keys` calls, to `-t pm-<k+1>`), and verify the model from the transcript.

**Panel**: tell the human: "PM context at <X>%, successor prep complete. Open a session, paste the last section of `<handover>`, then `/rename PM-<k+1> Program Manager …`".

## 6. Register and verify the successor
Confirm a transcript appeared (no transcript means the child-session marker leaked; respawn with a clean env). Set `PM = "<successor session id>"` in `.handover/ws-pulse.py`: it is a code line, and `reap-ghosts.sh` spares only ids on code lines, so a PM id left in a comment gets the PM reaped. **Read the successor's address from `ListAgents` and write it to `pm_address` in `program.yaml`**: every lane still holds yours. Then confirm the successor read the handover, verified trunk state itself, **recreated the recurring check and the board watch**, re-mapped any respawned session ids, and announced takeover: to the human, by `SendMessage` to every running lane ("PM-<k+1> live at `<address>`, same protocol"), and to the mailbox of every lane that is not running. Messaging rules: `../running-a-programme/references/messaging.md`.

## 7. Decommission this session
`CronDelete` every own cron · stop every own `Monitor` · append `SUPERSEDED by PM-<k+1>, <timestamp>` to the handover · stop answering programme traffic (if a message still reaches you, reply once with the successor's address). Do not kill tmux hosts carrying live workstreams; hand them over in the handover instead. The transcript remains the archive.
