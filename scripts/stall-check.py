#!/usr/bin/env python3
"""Stall check: find lanes that are silent while supposedly working.

The delta pulse reports what changed, so a stalled lane is invisible there. A lane is
flagged when its transcript has not moved for longer than the threshold; the PM then
tells it: "your subagents may have finished — check, do not wait."

Usage: python3 .handover/stall-check.py [minutes, default 15]
"""
import json, os, re, sys, time, subprocess

import sys as _s, pathlib as _p
_s.path.insert(0, str(_p.Path(__file__).resolve().parent))
from program_root import program_dir as _pd, program_root as _pr, program_transcripts as _pt
ROOT = _pd()

# The 200-byte "mail is waiting" threshold measures message text, with the mirror
# headers stripped; don't tune the number to the header size instead.
_ENVELOPE = _re_env = None
def _mail_only(text):
    """Drop mirror headers, keep the messages. Framing is not content."""
    import re as _re
    global _re_env
    if _re_env is None:
        # a mirror header: "## <ts> — <sender> message (delivered via <channel>)…"
        _re_env = _re.compile(r'^##\s.*?\smessage\s\(delivered via[^\n]*$', _re.M)
    return _re_env.sub('', text)
PROJ = _pt()
threshold = float(sys.argv[1]) if len(sys.argv) > 1 else 15.0

# Strip comments before matching: retired rows are commented out, not deleted.
src = re.sub(r"#.*", "", open(os.path.join(ROOT, "ws-pulse.py")).read())
lanes = re.findall(r'\("(WS\d-\d[^"]*)",\s*"([a-f0-9-]{36})",\s*"([^"]*)"\)', src)

# Hold gates: a lane waiting at a PM gate looks exactly like a dead one, so it is listed
# as held, not stalled. One line per gate in .handover/hold-gates.txt: WS<n> <what it waits on>
# Remove the line when you clear the gate; a stale gate hides a real stall, so open gates
# are always printed.
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
        # Already reported, with its cause, in the panel-lane section.
        if lane_id in _panel_lane_ids:
            continue
        pane = subprocess.run(["tmux", "capture-pane", "-t", "ws" + name[2], "-p"],
                              capture_output=True, text=True).stdout
        # A lane waiting on a permission prompt emits nothing and looks stalled; only
        # the PM can clear it, so it is detected from the pane and reported separately.
        if re.search(r"Do you want to proceed\?|requires approval|don.t ask again for", pane):
            cmd = ""
            m = re.search(r"^\s*(cd .+|\S.*)$", pane[max(0, pane.find("Bash command")):], re.M)
            if m: cmd = m.group(1).strip()[:70]
            blocked.append((name, cmd, quiet)); continue
        agents = len(re.findall(r"^\s*◯", pane, re.M))
        flagged.append((name, f"{agents} subagent rows in pane", quiet))

# ── Panel lanes with undrained mail ─────────────────────────────────────────
# A lane that lost its tmux seat gets PM messages in its inbox file only, and a lane
# without a poll never reads them: the lane looks healthy while the bus is one-way.
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
