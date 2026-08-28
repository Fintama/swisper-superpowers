#!/usr/bin/env bash
# T-AC-7 — the positive control IS the acceptance criterion.
#
# divergence-check.sh guards the one thing this fork cannot afford to lose silently:
# the local enhancements. So it is not enough that it passes. It must be shown to
# FAIL, in both the ways it can be wrong:
#
#   arm 1  all markers present            -> green
#   arm 2  one marker deleted             -> RED, and it NAMES the enhancement
#   arm 3  the ledger emptied             -> RED, not a vacuous green
#
# Arm 3 is the one that matters. A predicate over an empty set is vacuously true, so
# a checker handed an unparsed ledger reports success having verified nothing — and
# that green is byte-identical to a real one.
set -u
cd "$(dirname "$0")/.." || exit 2
CHECK=scripts/divergence-check.sh
LEDGER=DIVERGENCE.md
fails=0
say() { printf '  %-4s %s\n' "$1" "$2"; [ "$1" = FAIL ] && fails=$((fails+1)); return 0; }

echo "T-AC-7 · divergence-check.sh fails correctly, in all three directions"
echo

if [ ! -f "$CHECK" ]; then
  say FAIL "the checker does not exist at $CHECK"
  echo; echo "FAIL — $fails arm(s)"; exit 1
fi
if [ ! -f "$LEDGER" ]; then
  say FAIL "the ledger does not exist at $LEDGER"
  echo; echo "FAIL — $fails arm(s)"; exit 1
fi

# copy aside with a checksum; every restore is verified, never assumed
cp "$LEDGER" "/tmp/div.$$.aside"
shasum "$LEDGER" > "/tmp/div.$$.sha"
restore() { cp "/tmp/div.$$.aside" "$LEDGER"; shasum -c "/tmp/div.$$.sha" >/dev/null || { echo "🔴 RESTORE FAILED"; exit 2; }; }

# ---- ARM 1 ----
if bash "$CHECK" >/tmp/div.$$.a1 2>&1; then say PASS "arm 1: all markers present -> green"
else say FAIL "arm 1: healthy ledger went RED"; sed 's/^/         /' /tmp/div.$$.a1; fi

# it must also SAY how many it looked at — a count is what makes arm 3 possible
if /usr/bin/grep -qE '[0-9]+ marker' /tmp/div.$$.a1; then
  say PASS "arm 1: reports how many markers it scanned"
else
  say FAIL "arm 1: does not report a marker COUNT — arm 3 cannot be trusted without it"
fi

# ---- ARM 2: delete ONE marker; must go red AND name it ----
victim=$(/usr/bin/grep -oE '^\| `[^`]+` \| `[^`]+`' "$LEDGER" | head -1 | sed 's/.*| `\([^`]*\)`$/\1/')
if [ -z "$victim" ]; then
  say FAIL "arm 2: could not parse a marker out of the ledger to delete"
else
  # remove the marker from the SKILLS (not from the ledger) — that is the real defect:
  # an enhancement silently lost while the ledger still claims it
  target=$(/usr/bin/grep -lF "$victim" skills/*/SKILL.md 2>/dev/null | head -1)
  if [ -z "$target" ]; then
    say FAIL "arm 2: the first ledger marker does not exist in any skill — the ledger already lies"
  else
    cp "$target" "/tmp/div.$$.skill"; shasum "$target" > "/tmp/div.$$.skillsha"
    /usr/bin/grep -vF "$victim" "/tmp/div.$$.skill" > "$target"
    if /usr/bin/grep -qF "$victim" "$target"; then
      say FAIL "arm 2: MUTATION DID NOT LAND — the marker is still in $target"
    else
      say PASS "arm 2: mutation landed (marker removed from $target)"
      if bash "$CHECK" >/tmp/div.$$.a2 2>&1; then
        say FAIL "arm 2: a MISSING enhancement went GREEN"
      else
        say PASS "arm 2: a missing enhancement goes RED"
        if /usr/bin/grep -qF "$victim" /tmp/div.$$.a2; then
          say PASS "arm 2: the failure NAMES the missing enhancement"
        else
          say FAIL "arm 2: red, but it does not name '$victim' — 'something is wrong' is not a gate"
        fi
      fi
    fi
    cp "/tmp/div.$$.skill" "$target"; shasum -c "/tmp/div.$$.skillsha" >/dev/null \
      || { echo "🔴 SKILL RESTORE FAILED"; exit 2; }
  fi
fi

# ---- ARM 3: empty the ledger. THE ARM THIS PROGRAMME KEEPS FINDING MISSING ----
: > "$LEDGER"
if [ -s "$LEDGER" ]; then say FAIL "arm 3: MUTATION DID NOT LAND — ledger is not empty"; else
  say PASS "arm 3: mutation landed (ledger emptied)"
  if bash "$CHECK" >/tmp/div.$$.a3 2>&1; then
    say FAIL "arm 3: an EMPTY ledger went GREEN — the checker verified nothing and said so"
  else
    say PASS "arm 3: an empty ledger goes RED, not vacuously green"
  fi
fi
restore

# ---- and the behaviour must come back, not merely the file ----
if bash "$CHECK" >/dev/null 2>&1; then say PASS "post-restore: the BEHAVIOUR came back, not just the bytes"
else say FAIL "post-restore: file restored but the checker still fails"; fi

rm -f /tmp/div.$$.*
echo
if [ "$fails" -gt 0 ]; then echo "FAIL — $fails arm(s)"; exit 1; fi
echo "PASS — T-AC-7 holds: the checker is green when right, red when wrong, and red when empty."
