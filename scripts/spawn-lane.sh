#!/usr/bin/env bash
# spawn-lane.sh — start and name a workstream lane session in a tmux window.
#
# ONE implementation, used by BOTH `setup-delivery-program` (first spawn) and
# `respawn-workstream` (succession). It was two prose recipes in two skills; a
# procedure with two copies has two places to be wrong, and the one that is wrong
# is always the one you did not read.
#
#   bash scripts/spawn-lane.sh WS3 "Agents & PDLC" 1
#   bash scripts/spawn-lane.sh WS3 "Agents & PDLC" 4 --model opus
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

if [ "${#ARGS[@]}" -lt 3 ]; then
  echo "usage: spawn-lane.sh <WS-id> <lane title> <session-number> [--model <name>]" >&2
  echo "   eg: spawn-lane.sh WS3 \"Agents & PDLC\" 1" >&2
  exit 64
fi

WS="${ARGS[0]}"; TITLE="${ARGS[1]}"; K="${ARGS[2]}"
SESSION="$(echo "$WS" | tr '[:upper:]' '[:lower:]')"
NAME="$WS-$K $TITLE"

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

# Guards 1 + 2 live in this one command.
tmux new-session -d -s "$SESSION" -x 200 -y 50 \
  "env -u CLAUDE_CODE_CHILD_SESSION -u CLAUDE_CODE_ENTRYPOINT \
   CLAUDE_CODE_FORCE_SESSION_PERSISTENCE=1 claude --model $MODEL"

# Wait for a live prompt rather than sleeping a guessed interval: a slow start
# silently swallows everything typed at it.
for _ in $(seq 1 30); do
  sleep 2
  if tmux capture-pane -t "$SESSION" -p 2>/dev/null | grep -q '│\|>\|Welcome'; then
    READY=1; break
  fi
done
if [ "${READY:-0}" != "1" ]; then
  echo "spawn-lane: no prompt after 60s. Inspect with: tmux attach -t $SESSION" >&2
  exit 75
fi

# Guard 3: type, pause, THEN Enter — separately, both times.
tmux send-keys -t "$SESSION" "/rename $NAME"; sleep 2
tmux send-keys -t "$SESSION" Enter;           sleep 3

cat <<EOF

spawn-lane: '$NAME' is up.

  NEXT, and this script deliberately does NOT do it for you:
    1. Send the lane its spawn document path and tell it to use
       running-a-workstream. Type and Enter as SEPARATE commands:
         tmux send-keys -t $SESSION '<one-line briefing>' ; sleep 2
         tmux send-keys -t $SESSION Enter
    2. VERIFY THE MODEL from the transcript — a pinned flag is a claim until
       the running session agrees with it:
         tail -40 ~/.claude/projects/<proj>/<id>.jsonl | grep -o '"model":"[^"]*"' | tail -1
       Wrong model? Fix in place with /model $MODEL — no respawn needed.
    3. Register the session id in the monitoring map, then wait for the lane
       to report live before spawning the next one.

  Attach: tmux attach -t $SESSION   (detach with ctrl-b d)
EOF
