#!/usr/bin/env bash
# spawn-lane.sh — start and name a workstream lane session in a tmux window.
#
# ONE implementation, used by BOTH `setup-delivery-program` (first spawn) and
# `respawn-workstream` (succession). It was two prose recipes in two skills; a
# procedure with two copies has two places to be wrong, and the one that is wrong
# is always the one you did not read.
#
#   bash scripts/spawn-lane.sh WS3 "Agents & PDLC" 1 ../repo/.worktrees/ws3
#   bash scripts/spawn-lane.sh WS3 "Agents & PDLC" 4 /abs/path/wt --model opus
#
# Every guard below cost someone an afternoon. None is optional.
#
#  1. MODEL MUST BE PINNED. A bare `claude` silently inherits the last-saved
#     "default for new sessions" — that is how five lanes came up on the wrong
#     model while settings said otherwise. Pinned here AND verified after boot.
#
#  2. CLAUDE_CODE_CHILD_SESSION IS INHERITED from the spawning process and
#     SILENTLY DISABLES TRANSCRIPT WRITING → no picker entry, no monitoring, no
#     handover on respawn. Stripped, with persistence forced on.
#
#  3. TYPE AND ENTER MUST BE SEPARATE send-keys CALLS with a pause between. A
#     combined `... Enter` leaves the text sitting unsubmitted in the composer,
#     and the lane looks spawned while having received nothing.
#
#  4. tmux, NOT screen. macOS ships screen 4.00.03, which cannot inject into or
#     capture a detached TUI.
#
#  5. NEVER FORK A LIVE LANE. An existing tmux session of the same name is
#     refused, not reused: two sessions on one lane both keep working and the
#     divergence only shows up once their branches disagree.
#
#  6. THE WORKTREE IS AN ARGUMENT, NOT PROSE. Until 2026-08-30 this script had
#     no -c, so every lane started in *the PM's* cwd and the worktree reached it
#     only as a sentence in the spawn document. A session starts in the cwd it
#     was given, never the path in its briefing — that is how two mutators end
#     up in one .git/index, which yields silent false greens, not conflicts.
#     Passed to tmux with -c, validated before boot, ASSERTED after.
#
#  7. A WORKTREE ALREADY HOLDING A LIVE SESSION IS REFUSED — same index, same
#     failure. Read from `claude agents --json`.
#     ⚠ What guard 7 does NOT prove: it sees only sessions this CLI registers.
#     A plain editor, a script, or a session from another CLI build writing that
#     worktree is invisible to it. If the registry cannot be read at all the
#     guard says so LOUDLY and continues — an unverified spawn is announced,
#     never silent.
#
# KNOWN, and deliberately not worked around: a worktree Claude has never seen
# opens with the "Is this a project you trust?" dialog, which no send-keys here
# answers. The lane then never registers and this script exits 75. That is the
# correct outcome — a spawn that needs a human keystroke should stop and say so
# — but the message says "never registered", not "waiting on trust", so attach
# and look before assuming the lane is broken. Trust the worktree once, by hand.
#
# It does NOT write the spawn document and does NOT brief the lane — callers do
# that, because the content differs between a first spawn and a succession.
set -euo pipefail

MODEL="opus"
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --model) MODEL="$2"; shift 2 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

if [ "${#ARGS[@]}" -lt 4 ]; then
  echo "usage: spawn-lane.sh <WS-id> <lane title> <session-number> <worktree-path> [--model <name>]" >&2
  echo "   eg: spawn-lane.sh WS3 \"Agents & PDLC\" 1 ../helvetiq/.worktrees/ws3" >&2
  echo "" >&2
  echo "The worktree is REQUIRED (guard 6). Without it the lane starts in the" >&2
  echo "PM's cwd — which is how two lanes end up mutating one .git/index." >&2
  exit 64
fi

WS="${ARGS[0]}"; TITLE="${ARGS[1]}"; K="${ARGS[2]}"; WT_IN="${ARGS[3]}"
SESSION="$(echo "$WS" | tr '[:upper:]' '[:lower:]')"
NAME="$WS-$K $TITLE"

# Guard 6a: the path must exist and be a directory, before anything else.
if [ ! -d "$WT_IN" ]; then
  echo "spawn-lane: worktree '$WT_IN' does not exist or is not a directory — REFUSING." >&2
  exit 66
fi
# Realpath it: the session registry stores a resolved path, so an unresolved
# one here would make the post-boot assertion compare two different spellings
# of the same directory and fail for the wrong reason.
WT="$(cd "$WT_IN" && pwd -P)"

# Guard 6b: it must be the ROOT of a git worktree, not merely inside one.
# git's upward discovery answers about the ENCLOSING repo, so a path one level
# wrong reports the parent checkout and looks entirely healthy.
TOP="$(git -C "$WT" rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$TOP" ]; then
  echo "spawn-lane: '$WT' is not inside a git repository — REFUSING." >&2
  exit 66
fi
TOP="$(cd "$TOP" && pwd -P)"
if [ "$TOP" != "$WT" ]; then
  echo "spawn-lane: '$WT' is not a worktree ROOT — REFUSING." >&2
  echo "            git reports its toplevel as: $TOP" >&2
  echo "            Spawning here would put the lane in the enclosing checkout." >&2
  exit 66
fi

# Guard 7: refuse a worktree that already holds a live session. See header for
# what this does NOT cover.
if OCC_JSON="$(claude agents --json 2>/dev/null)"; then
  # NO f-strings and NO backslash-escaped quotes in here: this block lives
  # inside a single-quoted shell string, where \" reaches python verbatim and
  # is a SyntaxError. The first version of this guard did exactly that, with
  # stderr redirected to /dev/null — so it crashed on every run, produced an
  # empty answer, and read as "no occupant". It passed a worktree that had
  # three live sessions in it. A guard that cannot fail is not a guard.
  OCC_RC=0
  OCCUPANT="$(printf '%s' "$OCC_JSON" | python3 -c '
import json, sys, os
rows = json.load(sys.stdin)
want = os.path.realpath(sys.argv[1])
for s in rows:
    cwd = s.get("cwd")
    if cwd and os.path.realpath(cwd) == want:
        name = s.get("name") or s.get("sessionId") or "?"
        print("%s (pid %s, %s)" % (name, s.get("pid"), s.get("kind")))
        break
' "$WT")" || OCC_RC=$?

  if [ "$OCC_RC" -ne 0 ]; then
    echo "spawn-lane: ⚠ GUARD 7 CRASHED (python exit $OCC_RC) — occupancy NOT checked." >&2
    echo "            Proceeding UNVERIFIED for $WT." >&2
  elif [ -n "$OCCUPANT" ]; then
    echo "spawn-lane: worktree '$WT' already holds a live session — REFUSING." >&2
    echo "            occupant: $OCCUPANT" >&2
    echo "            Two sessions on one .git/index corrupt each other's staging" >&2
    echo "            silently. Give this lane its own worktree, or stop that one." >&2
    exit 70
  fi
else
  echo "spawn-lane: ⚠ GUARD 7 DID NOT RUN — 'claude agents --json' failed." >&2
  echo "            Proceeding UNVERIFIED: nothing checked whether another live" >&2
  echo "            session is already writing $WT." >&2
fi

command -v tmux >/dev/null 2>&1 || {
  echo "spawn-lane: tmux not installed — 'brew install tmux'." >&2
  echo "            macOS's bundled screen cannot drive a detached Claude TUI." >&2
  exit 69
}

# Guard 5: never fork a live lane. Two sessions on one lane both keep working,
# and the divergence is only visible once their branches disagree.
if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "spawn-lane: tmux session '$SESSION' already exists — REFUSING." >&2
  echo "            Attach: tmux attach -t $SESSION" >&2
  echo "            If it is genuinely dead: tmux kill-session -t $SESSION" >&2
  exit 70
fi

echo "spawn-lane: starting '$NAME' (model=$MODEL) in tmux session '$SESSION'"
echo "spawn-lane: worktree $WT"

# Guards 1 + 2 + 6 live in this one command. -c is what actually puts the lane
# in its own worktree; everything above only proved the path was worth using.
tmux new-session -d -s "$SESSION" -x 200 -y 50 -c "$WT" \
  "env -u CLAUDE_CODE_CHILD_SESSION -u CLAUDE_CODE_ENTRYPOINT \
   CLAUDE_CODE_FORCE_SESSION_PERSISTENCE=1 claude --model $MODEL"

# Readiness, step 1 of 2: wait for the session to REGISTER. This is the
# authoritative signal — the session writes ~/.claude/sessions/<pid>.json itself
# — and unlike scraping the TUI it does not change shape between releases.
#
# 🔴 The pane-scrape that used to be the ONLY readiness test grepped for
# '│', '>' or 'Welcome'. Claude Code 2.1.251 draws '❯' and '─' and no
# "Welcome", so NONE of the three ever matched: every spawn burned the full 60s,
# exited 75 "no prompt", and left a healthy un-renamed, un-briefed lane running
# in tmux for someone to find later. Measured 2026-08-30. A readiness check that
# cannot observe readiness reports a failure that did not happen, which is worse
# than no check — it manufactures orphans.
SID=""; LANE_CWD=""
for _ in $(seq 1 30); do
  read -r SID LANE_CWD <<<"$(python3 -c '
import json, glob, os, sys
want = sys.argv[1]
for f in glob.glob(os.path.expanduser("~/.claude/sessions/*.json")):
    try:
        d = json.load(open(f))
    except Exception:
        continue
    if str(d.get("tmux", "")).startswith(want + ":"):
        print(d.get("sessionId", ""), d.get("cwd", ""))
        break
' "$SESSION" 2>/dev/null)" || true
  [ -n "$SID" ] && break
  sleep 2
done
if [ -z "$SID" ]; then
  echo "spawn-lane: '$SESSION' never registered after 60s. Inspect with:" >&2
  echo "              tmux attach -t $SESSION" >&2
  echo "            If it is wedged: tmux kill-session -t $SESSION" >&2
  exit 75
fi

# Guard 6, the half that is a measurement: -c is a claim until the session that
# actually booted agrees with it. Read the cwd back from the running session's
# own registry entry — not from tmux, not from this script's variables, both of
# which would only re-assert what we already believe.
#
# This runs BEFORE the lane is typed at. A lane in the wrong worktree must
# receive nothing: a briefing is the first thing that would make it write.
if [ "$(cd "$LANE_CWD" 2>/dev/null && pwd -P || echo "$LANE_CWD")" != "$WT" ]; then
  echo "spawn-lane: ✗ CWD ASSERTION FAILED — the lane is NOT in its worktree." >&2
  echo "            expected: $WT" >&2
  echo "            actual:   $LANE_CWD" >&2
  echo "            Nothing has been sent to it. Kill it before it writes:" >&2
  echo "              tmux kill-session -t $SESSION" >&2
  exit 76
fi

# Readiness, step 2 of 2: the composer must actually be accepting input.
# Registration happens at startup, which is earlier — and guard 3 exists because
# typing before the composer is live is silently swallowed. Pattern covers the
# current TUI ('❯', '─') and older ones ('>', '│', 'Welcome').
for _ in $(seq 1 30); do
  if tmux capture-pane -t "$SESSION" -p 2>/dev/null | grep -q '❯\|─\|│\|>\|Welcome'; then
    READY=1; break
  fi
  sleep 2
done
if [ "${READY:-0}" != "1" ]; then
  echo "spawn-lane: registered as $SID but no composer after 60s." >&2
  echo "            Inspect with: tmux attach -t $SESSION" >&2
  exit 75
fi

# Guard 3: type, pause, THEN Enter — separately, both times.
tmux send-keys -t "$SESSION" "/rename $NAME"; sleep 2
tmux send-keys -t "$SESSION" Enter;           sleep 3

cat <<EOF

spawn-lane: '$NAME' is up.
  worktree:  $WT   (asserted from the running session, not from -c)
  session:   ${SID:-<UNVERIFIED — see warning above>}

  NEXT, and this script deliberately does NOT do it for you:
    1. Send the lane its spawn document path and tell it to use
       running-a-workstream. Type and Enter as SEPARATE commands:
         tmux send-keys -t $SESSION '<one-line briefing>' ; sleep 2
         tmux send-keys -t $SESSION Enter
    2. VERIFY THE MODEL from the transcript — a pinned flag is a claim until
       the running session agrees with it:
         tail -40 ~/.claude/projects/<proj>/<id>.jsonl | grep -o '"model":"[^"]*"' | tail -1
       Wrong model? Fix in place with /model $MODEL — no respawn needed.
    3. Register session ${SID:-<id>} in the monitoring map, then wait for the
       lane to report live before spawning the next one.

  Attach: tmux attach -t $SESSION   (detach with ctrl-b d)
EOF
