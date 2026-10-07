#!/usr/bin/env bash
# Regression arms for the programme scripts, one per fixed failure mode (FM-<name>).
# Each arm builds a throwaway programme under $TMPDIR and replaces tmux, claude, gh, git,
# pgrep and ps with stubs where the script under test calls them, so no real session,
# programme or rig is read or touched. The reaper arm runs in report mode only.
#
#   bash scripts/programme-scripts-check.sh                  # every arm
#   bash scripts/programme-scripts-check.sh FM-BOARD-DIR     # named arms only
#
# Exit: 0 every selected arm passes · 1 an arm failed
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/programme-scripts-check.XXXXXX")"
WORK="$(cd "$WORK" && pwd -P)"
trap 'rm -rf "$WORK"' EXIT
unset PROGRAM_ROOT PROGRAM_DIR PROGRAM_YAML
SELECTED=" ${*:-all} "
fails=0

say() { printf '  %-4s %s\n' "$1" "$2"; [ "$1" = FAIL ] && fails=$((fails + 1)); return 0; }
selected() { [ "$SELECTED" = " all " ] || [[ "$SELECTED" == *" $1 "* ]]; }
check() {  # check <name> <command…>: PASS when the command succeeds
    local name="$1"; shift
    if "$@"; then say PASS "$name"; else say FAIL "$name"; fi
}
has() { /usr/bin/grep -qsF -- "$2" "$1"; }
lacks() { [ -f "$1" ] && ! /usr/bin/grep -qF -- "$2" "$1"; }
stub() {  # stub <bin-dir> <name> <body>
    mkdir -p "$1"; printf '#!/usr/bin/env bash\n%s\n' "$3" > "$1/$2"; chmod +x "$1/$2"
}
programme() {  # programme <root> [extra top-level program.yaml lines…]
    local root="$1"; shift
    mkdir -p "$root/.handover/inbox"
    {
        printf 'program: Check Programme\nrepo: %s\n' "$root"
        printf 'board: {dir: .handover/board, port: 1}\n'
        printf 'goals: [{id: G-1, text: t, proof: UBER-AC-1}]\nlanes: []\n'
        [ $# -gt 0 ] && printf '%s\n' "$@"
    } > "$root/program.yaml"
}
free_port() { python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1])'; }

echo "programme scripts · one arm per fixed failure mode (throwaway programme in $WORK)"

# ---- FM-INBOX-PATH: msg.py's verified delivery must not wake ws-pulse-delta.py ----
if selected FM-INBOX-PATH; then
    echo; echo "FM-INBOX-PATH: a verified tmux delivery re-baselines the programme's own mailbox"
    root="$WORK/inbox"; programme "$root"; bin="$WORK/inbox-bin"
    # A hosted lane whose pane shows whatever is typed into it.
    stub "$bin" tmux 'case "$1" in
  has-session) exit 0 ;;
  send-keys) shift 3; case "$1" in Enter|C-u) ;; *) printf "%s\n" "$*" >> "$PANE" ;; esac ;;
  capture-pane) cat "$PANE" 2>/dev/null ;;
esac'
    stub "$bin" gh 'exit 0'
    stub "$bin" git 'exit 0'
    echo "earlier mail" > "$root/.handover/inbox/WS1.md"
    run() { (cd "$root" && env PATH="$bin:$PATH" PANE="$WORK/inbox-pane" MSG_SENDER=PM \
               PROGRAM_ROOT="$root" PROGRAM_DIR="$root/.handover" python3 "$@"); }
    run "$HERE/ws-pulse-delta.py" > "$WORK/inbox-pulse1" 2>&1
    run "$HERE/msg.py" WS1 'hello from the check' > "$WORK/inbox-send" 2>&1
    run "$HERE/ws-pulse-delta.py" > "$WORK/inbox-pulse2" 2>&1
    check "the arm drove the verified tmux path" has "$WORK/inbox-send" "delivered + verified"
    check "the message landed in the programme's mailbox" has "$root/.handover/inbox/WS1.md" "hello from the check"
    check "the next delta pulse does not report the PM's own write as lane mail" \
        lacks "$WORK/inbox-pulse2" "MAILBOX WS1.md"
fi

# ---- FM-PULSE-TRUNK: ws-pulse.py takes trunk and migrations from program.yaml ----
if selected FM-PULSE-TRUNK; then
    echo; echo "FM-PULSE-TRUNK: the pulse compares against program.yaml's trunk, with no Foundry default"
    root="$WORK/pulse"; home="$WORK/pulse-home"; mkdir -p "$root" "$home"
    g() { git -c user.name=check -c user.email=check@example.invalid "$@"; }
    g init -q -b trunk-check "$root"
    g -C "$root" commit -q --allow-empty -m "base"
    g -C "$root" worktree add -q -b ws1-branch "$root/.worktrees/ws1"
    mkdir -p "$root/.worktrees/ws1/db"
    touch "$root/.worktrees/ws1/db/0001_first.sql" "$root/.worktrees/ws1/db/0002_second.sql"
    g -C "$root/.worktrees/ws1" add -A
    g -C "$root/.worktrees/ws1" commit -q -m "lane work on ws1"
    programme "$root" "trunk: trunk-check" "migrations: db/00*.sql"
    PROGRAM_ROOT="$root" PROGRAM_DIR="$root/.handover" HOME="$home" \
        bash "$HERE/init-programme.sh" > "$WORK/pulse-init" 2>&1
    sid="11111111-2222-3333-4444-555555555555"
    python3 - "$root/.handover/ws-pulse.py" "$sid" <<'PY'
import sys
path, sid = sys.argv[1], sys.argv[2]
src = open(path).read()
row = f'    ("WS1-1 Check Lane", "{sid}", "ws1"),\n'
open(path, "w").write(src.replace("WS = [\n", "WS = [\n" + row, 1))
PY
    proj="$(PROGRAM_ROOT="$root" HOME="$home" python3 -c \
        "import sys; sys.path.insert(0, '$HERE'); from program_root import program_transcripts as t; print(t())")"
    mkdir -p "$proj"; echo '{}' > "$proj/$sid.jsonl"
    pulse() { PROGRAM_ROOT="$root" PROGRAM_DIR="$root/.handover" HOME="$home" \
                  python3 "$root/.handover/ws-pulse.py" 1 > "$1" 2>&1; }
    pulse "$WORK/pulse-out"
    check "the lane's commit ahead of program.yaml's trunk is listed" has "$WORK/pulse-out" "lane work on ws1"
    check "the latest migration from program.yaml's glob is shown" has "$WORK/pulse-out" "0002_second.sql"
    programme "$root"
    pulse "$WORK/pulse-unset"
    check "with no trunk in program.yaml the pulse says so instead of guessing one" \
        has "$WORK/pulse-unset" "no trunk in program.yaml"
fi

# ---- FM-BOARD-DIR: board-server.py serves program.yaml's board.dir ----
if selected FM-BOARD-DIR; then
    echo; echo "FM-BOARD-DIR: the board server serves board.dir from program.yaml, never the old docs path"
    root="$WORK/board"; port="$(free_port)"
    programme "$root"
    sed -i '' "s#^board: .*#board: {dir: ops/board, port: $port}#" "$root/program.yaml"
    mkdir -p "$root/ops/board"; echo "board-check-marker" > "$root/ops/board/index.html"
    (cd "$root" && PROGRAM_ROOT="$root" PROGRAM_DIR="$root/.handover" \
        exec python3 "$HERE/board-server.py") > "$WORK/board-log" 2>&1 &
    pid=$!
    body=""
    for _ in $(seq 1 25); do
        body="$(curl -s "http://127.0.0.1:$port/" 2>/dev/null)" && [ -n "$body" ] && break
        sleep 0.2
    done
    kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
    printf '%s\n' "$body" > "$WORK/board-body"
    check "GET / returns the page in program.yaml's board.dir" has "$WORK/board-body" "board-check-marker"

    rm -rf "$root/ops/board"; port="$(free_port)"
    sed -i '' "s#^board: .*#board: {dir: ops/board, port: $port}#" "$root/program.yaml"
    (cd "$root" && PROGRAM_ROOT="$root" PROGRAM_DIR="$root/.handover" \
        exec python3 "$HERE/board-server.py") > "$WORK/board-missing" 2>&1 &
    pid=$!
    sleep 2
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
        say FAIL "a missing board directory is refused at start, not served from another path"
    else
        say PASS "a missing board directory is refused at start, not served from another path"
        check "the refusal names the directory it looked for" has "$WORK/board-missing" "$root/ops/board"
    fi
fi

# ---- FM-PM-RESPAWN: spawn-lane.sh can host a successor PM beside a PM in tmux 'pm' ----
if selected FM-PM-RESPAWN; then
    echo; echo "FM-PM-RESPAWN: a successor PM spawns under its own tmux name; the guards still refuse"
    bin="$WORK/spawn-bin"; home="$WORK/spawn-home"; wt="$WORK/pm-successor"
    mkdir -p "$home/.claude/sessions"
    git init -q "$wt"; wt="$(cd "$wt" && pwd -P)"
    stub "$bin" claude 'printf "%s" "${AGENTS_JSON:-[]}"'
    # tmux: one existing session ($EXISTING, the current PM); new-session registers like Claude Code does.
    stub "$bin" tmux 'case "$1" in
  has-session) [ "$3" = "$EXISTING" ] ;;
  new-session)
    echo "$*" >> "$SPAWN_LOG"
    while [ $# -gt 0 ]; do case "$1" in -s) name="$2"; shift ;; -c) dir="$2"; shift ;; esac; shift; done
    printf "{\"sessionId\":\"succ-1\",\"cwd\":\"%s\",\"tmux\":\"%s:0\"}" "$dir" "$name" \
      > "$HOME/.claude/sessions/1.json" ;;
  capture-pane) echo "❯ " ;;
esac
exit 0'
    spawn() {  # spawn <log> <existing tmux session> <agents json> <spawn-lane args…>
        local log="$1" existing="$2" agents="$3"; shift 3
        rm -f "$home/.claude/sessions/"*.json
        env PATH="$bin:$PATH" HOME="$home" EXISTING="$existing" AGENTS_JSON="$agents" \
            SPAWN_LOG="$log.tmux" bash "$HERE/spawn-lane.sh" "$@" > "$log" 2>&1
    }
    spawn "$WORK/spawn-a" pm '[]' PM "Program Manager" 2 "$wt" --session pm-2; rc=$?
    check "with --session pm-2 beside a live tmux 'pm', the successor starts (exit 0, got $rc)" [ "$rc" -eq 0 ]
    check "the successor's tmux session is named pm-2" has "$WORK/spawn-a.tmux" "-s pm-2"
    spawn "$WORK/spawn-b" pm '[]' PM "Program Manager" 2 "$wt"; rc=$?
    check "without --session an existing tmux 'pm' is still refused (exit 70, got $rc)" [ "$rc" -eq 70 ]
    spawn "$WORK/spawn-c" none "[{\"cwd\":\"$wt\",\"name\":\"PM-1\",\"pid\":1,\"kind\":\"interactive\"}]" \
        PM "Program Manager" 2 "$wt" --session pm-2; rc=$?
    check "a directory a live session holds is still refused with --session (exit 70, got $rc)" [ "$rc" -eq 70 ]
fi

# ---- FM-PM-REAP: the PM id, filled in where the template says, is spared by the reaper ----
if selected FM-PM-REAP; then
    echo; echo "FM-PM-REAP: a PM resumed in a panel is protected once its id is in the lane map"
    root="$WORK/reap"; home="$WORK/reap-home"; bin="$WORK/reap-bin"; mkdir -p "$home"
    programme "$root"
    PROGRAM_ROOT="$root" PROGRAM_DIR="$root/.handover" HOME="$home" \
        bash "$HERE/init-programme.sh" > "$WORK/reap-init" 2>&1
    pm="aaaaaaaa-1111-2222-3333-444444444444"; old="bbbbbbbb-1111-2222-3333-444444444444"
    python3 - "$root/.handover/ws-pulse.py" "$pm" "$old" <<'PY'
import re, sys
path, pm, old = sys.argv[1:]
src = open(path).read()
# Fill the PM id into the template's own PM line, and retire an old lane as a comment.
src = re.sub(r'^(.*\bPM = ")<session-uuid>(".*)$', rf"\g<1>{pm}\g<2>", src, count=1, flags=re.M)
src = src.replace("WS = [\n", f'WS = [\n    # ("WS1-1 Retired Lane", "{old}", "ws1"),\n', 1)
open(path, "w").write(src)
PY
    stub "$bin" pgrep 'printf "4242\n4343\n"'
    stub "$bin" ps "case \"\$2\" in 4242) echo \"claude --resume=$pm\" ;; 4343) echo \"claude --resume=$old\" ;; esac"
    env PATH="$bin:$PATH" PROGRAM_ROOT="$root" PROGRAM_DIR="$root/.handover" \
        bash "$HERE/reap-ghosts.sh" > "$WORK/reap-out" 2>&1
    check "the resumed PM's session is reported LIVE, not a ghost" has "$WORK/reap-out" "LIVE  pid 4242  $pm"
    check "a retired id left in a comment is still reported as a ghost" has "$WORK/reap-out" "GHOST pid 4343  $old"
fi

echo
if [ "$fails" -gt 0 ]; then echo "FAIL — $fails check(s)"; exit 1; fi
echo "PASS — every selected arm holds."
