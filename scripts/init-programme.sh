#!/usr/bin/env bash
# Create a programme's state directory and seed the files the programme owns.
#
# Stateless tools run from the plugin (`python3 "$CLAUDE_PLUGIN_ROOT/scripts/msg.py" …`).
# The lane map (`ws-pulse.py`'s WS list) is edited by the PM on every succession, so it
# lives in $PROGRAM_DIR, where a plugin update cannot overwrite it; reap-ghosts.sh and
# ctx-check.py read it there.
#
# Idempotent: an existing lane map is never overwritten, because it is the live roster.
#
# Usage:
#   bash "$CLAUDE_PLUGIN_ROOT/scripts/init-programme.sh" [program-root]
#   PROGRAM_ROOT=/path/to/product bash .../init-programme.sh
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=program-root.sh
source "$HERE/program-root.sh"
program_resolve "${1:-${PROGRAM_ROOT:-}}" || exit 2

echo "programme root: $PROGRAM_ROOT"
echo "state dir:      $PROGRAM_DIR"
echo

created=0
kept=0

mk() {  # mk <path> <what-it-is>
    if [ -e "$1" ]; then
        echo "  kept    $2 (already exists)"
        kept=$((kept + 1))
    else
        mkdir -p "$(dirname "$1")"
        return 0
    fi
    return 1
}

mkdir -p "$PROGRAM_DIR/inbox" "$PROGRAM_DIR/logs"
echo "  ensured inbox/ and logs/"

# The lane map, seeded from the plugin's template once.
for f in ws-pulse.py ws-pulse-delta.py; do
    if mk "$PROGRAM_DIR/$f" "$f"; then
        cp "$HERE/$f" "$PROGRAM_DIR/$f"
        chmod +x "$PROGRAM_DIR/$f"
        echo "  created $f (empty lane map — add your lanes)"
        created=$((created + 1))
    fi
done

# ws-pulse.py imports program_root from its own directory, so its imports go beside the copy.
for f in program_root.py program_yaml.py; do
    if [ ! -f "$PROGRAM_DIR/$f" ]; then
        cp "$HERE/$f" "$PROGRAM_DIR/$f"
        echo "  created $f (import dependency of the lane map)"
        created=$((created + 1))
    else
        echo "  kept    $f (already exists)"
        kept=$((kept + 1))
    fi
done

if mk "$PROGRAM_DIR/outbox-to-pm.md" "outbox-to-pm.md"; then
    printf '# Outbox to PM\n\nAppend-only. Lanes write here; the PM reads with pm-outbox-read.sh.\n\n' \
        > "$PROGRAM_DIR/outbox-to-pm.md"
    echo "  created outbox-to-pm.md"
    created=$((created + 1))
fi

echo
echo "created $created, kept $kept."

# Re-read the disk rather than trust the counters above.
missing=0
for f in ws-pulse.py ws-pulse-delta.py program_root.py program_yaml.py outbox-to-pm.md; do
    [ -f "$PROGRAM_DIR/$f" ] || { echo "STILL MISSING: $PROGRAM_DIR/$f"; missing=$((missing + 1)); }
done
[ -d "$PROGRAM_DIR/inbox" ] || { echo "STILL MISSING: $PROGRAM_DIR/inbox"; missing=$((missing + 1)); }

if [ "$missing" -gt 0 ]; then
    echo "FAIL — $missing required item(s) absent after init."
    exit 1
fi

# Run the seeded copy: only that proves its imports resolve.
if ! PROGRAM_ROOT="$PROGRAM_ROOT" python3 "$PROGRAM_DIR/ws-pulse.py" 1 >/dev/null 2>&1; then
    echo "FAIL — the seeded ws-pulse.py does not run. Output:"
    PROGRAM_ROOT="$PROGRAM_ROOT" python3 "$PROGRAM_DIR/ws-pulse.py" 1 2>&1 | tail -5 | sed 's/^/    /'
    exit 1
fi
echo "  verified: the seeded ws-pulse.py runs"

echo "PASS — the programme state directory is complete."
echo
echo "Next: put your lanes in $PROGRAM_DIR/ws-pulse.py, then run"
echo "  python3 \"$PROGRAM_DIR/ws-pulse.py\" 1"
