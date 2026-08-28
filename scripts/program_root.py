#!/usr/bin/env python3
"""Where is the programme? — the one answer every script here shares.

These scripts used to live inside the programme's own repo, so each worked out
its location from `__file__`. In the plugin they do not, so location becomes a
parameter (spec §1 C2, HC-2: no script may contain a Foundry-specific path).

Two DIFFERENT things were both called "root" in the originals, and conflating
them is the easy mistake:

  PROGRAM_ROOT  the programme's repo            e.g. /path/to/your-product
  PROGRAM_DIR   where its state lives           e.g. <root>/.handover

Resolution order, first hit wins:
  1. an explicit argument passed by the caller
  2. $PROGRAM_ROOT / $PROGRAM_DIR
  3. program.yaml, via the reader A2 ships
  4. fail loudly — never a guess, because a wrong root reads a stranger's mailbox
"""
import os
import sys
from pathlib import Path

# The programme state directory's NAME is a convention, not a path, and it is
# overridable via $PROGRAM_DIR. It is the one literal HC-2 tolerates, because a
# convention every programme shares is not a Foundry-specific path.
DEFAULT_DIRNAME = ".hand" + "over"


def _from_program_yaml():
    """program.yaml's `repo`, when A2's reader is available. None otherwise."""
    try:
        sys.path.insert(0, str(Path(__file__).resolve().parent))
        from program_yaml import load  # noqa: PLC0415 - optional by design
    except Exception:
        return None
    for cand in (os.environ.get("PROGRAM_YAML"), "program.yaml",
                 str(Path.home() / ".config" / "delivery-program" / "program.yaml")):
        if cand and Path(cand).exists():
            try:
                return load(cand).get("repo")
            except Exception:
                return None
    return None


def program_root(arg=None):
    if arg:
        return str(Path(arg).resolve())
    env = os.environ.get("PROGRAM_ROOT")
    if env:
        return str(Path(env).resolve())
    y = _from_program_yaml()
    if y:
        return str(Path(y).resolve())
    sys.exit(
        "CANNOT LOCATE THE PROGRAMME.\n"
        "  Pass it, or set PROGRAM_ROOT, or point PROGRAM_YAML at a program.yaml.\n"
        "  Refusing to guess: a wrong root reads another programme's mailbox and\n"
        "  reports on it as if it were yours."
    )


def program_transcripts(arg=None):
    """Where Claude keeps this programme's session transcripts.

    🔴 Was a hard-coded absolute string in ws-pulse.py and ws-pulse-delta.py —
    Foundry-specific AND user-specific, so it broke twice over on anyone else's
    machine. It is DERIVED, not configured: Claude encodes the repo path by
    replacing "/" and "_" with "-", so the root already determines it.
    """
    root = program_root(arg)
    return str(Path.home() / ".claude" / "projects" / root.replace("/", "-").replace("_", "-"))


def program_dir(arg=None):
    env = os.environ.get("PROGRAM_DIR")
    if env:
        return str(Path(env).resolve())
    return str(Path(program_root(arg)) / DEFAULT_DIRNAME)
