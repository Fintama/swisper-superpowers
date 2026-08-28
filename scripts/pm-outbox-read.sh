#!/bin/bash
# PM outbox cursor-read: prints EVERYTHING unread since the last invocation, then advances the cursor.
# Fixes the tail(-N) gap that swallowed 3 WS2 replies on 2026-07-28 (cost #414 ~3h + a late succession).
# 🔴 C2/HC-2: both of these were HARD-CODED absolute Foundry paths.
source "$(dirname "${BASH_SOURCE[0]}")/program-root.sh"
program_resolve "${PROGRAM_ROOT:-}" || exit 2
F="$PROGRAM_DIR/outbox-to-pm.md"
C="$PROGRAM_DIR/.pm-outbox-cursor"
size=$(stat -f%z "$F")
off=$(cat "$C" 2>/dev/null || echo 0)
[ "$off" -gt "$size" ] && off=0   # file rotated/truncated
if [ "$off" -eq "$size" ]; then echo "NO-UNREAD"; else tail -c +$((off+1)) "$F"; fi
echo "$size" > "$C"
