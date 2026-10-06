#!/bin/bash
# quiet.sh — run a verbose/long command with full output logged to a file; only the tail enters the agent's context.
# Usage: bash .handover/quiet.sh <command> [args...]     (from the repo root or any worktree)
# For builds, installs, migrations and test suites whose output would flood the context.
set -o pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/program-root.sh"
program_resolve "${PROGRAM_ROOT:-}" || exit 2
dir="$PROGRAM_DIR/logs"
mkdir -p "$dir"
log="$dir/$(date +%Y%m%d-%H%M%S)-$$.log"
"$@" > "$log" 2>&1
code=$?
echo "── exit $code · full log: $log · last 15 lines ──"
tail -15 "$log"
exit $code
