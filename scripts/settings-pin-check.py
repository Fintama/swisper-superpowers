#!/usr/bin/env python3
"""Pin (C5): nothing in this repo may edit the user's own SessionStart hook in ~/.claude/settings.json.

That hook is the user's, not the one this plugin ships. The check hashes the
SessionStart block only, not the whole file, so an unrelated settings edit is not a red.

  --capture   record the current SessionStart block as the baseline
  (default)   compare the current block against the baseline, naming SessionStart
"""
import hashlib
import json
import sys
from pathlib import Path

SETTINGS = Path.home() / ".claude" / "settings.json"
BASELINE = Path("/tmp/settings-sessionstart.baseline")


def block():
    if not SETTINGS.exists():
        sys.exit(f"CANNOT RUN: no settings at {SETTINGS}")
    try:
        data = json.loads(SETTINGS.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        sys.exit(f"CANNOT RUN: {SETTINGS} is not valid JSON — {e}")
    return json.dumps(data.get("hooks", {}).get("SessionStart", None),
                      sort_keys=True, ensure_ascii=False)


def main():
    b = block()
    digest = hashlib.sha256(b.encode()).hexdigest()[:16]

    if "--capture" in sys.argv:
        BASELINE.write_text(b, encoding="utf-8")
        print(f"captured SessionStart baseline ({len(b)} chars, {digest})")
        return 0

    if not BASELINE.exists():
        sys.exit(f"CANNOT RUN: no baseline. Run with --capture first.")

    want = BASELINE.read_text(encoding="utf-8")
    if b == want:
        print(f"PASS — settings.json `hooks.SessionStart` is unchanged ({digest})")
        return 0

    # Name the thing. "settings.json changed" is not this check's job.
    print("FAIL — `hooks.SessionStart` in ~/.claude/settings.json HAS CHANGED.")
    print(f"       baseline: {len(want)} chars / {hashlib.sha256(want.encode()).hexdigest()[:16]}")
    print(f"       now:      {len(b)} chars / {digest}")
    print("       This work must not edit the user's own SessionStart hook.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
