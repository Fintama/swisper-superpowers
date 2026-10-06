---
name: respawn-workstream
description: PM procedure to succeed a workstream session whose context is nearly exhausted (ctx alert ≤15% remaining, or observed degradation) — verified handover, spawn prompt, monitoring re-registration, clean decommission of the old session.
---

# Respawn a workstream session (succession, not loss)

**Trigger:** a lane's context alert or observed degradation (thresholds and signs:
`../running-a-programme/references/messaging.md`, "Context thresholds"), or the
human's request.

**Messaging:** `../running-a-programme/references/messaging.md` is the single source. Below, "send" means `SendMessage` to the session's address while it is running, and the lane mailbox when it is not.

**Canonical spec** for naming, the context package, spawn commands, registration and decommission: `${CLAUDE_PLUGIN_ROOT}/docs/PROTOCOL-2026-07-27-session-lifecycle.md`. Read it; this skill is the operational sequence on top of it.

## 1. Secure the handover (send to the old session at its address, or via the human)
Instruct: finish or park the current task at a safe point (never mid-migration or mid-PR), then write the **CONTINUATION package (≤2KB)** into the lane's status file: **IN-FLIGHT (branch + commit + literal next step) · NEXT · DECISIONS OWED · live traps · pointer list (spec §, plan, shared docs, memory names)**. LANDED = one line of PR numbers; git is the record. **Move everything older into `WS<N>-STATUS-archive.md`** (successors never read it; the PM greps it on demand).
**Verify it yourself against git** (branch exists, commits pushed, claims true): a handover's labels do not always survive a grep.

## 2. Write the spawn prompt: `.handover/SPAWN-<date>-WS<N>-session-<k+1>.md`
Save it as `writing-handovers` ("Saving") says. Contents:
- identity line ("You are WS<N> — <lane>, session <k+1>")
- read-first list: the programme's working-model doc, if any → own status file, **current block only** → protocols → lane charter
- **an explicit DO-NOT-READ list** (the archive file, superseded specs)
- **verified live state** (trunk sha, open PRs, worktree, the next free migration number where the product has one), from git, not from the old session's words
- duties in priority order
- standing rules: the product's and lane's rules that cost time to learn; only the PM writes `program.yaml` and the lane map; never build on a branch that was squash-merged, cut a fresh one; context economy (subagent-first for investigations, builds and tests; `quiet.sh` for verbose commands; bus messages of three sentences or fewer)
- **channel**: the PM's address to report to, plus a pointer to `messaging.md` (no poll cron, no restating its rules); read the lane mailbox first, it holds what was sent while no session was running
- **context rule**: `[ctx:%]` on every message; context alert at the lane threshold in `messaging.md`
- first actions: verify trunk, SESSION marker in the status file, tell the PM you are live

## 3. Spawn and name it: the name is the registration
**Naming convention:** `WS<N>-<k> <Lane> — <human-readable scope>`
- `WS<N>` = lane number (stable forever) · `-<k>` = session counter, +1 on every respawn · then the lane title and a plain-language scope so anyone reading the picker knows what the lane owns.
- Example roster shape: `WS1-2 Environment & Onboarding — product setup, dev-env, compose` · `WS2-2 Providers & Subscriptions — model providers, credentials, billing`. The live roster lives in `program.yaml`, never in this skill.
- **One string, three places, identical:** the session's own name (`/rename`), the `ws-pulse.py` monitoring map, and the status/handover record. The human approves it; it is never invented per surface.

Two routes:

**Hosted in tmux**, with the script:
```bash
bash "$CLAUDE_PLUGIN_ROOT/scripts/spawn-lane.sh" WS<n> "<Lane title>" <k+1> <worktree-path>
```
Use the script; do not hand-roll the tmux commands. It is the same implementation `setup-delivery-program` uses for a first spawn and carries the guards: the model pin, stripping the inherited `CLAUDE_CODE_CHILD_SESSION` (which silently disables transcript writing), separate type and Enter calls, tmux rather than screen, and a refusal to fork a lane that is already live. Read its header once before first use.

**Pass the same worktree the outgoing session held**, so the successor lands where its predecessor's work is. The script asserts the landing from the running session and exits 76 if it is wrong, having sent the lane nothing. It also refuses (exit 70) while the outgoing session is still live in that worktree or in a tmux session of the same name, so once step 1 is verified, stop the old session first: send step 5's decommission message, then end it (`tmux kill-session -t ws<n>` if hosted; the human closes it if it is in a panel).

Still yours after the script returns:
- **Send the briefing** pointing at the SPAWN doc and at `running-a-workstream`. Type and Enter as separate `send-keys` calls.
- **Verify the model from the transcript**; a pinned flag is a claim until the running session agrees: `tail -40 ~/.claude/projects/<proj>/<id>.jsonl | grep -o '"model":"[^"]*"' | tail -1`. Fix in place with `/model <name>`; no respawn needed.
- The workspace must be trusted (`hasTrustDialogAccepted`) and first-run dialogs pre-answered once per machine; live sessions rewrite `~/.claude.json` and can revert external edits.
- **Baton rule:** one driver at a time. Before the human opens a hosted session in their panel, kill the tmux host (`tmux kill-session -t ws<n>`); to hand it back, re-host with `claude --resume <session-id>`.

**Panel** (lanes the human drives directly): hand them the SPAWN doc; they open a session, paste it, and rename it with `/rename <canonical name>`.

## 4. Register the new session
Find its session id: newest `*.jsonl` in `~/.claude/projects/<project>/` whose first user message contains the spawn-prompt identity line. Update the **`.handover/ws-pulse.py` lane map**: replace the lane's row (comment out the retired one, as the map's header says). Run `ws-pulse.py` once to verify the new session shows LIVE. **Read its address from `ListAgents`, and update the lane's `id`, `session` and `address` in `program.yaml` in one edit**: the old address now reaches the retired session, not the lane. Ensure `.handover/inbox/WS<N>.md` exists (it persists across sessions; the new session inherits the mailbox).

## 4b. Reap the old process
A decommissioned session survives as its own `claude --resume=<id>` process if it is open in a VS Code panel; closing the window does not kill it, and it keeps working. After the successor is seated and the lane map remapped:
```bash
bash "$CLAUDE_PLUGIN_ROOT/scripts/reap-ghosts.sh"          # report
bash "$CLAUDE_PLUGIN_ROOT/scripts/reap-ghosts.sh" --kill   # terminate retired sessions only
```
**Report first, every time.** It reads the lane map to tell live from retired, so an incomplete or freshly seeded map makes every real session look like a ghost. Read the report and recognise the sessions in it before you add `--kill`.
It refuses to touch any id present in the lane map, so remap first or it will decline to reap. Verify the report then shows only LIVE lanes. A reaped session may still appear in VS Code until the view refreshes; that is cosmetic.

## 5. Decommission the old session
Send to the OLD session's address (or via the human): "Session <k> is decommissioned — append a final `PROCESSED-MARKER` + 'superseded by session <k+1>' to the inbox, make no further writes." An address names one session, so this cannot land on the successor. Confirm its worktree is clean or handed over; never delete a dirty worktree. The human closes the window. The old transcript stays on disk as the archive.

## 6. Record
One line in the lane's status file ("SESSION <k+1> — succeeded session <k>, <date>") and, if the programme tracker or memory carries session ids, update them.
