#!/bin/bash
# quiet.sh — run a verbose/long command with full output logged to a file; only the tail enters the agent's context.
# Usage: bash .handover/quiet.sh <command> [args...]     (from the repo root or any worktree)
# Why: docker builds, npm installs, migrations and test suites stream thousands of log lines into a session's
# context window when run inline. Logged-to-file, an agent keeps the evidence and pays ~15 lines.
set -o pipefail
# C2: logs belong to the PROGRAMME, not to wherever this script happens to live.
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
