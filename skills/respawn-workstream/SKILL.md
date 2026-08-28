---
name: respawn-workstream
description: PM procedure to succeed a workstream session whose context is nearly exhausted (ctx alert ≤15% remaining, or observed degradation) — verified handover, spawn prompt, monitoring re-registration, clean decommission of the old session.
---

# Respawn a workstream session (succession, not loss)

Trigger: an outbox `CONTEXT ALERT` (ctx ≤15%), a session showing degradation (forgetting rules, re-asking settled questions), or Heiko's request.

**Canonical spec — naming, the nine-part context package, spawn commands + gotchas, registration and decommission: `${CLAUDE_PLUGIN_ROOT}/docs/PROTOCOL-2026-07-27-session-lifecycle.md`** (C4 — ships with the plugin; Foundry's `.handover/` copy stays for its own historical citations).** Read it; this skill is the operational sequence on top of it.

## 1. Secure the handover (old session, via its inbox or Heiko-paste)
Instruct: finish/park the current task at a safe point (never mid-migration or mid-PR), then write the **CONTINUATION package (protocol §2 v2, ≤2KB)** into the lane's status file: **IN-FLIGHT (branch+commit+literal next step) · NEXT · DECISIONS OWED · live traps · pointer list (spec §, plan, share/ docs, memory names)**. LANDED = one line of PR numbers — git is the record, the PM already knows the history. **Move everything older into `WS<N>-STATUS-archive.md`** (successors never read it; PM greps on demand).
**Verify it yourself against git** (branch exists, commits pushed, claims true) — handover labels don't always survive a grep.

## 2. Write the spawn prompt — `.handover/SPAWN-<date>-WS<N>-session-<k+1>.md`
Pattern: identity line ("You are WS<N> — <lane>, session <k+1>") · read-first list (working model / SWITCH doc → own status **current block only** → protocols → lane charter) · **an explicit DO-NOT-READ list** (the archive file, superseded specs) · **verified live state** (trunk sha, open PRs, worktree, migration ladder next-free) — from git, not from the old session's words · duties in priority order · standing rules (single-writer map, biome CI pin, squash-branch discipline, merges auto-deploy, **§2b context economy: subagent-first for investigations/builds/tests, quiet.sh for verbose ops, ≤3-sentence bus messages**) · **channel** (hosted lanes get NO poll cron — messages arrive as prompts; outbox uplink with ctx%) · **context rule** (ctx% in every outbox message; alert at 85% full) · first actions (verify trunk, SESSION marker in status file, tell the PM you're live).

## 3. Spawn and NAME it — the name is the registration
**Canonical naming convention (Heiko, 2026-07-27):** `WS<N>-<k> <Lane> — <human-readable scope>`
- `WS<N>` = lane number (stable forever) · `-<k>` = session counter, +1 on every respawn · then the lane title and a plain-language scope so anyone reading the picker knows what the lane owns.
- Example roster shape: `WS1-2 Environment & Onboarding — product setup, dev-env, compose` · `WS2-2 Providers & Subscriptions — model providers, credentials, billing` · `WS3-2 Agents & Lifecycle — rosters, copilot, lifecycle design`. The live roster lives in `program.yaml`, never in this skill.
- **ONE string, three places, identical:** the session's own name (`/rename`), the `ws-pulse.py` monitoring map, and the status/handover record. Heiko approves it; it is never invented per-surface.

**Autonomous spawn (PM-hosted, proven 2026-07-27):**
```bash
bash scripts/spawn-lane.sh WS<n> "<Lane title>" <k+1>
```
⚠ **Use the script, do not hand-roll the tmux commands.** It is the SAME
implementation `setup-delivery-program` uses for a first spawn, and it carries
every guard that cost an afternoon: the model pin, stripping the inherited
`CLAUDE_CODE_CHILD_SESSION` (which **silently disables transcript writing** → no
picker entry, no monitoring, no handover next time), separate type/Enter calls,
the tmux-not-screen requirement, and a refusal to fork a lane that is already
live. Read its header once before first use.

**Still yours after the script returns — it deliberately does not do these:**
- **Send the briefing** pointing at the SPAWN doc and at `running-a-workstream`. Type and Enter as separate `send-keys` calls.
- **VERIFY THE MODEL from the transcript.** Every program session runs **Opus 5, high effort** (Heiko's standing requirement), and a pinned flag is a claim until the running session agrees: `tail -40 ~/.claude/projects/<proj>/<id>.jsonl | grep -o '"model":"[^"]*"' | tail -1`. Five lanes once came up on the wrong model while settings said otherwise. Fix in place with `/model opus` — no respawn needed.
- Workspace must be trusted (`hasTrustDialogAccepted`) and first-run dialogs pre-answered once per machine; note that LIVE sessions rewrite `~/.claude.json` and can revert external edits.
- **Baton rule:** only one driver at a time. Before Heiko opens a hosted session in his panel, kill the tmux host (`tmux kill-session -t ws<n>`); to hand it back, re-host with `claude --resume <session-id>`.

**Panel spawn (lanes Heiko drives directly):** hand him the SPAWN doc; he opens a session, pastes it, and renames it with `/rename <canonical name>`.

## 4. Register the new session
Find its session id: newest `*.jsonl` in `~/.claude/projects/<project>/` whose first user message contains the spawn-prompt identity line. Update **`.handover/ws-pulse.py` WS map**: replace the lane's id, comment the old one as retired with date. Run `ws-pulse.py` once to verify the new session shows LIVE. Ensure `.handover/inbox/WS<N>.md` exists (it persists across sessions — the new session inherits the mailbox).

## 4b. REAP THE OLD PROCESS (mandatory — not optional cleanup)
A decommissioned session survives as its own `claude --resume=<id>` process if it is open in a VS Code panel; closing the window does not kill it, and it will keep working (observed twice on 2026-07-27, both forked a lane). After the successor is seated and the pulse map remapped:
```bash
bash "$CLAUDE_PLUGIN_ROOT/scripts/reap-ghosts.sh"          # report
bash "$CLAUDE_PLUGIN_ROOT/scripts/reap-ghosts.sh" --kill   # terminate retired sessions only
```
⚠ **Report first, every time.** It reads the lane map to tell live from retired,
so an incomplete or freshly-seeded map makes every real session look like a
ghost. Read the report and recognise the sessions in it before you ever add
`--kill`.
It refuses to touch any id present in the `ws-pulse.py` map, so remap FIRST or it will decline to reap. Verify the report then shows only LIVE lanes. A reaped session may still appear in VS Code until the view refreshes — inert, cosmetic only.

## 5. Decommission the old session
Via inbox or Heiko: "Session <k> is decommissioned — append a final `PROCESSED-MARKER` + 'superseded by session <k+1>' to the inbox, make no further writes." Confirm its worktree is clean or handed over (never delete a dirty worktree). Heiko closes the window. The old transcript stays on disk as the archive.

## 6. Record
One line in the lane's status file ("SESSION <k+1> — succeeded session <k>, <date>") and, if the program tracker/memory carries session ids, update them.

**Anti-patterns:** spawning before the handover is verified · trusting "cosmetic"/"done" labels without grep · reusing the old branch after a squash merge · forgetting the pulse-map remap (monitoring silently watches a dead session).
