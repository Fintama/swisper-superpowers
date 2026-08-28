#!/usr/bin/env python3
"""Stall check — find lanes that are SILENT while claiming to be working.

The delta pulse reports what CHANGED. A stalled lane changes nothing, so it is
invisible there: exactly how WS5 sat waiting for a fix agent that had already
finished (2026-07-27) until Heiko asked. This script reports the absence.

A lane is flagged when its transcript has not moved for longer than the threshold.
The PM then messages that lane: "your subagents may have finished — check, do not wait."

Usage: python3 .handover/stall-check.py [minutes, default 15]
"""
import json, os, re, sys, time, subprocess

import sys as _s, pathlib as _p
_s.path.insert(0, str(_p.Path(__file__).resolve().parent))
from program_root import program_dir as _pd, program_root as _pr, program_transcripts as _pt
ROOT = _pd()

# ── Measure the MAIL, not the envelope (PM ruling, 2026-08-27) ───────────────
# The threshold below uses tail length as a proxy for "there is real content
# waiting". C1 gave every message a `· session … · seq …` envelope — +25 bytes
# each — which is framing, not content, and it pushed lanes over the line sooner.
#
# 🔴 The fix is NOT to raise 200. A constant tuned to today's field count rots
# silently the next time the envelope changes, and nothing announces the rot.
# Strip the framing, then measure what is left.
_ENVELOPE = _re_env = None
def _mail_only(text):
    """Drop mirror headers, keep the messages. Framing is not content."""
    import re as _re
    global _re_env
    if _re_env is None:
        # a mirror header: "## <ts> — <sender> message (delivered via <channel>)…"
        _re_env = _re.compile(r'^##\s.*?\smessage\s\(delivered via[^\n]*$', _re.M)
    return _re_env.sub('', text)
          # C2: was dirname(__file__)
PROJ = _pt()          # C2/HC-2: was a hard-coded, USER-specific absolute path.
                      # On anyone else's machine it named a directory that does not
                      # exist, so every lane read as "no transcript" and the check
                      # reported clean while being incapable of reporting anything else.
threshold = float(sys.argv[1]) if len(sys.argv) > 1 else 15.0

# Strip comments BEFORE matching: the protocol tells the PM to comment a retired
# row rather than delete it, so an uncommented parse counts retired sessions as
# live. reap-ghosts.sh has always done this; this file did not.
src = re.sub(r"#.*", "", open(os.path.join(ROOT, "ws-pulse.py")).read())
lanes = re.findall(r'\("(WS\d-\d[^"]*)",\s*"([a-f0-9-]{36})",\s*"([^"]*)"\)', src)

# ── HOLD GATES (WS2-8, 2026-07-29) ─────────────────────────────────────────
# The heuristic could not tell STOPPED-BECAUSE-TOLD-TO from STOPPED-BECAUSE-BROKEN.
# A lane holding correctly at a PM gate produces a transcript trace identical to a
# dead one — so the lanes flagged most often were the ones obeying most exactly, and
# several wake-ups were spent chasing lanes doing precisely what they were told.
# A gate is one line in .handover/hold-gates.txt:  WS<n> <what it waits on>
# Remove the line when you clear the gate; a stale gate hides a real stall, so the
# report prints open gates even when nothing is flagged.
gates = {}
gp = os.path.join(ROOT, "hold-gates.txt")
if os.path.exists(gp):
    for line in open(gp):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split(None, 1)
        if len(parts) == 2 and re.fullmatch(r"WS\d", parts[0]):
            gates[parts[0]] = parts[1]

# Lanes whose tmux seat is gone AND whose inbox has queued mail — computed early so
# the stall loop can skip them (they are reported in their own section below).
_panel_lane_ids = set()
try:
    import subprocess as _sp0
    _seats0 = _sp0.run(["tmux", "ls", "-F", "#{session_name}"], capture_output=True, text=True).stdout.split()
    for _n0, _s0, _w0 in lanes:
        _l0 = _n0.split()[0].split("-")[0]
        if ("ws" + _l0[2:]) in _seats0:
            continue
        _f0 = os.path.join(ROOT, "inbox", f"{_l0}.md")
        if not os.path.exists(_f0):
            continue
        _b0 = open(_f0).read()
        _t0 = _b0.rsplit("PROCESSED-MARKER", 1)[-1] if "PROCESSED-MARKER" in _b0 else _b0
        if len(_mail_only(_t0).strip()) > 200:
            _panel_lane_ids.add(_l0)
except Exception:
    pass

now = time.time()
flagged = []
held = []
blocked = []
for name, sid, wt in lanes:
    lane_id = name.split()[0].split("-")[0]          # "WS3-7 …" -> "WS3"
    p = os.path.join(PROJ, sid + ".jsonl")
    if not os.path.exists(p):
        flagged.append((name, "NO TRANSCRIPT", 0)); continue
    quiet = (now - os.path.getmtime(p)) / 60.0
    if quiet >= threshold:
        if lane_id in gates:
            held.append((name, gates[lane_id], quiet)); continue
        # A PANEL lane with queued mail is already reported in its own section with a
        # known cause; flagging it a second time as a stall makes the PM chase a lane
        # it has just explained to itself. Same principle as the hold-gate skip.
        if lane_id in _panel_lane_ids:
            continue
        pane = subprocess.run(["tmux", "capture-pane", "-t", "ws" + name[2], "-p"],
                              capture_output=True, text=True).stdout
        # BLOCKED ON A PERMISSION PROMPT (PM-3, 2026-07-29). A lane awaiting an
        # interactive approval cannot emit a token, so its transcript freezes and it
        # is INDISTINGUISHABLE from a stall to both instruments — the delta pulse sees
        # nothing change (nothing IS changing) and this check saw only "0 subagent
        # rows". WS1 sat 28 minutes behind a read-only `docker context ls` prompt, with
        # its rebase agent blocked behind it. Only the PM can clear it, and only if the
        # PM knows. Detect it explicitly rather than hoping someone reads the pane.
        if re.search(r"Do you want to proceed\?|requires approval|don.t ask again for", pane):
            cmd = ""
            m = re.search(r"^\s*(cd .+|\S.*)$", pane[max(0, pane.find("Bash command")):], re.M)
            if m: cmd = m.group(1).strip()[:70]
            blocked.append((name, cmd, quiet)); continue
        agents = len(re.findall(r"^\s*◯", pane, re.M))
        flagged.append((name, f"{agents} subagent rows in pane", quiet))

# ── PANEL LANES WITH UNDRAINED MAIL (PM-3, 2026-07-29) ─────────────────────
# When a lane loses its tmux seat and becomes a VS Code panel process, msg.py
# correctly switches it to "panel (polled)" — but hosted lanes were told to
# install NO poll cron, so nothing polls and PM messages queue to a file forever.
# The lane stays healthy and the BUS goes one-way, silently: no error, no warning,
# and the delta pulse cannot see it because a lane that is working is not stalled.
# WS2 sat like this for 2+ hours; WS1 followed. Detect the combination explicitly.
panel_starved = []
try:
    import subprocess as _sp
    _seats = _sp.run(["tmux", "ls", "-F", "#{session_name}"], capture_output=True, text=True).stdout.split()
    for _name, _sid, _wt in lanes:
        _lane = _name.split()[0].split("-")[0]           # "WS2-8 …" -> "WS2"
        if ("ws" + _lane[2:]) in _seats:
            continue                                     # still tmux-hosted, fine
        _f = os.path.join(ROOT, "inbox", f"{_lane}.md")
        if not os.path.exists(_f):
            continue
        _b = open(_f).read()
        _tail = _b.rsplit("PROCESSED-MARKER", 1)[-1] if "PROCESSED-MARKER" in _b else _b
        if len(_mail_only(_tail).strip()) > 200:
            panel_starved.append((_name, len(_mail_only(_tail).strip())))
except Exception:
    pass

# ── undrained mail: the PROCESSED-MARKER is a cumulative ack, free to read ──
undrained = []
for name, sid, wt in lanes:
    lane = name.split()[0].split("-")[0]          # "WS3-4 …" -> "WS3"
    f = os.path.join(ROOT, "inbox", f"{lane}.md")
    if not os.path.exists(f):
        continue
    body = open(f).read()
    tail = body.rsplit("PROCESSED-MARKER", 1)[-1] if "PROCESSED-MARKER" in body else body
    n = tail.count("— PM message")
    if n:
        undrained.append((lane, n, "never marked" if "PROCESSED-MARKER" not in body else "since last marker"))

if undrained:
    print("UNDRAINED MAIL — messages the lane has not marked as consumed:")
    for lane, n, how in undrained:
        print(f"  ✉ {lane}: {n} message(s) {how}")
    print("  → the marker is the ack. Chase, or confirm the lane is mid-turn and will drain.")

if panel_starved:
    print("\U0001F4FB PANEL LANE WITH UNDRAINED MAIL — its tmux seat is gone, so PM messages QUEUE AND SIT:")
    for _n, _b in panel_starved:
        print(f"  \U0001F4E5 {_n}\n      {_b:,} bytes waiting behind its marker \u00b7 msg.py cannot reach it as a prompt")
    print("  \u2192 the lane is not stalled, the BUS is. Reach it out-of-band or succeed it.")

if blocked:
    print("\U0001F534 BLOCKED ON A PERMISSION PROMPT — cannot proceed without YOU. Answer it:")
    for name, cmd, quiet in sorted(blocked, key=lambda r: -r[2]):
        print(f"  \u26d4 {name}\n      waiting {quiet:.0f} min on an approval dialog" + (f" \u00b7 {cmd}" if cmd else ""))
    print("  \u2192 read the command, then answer the SINGLE-USE option; a standing grant is Heiko\'s.")

if held:
    print("HELD AT A GATE — quiet BY INSTRUCTION, not stalled. Do not chase:")
    for name, why, quiet in sorted(held, key=lambda r: -r[2]):
        print(f"  ⏸ {name}\n      quiet {quiet:.0f} min · waiting on: {why}")
    print("  → clearing the gate is YOUR move. A stale gate hides a real stall.")

if not flagged:
    print(f"STALL CHECK: all lanes moved within {threshold:.0f} min — nothing to chase.")
else:
    print(f"STALL CHECK: {len(flagged)} lane(s) silent >{threshold:.0f} min —")
    for name, detail, quiet in sorted(flagged, key=lambda r: -r[2]):
        print(f"  ⏸ {name}\n      quiet {quiet:.0f} min · {detail}")
    print("  → message each: 'you have been silent N min — check whether your subagents")
    print("    already finished; report state or resume. Do not wait on a finished agent.'")
