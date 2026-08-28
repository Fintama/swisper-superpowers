#!/bin/bash
# reap-ghosts.sh — kill panel/CLI processes belonging to RETIRED sessions.
#
# Why: a decommissioned session keeps running as a `claude --resume=<id>` process
# (VS Code panel or elsewhere). Closing the editor window does NOT kill it; it can
# wake and act on its stale plan, forking a lane. See PROTOCOL §5 Second-Door Rule.
#
# Safety: a process is killed ONLY if its session id is absent from the WS map in
# ws-pulse.py (i.e. not a currently-registered lane). Registered lanes are never touched.
#
# Usage:  bash .handover/reap-ghosts.sh          # report only (default, safe)
#         bash .handover/reap-ghosts.sh --kill   # actually reap
set -uo pipefail
# C2: the programme is a parameter, not this script's parent directory.
source "$(dirname "${BASH_SOURCE[0]}")/program-root.sh"
program_resolve "${PROGRAM_ROOT:-}" || exit 2
cd "$PROGRAM_ROOT" || exit 1
MAP="$PROGRAM_DIR/ws-pulse.py"
[ -f "$MAP" ] || { echo "ws-pulse.py not found — cannot tell live from retired. Aborting."; exit 1; }

mode="${1:-report}"
found=0

# PROTECTION IS DECIDED ON CODE LINES ONLY (PM-3, 2026-07-29).
# The old check was `grep -q "$sid" "$MAP"` against the WHOLE file — but PROTOCOL §4
# step 2 *instructs* you to "comment the retired id with its date and reason". So every
# session retired according to protocol stayed matched by its OWN RETIREMENT COMMENT and
# was reported "registered lane, left alone". The reaper could only ever have killed a
# session deleted from the map entirely — which protocol tells you not to do. It was
# never shown a retired-but-commented id; that is the only input it gets in practice.
# Found live: PM-2 (09d113d4) had been retired, was still running, and was protected.
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
