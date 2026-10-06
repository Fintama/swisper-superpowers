#!/usr/bin/env bash
# Has a local enhancement disappeared? Reads DIVERGENCE.md and fails, naming the
# enhancement, when a marker is missing from its skill (an upstream merge can drop one silently).
#
#   exit 0  every marker still present
#   exit 1  a marker is missing, or the ledger is empty/unparseable
#   exit 2  the checker could not run
#
# It prints how many markers it scanned and fails on zero, so an unparsed ledger is not a pass.
set -u
cd "$(dirname "$0")/.." || exit 2

LEDGER=${1:-DIVERGENCE.md}
[ -f "$LEDGER" ] || { echo "divergence-check: no ledger at $LEDGER"; exit 2; }

scanned=0
missing=0

# Backtick as the field separator: markers contain apostrophes and commas.
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
    # A marker that names a file must also find the file, or a merge that deleted a
    # script but kept the prose naming it would pass. Search by basename anywhere in the
    # fork: tooling often ships in a different skill (or the repo root) than the one naming it.
    case "$marker" in
        *.sh|*.mjs|*.js|*.ts|*.py|*.md)
            if [ -z "$(/usr/bin/find . -name "$marker" -not -path './.git/*' -print -quit)" ]; then
                echo "LOST FILE       $skill — SKILL.md still names '$marker' but no such file exists in the fork"
                missing=$((missing + 1))
            fi
            ;;
    esac
# Only rows shaped exactly `| \`skill\` | \`marker\` | prose |` count; field 3 must be " | ",
# which keeps tables whose prose cells hold backticked names from being read as rows.
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
