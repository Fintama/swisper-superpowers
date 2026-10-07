#!/usr/bin/env python3
"""Mission Control server: serves the board and takes the human's clicks.

  GET  /            static board files
  POST /decide      {id, answer, note} -> appends to .handover/outbox-to-pm.md, where the PM looks
  GET  /state       {answers, acks} -> what is already answered and what the PM did about it,
                    so a reload keeps answers and the sender can tell "seen" from "lost"

Whoever starts this server arms a watch on the outbox in the same turn, so a click wakes
the PM instead of waiting to be noticed:

    Monitor(command: 'tail -n 0 -f <root>/.handover/outbox-to-pm.md '
                     '| grep --line-buffered "via board"',
            persistent: true)

  `tail -n 0` or every historical line replays on arming.
  `--line-buffered` or grep holds matches in its buffer and the watch is silently dead.

  python3 "$CLAUDE_PLUGIN_ROOT/scripts/board-server.py" &
"""
import json
import os
import re
import time
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

import sys as _s, pathlib as _p
_s.path.insert(0, str(_p.Path(__file__).resolve().parent))
from program_root import program_dir as _pd, program_root as _pr

H = _pd()
ROOT = _pr()
OUTBOX = f"{H}/outbox-to-pm.md"

# board.dir (relative to the programme root) and board.port from program.yaml; without
# one, the programme's own board directory. Ports are global to the machine, so a second
# programme on the same laptop needs its own board.port.
BOARD, PORT = f"{H}/board", 8794
try:
    import yaml  # noqa: F401  (PyYAML is a documented prerequisite)
    with open(f"{ROOT}/program.yaml") as _f:
        _board = yaml.safe_load(_f).get("board") or {}
    BOARD = os.path.join(ROOT, _board.get("dir", BOARD))
    PORT = int(_board.get("port", PORT))
except Exception:
    pass
# Written by the PM AFTER acting: {"<decision id>": {"at": "...", "did": "<what happened>"}}
ACKS = f"{BOARD}/acks.json"

_LINE = re.compile(r"HEIKO (\S+) (\S+) \[via board\] — \*\*(.+?)\*\* → \*\*(.+?)\*\*")


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *a, **kw):
        super().__init__(*a, directory=BOARD, **kw)

    def end_headers(self):
        # The PM regenerates the board by hand; never let a browser serve a stale one.
        self.send_header("Cache-Control", "no-store, must-revalidate")
        super().end_headers()

    def do_GET(self):
        if self.path != "/state":
            return super().do_GET()
        answers, acks = {}, {}
        try:
            with open(OUTBOX) as f:
                for line in f:
                    m = _LINE.match(line)
                    if m:
                        d, t, item, ans = m.groups()
                        answers[item] = {"answer": ans, "at": f"{d} {t}"}  # last wins
        except FileNotFoundError:
            pass
        try:
            with open(ACKS) as f:
                acks = json.load(f)
        except (FileNotFoundError, ValueError):
            pass
        body = json.dumps({"answers": answers, "acks": acks}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        if self.path != "/decide":
            return self.send_error(404)
        try:
            body = json.loads(self.rfile.read(int(self.headers["Content-Length"] or 0)))
            item, answer = str(body.get("id", "?"))[:200], str(body.get("answer", "?"))[:200]
            note = str(body.get("note", ""))[:500]
            line = (f"HEIKO {time.strftime('%Y-%m-%d %H:%M')} [via board] — "
                    f"**{item}** → **{answer}**" + (f" · {note}" if note else "") + "\n")
            with open(OUTBOX, "a") as f:
                f.write(line)
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"ok": True, "recorded": line.strip()}).encode())
        except Exception as e:
            self.send_error(500, str(e))

    def log_message(self, *a):
        pass  # quiet


if __name__ == "__main__":
    if not os.path.isdir(BOARD):
        _s.exit(f"REFUSED: the board directory {BOARD} does not exist. Create it, or set "
                "board.dir in program.yaml.")
    print(f"Mission Control on http://localhost:{PORT}/   (serving {BOARD})")
    print(f"decisions → {OUTBOX}")
    print("⚠ Arm the Monitor watch on that file, or a click will not wake the PM.")
    ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
