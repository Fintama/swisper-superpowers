#!/usr/bin/env bash
# mock-cross-check.sh — set-compare a mock's interactive elements against the spec.
#
# A tool for when a mock exists, not a gate every spec must pass. A spec can have a
# complete §3 and still never say what a button that calls an existing route does;
# this lists every interactive `data-testid` in the mock that the spec never names,
# and every table row with an empty cell (an empty cell reads as covered).
#
# Usage:  bash mock-cross-check.sh <spec.md> <mock.tsx> [mock2.tsx ...]
# Exit:   0 = every interactive element is named in the spec, 1 = gaps, 2 = usage

set -uo pipefail

SPEC="${1:-}"
if [[ -z "$SPEC" || ! -f "$SPEC" || $# -lt 2 ]]; then
  echo "usage: mock-cross-check.sh <spec.md> <mock.tsx> [mock2.tsx ...]" >&2
  exit 2
fi

FAIL=0
red()  { printf '  \033[31m✗\033[0m %s\n' "$*"; FAIL=1; }
grn()  { printf '  \033[32m✓\033[0m %s\n' "$*"; }
note() { printf '  \033[33m·\033[0m %s\n' "$*"; }

echo "mock-cross-check: $SPEC"
echo

MOCKS=("${@:2}")
MISSING=""
FOUND=0
for m in "${MOCKS[@]}"; do
  [[ -f "$m" ]] || { red "mock not found: $m"; continue; }
  # Interactive = a handler or a form element within a few lines of the id (JSX wraps).
  while IFS= read -r tid; do
    [[ -n "$tid" ]] || continue
    ctx=$(grep -A6 -B6 -F "data-testid=\"$tid\"" "$m" 2>/dev/null || true)
    if grep -qE 'onClick|onChange|onSubmit|onDrop|onPaste|onKeyDown|<button|<input|<select|<textarea' <<<"$ctx"; then
      FOUND=$((FOUND+1))
      grep -qF "$tid" "$SPEC" || MISSING+="      $tid  ($m)"$'\n'
    fi
  done < <(grep -oE 'data-testid="[^"]+"' "$m" 2>/dev/null | sed 's/data-testid="//;s/"$//' | sort -u)
done

if (( FOUND == 0 )); then
  note "no interactive data-testid found in the given mock(s) — nothing to cross-check"
elif [[ -n "$MISSING" ]]; then
  red "$FOUND interactive element(s) in the mock; these appear NOWHERE in the spec:"
  printf '%s' "$MISSING"
  echo "      Every control the mock shows is a commitment. Give each a row:"
  echo "      element | trigger | precondition | backend call | request | response | failure | empty/loading"
else
  grn "all $FOUND interactive element(s) from the mock(s) are named in the spec"
fi

BLANK=$(grep -nE '\|\s*(\|\s*){2,}' "$SPEC" | grep -vE '^\s*[0-9]+:\s*\|[\s|:-]*\|\s*$' || true)
if [[ -n "$BLANK" ]]; then
  red "table row(s) with empty cells — an unfilled cell reads as specified:"
  printf '      %s\n' "$BLANK"
else
  grn "no empty table cells"
fi

echo
if (( FAIL )); then
  echo "FAIL — every control the mock shows needs a row in the spec."
  exit 1
fi
echo "PASS"
