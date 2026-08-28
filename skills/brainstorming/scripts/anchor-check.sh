#!/usr/bin/env bash
# anchor-check.sh — do the spec's codebase anchors point at anything real?
#
# WHY THIS ONE IS A GATE, when the grep gate that used to live here was NOT.
# A mechanical check earns its place when it compares TWO INDEPENDENT SOURCES and
# can therefore be visibly wrong. This compares the SPEC against the REPO. The
# gate cut on 2026-08-12 (spec-check.sh) counted strings inside the document it
# was checking, so it could only ever report that the string was present:
# `Who benefits: the system` passed it. Do not add anything of that shape here.
#
# WHAT IT CHECKS — existence only:
#   · every `path:line` anchor resolves to a file that exists
#   · the line number is inside that file
#   · every `path::symbol` seam names a file that exists, and the symbol appears in it
#
# WHAT IT DOES NOT CHECK, deliberately:
#   whether the code at the anchor actually DOES what `today` says. That is a
#   read, and it is spec-review Gate 2's job. A script cannot judge it, and a
#   script that pretended to would be the cut gate wearing a new name.
#
# Usage:  bash anchor-check.sh <spec.md> [repo-root]        (repo-root defaults to $PWD)
# Exit:   0 = every anchor resolves, 1 = at least one does not, 2 = usage error
#
# Positive-control it before trusting it: break one anchor on purpose and confirm
# it goes red, then restore. A gate never seen failing is a claim, not a
# measurement.

set -uo pipefail

SPEC="${1:-}"; ROOT="${2:-$PWD}"
if [[ -z "$SPEC" || ! -f "$SPEC" ]]; then
  echo "usage: anchor-check.sh <spec.md> [repo-root]" >&2
  exit 2
fi
[[ -d "$ROOT" ]] || { echo "repo root not a directory: $ROOT" >&2; exit 2; }

FAIL=0
red() { printf '  \033[31m✗\033[0m %s\n' "$*"; FAIL=1; }
grn() { printf '  \033[32m✓\033[0m %s\n' "$*"; }
note(){ printf '  \033[33m·\033[0m %s\n' "$*"; }

echo "anchor-check: $SPEC  against  $ROOT"

# ---- path:line anchors -------------------------------------------------------
# Matches src/a/b.ts:214 and skills/x/SKILL.md:245-249 (range → check the start).
# Requires a path separator or an extension so prose like "Foundry 2026-07-29"
# and "p95:200" are not mistaken for anchors.
echo
echo "Anchors (path:line)"
# NOTE: `mapfile` is a bash 4 builtin and macOS ships bash 3.2, where it fails
# and — because this script does not `set -e` — the run continued and printed
# PASS. A false green, in the gate written to catch false greens. Caught by the
# positive control on the first run, 2026-08-12. Portable read loop instead.
ANCHORS=""
while IFS= read -r a; do ANCHORS="$ANCHORS$a
"; done < <(grep -oE '[A-Za-z0-9_./-]+\.[A-Za-z0-9]+:[0-9]+(-[0-9]+)?' "$SPEC" | sort -u)
ANCHORS=$(printf '%s' "$ANCHORS")

if [[ -z "$ANCHORS" ]]; then
  note "none found — correct for a spec whose changes are all ADDED, suspicious otherwise"
else
  ok=0
  while IFS= read -r a; do
    [[ -z "$a" ]] && continue
    path="${a%%:*}"; rest="${a#*:}"; line="${rest%%-*}"
    file="$ROOT/$path"
    if [[ ! -f "$file" ]]; then
      # Match on the PATH SUFFIX, not the basename. A spec that writes
      # `brainstorming/SKILL.md` inside a repo whose file is at
      # `skills/brainstorming/SKILL.md` is being reasonable; matching on the
      # basename alone would make every SKILL.md in the tree a candidate and
      # report "ambiguous" for all of them. Measured on the first real run.
      hits=$(find "$ROOT" -path "*/$path" -not -path '*/.git/*' -not -path '*/node_modules/*' 2>/dev/null | head -3)
      cnt=$(printf '%s' "$hits" | grep -c . || true)
      if (( cnt == 0 )); then
        red "$a — no such file"
        continue
      elif (( cnt > 1 )); then
        red "$a — matches $cnt files; write it relative to the repo root"
        continue
      fi
      file="$hits"
    fi
    total=$(wc -l < "$file")
    if (( line > total )); then
      red "$a — file has only $total lines"
    else
      ok=$((ok+1))
    fi
  done <<< "$ANCHORS"
  (( ok > 0 )) && grn "$ok anchor(s) resolve to a real file and line"
fi

# ---- path::symbol seams ------------------------------------------------------
echo
echo "Seams (path::symbol)"
SEAMS=""
while IFS= read -r x; do SEAMS="$SEAMS$x
"; done < <(grep -oE '[A-Za-z0-9_./-]+\.[A-Za-z0-9]+::[A-Za-z_][A-Za-z0-9_]*' "$SPEC" | sort -u)
SEAMS=$(printf '%s' "$SEAMS")

if [[ -z "$SEAMS" ]]; then
  note "none in path::symbol form"
else
  ok=0
  while IFS= read -r s; do
    [[ -z "$s" ]] && continue
    path="${s%%::*}"; sym="${s##*::}"
    file="$ROOT/$path"
    [[ -f "$file" ]] || file=$(find "$ROOT" -path "*/$path" -not -path '*/.git/*' -not -path '*/node_modules/*' 2>/dev/null | head -1)
    if [[ -z "$file" || ! -f "$file" ]]; then
      red "$s — no such file"
    elif ! grep -qF "$sym" "$file"; then
      red "$s — file exists, but \`$sym\` does not appear in it"
    else
      ok=$((ok+1))
    fi
  done <<< "$SEAMS"
  (( ok > 0 )) && grn "$ok seam(s) name a symbol that exists in the named file"
fi

echo
if (( FAIL )); then
  echo "FAIL — the spec points at something that is not there."
  echo "       Re-ground it (prism def / body, else grep) before dispatching anything."
  exit 1
fi
echo "PASS — every anchor resolves. Whether the code DOES what \`today\` says is a read, not this."
