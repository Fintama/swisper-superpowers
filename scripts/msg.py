#!/usr/bin/env python3
"""msg: the offline mailbox and the record. Not the live channel.

  MSG_SENDER=PM python3 "$CLAUDE_PLUGIN_ROOT/scripts/msg.py" WS4 'your message'
  MSG_SENDER=PM python3 "$CLAUDE_PLUGIN_ROOT/scripts/msg.py" all  'broadcast'
  python3 "$CLAUDE_PLUGIN_ROOT/scripts/msg.py" --status          # tmux seat map

A RUNNING session is reached with Claude Code's built-in SendMessage, addressed by
its session name as ListAgents shows it — that is the live channel. Use this script
for a session that is NOT running: a built-in message to one is lost, and the
mailbox `.handover/inbox/WS<n>.md` is what its respawned successor reads at start.
Rules: skills/running-a-programme/references/messaging.md.

If a tmux session named ws<n> exists, the message is typed into it and verified by
reading the pane back; otherwise it is appended to the mailbox. Either way the mailbox
gets a copy. The sender writes that copy, so it is an audit trail, never evidence that
the lane received anything: read the exit line, not the mirror.
"""
import subprocess, sys, time, os

import sys as _s, pathlib as _p
_s.path.insert(0, str(_p.Path(__file__).resolve().parent))
from program_root import program_dir as _pd, program_root as _pr
ROOT = _pd()
# Set MSG_SENDER when sending; an unset sender is stamped UNATTRIBUTED, visibly, rather than
# passing as the PM.
SENDER = os.environ.get("MSG_SENDER", "UNATTRIBUTED")

# SESSION names which incarnation of a lane sent the message, which is what makes a fork
# (two sessions with one label) visible. Unlike SENDER it defaults to absent, not to a
# placeholder: the receiver rejects a message with no session field, but a placeholder is
# present, fails to match the roster and would be reported as a false fork. With
# MSG_SESSION unset the output is byte-identical to the pre-session format (T-AC-3).
SESSION = os.environ.get("MSG_SESSION") or None
def lanes():
    """The lane roster, derived from program.yaml. Raises if it cannot be read.

    No fallback list: a broadcast over a stale roster silently omits lanes while
    reporting success for each one it tried. Only --status and `all` call this, so a
    named target still works when program.yaml is broken.
    """
    from program_yaml import load          # sibling; sys.path was extended above
    data = load(f"{_pr()}/program.yaml")
    return [w["name"] for w in (data.get("workstreams") or data.get("lanes") or [])]


def _next_seq(lane):
    """Monotonic per (session, lane), so a receiver that sees seq 4 then 6 knows one was lost."""
    if SESSION is None:
        return None
    if os.environ.get("MSG_SEQ"):
        return os.environ["MSG_SEQ"]
    import json
    path = os.path.join(ROOT, ".msg-seq.json")
    try:
        state = json.load(open(path)) if os.path.exists(path) else {}
    except Exception:
        state = {}                      # a corrupt counter must not block a message
    key = f"{SESSION}:{lane}"
    n = int(state.get(key, 0)) + 1
    state[key] = n
    try:
        with open(path, "w") as fh:
            json.dump(state, fh)
    except Exception:
        pass                            # an unwritable counter must not block a message
    return str(n)


def _identity(lane):
    """The envelope suffix, or "" when there is no session — see SESSION above."""
    if SESSION is None:
        return ""
    seq = _next_seq(lane)
    return f" · session {SESSION}" + (f" · seq {seq}" if seq else "")



# After a verified delivery, re-baseline this mailbox's recorded size, so ws-pulse-delta.py
# does not report the PM's own write back to it as lane activity.
def _rebaseline_inbox(lane: str, expected_size: int) -> None:
    """Re-baseline this mailbox only, and only if nobody else wrote to it.

    The baseline is set to the size we expect (before our write plus our bytes). If the
    file differs, someone else wrote too: leave the baseline so the delta still reports
    it. A missed re-baseline costs one false positive; a swallowed write costs a message.
    """
    import json as _json, os as _os
    state = _os.path.join(ROOT, ".pulse-state.json")
    inbox = _os.path.join(ROOT, "inbox", f"{lane}.md")
    try:
        if not (_os.path.exists(state) and _os.path.exists(inbox)):
            return
        actual = _os.path.getsize(inbox)
        if actual != expected_size:
            return                       # a third party wrote — do NOT absorb it
        with open(state) as fh:
            st = _json.load(fh)
        key = f"inbox_{lane}.md"
        if key in st:                    # only re-baseline a key that EXISTS
            st[key] = str(actual)
            with open(state, "w") as fh:
                _json.dump(st, fh)
    except Exception:
        pass                             # never let hygiene break delivery

def hosted(lane):
    """True if a tmux host exists for this lane (ws1..ws5)."""
    r = subprocess.run(["tmux", "has-session", "-t", lane.lower()],
                       capture_output=True)
    return r.returncode == 0


def to_inbox(lane, text, channel):
    ts = time.strftime("%Y-%m-%d %H:%M")
    with open(f"{ROOT}/inbox/{lane}.md", "a") as f:
        f.write(f"\n## {ts} — {SENDER} message (delivered via {channel})"
                f"{_identity(lane)}\n{text}\n")


def pane_has(lane, needle, lines=200):
    """Whitespace-insensitive search of the pane + recent scrollback.
    Wrapping breaks naive substring checks, so both sides are de-whitespaced."""
    r = subprocess.run(["tmux", "capture-pane", "-t", lane.lower(), "-p", "-S", f"-{lines}"],
                       capture_output=True, text=True)
    flat = "".join(r.stdout.split())
    return "".join(needle.split()) in flat


def send(lane, text):
    """Type into a hosted lane, then verify the message appears in its pane.

    A successful send-keys only means the terminal got keystrokes: a busy session's
    redraw between the text and Enter can wipe the input line with no error anywhere.
    """
    if not hosted(lane):
        to_inbox(lane, text, "inbox — read on your next poll")
        return f"{lane}: queued in inbox (polled channel)"

    t = lane.lower()
    probe = text[:60]                       # distinctive enough, short enough to survive wrapping
    for attempt in (1, 2):
        # Type, pause, then Enter — a combined send-keys leaves the text unsubmitted.
        payload = f"[{SENDER} message{_identity(lane)}] {text}"
        subprocess.run(["tmux", "send-keys", "-t", t, payload], check=True)
        # Wait in proportion to length: tmux delivers a long payload over time, and an
        # early Enter submits the bulk and strands the tail at the prompt.
        time.sleep(2 + len(payload) / 600.0)
        subprocess.run(["tmux", "send-keys", "-t", t, "Enter"], check=True)
        time.sleep(1)
        # A non-empty prompt line after Enter means a tail stranded. Clear it so the
        # next message is not concatenated onto a fragment, and say so.
        pane_now = subprocess.run(["tmux", "capture-pane", "-t", t, "-p"],
                                  capture_output=True, text=True).stdout
        for line in pane_now.splitlines():
            if line.startswith("\u276f ") and len(line.strip()) > 2:
                subprocess.run(["tmux", "send-keys", "-t", t, "C-u"], check=False)
                print(f"  \u26a0 stranded tail cleared on {t}", file=sys.stderr)
                break
        time.sleep(3)                        # let the TUI render the submitted prompt
        if pane_has(t, probe):
            import os as _os
            _ib = _os.path.join(ROOT, "inbox", f"{lane}.md")
            _before = _os.path.getsize(_ib) if _os.path.exists(_ib) else 0
            to_inbox(lane, text, f"tmux — DELIVERY VERIFIED in pane (attempt {attempt})")
            _after = _os.path.getsize(_ib) if _os.path.exists(_ib) else 0
            # our own write must not wake the delta check — but only absorb OUR bytes
            _rebaseline_inbox(lane, _after)  if _after >= _before else None
            return f"{lane}: delivered + verified in pane"
        if attempt == 1:
            time.sleep(4)                    # busy redraw storm — let it settle, then retry once

    to_inbox(lane, text, "tmux — ⚠️ SENT BUT NOT VERIFIED; lane must pick this up from the inbox")
    return (f"{lane}: ⚠️ NOT VERIFIED — keystrokes sent twice, message never appeared in the pane. "
            f"Mirrored to inbox/{lane}.md; chase the lane or resend when it is idle.")


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--status":
        try:
            roster = lanes()
        except Exception as e:                       # refuse, never a stale list
            print(f"REFUSED: cannot read the lane roster from {_pr()}/program.yaml — {e}\n"
                  "The roster is derived, so a broken registry means the channel map is "
                  "unknown, not 'the last six lanes'. Fix program.yaml and re-run; a NAMED "
                  "target (msg.py WS5 'text') still delivers meanwhile.")
            sys.exit(1)
        for l in roster:
            print(f"{l}: {'tmux-hosted (instant)' if hosted(l) else 'panel (polled)'}")
        sys.exit(0)
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    target, text = sys.argv[1], " ".join(sys.argv[2:])
    # Refuse shell-active spans: the shell has usually substituted them already, and one
    # that survives would garble on the receiving side.
    if any(tok in text for tok in ("`", "$(", "${")):
        print("REFUSED: message contains a shell-active span (backtick, dollar-paren or "
              "dollar-brace). The bus rides a shell — these execute or blank out before "
              "delivery, usually in the SENDER's own command line. Rewrite in plain words "
              "(and single-quote the msg.py argument) and resend.")
        sys.exit(1)
    if target.lower() == "all":
        try:
            targets = lanes()                        # derived; see lanes() for why no fallback
        except Exception as e:
            print(f"REFUSED: cannot read the lane roster from {_pr()}/program.yaml — {e}\n"
                  "A broadcast over a roster we cannot read would silently omit lanes, which "
                  "is the exact defect this derivation removed. Address the lane by name to "
                  "send now, and fix program.yaml before broadcasting.")
            sys.exit(1)
    else:
        targets = [target.upper()]                   # a named target never goes through the roster
    for l in targets:
        print(send(l, text))
