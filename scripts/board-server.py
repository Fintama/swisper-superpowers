#!/usr/bin/env python3
"""Mission Control server — serves the board on :8794 and takes Heiko's clicks.

Same static serving as before, plus one endpoint: POST /decide {id, answer, note}
appends a line to .handover/outbox-to-pm.md, which is exactly where the PM already
looks. A click therefore reaches the PM through the channel that already exists.

  python3 .handover/board-server.py &
"""
import json, os, time
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

import sys as _s, pathlib as _p
_s.path.insert(0, str(_p.Path(__file__).resolve().parent))
from program_root import program_dir as _pd, program_root as _pr
H = _pd()             # C2: was dirname(__file__)
ROOT = _pr()          # C2: was its parent
MOCKS = f"{ROOT}/docs/superpowers/specs/2026-07-25-generic-agent-and-pdlc-overview-mockups"
OUTBOX = f"{H}/outbox-to-pm.md"


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *a, **kw):
        super().__init__(*a, directory=MOCKS, **kw)

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
    print(f"Mission Control on http://localhost:8794/  (decisions → {OUTBOX})")
    ThreadingHTTPServer(("127.0.0.1", 8794), Handler).serve_forever()
