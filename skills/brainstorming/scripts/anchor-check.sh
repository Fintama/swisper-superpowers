#!/usr/bin/env bash
# anchor-check.sh — do the spec's codebase anchors point at anything real?
#
# Compares the spec against the repo, so it can be visibly wrong. Do not add checks
# that only count strings inside the spec: those pass on `Who benefits: the system`.
#
# Checks existence only: every `path:line` resolves to a file with that many lines,
# and every `path::symbol` names a file that contains the symbol. Whether the code
# does what `today` says is a read (self-review check 7), not this.
#
# Usage:  bash anchor-check.sh <spec.md> [repo-root]        (repo-root defaults to $PWD)
# Exit:   0 = every anchor resolves, 1 = at least one does not, 2 = usage error

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
# Matches src/a/b.ts:214 and skills/x/SKILL.md:245-249 (a range checks its start).
# The extension requirement keeps prose like "p95:200" out.
echo
echo "Anchors (path:line)"
# No `mapfile`: macOS ships bash 3.2, where it fails and this script would print PASS.
ANCHORS=""
while IFS= read -r a; do ANCHORS="$ANCHORS$a
"; done < <(grep -oE '[A-Za-z0-9_./-]+\.[A-Za-z0-9]+:[0-9]+(-[0-9]+)?' "$SPEC" | sort -u)
ANCHORS=$(printf '%s' "$ANCHORS")

if [[ -z "$ANCHORS" ]]; then
  note "none in path:line form"
else
  ok=0
  while IFS= read -r a; do
    [[ -z "$a" ]] && continue
    path="${a%%:*}"; rest="${a#*:}"; line="${rest%%-*}"
    file="$ROOT/$path"
    if [[ ! -f "$file" ]]; then
      # Match the path suffix, not the basename: `brainstorming/SKILL.md` must find
      # `skills/brainstorming/SKILL.md` without matching every SKILL.md in the tree.
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
  note "none in path::symbol form — correct only if every change is ADDED"
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
