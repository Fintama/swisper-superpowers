#!/usr/bin/env python3
"""Measure every lane's context usage from its transcript, not from its self-reported `[ctx:%]`.

A turn's input_tokens + cache_read + cache_creation is the context size at that turn.

Usage: python3 .handover/ctx-check.py [window_tokens, default 1_000_000]
"""
import json, os, re, sys

import sys as _s, pathlib as _p
_s.path.insert(0, str(_p.Path(__file__).resolve().parent))
from program_root import program_dir as _pd, program_root as _pr, program_transcripts as _pt
ROOT = _pd()
PROJ = _pt()
WINDOW = int(sys.argv[1]) if len(sys.argv) > 1 else 1_000_000

# Strip comments before matching: retired rows are commented out, not deleted.
_src = re.sub(r"#.*", "", open(f"{ROOT}/ws-pulse.py").read())
lanes = re.findall(r'\("(WS\d-\d[^"]*)",\s*"([a-f0-9-]{36})"', _src)

print(f"CONTEXT — measured from transcripts, window {WINDOW:,}")
alerts = []
for name, sid in lanes:
    p = os.path.join(PROJ, sid + ".jsonl")
    lane = name.split()[0]
    if not os.path.exists(p):
        print(f"  {lane:<8} no transcript"); continue
    # Max of the last few turns, not the last turn: a prompt-cache miss can report one
    # turn at half its real size, which looks like a compaction. A real compaction keeps
    # every later turn low, so the short-window max still catches it within a few turns.
    SMOOTH = 5
    recent = []
    for line in open(p):
        try: d = json.loads(line)
        except Exception: continue
        m = d.get("message", {})
        if d.get("type") == "assistant" and isinstance(m, dict):
            u = m.get("usage", {}) or {}
            t = u.get("input_tokens", 0) + u.get("cache_read_input_tokens", 0) + u.get("cache_creation_input_tokens", 0)
            if t:
                recent.append(t)
                if len(recent) > SMOOTH: recent.pop(0)
    used = max(recent) if recent else 0
    pct_used = 100.0 * used / WINDOW
    left = 100.0 - pct_used
    bar = "█" * int(pct_used / 5) + "·" * (20 - int(pct_used / 5))
    flag = ""
    if left <= 15:
        flag = "  ← SUCCESSION"; alerts.append(lane)
    elif left <= 30:
        flag = "  ← plan handover"
    print(f"  {lane:<8} {used:>9,}  {pct_used:5.1f}% used  {left:5.1f}% free  {bar}{flag}")

print(f"\n  {len(alerts)} lane(s) genuinely need succession" if alerts
      else "\n  No lane needs succession. Ignore any self-reported figure that disagrees with this.")
