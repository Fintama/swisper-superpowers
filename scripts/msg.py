#!/usr/bin/env python3
"""msg — the OFFLINE mailbox and the record. NOT the live channel (since 2026-10-01).

  MSG_SENDER=PM python3 "$CLAUDE_PLUGIN_ROOT/scripts/msg.py" WS4 'your message'
  MSG_SENDER=PM python3 "$CLAUDE_PLUGIN_ROOT/scripts/msg.py" all  'broadcast'
  python3 "$CLAUDE_PLUGIN_ROOT/scripts/msg.py" --status          # tmux seat map

A RUNNING session is reached with Claude Code's built-in SendMessage, addressed by
its session name as ListAgents shows it — that is the live channel. Use this script
for a session that is NOT running: a built-in message to one is lost, and the
mailbox `.handover/inbox/WS<n>.md` is what its respawned successor reads at start.
Rules: skills/running-a-programme/references/messaging.md.

Behaviour is unchanged from the tmux era: if a tmux session named ws<n> exists, the
message is still TYPED INTO it and verified by reading the pane back; otherwise it
is appended to the mailbox. Either way the mailbox gets a copy.

That copy is written by the SENDER, so it is an audit trail — never evidence that
the lane received anything. Read the exit line, not the mirror.
"""
import subprocess, sys, time, os

import sys as _s, pathlib as _p
_s.path.insert(0, str(_p.Path(__file__).resolve().parent))
from program_root import program_dir as _pd, program_root as _pr
ROOT = _pd()          # C2: was dirname(__file__) — the programme is now a parameter
# Sender attribution (2026-07-28): every mirror header before this date says "PM message"
# REGARDLESS of who ran the script — those headers prove transit through this tool, never
# authorship. Set MSG_SENDER when sending; an unset sender is stamped UNATTRIBUTED so the
# gap is visible instead of impersonating the PM.
SENDER = os.environ.get("MSG_SENDER", "UNATTRIBUTED")

# Session identity (C1, 2026-08-27). SENDER says WHO; SESSION says WHICH INCARNATION,
# and that is the difference that makes a fork visible: two sessions wearing the same
# lane label are indistinguishable by SENDER alone, and that IS the fork.
#
# 🔴 SESSION DEFAULTS TO ABSENT, NOT TO A PLACEHOLDER, and this deliberately INVERTS
# the SENDER convention four lines above. SENDER falls back to "UNATTRIBUTED" so a
# missing sender is VISIBLE. SESSION must not do that: §2 RULE-1 rejects a message
# whose session field is ABSENT ("an OLD sender, or something that is not our
# machinery — NOT 'probably fine'"), and a literal placeholder is a field that is
# PRESENT. It would sail past rule 1, then fail to match the roster, and be reported
# as a FORK — a false fork on every unattributed message, which is the one outcome
# that would teach everyone to ignore fork reports.
#
# The corollary is what makes the change safe: with MSG_SESSION unset, every byte
# this tool emits is exactly what it emitted before C1. T-AC-3 asserts that.
SESSION = os.environ.get("MSG_SESSION") or None
def lanes():
    """The roster, DERIVED from program.yaml — never a typed copy.

    It was a hand-typed list until 2026-09-12, and it had gone stale: WS7 was
    registered in program.yaml and absent here, so `msg.py all` reached six of seven
    lanes AND REPORTED SUCCESS FOR EACH ONE IT TRIED. A broadcast that silently omits
    a lane is worse than no broadcast, because the sender believes everyone was told.
    Registering a lane is now the only act needed to make it reachable.

    🔴 NO SILENT FALLBACK. If the registry cannot be read this RAISES, and the caller
    refuses. Falling back to a stale literal is the original bug wearing a hat: the
    bus would keep messaging a set that quietly stopped matching the programme. Same
    idiom as program_root.py, which refuses to guess a root rather than read another
    programme's mailbox.

    Called LAZILY, only by --status and by the `all` broadcast. A NAMED target must
    keep working when the registry is broken — that path never touches this.
    """
    from program_yaml import load          # sibling; sys.path was extended above
    data = load(f"{_pr()}/program.yaml")
    return [w["name"] for w in (data.get("workstreams") or data.get("lanes") or [])]


def _next_seq(lane):
    """Monotonic per (session, lane). Detects a GAP, which a bare counter cannot.

    Sequence is what separates "I have not heard from WS3" from "WS3's messages are
    not arriving": a receiver that sees seq 4 then seq 6 knows a message was lost,
    where two unnumbered messages look like one quiet lane.
    """
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



# ── Keep the delta instrument from waking the PM with its own echo ──────────
# A PM write GROWS the lane's inbox file, which ws-pulse-delta.py then reports
# as "MAILBOX WSn grew — a WS consumed or PM wrote". That is a FALSE POSITIVE:
# the PM is being signalled by its own message. False positives erode a silence
# detector faster than misses do, because the reader learns to skim it.
#
# After a VERIFIED delivery, re-baseline just this mailbox's recorded size so
# the next delta reports only what a LANE did. Any other key is left untouched,
# so a genuine change elsewhere is still caught.
def _rebaseline_inbox(lane: str, expected_size: int) -> None:
    """Re-baseline ONLY this mailbox, and ONLY if nobody else wrote to it.

    WS6's race, 2026-07-29: re-baselining to the file's size AFTER our write
    silently absorbs anything that landed in the window between the write and
    the re-baseline — that write would then never be reported as a delta.
    Today the window is empty by construction (only the PM writes here), but a
    second PM instance, or a lane writing to another lane's inbox, would be
    swallowed without trace.

    So we re-baseline to the size we EXPECT (size observed before our write,
    plus the bytes we wrote). If the file is a different size, someone else
    wrote too — leave the old baseline alone so the delta check still reports
    it. A missed re-baseline costs one false positive; a swallowed write costs
    a real message.
    """
    import json as _json, os as _os
    here = _os.path.dirname(_os.path.abspath(__file__))
    state = _os.path.join(here, ".pulse-state.json")
    inbox = _os.path.join(here, "inbox", f"{lane}.md")
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
    """Type into a hosted lane, then VERIFY the session actually received it.

    'send-keys succeeded' only means keystrokes were handed to the terminal. A busy
    session redraws constantly (spinner, token counts, subagent rows), and a redraw
    between the text and the Enter can wipe the input line — the message is then lost
    with no error anywhere. That happened to WS6 on 2026-07-28 and was only caught
    because Heiko asked the lane directly. Never report delivery you have not checked.
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
        # SETTLE PROPORTIONAL TO LENGTH (PM-3, 2026-07-29 — WS6 diagnosed this).
        # A fixed 2s was fine for short messages and WRONG for long ones: tmux hands
        # a long payload to the pane over time, so Enter fired while the tail was
        # still arriving — the bulk submitted and the REMAINDER stranded in the now
        # empty input line. WS6 found a verbatim fragment of a PM message sitting at
        # its own prompt and correctly identified it as the PM's, not its own. The
        # lane still RECEIVED the message, so nothing was lost — but the stranded
        # tail then blocks that lane silently (rule 31's class), and it defeats both
        # instruments at once: no tokens emitted, and nothing "changed" to detect.
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
            _ib = _os.path.join(_os.path.dirname(_os.path.abspath(__file__)),
                                "inbox", f"{lane}.md")
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
        except Exception as e:                       # HC-2: refuse, never a stale list
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
    # Backtick guard (2026-07-28, after the PM garbled two messages in one day): by the time
    # Python sees a backtick the shell has usually ALREADY substituted it away — but a literal
    # backtick that survives (single-quoted sender) would garble on some receiving shells too,
    # and refusing here is the only place a guard can live. Spell commands in plain words.
    if any(tok in text for tok in ("`", "$(", "${")):
        print("REFUSED: message contains a shell-active span (backtick, dollar-paren or "
              "dollar-brace). The bus rides a shell — these execute or blank out before "
              "delivery, usually in the SENDER's own command line. Rewrite in plain words "
              "(and single-quote the msg.py argument) and resend.")
        sys.exit(1)
    if target.lower() == "all":
        try:
            targets = lanes()                        # derived; see lanes() for why no fallback
        except Exception as e:                       # HC-2
            print(f"REFUSED: cannot read the lane roster from {_pr()}/program.yaml — {e}\n"
                  "A broadcast over a roster we cannot read would silently omit lanes, which "
                  "is the exact defect this derivation removed. Address the lane by name to "
                  "send now, and fix program.yaml before broadcasting.")
            sys.exit(1)
    else:
        targets = [target.upper()]                   # PIN: never routed through the roster
    for l in targets:
        print(send(l, text))
