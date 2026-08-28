#!/usr/bin/env bash
# Where is the programme? — shell half of scripts/program_root.py. Source it.
#
#   PROGRAM_ROOT  the programme's repo
#   PROGRAM_DIR   where its state lives (default: $PROGRAM_ROOT/.handover)
#
# Resolution: explicit argument -> environment -> program.yaml -> fail loudly.
# ⚠ Never guesses. A wrong root reads another programme's mailbox and reports on
# it as if it were yours.
program_resolve() {
    if [ -n "${1:-}" ]; then PROGRAM_ROOT="$1"; fi
    if [ -z "${PROGRAM_ROOT:-}" ] && [ -n "${PROGRAM_YAML:-}" ]; then
        PROGRAM_ROOT=$(python3 "$(dirname "${BASH_SOURCE[0]}")/program_root.py" 2>/dev/null) || true
    fi
    if [ -z "${PROGRAM_ROOT:-}" ]; then
        echo "CANNOT LOCATE THE PROGRAMME." >&2
        echo "  Pass it, or set PROGRAM_ROOT, or point PROGRAM_YAML at a program.yaml." >&2
        echo "  Refusing to guess: a wrong root reads another programme's mailbox." >&2
        return 2
    fi
    PROGRAM_ROOT=$(cd "$PROGRAM_ROOT" && pwd) || return 2
    : "${PROGRAM_DIR:=$PROGRAM_ROOT/.handover}"
    export PROGRAM_ROOT PROGRAM_DIR
}
