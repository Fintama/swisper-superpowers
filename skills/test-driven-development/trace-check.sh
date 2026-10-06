#!/usr/bin/env bash
# trace-check.sh — does every NEW test case name what it proves?
#
# Rule R2 of test-driven-development: a test's title carries an AC id
# (UBER-AC-n / B-AC-n / T-AC-n), an invariant id (INV-x, I-n / In) or a
# documented failure mode (FM-x; a bug ticket is FM-<ticket>).
#
#   usage:  trace-check.sh [RANGE]        RANGE defaults to origin/main...HEAD
#           trace-check.sh --self-test    positive control: fixture diffs, red and green
#
#   exit 0  every new test case is traced (or allowed, with a reason)
#   exit 1  at least one new test case is untraced — each is listed
#   exit 2  could not run (bad range, not a git repo)
#
# Reads: vitest/jest/node:test/playwright `it(` / `test(` (incl. .only/.skip/
# .each/…), and pytest `def test_…`. Only the test's own title is read: an id
# on an enclosing describe() does not count, because the diff cannot see it.
#
# Escape (the allow-list): `trace-allow: <reason>` in a comment on the test's
# line or on the line directly above it. The reason must be at least 10
# characters; an empty or token reason is itself reported as untraced. Every
# allowed case is printed with its reason, so the escape is visible in review.
#
# Extra id shapes for one project: TRACE_CHECK_ID_RE='AUTH_[0-9]{3}' (ERE).
#
# Also prints tests added and removed in the range, for the report's net growth (R7).
set -u

if [ "${1:-}" = "--self-test" ]; then
    # Positive control: one fixture commit per case in a throwaway repo, each with its expected exit code.
    self=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")
    tmp=$(mktemp -d) || exit 2
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp" && git init -q && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m base
    fails=0
    # Each case also states how many test cases must be seen: a green that scanned none proves nothing.
    expect() {  # expect <exit-code> <cases-seen> <label> <file> <content>
        mkdir -p "$(dirname "$4")"; printf '%s\n' "$5" > "$4"
        git add -A && git -c user.email=t@t -c user.name=t commit -q -m "$3"
        out=$(bash "$self" HEAD~1..HEAD 2>&1); got=$?
        seen=$(printf '%s\n' "$out" | sed -n 's/^trace-check: \([0-9]*\) test case.*/\1/p')
        if [ "$got" -eq "$1" ] && [ "$seen" = "$2" ]; then echo "ok    exit $got  seen $seen  $3"
        else echo "WRONG exit $got (want $1), seen ${seen:-?} (want $2)  $3"; echo "$out" | sed 's/^/      /'; fails=$((fails + 1)); fi
    }
    expect 1 1 "untraced vitest it()"            a.test.ts "it('returns the right total', () => {})"
    expect 0 1 "traced vitest test()"            b.test.ts "test('B-AC-1: gold customer pays 108', () => {})"
    expect 0 3 "invariant + failure-mode ids"    c.spec.ts "$(printf "it('INV-1: total never negative', f)\ntest('FM-2: unknown customer is 404', f)\nit('I3: one Result per Task', f)")"
    expect 1 1 "id only on describe()"           d.test.ts "$(printf "describe('B-AC-2', () => {\n  it('works', () => {})\n})")"
    expect 0 1 "allowed, with a reason"          e.test.ts "$(printf "// trace-allow: characterises the vendor SDK retry header we depend on\nit('sends x-retry', f)")"
    expect 1 1 "allowed, reason too short"       f.test.ts "it('sends x-retry', f) // trace-allow: needed"
    expect 1 1 "untraced pytest"                 tests/test_price.py "def test_rounds_to_five_rappen():"
    expect 0 1 "traced pytest (snake case id)"   tests/test_order.py "def test_b_ac_1_gold_discount():"
    expect 1 1 "multi-line title, untraced"      g.test.ts "$(printf "it(\n  'calls store.save once',\n  f)")"
    expect 0 1 "multi-line title, traced"        k.test.ts "$(printf "it(\n  'FM-1: unknown coupon is refused',\n  f)")"
    expect 1 1 "test.each table, untraced title" h.test.ts "$(printf "test.each([\n  [1, 2],\n])('adds %%s', f)")"
    expect 0 1 "test.each table, traced title"   i.test.ts "$(printf "test.each([\n  [1, 2],\n])('B-AC-3: adds %%s', f)")"
    expect 1 1 "it.each(X)( title on next line, untraced" m.test.ts "$(printf "it.each(cases)(\n  'adds %%s',\n  f)")"
    expect 0 1 "it.each(X)( title on next line, traced"   n.test.ts "$(printf "it.each(cases)(\n  'B-AC-3: adds %%s',\n  f)")"
    expect 0 1 "test.each [...] as const table, traced"   o.test.ts "$(printf "test.each([\n  [1, 2],\n] as const)('B-AC-3: adds %%s', f)")"
    expect 1 1 "test.each [...] as const table, untraced" p.test.ts "$(printf "test.each([\n  [1, 2],\n] as const)('adds %%s', f)")"
    expect 0 1 "test.each table, title on line after ])(" q.test.ts "$(printf "test.each([\n  [1, 2],\n])(\n  'B-AC-3: adds %%s',\n  f)")"
    # A table the parser cannot close must not swallow the tests after it (a false PASS).
    expect 1 2 "unreadable table does not hide a later untraced test" r.test.ts "$(printf "test.each(\n  makeRows(\n    1,\n  ) satisfies Row[],\n)\n('B-AC-3: adds %%s', f)\nit('renders the page', f)")"
    expect 1 1 "it.each template table, untraced" l.test.ts "$(printf "it.each\`\n  a | b\n  \${1} | \${2}\n\`('adds \$a', f)")"
    expect 0 0 "removing a test is not adding one" b.test.ts ""
    expect 0 0 "non-test file is ignored"        src/x.ts "it('not a test file', f)"
    expect 0 0 "hooks and steps are not cases"   j.test.ts "$(printf "test.describe('x', f)\ntest.beforeEach(f)\nawait test.step('do', f)")"
    # Deleting a whole test file counts as removals; R7's net growth depends on it.
    git rm -q c.spec.ts && git -c user.email=t@t -c user.name=t commit -q -m "delete a test file"
    if bash "$self" HEAD~1..HEAD | grep -q '0 test case(s) added, 3 removed'; then echo "ok    deleting a file with 3 tests counts 3 removed"
    else echo "WRONG deleting a file with 3 tests did not count 3 removed"; fails=$((fails + 1)); fi
    [ "$fails" -eq 0 ] && { echo "self-test: PASS — every case gave its expected exit code"; exit 0; }
    echo "self-test: FAIL — $fails case(s) wrong"; exit 1
fi

git rev-parse --git-dir >/dev/null 2>&1 || { echo "trace-check: not a git repository"; exit 2; }
RANGE=${1:-origin/main...HEAD}
diff_out=$(git diff --no-color --no-ext-diff --unified=0 --diff-filter=AMRD "$RANGE" -- \
    '*.test.*' '*.spec.*' '*_test.py' '*test_*.py' 2>&1) || {
    echo "trace-check: git diff failed for range '$RANGE':"; echo "$diff_out" | head -3; exit 2; }

printf '%s\n' "$diff_out" | awk -v extra="${TRACE_CHECK_ID_RE:-}" '
function is_test_file(f) {
    return f ~ /\.(test|spec)\.[cm]?[jt]sx?$/ || f ~ /(^|\/)test_[^\/]*\.py$/ || f ~ /_test\.py$/
}
# Return the first string literal at the start of s (after spaces), or "" if none.
function first_literal(s,   q, i, c, out) {
    sub(/^[ \t]*/, "", s)
    q = substr(s, 1, 1)
    if (q != "\"" && q != "\047" && q != "`") return ""
    out = ""
    for (i = 2; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c == "\\") { out = out substr(s, i + 1, 1); i++; continue }
        if (c == q) return out
        out = out c
    }
    return out   # unterminated on this line: use what we have
}
function traced(t,   u) {
    u = toupper(t)
    if (u ~ /(^|[^A-Z0-9])(UBER|B|T)[-_]AC[-_]?[0-9]+/) return 1
    if (u ~ /(^|[^A-Z0-9])INV[-_]?[A-Z0-9]+/) return 1
    if (u ~ /(^|[^A-Z0-9])FM[-_][A-Z0-9]+/) return 1
    if (u ~ /(^|[^A-Z0-9])I[-_]?[0-9]+([^A-Z0-9]|$)/) return 1
    if (extra != "" && t ~ extra) return 1
    return 0
}
function allow_reason(line,   r) {
    if (line !~ /trace-allow:/) return ""
    r = line; sub(/.*trace-allow:[ \t]*/, "", r); sub(/[ \t]*(\*\/|-->)?[ \t]*$/, "", r)
    return r
}
# A JS test-case head: it( / test( with optional modifiers, never describe/step/hooks.
function js_head(s) {
    return s ~ /^[ \t]*(it|test)(\.(only|skip|todo|concurrent|sequential|fails|failing|fixme))*(\.each)?[ \t]*[(`]/
}
function record(kind, file, ln, title, prev,   r) {
    if (kind == "-") { removed++; return }
    added++
    r = allow_reason(cur_line); if (r == "") r = allow_reason(prev)
    if (traced(title)) { ok++; return }
    if (r != "" && length(r) >= 10) { allowed++; printf "ALLOWED    %s:%d  %s\n           reason: %s\n", file, ln, title, r; return }
    bad++
    if (title == "") title = "<title is not a string literal — cannot be read>"
    printf "UNTRACED   %s:%d  %s\n", file, ln, title
}
/^diff --git / { if (pend != "" && file != "") record(pend_sign, file, pend_ln, "", pend_prev); file = ""; pend = ""; next }
/^--- / { old = substr($0, 5); sub(/^a\//, "", old); next }
/^\+\+\+ / { f = substr($0, 5); if (f == "/dev/null") f = old; sub(/^b\//, "", f); file = is_test_file(f) ? f : ""; next }
/^@@ / { split($0, h, " "); n = h[3]; sub(/^\+/, "", n); split(n, nn, ","); ln = nn[1] + 0; prev_add = ""; next }
file == "" { next }
/^[+-]/ {
    sign = substr($0, 1, 1); s = substr($0, 2); cur_line = s
    # title of a head seen on the previous line (multi-line call, or .each table)
    if (pend == "each" && sign == pend_sign && js_head(s)) {
        # A new test began while a table was still open: count the case of the table as untraced
        # and scan this line normally, so it is not swallowed.
        record(sign, file, pend_ln, "", pend_prev); pend = ""
    }
    if (pend != "" && sign == pend_sign) {
        if (pend == "call") { record(sign, file, pend_ln, first_literal(s), pend_prev); pend = "" }
        else if (match(s, /\)[ \t]*\(/) || match(s, /`[ \t]*\(/)) {
            # the table closes: `])(`, `] as const)(`, `X)(`, or the template form
            rest = substr(s, RSTART + RLENGTH)
            if (rest ~ /^[ \t]*$/) pend = "call"          # title on the next line
            else { record(sign, file, pend_ln, first_literal(rest), pend_prev); pend = "" }
        }
        else if (++pend_n > 80) { record(sign, file, pend_ln, "", pend_prev); pend = "" }  # give up, counted
        if (sign == "+") { prev_add = s; ln++ }
        next
    }
    if (js_head(s)) {
        x = s; sub(/^[ \t]*(it|test)[^(`]*/, "", x)
        if (s ~ /\.each[ \t]*[(`]/) {
            # test.each([...])("title", fn) — the title follows the table
            if (match(x, /\)[ \t]*\(/)) {
                rest = substr(x, RSTART + RLENGTH)
                # it.each(X)(  — the formatter put the title on the next line
                if (rest ~ /^[ \t]*$/) { pend = "call"; pend_sign = sign; pend_ln = ln; pend_prev = prev_add }
                else record(sign, file, ln, first_literal(rest), prev_add)
            }
            else { pend = "each"; pend_n = 0; pend_sign = sign; pend_ln = ln; pend_prev = prev_add }
        } else {
            sub(/^\(/, "", x)
            if (x ~ /^[ \t]*$/) { pend = "call"; pend_sign = sign; pend_ln = ln; pend_prev = prev_add }
            else record(sign, file, ln, first_literal(x), prev_add)
        }
    } else if (s ~ /^[ \t]*(async[ \t]+)?def[ \t]+test_[A-Za-z0-9_]*[ \t]*\(/) {
        t = s; sub(/^[ \t]*(async[ \t]+)?def[ \t]+/, "", t); sub(/[ \t]*\(.*/, "", t)
        record(sign, file, ln, t, prev_add)
    }
    if (sign == "+") { prev_add = s; ln++ }
    next
}
END {
    if (pend != "" && file != "") record(pend_sign, file, pend_ln, "", pend_prev)
    printf "\ntrace-check: %d test case(s) added, %d removed (net %+d) · %d traced · %d allowed · %d untraced\n", added, removed, added - removed, ok, allowed, bad
    if (bad > 0) {
        print "FAIL — each test above must name what it proves in its title: an AC id (B-AC-n / T-AC-n /"
        print "       UBER-AC-n), an invariant (INV-x / I-n) or a documented failure mode (FM-x)."
        print "       Cannot name one? Do not keep the test. Genuine exception? `trace-allow: <reason>`."
        exit 1
    }
    print "PASS"
}'
