#!/bin/bash
# reap-ghosts.sh — kill `claude --resume=<id>` processes of retired sessions.
# A retired session keeps running after its editor window closes, and can wake and act
# on its stale plan, forking a lane.
#
# A process is killed only if its session id is on no code line of ws-pulse.py (ids in
# comments don't count). Remap a lane to its successor before running this.
#
# Usage:  bash .handover/reap-ghosts.sh          # report only (default, safe)
#         bash .handover/reap-ghosts.sh --kill   # actually reap
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/program-root.sh"
program_resolve "${PROGRAM_ROOT:-}" || exit 2
cd "$PROGRAM_ROOT" || exit 1
MAP="$PROGRAM_DIR/ws-pulse.py"
[ -f "$MAP" ] || { echo "ws-pulse.py not found — cannot tell live from retired. Aborting."; exit 1; }

mode="${1:-report}"
found=0

# Ids on code lines only: retired rows stay in the map as comments.
REGISTERED=$(sed 's/#.*//' "$MAP" | grep -oE "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}")
if [ -z "$REGISTERED" ]; then
  echo "WS map yielded ZERO registered session ids after stripping comments — refusing to run."
  echo "(A parse failure here would mark every live lane as a ghost. Fix the map, then re-run.)"
  exit 1
fi

while read -r pid sid; do
  [ -z "${sid:-}" ] && continue
  found=1
  if printf '%s\n' "$REGISTERED" | grep -qx "$sid"; then
    echo "  LIVE  pid $pid  $sid  — registered lane, left alone"
  else
    if [ "$mode" = "--kill" ]; then
      kill "$pid" 2>/dev/null && echo "  REAPED pid $pid  $sid  — retired session terminated"
    else
      echo "  GHOST pid $pid  $sid  — retired; run with --kill to reap"
    fi
  fi
done < <(pgrep -f -- "--resume=" | while read -r p; do
           s=$(ps -p "$p" -o command= 2>/dev/null | grep -oE -- "--resume=[a-f0-9-]{36}" | cut -d= -f2)
           [ -n "$s" ] && echo "$p $s"
         done)

[ "$found" -eq 0 ] && echo "  no resumed sessions running"
echo "Note: a killed process may still LOOK open in VS Code until the view refreshes — that window is inert; a dead process cannot act."
