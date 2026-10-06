#!/bin/bash
# PM outbox cursor-read: prints everything unread since the last run, then advances the cursor.
# Use it instead of `tail -n N`, which silently drops messages when more than N arrived.
source "$(dirname "${BASH_SOURCE[0]}")/program-root.sh"
program_resolve "${PROGRAM_ROOT:-}" || exit 2
F="$PROGRAM_DIR/outbox-to-pm.md"
C="$PROGRAM_DIR/.pm-outbox-cursor"
size=$(stat -f%z "$F")
off=$(cat "$C" 2>/dev/null || echo 0)
[ "$off" -gt "$size" ] && off=0   # file rotated/truncated
if [ "$off" -eq "$size" ]; then echo "NO-UNREAD"; else tail -c +$((off+1)) "$F"; fi
echo "$size" > "$C"
