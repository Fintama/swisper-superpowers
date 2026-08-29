#!/usr/bin/env bash
# A7 — has a local enhancement disappeared?
#
# This fork tracks upstream `superpowers`. A merge can silently drop one of our
# additions, and nothing about a clean merge says so. DIVERGENCE.md is the ledger;
# this reads it and fails, NAMING the enhancement, when a marker is gone.
#
#   exit 0  every marker still present
#   exit 1  a marker is missing, or the ledger is empty/unparseable
#   exit 2  the checker could not run
#
# 🔴 IT FAILS ON AN EMPTY LEDGER, AND THAT IS THE POINT. A predicate over an empty
# set is vacuously true: a checker handed an unparsed ledger would loop zero times,
# find zero problems and report success — a green byte-identical to a real one. So
# it prints how many markers it scanned and refuses to pass on zero.
set -u
cd "$(dirname "$0")/.." || exit 2

LEDGER=${1:-DIVERGENCE.md}
[ -f "$LEDGER" ] || { echo "divergence-check: no ledger at $LEDGER"; exit 2; }

scanned=0
missing=0

# backtick as the field separator: markers contain apostrophes and commas, which a
# whitespace or comma split would tear apart.
while IFS=$'\t' read -r skill marker; do
    [ -z "${skill:-}" ] && continue
    [ -z "${marker:-}" ] && continue
    scanned=$((scanned + 1))
    f="skills/$skill/SKILL.md"
    if [ ! -f "$f" ]; then
        echo "MISSING SKILL   $skill — $f does not exist (the whole enhancement is gone)"
        missing=$((missing + 1))
        continue
    fi
    if ! /usr/bin/grep -qF -- "$marker" "$f"; then
        echo "LOST            $skill — '$marker' is no longer in $f"
        missing=$((missing + 1))
        continue
    fi
    # 🔴 A MARKER THAT NAMES A FILE MUST ALSO FIND THE FILE.
    #
    # Measured 2026-08-29: two markers were added naming shipped scripts
    # (`init-workspace.sh`, `verify-review-loop.mjs`). Both passed on the SKILL.md
    # grep alone — and would have kept passing if a merge deleted the scripts and
    # left the prose, because the prose is what mentions them. That is this
    # ledger's own stated failure mode: a check that "lies in the safe-looking
    # direction". A skill whose tooling is gone but whose instructions still tell
    # an agent to run it is worse than one that never had it.
    # 🔴 SEARCH BY BASENAME, ANYWHERE IN THE FORK — NEVER `skills/$skill/$marker`.
    #
    # The flat-path version was written first and produced THREE FALSE FAILURES
    # on its first run: `plan-check.sh` lives in `skills/writing-plans/scripts/`,
    # `init-programme.sh` at the repo root, and `render-gate.mjs` is named by
    # `subagent-driven-development` but shipped under `creating-screen-mocks/`.
    # Tooling is routinely referenced from a skill that does not host it, and a
    # check that cries wolf trains everyone to ignore it — the same false-red
    # failure this fork warns about elsewhere, committed one file later.
    case "$marker" in
        *.sh|*.mjs|*.js|*.ts|*.py)
            if [ -z "$(/usr/bin/find . -name "$marker" -not -path './.git/*' -print -quit)" ]; then
                echo "LOST FILE       $skill — SKILL.md still names '$marker' but no such file exists in the fork"
                missing=$((missing + 1))
            fi
            ;;
    esac
# The row shape is EXACT: `| \`skill\` | \`marker\` | prose |`. Requiring field 3 to be
# exactly " | " is what keeps prose tables out — an NF>=5 test also matched the
# "rows deliberately NOT in this table" section, whose cells contain backticked
# filenames, and silently invented two skills that never existed.
done < <(awk -F'`' '/^\| `/ && $3 == " | " { print $2 "\t" $4 }' "$LEDGER")

echo "divergence-check: scanned $scanned marker(s) from $LEDGER"

if [ "$scanned" -eq 0 ]; then
    echo
    echo "FAIL — 0 markers scanned. An empty or unparseable ledger is NOT a pass:"
    echo "       a check that verified nothing must not report success."
    exit 1
fi

if [ "$missing" -gt 0 ]; then
    echo
    echo "FAIL — $missing of $scanned enhancement(s) missing. Named above."
    echo "       Either upstream's merge dropped them, or the ledger is stale."
    exit 1
fi

echo "PASS — all $scanned local enhancements still present."
