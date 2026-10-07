#!/usr/bin/env python3
"""T-AC-2 — program.yaml round-trips: every field read back equals what was written.

Every assertion re-reads the file on disk; an in-memory comparison passes even if
the writer never flushed.

Run:  python3 scripts/program-yaml-check.py
Exit: 0 all arms pass · 1 an arm failed · 2 the checker itself could not run
"""
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

try:
    from program_yaml import ProgramYamlError, dump, load
except ModuleNotFoundError as exc:
    if exc.name == "yaml":
        sys.exit(
            "CHECKER CANNOT RUN: PyYAML is not installed for this interpreter\n"
            f"  interpreter: {sys.executable}\n"
            "  fix:         python3 -m pip install pyyaml\n"
            "  ⚠ macOS system python3 (3.9.6) ships WITHOUT PyYAML."
        )
    sys.exit(f"CHECKER CANNOT RUN: {exc}")

FIXTURE = {
    "program": "Swisper Foundry",
    "repo": "/Users/x/Projects/swisper_foundry",
    "board": {"dir": ".handover/board", "port": 8794},
    "goals": [
        {"id": "G-1", "text": "Run the programme without Heiko in the room",
         "proof": "UBER-AC-1"},
        {"id": "G-2", "text": "Talk to a lane without breaking the programme",
         "proof": "UBER-AC-2"},
    ],
    "lanes": [
        {"name": "WS5", "id": "WS5-6", "session": "9f2c1a", "scope": "platform",
         "worktree": "/Users/x/wt/ws5", "branch": "feature/ws5",
         "rig": {"frontend": "http://localhost:3176", "backend": "http://localhost:3177",
                 "db": "postgres://localhost:5442/foundry", "project": "foundry-ws5"}},
    ],
}

failures = []


def check(name, condition, detail=""):
    print(f"  {'PASS' if condition else 'FAIL'}  {name}" + (f"  — {detail}" if detail and not condition else ""))
    if not condition:
        failures.append(name)


def main():
    print("T-AC-2 · program.yaml round-trips  (observed_at: the file on disk)\n")

    with tempfile.TemporaryDirectory() as d:
        path = Path(d) / "program.yaml"

        # ---- ARM 1: the round trip, read back FROM DISK ----
        # Wrapped: a real defect here raises, and an uncaught raise would skip the
        # later arms and print a traceback instead of a verdict.
        try:
            dump(FIXTURE, path)
            check("the writer actually created a file", path.exists())
            check("the file is non-empty", path.exists() and path.stat().st_size > 0)
            back = load(path)
            check("every field read back equals what was written", back == FIXTURE,
                  f"differs: {[k for k in FIXTURE if back.get(k) != FIXTURE[k]]}")

            # a nested value, named: a top-level compare passes a reader that flattens nested keys
            check("nested board.port survives as an int, not a string",
                  back["board"]["port"] == 8794 and isinstance(back["board"]["port"], int),
                  f"got {back['board']['port']!r}")
            check("nested lane rig survives whole",
                  back["lanes"][0]["rig"] == FIXTURE["lanes"][0]["rig"])
            check("goal order is preserved",
                  [g["id"] for g in back["goals"]] == ["G-1", "G-2"])
        except Exception as e:  # noqa: BLE001 - a raise here IS the failure
            check("the round trip completes without raising", False,
                  f"{type(e).__name__}: {e}")

        # ---- ARM 2 (the AC's negative case): a malformed lane fails loudly ----
        # Raw text, not dump(): this arm tests the reader, so a broken writer must not turn it red.
        bad_path = Path(d) / "bad.yaml"
        bad_path.write_text(
            "program: Swisper Foundry\n"
            "repo: /Users/x/Projects/swisper_foundry\n"
            "board:\n  dir: .handover/board\n  port: 8794\n"
            "goals:\n  - id: G-1\n    text: t\n    proof: UBER-AC-1\n"
            "lanes:\n  - name: WS5\n    session: 9f2c1a\n",  # no `id`
            encoding="utf-8",
        )
        try:
            load(bad_path)
            check("a lane missing `id` is rejected", False, "load() accepted it silently")
        except ProgramYamlError as e:
            check("a lane missing `id` is rejected", True)
            check("the error NAMES the missing field", "id" in str(e), f"said: {e}")
            check("the error names WHICH lane", "WS5" in str(e), f"said: {e}")

        # ---- ARM 3: the checker must be able to fail. Prove it. ----
        try:
            load(Path(d) / "does-not-exist.yaml")
            check("a missing file is rejected", False, "load() invented a programme")
        except (ProgramYamlError, FileNotFoundError):
            check("a missing file is rejected", True)

    print()
    if failures:
        print(f"FAIL — {len(failures)} arm(s): {', '.join(failures)}")
        return 1
    print("PASS — T-AC-2 holds, and both negative arms fired.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
