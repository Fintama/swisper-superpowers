#!/usr/bin/env bash
# init-programme.sh — create a programme's state directory and seed the files
# that belong to the PROGRAMME rather than to the plugin.
#
# The split this script exists to serve:
#
#   THE PLUGIN owns the stateless tools. Run them from where they are installed
#   — `python3 "$CLAUDE_PLUGIN_ROOT/scripts/msg.py" …`. They take the programme
#   as a parameter, hold no programme state, and are replaced on every update.
#
#   THE PROGRAMME owns its lane map. `ws-pulse.py` carries the WS list — which
#   sessions are live, under which names — and the PM edits it on every
#   succession. It therefore CANNOT live in the plugin cache: an update would
#   overwrite the roster. `reap-ghosts.sh` reads it from $PROGRAM_DIR by design
#   and aborts when it is missing, which is the failure this script prevents.
#
# Idempotent. It NEVER overwrites an existing lane map — that file is the live
# roster, and clobbering it would make the monitoring watch dead sessions while
# reporting success.
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

# The lane map — programme data. Seeded from the plugin's template ONCE.
for f in ws-pulse.py ws-pulse-delta.py; do
    if mk "$PROGRAM_DIR/$f" "$f"; then
        cp "$HERE/$f" "$PROGRAM_DIR/$f"
        chmod +x "$PROGRAM_DIR/$f"
        echo "  created $f (empty lane map — add your lanes)"
        created=$((created + 1))
    fi
done

# The modules those two import. They must sit BESIDE the copy, not in the plugin:
# ws-pulse.py does `from program_root import …`, which resolves against its own
# directory. Without them the programme copy dies with ModuleNotFoundError — and
# it does so only after the map has been edited, which is the worst moment.
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

# A summary that can DISAGREE with us: re-read the disk rather than assert.
missing=0
for f in ws-pulse.py ws-pulse-delta.py program_root.py program_yaml.py outbox-to-pm.md; do
    [ -f "$PROGRAM_DIR/$f" ] || { echo "STILL MISSING: $PROGRAM_DIR/$f"; missing=$((missing + 1)); }
done
[ -d "$PROGRAM_DIR/inbox" ] || { echo "STILL MISSING: $PROGRAM_DIR/inbox"; missing=$((missing + 1)); }

if [ "$missing" -gt 0 ]; then
    echo "FAIL — $missing required item(s) absent after init."
    exit 1
fi

# Presence is not function. The seeded copy imports program_root from its own
# directory, so the only proof that the seeding worked is running it — a file
# list would look identical whether or not the import resolves.
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
