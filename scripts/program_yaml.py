#!/usr/bin/env python3
"""`program.yaml`, the sole owner of programme identity: reader and validator.

Shape (spec §1 A2):

    program: <name>
    repo:    <path to the programme's repo>
    board:   {dir, port}
    goals:   [{id, text, proof}]
    lanes:   [{name, id, session, scope, worktree, branch,
               rig: {frontend, backend, db, project}}]
    optional: pm_address, trunk, migrations (docs/program-yaml.md)

The PM lane is the sole writer (`setup-delivery-program` at creation, or a PM edit for
a respawn, a new lane or a rig change); anything may read it. Nothing enforces that yet
because there is one writer; the PR that adds a second writer adds the guard.

Needs PyYAML, which macOS's system python3 lacks; imports fail with the fix, not a bare ImportError.
"""

try:
    import yaml
except ModuleNotFoundError as exc:  # pragma: no cover - environment, not logic
    raise ModuleNotFoundError(
        "program.yaml needs PyYAML, which this interpreter does not have.\n"
        "  fix: python3 -m pip install pyyaml\n"
        "  note: macOS system python3 (3.9.6) ships without it."
    ) from exc

from pathlib import Path

REQUIRED_TOP = ("program", "repo", "board", "goals", "lanes")
REQUIRED_BOARD = ("dir", "port")
REQUIRED_GOAL = ("id", "text", "proof")
REQUIRED_LANE = ("name", "id", "session", "scope", "worktree", "branch", "rig")
REQUIRED_RIG = ("frontend", "backend", "db", "project")


class ProgramYamlError(Exception):
    """A program.yaml that cannot be trusted. Always names the offending field."""


def _require(mapping, keys, where):
    if not isinstance(mapping, dict):
        raise ProgramYamlError(f"{where}: expected a mapping, got {type(mapping).__name__}")
    for key in keys:
        if key not in mapping:
            raise ProgramYamlError(f"{where}: missing required field `{key}`")


def _validate(data):
    """Raise ProgramYamlError naming the first offending field. Returns data."""
    _require(data, REQUIRED_TOP, "program.yaml")
    _require(data["board"], REQUIRED_BOARD, "program.yaml: board")

    if not isinstance(data["board"]["port"], int):
        raise ProgramYamlError(
            f"program.yaml: board: field `port` must be an int, "
            f"got {type(data['board']['port']).__name__}"
        )

    for i, goal in enumerate(data["goals"]):
        label = goal.get("id") if isinstance(goal, dict) else None
        _require(goal, REQUIRED_GOAL, f"program.yaml: goals[{i}]"
                 + (f" ({label})" if label else ""))

    for i, lane in enumerate(data["lanes"]):
        # name the lane as a human would look for it, falling back to the index
        label = lane.get("name") if isinstance(lane, dict) else None
        where = f"program.yaml: lanes[{i}]" + (f" ({label})" if label else "")
        _require(lane, REQUIRED_LANE, where)
        _require(lane["rig"], REQUIRED_RIG, f"{where}: rig")

    return data


validate = _validate  # public name; `dump` needs the private one to keep its kwarg


def load(path):
    """Read and validate program.yaml FROM DISK. Raises ProgramYamlError."""
    path = Path(path)
    if not path.exists():
        raise ProgramYamlError(f"program.yaml: no such file: {path}")
    with path.open("r", encoding="utf-8") as fh:
        data = yaml.safe_load(fh)
    if data is None:
        raise ProgramYamlError(f"program.yaml: file is empty: {path}")
    return _validate(data)


def dump(data, path, validate=True):
    """Write program.yaml. Set validate=False only to author a fixture on purpose."""
    if validate:
        _validate(data)
    path = Path(path)
    with path.open("w", encoding="utf-8") as fh:
        yaml.safe_dump(data, fh, sort_keys=False, allow_unicode=True, default_flow_style=False)
    return path
