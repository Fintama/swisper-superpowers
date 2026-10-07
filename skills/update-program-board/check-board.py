#!/usr/bin/env python3
"""Check a Mission Control board after an edit; exit 1 on any failure.

    python3 check-board.py [board-dir] [--url http://localhost:8794]
"""
import argparse
import json
import re
import sys
import urllib.request
from html.parser import HTMLParser
from pathlib import Path

VOID = {"area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta",
        "source", "track", "wbr"}
PANELS = ["panel-open", "panel-decided", "panel-record"]
PROSE_IN_ONCLICK = re.compile(r'onclick="[A-Za-z_]+\(["\']')
CARD_ID = re.compile(r'class="[^"]*\bdcard\b[^"]*"[^>]*\bdata-id="([^"]+)"')


class Nesting(HTMLParser):
    def __init__(self):
        super().__init__()
        self.stack, self.problems = [], []

    def handle_starttag(self, tag, attrs):
        if tag not in VOID:
            self.stack.append((tag, self.getpos()[0]))

    def handle_endtag(self, tag):
        if tag in VOID:
            return
        if not self.stack or self.stack[-1][0] != tag:
            opened = self.stack[-1] if self.stack else ("nothing", 0)
            self.problems.append(f"line {self.getpos()[0]}: </{tag}> closes <{opened[0]}> from line {opened[1]}")
            if any(t == tag for t, _ in self.stack):
                while self.stack and self.stack[-1][0] != tag:
                    self.stack.pop()
                self.stack.pop()
            return
        self.stack.pop()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("board_dir", nargs="?", default=".")
    ap.add_argument("--url", default="http://localhost:8794")
    args = ap.parse_args()
    board = Path(args.board_dir)
    index = (board / "index.html").read_text()
    failures = []

    try:
        code = urllib.request.urlopen(args.url + "/", timeout=5).status
    except Exception as e:
        code = f"unreachable ({e})"
    if code != 200:
        failures.append(f"board at {args.url}/ answered {code}, not 200")

    for page in sorted(board.glob("*.html")):
        for n, line in enumerate(page.read_text().splitlines(), 1):
            if PROSE_IN_ONCLICK.search(line):
                failures.append(f"{page.name}:{n}: prose inside an onclick call")

    found = re.findall(r'id="(panel-[a-z]+)"', index)
    if found != PANELS:
        failures.append(f"panel ids are {found}, expected each of {PANELS} once, in that order")

    parser = Nesting()
    parser.feed(index)
    failures += [f"index.html nesting: {p}" for p in parser.problems]
    failures += [f"index.html nesting: <{t}> from line {n} never closed" for t, n in parser.stack]

    cards = CARD_ID.findall(index)
    try:
        state = json.load(urllib.request.urlopen(args.url + "/state", timeout=5))
        answered = set(state.get("answers", {})) | set(state.get("acks", {}))
        still_open = [c for c in cards if c not in answered]
        print(f"OPEN ({len(still_open)}):")
        for c in still_open:
            print("   -", c)
        print(f"DECIDED: {len(cards) - len(still_open)}")
        for orphan in sorted(answered - set(cards)):
            print(f"WARN answer or ack for '{orphan}' matches no card's data-id (removed card, or a mismatched id)")
    except Exception as e:
        failures.append(f"/state not readable: {e}")

    for f in failures:
        print("FAIL", f)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
