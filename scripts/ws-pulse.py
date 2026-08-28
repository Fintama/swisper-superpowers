#!/usr/bin/env python3
"""PM workstream pulse — passive monitor of the 4 live workstream sessions.

Reads each session's transcript tail + its worktree git state. Read-only.
Usage:  python3 ws-pulse.py [n_recent_events]
"""
import json, os, re, subprocess, sys, time

import sys as _s, pathlib as _p
_s.path.insert(0, str(_p.Path(__file__).resolve().parent))
from program_root import program_dir as _pd, program_root as _pr, program_transcripts as _pt

PROJ = _pt()          # 🔴 C2/HC-2: was a hard-coded, USER-specific absolute path
ROOT = _pr()          # 🔴 C2/HC-2: was a HARD-CODED absolute Foundry path

# Sessions are re-spawned when they exhaust context — re-map the id when that happens.
# PM SESSION (NOT a lane, but NEVER reap — reap-ghosts.sh whitelists by grep on this file):
# PM = <session-uuid>   (tmux "pm")   <- put the live PM id here
WS = [
    # ── LANE MAP ──────────────────────────────────────────────────────────────
    # One row per live workstream session:
    #     ("WS<n>-<k> <Lane title> — <plain-language scope>", "<session-uuid>", "<worktree>")
    #
    # The session uuid is the filename (minus .jsonl) of the lane's transcript in
    # ~/.claude/projects/<project>/. Find a new one with:
    #     ls -t ~/.claude/projects/<project>/*.jsonl | head
    #
    # Keep the label byte-identical to the session's own /rename and to the
    # status file — one string, three places (see the respawn-workstream skill).
    # Comment a retired row rather than deleting it; the history is how you tell
    # a succession from a fork.
    #
    # ("WS1-1 Example Lane — what this lane owns", "00000000-0000-0000-0000-000000000000", "main"),
]
N = int(sys.argv[1]) if len(sys.argv) > 1 else 6


def live_worktree(path, fallback):
    """Worktrees move per sub-branch — trust the session's most recent cwd over the constant."""
    try:
        with open(path, "rb") as f:
            try:
                f.seek(-1_500_000, os.SEEK_END)
                f.readline()
            except OSError:
                f.seek(0)
            body = f.read().decode("utf-8", "replace")
        hits = re.findall(r'"cwd":"' + re.escape(ROOT) + r'/\.worktrees/([^/"]+)', body)
        return hits[-1] if hits else fallback
    except Exception:
        return fallback


def sh(args, cwd):
    try:
        return subprocess.run(args, cwd=cwd, capture_output=True, text=True, timeout=20).stdout.strip()
    except Exception:
        return ""


def tail_events(path, n):
    """Last n meaningful events: assistant prose, tool calls, user turns."""
    out = []
    with open(path, "rb") as f:
        try:
            f.seek(-2_000_000, os.SEEK_END)
            f.readline()
        except OSError:
            f.seek(0)
        lines = f.read().decode("utf-8", "replace").splitlines()
    for line in lines:
        try:
            d = json.loads(line)
        except Exception:
            continue
        msg = d.get("message") or {}
        role = msg.get("role") or d.get("type")
        content = msg.get("content")
        if isinstance(content, str):
            content = [{"type": "text", "text": content}]
        if not isinstance(content, list):
            continue
        for b in content:
            if not isinstance(b, dict):
                continue
            t = b.get("type")
            if t == "text" and b.get("text", "").strip():
                txt = " ".join(b["text"].split())
                if len(txt) > 20:
                    out.append((role, "say", txt[:400]))
            elif t == "tool_use":
                name = b.get("name", "?")
                inp = b.get("input") or {}
                hint = (inp.get("description") or inp.get("file_path")
                        or inp.get("command") or inp.get("pattern") or inp.get("prompt") or "")
                hint = " ".join(str(hint).split())[:150]
                out.append((role, name, hint))
    return out[-n:]


print(f"\n{'='*78}\nWORKSTREAM PULSE — {time.strftime('%Y-%m-%d %H:%M:%S')}\n{'='*78}")
for label, sid, wt_default in WS:
    path = f"{PROJ}/{sid}.jsonl"
    wt = live_worktree(path, wt_default)
    # A lane without a worktree (e.g. WS5 docs — works inside the docs submodule)
    # is monitored at that path directly; "docs" means ROOT/docs, not .worktrees/docs.
    cwd = f"{ROOT}/docs" if wt == "docs" else f"{ROOT}/.worktrees/{wt}"
    age = (time.time() - os.path.getmtime(path)) / 60 if os.path.exists(path) else -1
    live = "🟢 LIVE" if age < 3 else ("🟡 idle" if age < 20 else "⚪ quiet")
    print(f"\n\n### {label}  [{live} · last activity {age:.0f}m ago]")
    print(f"    worktree {wt}")

    branch = sh(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd)
    ahead = sh(["git", "rev-list", "--left-right", "--count",
                "origin/feature/workbench...HEAD"], cwd).replace("\t", " behind / ")
    print(f"    branch {branch}  ({ahead} ahead of trunk)")
    commits = sh(["git", "log", "--oneline", "origin/feature/workbench..HEAD"], cwd)
    for c in (commits.splitlines() or ["(no commits yet)"]):
        print(f"      • {c}")
    dirty = sh(["git", "status", "--short"], cwd).splitlines()
    if dirty:
        print(f"    working tree: {len(dirty)} files dirty")
        for d in dirty[:10]:
            print(f"      {d}")
        if len(dirty) > 10:
            print(f"      … +{len(dirty)-10} more")
    migs = sh(["bash", "-c", "ls backend/drizzle/00*.sql 2>/dev/null | tail -2"], cwd)
    print(f"    migrations: {', '.join(os.path.basename(m) for m in migs.split()) or 'n/a'}")

    print("    — recent activity —")
    for role, kind, hint in tail_events(path, N):
        tag = "AI " if role == "assistant" else ("YOU" if role == "user" else "   ")
        print(f"      {tag} [{kind}] {hint}")
print()
