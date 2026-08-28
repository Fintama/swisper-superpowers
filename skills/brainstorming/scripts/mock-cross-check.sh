#!/usr/bin/env bash
# mock-cross-check.sh — set-compare a mock's interactive elements against the spec.
#
# NOT A GATE. A tool, reached for when a mock/scaffold exists. There is no
# "every spec must pass this" step, deliberately: the grep gate that used to
# live here (spec-check.sh) was cut on 2026-08-12 because it counted strings it
# could not read and passed on `Who benefits: the system`.
#
# WHAT SURVIVED, AND WHY. §3 of a spec covers DATA CONTRACTS — request/response
# shapes, tables, event payloads. A UI spec can have a complete §3 and still
# never say what happens when you press a button that calls an EXISTING route
# with an EXISTING shape: nothing new to define, so nothing triggers. Measured
# 2026-08-07: a spec shipped `§3 N/A — no new contract` while its mock carried
# an upload, a clipboard paste, a model picker, a generate action and a
# lightbox. Every one would have reached an implementer as a guess.
#
# This is a SET COMPARISON ACROSS TWO FILES — the one thing a reader does badly
# and grep does well. That is the whole reason it is a script and the §0
# field-counting was not.
#
# The join key is `data-testid`, deliberately: it is stable, it already exists
# on this repo's interactive elements, and it is the one string a spec row and
# a mock can BOTH name. Prose descriptions ("the approve button") cannot be
# set-compared; ids can.
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
  # An interactive testid: one on a line that also carries a handler, or on a
  # <button>/<input>/<select>/<textarea>. Grep the id, then confirm the
  # element is interactive within a small window (JSX wraps across lines).
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
  echo "      Every control the mock SHOWS is a commitment (RULE 0). Give each a row:"
  echo "      element | trigger | precondition | backend call | request | response | failure | empty/loading"
else
  grn "all $FOUND interactive element(s) from the mock(s) are named in the spec"
fi

# A row that exists but leaves a cell blank is worse than a missing row: it
# reads as covered. Catch the empty-cell shapes that markdown tables produce.
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
