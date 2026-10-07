#!/usr/bin/env python3
"""PM pulse, delta edition: prints only what changed since the last run, plus new mailbox traffic.

For the recurring cron; state is hashed into .handover/.pulse-state.json, and an unchanged
programme prints one short line. Run ws-pulse.py by hand to investigate a change.
"""
import hashlib, json, os, re, subprocess, sys

import sys as _s, pathlib as _p
_s.path.insert(0, str(_p.Path(__file__).resolve().parent))
from program_root import program_dir as _pd, program_root as _pr, program_transcripts as _pt
H = _pd()
STATE = f"{H}/.pulse-state.json"
PROJ = _pt()
WS = [
    # Same rows as ws-pulse.py: ("WS<n>-<k> <Lane title>", "<session-uuid>")
    # ("WS1-1 Example Lane", "00000000-0000-0000-0000-000000000000"),
]

def sh(cmd):
    try:
        # shell=True for the pipelines: every cmd is a literal built in this file, no outside input.
        # Suppressed here, not in a .semgrepignore, which would replace semgrep's default ignores.
        # The directive must stay the last line before the call.
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
