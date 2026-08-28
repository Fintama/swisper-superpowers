#!/usr/bin/env python3
"""PM pulse, delta edition — prints ONLY what changed since the last run.

Replaces the full ws-pulse.py output in the recurring cron: state is hashed
into .handover/.pulse-state.json; an unchanged program prints one short line
(~20 tokens) instead of ~800. Run ws-pulse.py manually when a change needs
investigation. Also surfaces new PM-mailbox traffic (inbox/outbox protocol).
"""
import hashlib, json, os, re, subprocess, sys

import sys as _s, pathlib as _p
_s.path.insert(0, str(_p.Path(__file__).resolve().parent))
from program_root import program_dir as _pd, program_root as _pr, program_transcripts as _pt
H = _pd()             # C2: was a literal relative directory name
STATE = f"{H}/.pulse-state.json"
PROJ = _pt()          # 🔴 C2/HC-2: was a hard-coded, USER-specific absolute path
WS = [
    # ── LANE MAP ──────────────────────────────────────────────────────────────
    # ("WS<n>-<k> <Lane title>", "<session-uuid>") — must match ws-pulse.py.
    # ("WS1-1 Example Lane", "00000000-0000-0000-0000-000000000000"),
]

def sh(cmd):
    try:
        # shell=True is deliberate and the pipelines below depend on it. Every
        # `cmd` passed here is a literal composed in this file from git/tmux
        # output — no external or user-supplied input reaches it — and this
        # script is PM tooling run from a local cron. It is never deployed and
        # never runs in the product. Annotated locally rather than adding a
        # .semgrepignore: the repo has none, so creating one would REPLACE
        # semgrep's default ignore set and weaken SAST across the whole tree
        # to silence one line. The directive must be the LAST comment before
        # the match — semgrep only honours it on the match line or the line
        # immediately preceding it.
        # nosemgrep: python.lang.security.audit.subprocess-shell-true.subprocess-shell-true
        return subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=30).stdout.strip()
    except Exception:
        return "?"

def tail_sig(sid):
    """Signature of a session's recent activity: transcript size + tail hash."""
    p = f"{PROJ}/{sid}.jsonl"
    if not os.path.exists(p):
        return "missing"
    sz = os.path.getsize(p)
    with open(p, "rb") as f:
        try:
            f.seek(-4096, os.SEEK_END)
        except OSError:
            f.seek(0)
        tail = f.read()
    return f"{sz}:{hashlib.md5(tail).hexdigest()[:8]}"

sh("git fetch origin --quiet")
now = {
    "main": sh("git log --oneline -1 origin/main"),
    "prs": sh("gh pr list --base main --state open --limit 15 --json number,headRefName "
              "--jq '[.[] | select(.headRefName | startswith(\"main-\") or startswith(\"feature\"))] "
              "| map(\"\\(.number):\\(.headRefName)\") | join(\" \")'"),
    "branches": sh("git ls-remote --heads origin 'main-*' 'feature/*' | awk -F'refs/heads/' '{print $2}' | sort | tr '\\n' ' '"),
}
for name, sid in WS:
    now[f"{name}_act"] = tail_sig(sid)
for f in sorted(os.listdir(f"{H}/inbox")) if os.path.isdir(f"{H}/inbox") else []:
    now[f"inbox_{f}"] = str(os.path.getsize(f"{H}/inbox/{f}"))
if os.path.exists(f"{H}/outbox-to-pm.md"):
    now["outbox"] = str(os.path.getsize(f"{H}/outbox-to-pm.md"))

prev = {}
if os.path.exists(STATE):
    try:
        prev = json.load(open(STATE))
    except Exception:
        prev = {}

changes = []
for k, v in now.items():
    if prev.get(k) != v:
        if k.endswith("_act"):
            changes.append(f"{k[:-4]} active since last pulse")
        elif k == "main":
            changes.append(f"MAIN MOVED: {prev.get('main','?')} -> {v}")
        elif k == "prs":
            changes.append(f"PR SET CHANGED: [{prev.get('prs','?')}] -> [{v}]")
        elif k == "branches":
            changes.append("remote branch set changed")
        elif k.startswith("inbox_"):
            changes.append(f"MAILBOX {k[6:]} grew — a WS consumed or PM wrote")
        elif k == "outbox":
            changes.append("OUTBOX-TO-PM has new traffic — READ .handover/outbox-to-pm.md")

json.dump(now, open(STATE, "w"))

if not changes or (len(changes) <= len(WS) and all(c.endswith("active since last pulse") for c in changes)):
    acts = [c.split()[0] for c in changes]
    print("NO-CHANGE" + (f" (activity only: {','.join(acts)})" if acts else ""))
else:
    print("CHANGES:")
    for c in changes:
        print(" •", c)
    print("(investigate with ws-pulse.py / gh as needed)")
