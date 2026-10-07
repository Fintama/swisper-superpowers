#!/usr/bin/env bash
# plan-check.sh: the mechanical part of the writing-plans self-review (check 1).
#
# Checks: no placeholder markers; a Goals table whose delivery column puts no
# goal after the second unit; Non-goals and the thin-baseline relationship
# stated; every spec change ID and AC ID named inside a `- [ ]` step; no code
# block under an implement step; `may_edit` / `must_not_edit` when the plan has
# a PR table. Judgement checks are left to the author.
#
# An ID named only in a table is not covered. An ID with deliberately no task is
# declared on one line, with its reason:
#   <!-- plan-check: no-task C9 C10 — Phase 2, spec §7 -->
#
# Usage:  bash plan-check.sh <plan.md> <spec.md>
# Exit:   0 = clean, 1 = failures found, 2 = usage error

set -uo pipefail

PLAN="${1:-}"; SPEC="${2:-}"
if [[ -z "$PLAN" || -z "$SPEC" || ! -f "$PLAN" || ! -f "$SPEC" ]]; then
  echo "usage: plan-check.sh <plan.md> <spec.md>" >&2
  exit 2
fi

FAIL=0
red()  { printf '  \033[31m✗\033[0m %s\n' "$*"; FAIL=1; }
grn()  { printf '  \033[32m✓\033[0m %s\n' "$*"; }
note() { printf '  \033[33m·\033[0m %s\n' "$*"; }

# Only a plan with a PR decomposition table owes per-PR authority; a Sketch's task list does not.
HAS_PR_TABLE=0
grep -qiE '^#+.*PR decomposition' "$PLAN" && HAS_PR_TABLE=1
echo "plan-check: $PLAN  (PR table: $([ $HAS_PR_TABLE = 1 ] && echo yes || echo 'no — task list'))  against $SPEC"

echo
echo "Placeholders"
PH=$(grep -nE 'TBD|TODO|FIXME|<placeholder>|implement later|fill in details' "$PLAN" || true)
if [[ -n "$PH" ]]; then
  red "placeholder markers present:"
  printf '      %s\n' "$PH"
else
  grn "none"
fi

echo
echo "Goals table (lifted from spec §0)"
# Find the delivery column by its header cell, not by grepping the file for its
# label (prose mentioning the label would pass), and read that indexed cell.
GOALROWS=$(awk -F'|' '
  BEGIN { col = 0; rows = 0 }
  /^[[:space:]]*\|/ {
    if (col == 0) {
      for (i = 2; i < NF; i++) {
        c = $i; gsub(/^[[:space:]]+|[[:space:]]+$/, "", c)
        lc = tolower(c)
        # A header cell, not a sentence.
        if (length(c) <= 60 && (lc ~ /first delivered in/ || lc ~ /first touches/ || lc ~ /delivered in/)) {
          col = i; break
        }
      }
      if (col > 0) next                 # that row was the header itself
    }
    # Goal id in the first cell only: other tables can mention a G-n in a later column.
    if (col > 0 && $2 ~ /G-[0-9]/) {
      goal = $2; gsub(/^[[:space:]]+|[[:space:]]+$/, "", goal)
      gid = (match(goal, /G-[0-9]+/)) ? substr(goal, RSTART, RLENGTH) : "G-?"
      cell = (col <= NF) ? $col : ""
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", cell)
      rows++
      print gid "\t" cell
    }
  }
  END {
    if (col == 0)        print "!NOCOL\t"
    else if (rows == 0)  print "!NOROWS\t"
  }
' "$PLAN")

if grep -q '^!NOCOL' <<<"$GOALROWS"; then
  red "no goals-table column naming where each goal is first delivered"
  note "    it may be headed \"First delivered in\" or \"PR that first touches it\","
  note "    but it must be a CELL in the goals-table header — a sentence in the"
  note "    prose is not a column."
elif grep -q '^!NOROWS' <<<"$GOALROWS"; then
  red "goals table has a delivery column but no \`G-n\` rows under it"
else
  grn "delivery column located by header position ($(grep -c . <<<"$GOALROWS") goal row(s))"

  LATE=0; UNPARSED=0; EMPTY=0
  while IFS=$'\t' read -r goal cell; do
    [[ -z "$goal" ]] && continue
    if [[ -z "$cell" || "$cell" =~ ^(\.\.\.|TBD|\?)$ ]]; then
      red "$goal has an empty delivery cell"; EMPTY=1; continue
    fi
    n=$(grep -oiE '\b(PR|CG)-?[0-9]+' <<<"$cell" | grep -oE '[0-9]+' | head -1)
    if [[ -z "$n" ]]; then
      # "this plan" is the task-list form; any other unparseable cell is a failure, never skipped.
      if grep -qiE 'this plan' <<<"$cell"; then continue; fi
      red "$goal's delivery cell names no PR/CG and is not \"this plan\": \"$cell\""
      note "    is the delivery column still where the header says it is?"
      UNPARSED=1; continue
    fi
    if (( n > 2 )); then
      red "$goal is first delivered in $cell — later than the second unit"
      LATE=1
    fi
  done <<<"$GOALROWS"
  (( EMPTY || UNPARSED )) || grn "every goal row names a delivery unit"
  if (( LATE )); then
    note "    decomposition is by architectural layer: the user sees nothing until the end."
    note "    Redo it, or state the reason in the plan (self-review check 2)."
  elif (( UNPARSED == 0 && EMPTY == 0 )); then
    grn "no goal first delivered later than the second unit"
  fi
  # Each summary line is gated only on the condition it describes.
  if (( UNPARSED || EMPTY )); then
    note "    delivery order NOT fully established — a goal row above could not be read."
  fi
fi
grep -qiE 'non-goals?' "$PLAN" && grn "Non-goals lifted from spec" || red "Non-goals not lifted from spec §0"
grep -qiE 'thin baseline' "$PLAN" && grn "thin-baseline relationship stated" || red "PR-1's relationship to §0.1's thin baseline is not stated"

# The plan's task steps: the only place an ID counts as covered.
STEPS=$(grep -E '^[[:space:]]*-[[:space:]]*\[[ x]\]' "$PLAN" || true)
# IDs the plan explicitly declares as having no task, with a reason on the line.
EXEMPT=$(grep -oE '<!--[[:space:]]*plan-check:[[:space:]]*no-task[^>]*-->' "$PLAN" || true)

# covered <ID> -> 0 in a step | 1 exempt | 2 mentioned but never in a step | 3 absent
covered() {
  local id="$1"
  grep -qE "\b$id\b" <<<"$STEPS" && return 0
  grep -qE "\b$id\b" <<<"$EXEMPT" && return 1
  grep -qE "\b$id\b" "$PLAN" && return 2
  return 3
}

report_coverage() {
  local label="$1" kind="$2"; shift 2
  local ids=("$@")
  local instep=0 exempt="" mentioned="" absent=""
  for id in "${ids[@]}"; do
    covered "$id"
    case $? in
      0) instep=$((instep+1)) ;;
      1) exempt="$exempt $id" ;;
      2) mentioned="$mentioned $id" ;;
      3) absent="$absent $id" ;;
    esac
  done
  (( instep > 0 )) && grn "$instep $label in a \`- [ ]\` step"
  [[ -n "$exempt" ]] && note "declared exempt (no task, reason recorded):$exempt"
  if [[ -n "$mentioned" ]]; then
    red "$label MENTIONED but in no \`- [ ]\` step —$mentioned"
    note "    a PR table or a risks table is not a task. Add the $kind, or declare"
    note "    it exempt: <!-- plan-check: no-task$mentioned — why -->"
  fi
  [[ -n "$absent" ]] && red "$label absent from the plan entirely —$absent"
  return 0
}

echo
echo "Change-ID coverage (spec §1 → plan tasks)"
# Accept `C1` and `C-1`. A spec that numbers something else `X-n` (old amendment
# ids like `A-4`) shows up as uncovered; exempt it with `no-task` rather than
# narrowing the pattern, since a narrow pattern reports an empty set as a pass.
IDS=$(grep -oE '\b[ACN]-?[0-9]{1,3}\b' "$SPEC" | sort -u)
if [[ -z "$IDS" ]]; then
  note "no change IDs matched \`[ACN]-?<n>\` in $SPEC — N/A only if §1 numbers no changes"
  note "    if the spec does number its changes, this is a false pass: check the ID form."
else
  note "scanned $SPEC — $(wc -w <<<"$IDS" | tr -d ' ') distinct change ID(s) found"
  # shellcheck disable=SC2086
  report_coverage "change ID(s)" "implement step" $IDS
fi

echo
echo "AC coverage (spec ACs → AC-named test tasks)"
ACS=$(grep -oE '\b[BT]-AC-[0-9]{1,3}\b' "$SPEC" | sort -u)
if [[ -z "$ACS" ]]; then
  note "spec declares no ACs — N/A (correct for a Sketch with no behaviour change)"
else
  # shellcheck disable=SC2086
  report_coverage "AC(s)" "test task" $ACS
fi

echo
echo "Reference-don't-duplicate (forbidden blocks)"
# A code fence within six lines under an implement step is a pasted body. Disarm at
# the next step, so a short snippet in the following step is not reported.
SUSPECT=$(awk '
  /^[[:space:]]*-?[[:space:]]*\[[ x]\][[:space:]]*\*\*Step .*[Ii]mplement/ { armed=NR; next }
  /^[[:space:]]*-?[[:space:]]*\[[ x]\]/ { armed=0; next }
  /^[[:space:]]*```/ && armed && NR-armed<=6 { print armed": implementation step followed by a code fence at line "NR; armed=0 }
  /^[[:space:]]*$/ { next }
' "$PLAN")
if [[ -n "$SUSPECT" ]]; then
  red "implementation step(s) carrying an inline code block — reference the spec instead:"
  printf '      %s\n' "$SUSPECT"
else
  grn "no implementation step carries a pasted body"
fi

if (( HAS_PR_TABLE )); then
  echo
  echo "Per-PR authority (what is mine, and what is NOT)"
  for field in may_edit must_not_edit; do
    if grep -qE "\b${field}\b" "$PLAN"; then
      grn "$field declared"
    else
      red "no \`$field\` anywhere — every PR owes it, with a reason for the negatives"
    fi
  done
fi

echo
if (( FAIL )); then
  echo "FAIL — fix the above, or declare an exemption, and re-run."
  exit 1
fi
echo "PASS — mechanical checks clean. Checks 2-5 are yours."
