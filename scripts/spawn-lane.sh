#!/usr/bin/env bash
# spawn-lane.sh — start and name a workstream lane session in a tmux window.
# Used by setup-delivery-program (first spawn) and respawn-workstream (succession).
#
#   bash scripts/spawn-lane.sh WS3 "Agents & PDLC" 1 ../repo/.worktrees/ws3
#   bash scripts/spawn-lane.sh WS3 "Agents & PDLC" 4 /abs/path/wt --model opus
#   bash scripts/spawn-lane.sh PM "Program Manager" 3 /abs/path/wt --session pm-3
#
# Guards:
#  1. The model is pinned: a bare `claude` inherits the last-saved default. Verify it after boot.
#  2. CLAUDE_CODE_CHILD_SESSION is inherited from the spawner and disables transcript
#     writing (no picker entry, no monitoring); it is stripped and persistence forced on.
#  3. Type and Enter are separate send-keys calls with a pause; combined, the text sits unsubmitted.
#  4. tmux, not screen: macOS's screen cannot inject into or capture a detached TUI.
#  5. An existing tmux session of the same name is refused: never fork a live lane.
#     The name is the lowercased WS-id; --session names it instead, for a successor PM
#     whose predecessor still holds tmux session `pm`. The guard applies to that name.
#  6. The worktree is an argument, passed with -c and asserted from the booted session.
#     A session works in the cwd it was started in, whatever its briefing says, and two
#     sessions in one .git/index give silent false greens.
#  7. A worktree already holding a live session (per `claude agents --json`) is refused.
#     It sees only sessions this CLI registers; if the registry can't be read, it warns
#     and continues unverified.
#
# A worktree Claude has never seen opens the "trust this project?" dialog, which nothing
# here answers: the script exits 75 "never registered". Attach, trust it once by hand.
#
# It does not write the spawn document or brief the lane; callers do, because a first
# spawn and a succession differ.
set -euo pipefail

MODEL="opus"
SESSION=""
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --model) MODEL="$2"; shift 2 ;;
    --session) SESSION="$2"; shift 2 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

if [ "${#ARGS[@]}" -lt 4 ]; then
  echo "usage: spawn-lane.sh <WS-id> <lane title> <session-number> <worktree-path> [--model <name>] [--session <tmux-name>]" >&2
  echo "   eg: spawn-lane.sh WS3 \"Agents & PDLC\" 1 ../helvetiq/.worktrees/ws3" >&2
  echo "" >&2
  echo "The worktree is REQUIRED (guard 6). Without it the lane starts in the" >&2
  echo "PM's cwd — which is how two lanes end up mutating one .git/index." >&2
  exit 64
fi

WS="${ARGS[0]}"; TITLE="${ARGS[1]}"; K="${ARGS[2]}"; WT_IN="${ARGS[3]}"
[ -n "$SESSION" ] || SESSION="$(echo "$WS" | tr '[:upper:]' '[:lower:]')"
NAME="$WS-$K $TITLE"

# Guard 6a: the path must exist and be a directory, before anything else.
if [ ! -d "$WT_IN" ]; then
  echo "spawn-lane: worktree '$WT_IN' does not exist or is not a directory — REFUSING." >&2
  exit 66
fi
# Resolved, because the session registry stores resolved paths and the post-boot check compares them.
WT="$(cd "$WT_IN" && pwd -P)"

# Guard 6b: it must be a worktree root; a path inside one would put the lane in the enclosing checkout.
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

# Guard 7: refuse a worktree that already holds a live session (limits in the header).
if OCC_JSON="$(claude agents --json 2>/dev/null)"; then
  # No f-strings or \" in this single-quoted python: \" reaches python verbatim, the
  # SyntaxError is hidden, and an empty answer reads as "no occupant".
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

# Guard 5: never fork a live lane.
if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "spawn-lane: tmux session '$SESSION' already exists — REFUSING." >&2
  echo "            Attach: tmux attach -t $SESSION" >&2
  echo "            If it is genuinely dead: tmux kill-session -t $SESSION" >&2
  exit 70
fi

echo "spawn-lane: starting '$NAME' (model=$MODEL) in tmux session '$SESSION'"
echo "spawn-lane: worktree $WT"

# Guards 1, 2 and 6.
tmux new-session -d -s "$SESSION" -x 200 -y 50 -c "$WT" \
  "env -u CLAUDE_CODE_CHILD_SESSION -u CLAUDE_CODE_ENTRYPOINT \
   CLAUDE_CODE_FORCE_SESSION_PERSISTENCE=1 claude --model $MODEL"

# Readiness 1/2: wait for the session to register in ~/.claude/sessions/<pid>.json.
# That file is the reliable signal; the TUI's characters change between releases.
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

# Guard 6: read the cwd back from the booted session's own registry entry, before
# anything is typed at it; a lane in the wrong worktree must receive nothing.
if [ "$(cd "$LANE_CWD" 2>/dev/null && pwd -P || echo "$LANE_CWD")" != "$WT" ]; then
  echo "spawn-lane: ✗ CWD ASSERTION FAILED — the lane is NOT in its worktree." >&2
  echo "            expected: $WT" >&2
  echo "            actual:   $LANE_CWD" >&2
  echo "            Nothing has been sent to it. Kill it before it writes:" >&2
  echo "              tmux kill-session -t $SESSION" >&2
  exit 76
fi

# Readiness 2/2: the composer accepts input (it comes up after registration). The
# pattern covers the current TUI ('❯', '─') and older ones ('>', '│', 'Welcome').
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

# Guard 3: type, pause, then Enter.
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
