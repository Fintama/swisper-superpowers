---
name: respawn-pm
description: PM self-succession — when the PM session's own context runs low (~85% full) or quality degrades, prepare the handover and spawn/register the successor PM (autonomously via tmux, or hand Heiko a paste-ready kickoff), then decommission this session.
---

# Respawn the PM (self-succession)

Trigger: own context ≥85% consumed, degraded recall of program facts, or Heiko's request.
**Canonical spec for naming, context package, spawning, registration and decommission: `${CLAUDE_PLUGIN_ROOT}/docs/PROTOCOL-2026-07-27-session-lifecycle.md`** (C4 — it ships with the plugin now, so a programme on any product has it; Foundry's `.handover/` copy stays for its own historical citations).** This skill is the PM-specific sequence on top of it.

**Do it BEFORE quality degrades.** Auto-compaction is a safety net, not a plan: a fresh session with a verified handover beats a compacted one.

## 1. Freeze and verify
Finish or safely park in-flight actions (never mid-merge). Verify live state from git/gh — trunk sha, open PRs, migration ladder next-free, per-lane branch/PR/ctx state — never from conversational memory.

## 2. Write the handover — `.handover/PM-HANDOVER-<date>-<slug>.md`
House pattern (reference: `PM-HANDOVER-2026-07-26-uat-a-wave-to-mlp-merge.md`): one-paragraph state · read-these-in-order · monitoring tooling + **current ws-pulse session-id map** · per-lane state, owed items and ctx levels · Heiko's open decisions · standing rules that were tested, including mistakes made (the §7-class lessons) · immediate duties · **paste-ready kickoff for the successor as the final section**.

## 3. List the session-bound losses explicitly
They die with this session and must be recreated by the successor in its first minutes:
- **Crons** — the PM poll (cadence + the EXACT prompt text, verbatim).
- **tmux hosts** — run `tmux ls`; name each session and which lane it carries, so the successor keeps the baton map straight.
- Any background watchers or unfinished monitors.

## 4. Update the durable stores
Project memory: point the program memories at the new handover as CURRENT, correct anything stale, keep the MEMORY.md index hooks accurate.

## 5. Spawn the successor
**Autonomous (preferred — no Heiko involvement):** follow §3 of the lifecycle protocol — `tmux new-session -d -s pm …` with `CLAUDE_CODE_CHILD_SESSION` stripped and `CLAUDE_CODE_FORCE_SESSION_PERSISTENCE=1` set → `/rename PM-<k+1> Program Manager — program coordination, routing, merges` → one-line briefing pointing at the handover doc (type and Enter as separate send-keys calls).
**Panel (if Heiko wants it in his UI):** tell him — "PM context at <X>% — successor prep complete. Open a session, paste §last of `<handover>`, then `/rename PM-<k+1> Program Manager …`".

## 6. Register and verify the successor
Confirm a transcript appeared (no transcript = the child-session marker leaked; respawn with a clean env). Add/replace the PM entry in the ws-pulse map. Then confirm the successor: read the handover, verified trunk state itself, **recreated the poll cron**, re-mapped any respawned session ids, and announced takeover (to Heiko + one line into each WS inbox: "PM-<k+1> live, same protocol").

## 7. Decommission this session
`CronDelete` every own cron · append `SUPERSEDED by PM-<k+1>, <timestamp>` to the handover · stop answering program traffic (if addressed, one line pointing at the successor). Do NOT kill tmux hosts carrying live workstreams — hand them over in the handover instead. The transcript remains the archive.

**Anti-patterns:** handing over unverified claims · forgetting that crons and tmux hosts die with the session (monitoring and instant delivery silently stop) · writing the handover after degradation · two PMs answering traffic.
