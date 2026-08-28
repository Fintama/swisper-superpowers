#!/usr/bin/env python3
"""ctx-check — measure every lane's REAL context usage from its transcript.

Why this exists (2026-07-28, expensive lesson): lanes were self-reporting `[ctx:%]`
from a *felt sense* of how much had happened, against an assumed ~200k window. The
real window is 1M. WS6 reported 12% remaining when it actually had 73% free, and the
transcripts show WS2/WS3/WS4 all peaking at ~200k and then being succeeded — sessions
terminating at a ceiling that does not exist. Every one of those successions was
avoidable, and each cost a handover, a spawn and an adoption read.

Never trust a self-reported percentage again. The transcript is the ground truth:
a turn's input_tokens + cache_read + cache_creation IS the context size at that turn.

Usage: python3 .handover/ctx-check.py [window_tokens, default 1_000_000]
"""
import json, os, re, sys

import sys as _s, pathlib as _p
_s.path.insert(0, str(_p.Path(__file__).resolve().parent))
from program_root import program_dir as _pd, program_root as _pr, program_transcripts as _pt
ROOT = _pd()          # C2: was dirname(__file__)
PROJ = _pt()          # C2/HC-2: was a hard-coded, USER-specific absolute path.
                      # On anyone else's machine it named a directory that does not
                      # exist, so every lane read as "no transcript" and the check
                      # reported clean while being incapable of reporting anything else.
WINDOW = int(sys.argv[1]) if len(sys.argv) > 1 else 1_000_000

# Strip comments BEFORE matching: the protocol tells the PM to comment a retired
# row rather than delete it, so an uncommented parse counts retired sessions as
# live. reap-ghosts.sh has always done this; this file did not.
_src = re.sub(r"#.*", "", open(f"{ROOT}/ws-pulse.py").read())
lanes = re.findall(r'\("(WS\d-\d[^"]*)",\s*"([a-f0-9-]{36})"', _src)

print(f"CONTEXT — measured from transcripts, window {WINDOW:,}")
alerts = []
for name, sid in lanes:
    p = os.path.join(PROJ, sid + ".jsonl")
    lane = name.split()[0]
    if not os.path.exists(p):
        print(f"  {lane:<8} no transcript"); continue
    # WHY THE MAX OF THE LAST FEW TURNS, NOT THE LAST TURN (PM-3, 2026-07-29 — after
    # raising a false compaction alarm on WS2-8 and writing it into protocol):
    # on a PROMPT-CACHE MISS the accounting splits differently — one WS2-8 turn read
    #   cache_read=20,861  cache_creation=330,115  -> sum 350,978
    # while the turns either side read ~715,000. The context never shrank by 364k; only
    # the billing split moved. Reading the LAST turn therefore reports a phantom halving,
    # which looks exactly like an auto-compact and is the more alarming of the two.
    # A REAL compaction keeps EVERY subsequent turn low, so the max over a short window
    # survives a one-turn cache dip and still falls within a few turns of a true compact.
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
