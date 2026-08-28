#!/usr/bin/env bash
# plan-check.sh — the mechanical half of the plan self-review (check 1) and of
# the plan review's Gate 2(a).
#
# Asserts what can be asserted without judgement:
#   · no placeholder markers
#   · the Goals table exists, its delivery column is located BY HEADER POSITION
#     (whatever it is called), and no goal is first delivered after the 2nd unit
#   · every artifact ID in the spec's inventory is named by at least one task
#   · every AC ID in the spec has a test task naming it verbatim
#
# ⚠ "named by a task" means named INSIDE a `- [ ]` step. Naming an ID in a PR
# table, a risks table or an "IDs deliberately absent" section is NOT a task, and
# an earlier version of this script accepted it — so a plan could claim an AC in
# its PR table, have no test for it, and pass. Measured 2026-08-07 on the
# detection plan: 4 of 15 ACs had no test task and this script said "all 15
# covered". An ID with no task is declared exempt on one line, which makes
# declining first-class and visible (see review-termination.md Rule 1b):
#
#   <!-- plan-check: no-task A8 C9 C10 C11 — Phase 2, spec §6 -->
#
# Everything not exempt must sit in a `- [ ]` step.
#   · no forbidden code blocks (full source bodies / re-stated signatures)
#
# Everything requiring judgement — is PR-1 the thin baseline, does a task serve a
# non-goal, is this sequencing wasteful — is left to the human/agent checks.
#
# Usage:  bash plan-check.sh <plan.md> <spec.md>
# Exit:   0 = clean, 1 = failures found, 2 = usage error
#
# Positive-control it before trusting it: delete the task naming one artifact ID
# and confirm this goes red. A gate never seen failing is a claim, not a
# measurement.

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

# A plan with a PR decomposition table owes per-PR authority and single-PR change
# coverage. A task-list plan (Sketch class) owes neither, and reporting them as
# gaps would be reviewing the class rather than the plan.
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
# 🔴 2026-08-25 — THIS BLOCK WAS GREEN ON THE OBITUARY OF THE THING IT CHECKS.
# It used to gate on `grep -qE 'First delivered in' "$PLAN"`: a whole-file grep
# for a COLUMN LABEL. Three failures, all measured against fixtures, all silent:
#
#   1. The column was renamed to "PR that first touches it". The gate stayed
#      green on PROSE mentioning the old name — including the very paragraph
#      written to document the rename. Documenting the defect fed it: the more
#      carefully you explained it, the more certainly the check stayed green.
#      (WS1, Foundry, on the agents-in-the-dev-container plan.)
#   2. With that prose removed, a PERFECTLY WELL-FORMED renamed table FAILED.
#      A table that does not exist passed; a correct one did not.
#   3. 🔴 The worst, and the one nobody reported: keep the original label and add
#      a "State today" column AFTER it. The gate passes, then the parser reads
#      the LAST cell — "🟡 half" — finds no PR number, and `continue`s. Result:
#      "✓ no goal first delivered later than the second unit" printed over a goal
#      first delivered in PR-7. That is exactly the 2026-07-29 Foundry failure
#      this column exists to catch, passing silently.
#
# A LABEL IS NOT A STRUCTURE, and a column's POSITION is not its identity. Find
# the delivery column by header position, accept either name, read that indexed
# cell — and never skip a cell you cannot parse.
GOALROWS=$(awk -F'|' '
  BEGIN { col = 0; rows = 0 }
  /^[[:space:]]*\|/ {
    if (col == 0) {
      for (i = 2; i < NF; i++) {
        c = $i; gsub(/^[[:space:]]+|[[:space:]]+$/, "", c)
        lc = tolower(c)
        # A header CELL, not a sentence: short, and inside a table row.
        if (length(c) <= 60 && (lc ~ /first delivered in/ || lc ~ /first touches/ || lc ~ /delivered in/)) {
          col = i; break
        }
      }
      if (col > 0) next                 # that row was the header itself
    }
    # FIRST CELL only. `^\|.*\bG-[0-9]` also matched a commit-group table whose
    # "Delivers" column named G-3, and then parsed that row for a PR number.
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
  note "    prose is not a column, and used to satisfy this check."
elif grep -q '^!NOROWS' <<<"$GOALROWS"; then
  red "goals table has a delivery column but no \`G-n\` rows under it"
else
  grn "delivery column located by header position ($(grep -c . <<<"$GOALROWS") goal row(s))"

  # 🔴 Compare the VALUE, not its presence. Until 2026-08-12 this script checked
  # only that the cell was non-empty — so a plan whose goal first landed in PR-7
  # printed PASS (Foundry 2026-07-29: UBER-AC-1 verified by PR-7 of 10, a full
  # day of correct backend merged with nothing the user could see).
  LATE=0; UNPARSED=0; EMPTY=0
  while IFS=$'\t' read -r goal cell; do
    [[ -z "$goal" ]] && continue
    if [[ -z "$cell" || "$cell" =~ ^(\.\.\.|TBD|\?)$ ]]; then
      red "$goal has an empty delivery cell"; EMPTY=1; continue
    fi
    n=$(grep -oiE '\b(PR|CG)-?[0-9]+' <<<"$cell" | grep -oE '[0-9]+' | head -1)
    if [[ -z "$n" ]]; then
      # "this plan" is the legitimate task-list form. ANYTHING ELSE unparseable
      # used to be skipped silently, which is how failure 3 above went green.
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
  # ⚠ This line used to read "every goal row has a delivery target" and was gated
  # on EMPTY alone — so a row whose cell was non-empty but UNPARSEABLE got a red
  # and this ✓ on adjacent lines, disagreeing about the same row. The verdict was
  # never wrong (the red is right there, the gate fails), but the WORDS claimed
  # more than the check: it meant "non-empty", not "names a target". Caught by WS1
  # 2026-08-25 while controlling the fix on a real plan. Say only what is checked.
  (( EMPTY || UNPARSED )) || grn "every goal row names a delivery unit"
  if (( LATE )); then
    note "    decomposition is by architectural layer: the user sees nothing until the end."
    note "    Redo it, or state in the plan why each unit is independently useful."
  elif (( UNPARSED == 0 && EMPTY == 0 )); then
    grn "no goal first delivered later than the second unit"
  fi
  # ⚠ THIRD instance of one shape in this block, and each fix exposed the next:
  #   1. the ✓ printed over a row that redded          (WS1 found it)
  #   2. its SIBLING ✓ did the same                    (my control found it)
  #   3. this note was nested in the `else` of (2), so a DIFFERENT row redding
  #      for lateness swallowed it entirely             (WS1 found it, on its
  #      own file, because LATE and EMPTY were both set)
  # All three are one mistake: TYING A LINE'S EMISSION TO A CONDITION IT DOES NOT
  # DESCRIBE. This note describes unread rows, so it is gated on unread rows and
  # on nothing else.
  if (( UNPARSED || EMPTY )); then
    note "    delivery order NOT fully established — a goal row above could not be read."
  fi
fi
grep -qiE 'non-goals?' "$PLAN" && grn "Non-goals lifted from spec" || red "Non-goals not lifted from spec §0"
grep -qiE 'thin baseline' "$PLAN" && grn "thin-baseline relationship stated" || red "PR-1's relationship to §0.1's thin baseline is not stated"

# The plan's task steps — the ONLY place an ID counts as covered.
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
echo "Artifact-ID coverage (spec inventory → plan tasks)"
# 🔴 2026-08-25 — THIS PRINTED "N/A" OVER A 23-ARTIFACT PROGRAMME SPEC.
# The pattern was `\b[ACN][0-9]{1,3}\b` — NO HYPHEN — so it never matched the
# `A-1`…`A-21` form and reported "spec declares no artifact inventory". The AC
# pattern one block below DOES carry hyphens (`[BT]-AC-[0-9]`), which is exactly
# why AC coverage worked and artifact coverage silently did not: two ID
# conventions in one file, one of them unmatched.
#
# **This is a vacuous truth, not a miss.** `$IDS` was empty, so the `-z` branch
# was *correct* about the set it had — and the set was empty because the pattern
# built it wrong. The N/A line even asserts a REASON ("correct for a Sketch")
# that was false: the spec was a Programme. Proven by WS2 — stripping the hyphens
# from a scratch copy made it fire instantly, naming 18 absent artifacts.
#
# Accept BOTH forms, and never claim "no inventory" without saying what was scanned.
#
# ⚠ THE FIX IS NOT FREE, and the trade is deliberate. `A-<n>` collides with the
# §8 amendment convention some specs use ("A-4 · 2026-08-24, at plan time — …").
# Measured on `2026-08-24-asset-drawer-spec.md`: A-4/A-5/A-6 are AMENDMENTS and
# are now reported as uncovered artifacts. That is a FALSE POSITIVE.
#
# It is still the right trade: this swaps a SILENT false negative (23 artifacts
# reported as "no inventory") for a VISIBLE false positive a human resolves in
# one line with the `no-task` exemption. **A wrong answer you can see beats a
# right-looking answer over an empty set.** If the noise becomes a problem, the
# real fix is to scope extraction to the inventory SECTION rather than the whole
# file — do that rather than narrowing the pattern back.
IDS=$(grep -oE '\b[ACN]-?[0-9]{1,3}\b' "$SPEC" | sort -u)
if [[ -z "$IDS" ]]; then
  note "no artifact IDs matched \`[ACN]-?<n>\` in $SPEC — N/A only if this is a Sketch"
  note "    ⚠ if the spec HAS an inventory, this line is a FALSE PASS: check the ID form."
else
  note "scanned $SPEC — $(wc -w <<<"$IDS" | tr -d ' ') distinct artifact ID(s) found"
  # shellcheck disable=SC2086
  report_coverage "artifact ID(s)" "implement step" $IDS
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
# A code fence immediately under a "Implement A<n>" step is the classic violation.
# ⚠ DISARM at the next step. Without the second rule the 6-line window runs past
# the end of an implement step and into the NEXT step's fence — and when that
# next step is "Failing test …", the fence is a TEST BODY, which this rule
# explicitly allows. Measured 2026-08-07: two such false positives on the
# detection plan, both pointing at a legitimate test one step further down.
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
  # Measured 2026-08-12 across 153 plans: 14 declared tasks parallelizable with
  # each other; 3 said what the parallel task may not touch. A positive-only file
  # list is half of what a fresh subagent needs, and the missing half is the half
  # that causes merge conflicts and rebuilt screens.
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
  echo "FAIL — fix the above before dispatching Gate 1."
  exit 1
fi
echo "PASS — mechanical checks clean. Checks 2-4 are yours."
