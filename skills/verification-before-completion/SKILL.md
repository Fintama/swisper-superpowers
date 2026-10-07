---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
---

# Verification Before Completion

**Evidence before claims.** Don't say work is done, fixed or passing until you have read
fresh evidence for it. The exception: you may report something you have not verified if
you say so plainly ("not verified: the e2e suite has not run on this commit").

## What counts as verified

**Verified means fresh evidence for THIS commit**, the SHA you are making the claim
about, from one of:

- **a scoped run** you did on it: the tests for the change, the existing tests of the
  module you touched, and the project's core smoke set (the test tiers in
  `swisper-superpowers:test-driven-development`); or
- **CI's run on that SHA**, whose result you have read.

The full suite is CI's job; run it locally only when asked. Not evidence for this commit:
a run on an earlier commit, a run before your last edit, an agent's or colleague's
report, "CI was green yesterday".

## The gate

1. **Identify** the command or CI check that proves the claim.
2. **Run** it on this commit, or open CI's result for this SHA.
3. **Read** all of it: exit code, failure count, which tests actually ran.
4. **Claim** exactly what it shows, with the evidence (count, check name, SHA). If it
   doesn't confirm the claim, report the actual state.

"Should pass", "probably", "seems to", "Done!" before step 3 are claims without evidence.

## What each claim needs

| Claim | Evidence | Not enough |
|---|---|---|
| Tests pass | test output: 0 failures, the expected tests ran | an earlier run, "should pass" |
| Lint clean | linter output: 0 errors | a partial check |
| Build succeeds | build exits 0 | lint passing, logs look fine |
| Bug fixed | the original symptom, reproduced, now gone | code changed |
| Regression test works | red-green: it fails without the fix (see Positive control) | it passes once |
| Requirements met | the plan or spec re-read, each item checked, gaps listed | tests pass |
| TDD followed | `git log -p`: the failing-test commit precedes the fix | "I followed TDD" |
| AC-N verified | a test titled with its id (`B-AC-N: …`, `T-AC-N: …`) is green | some test in the area |
| Business AC, frontend touched | a front-to-back test at promise altitude, as `test-driven-development/proving-acs.md` defines | a component test against a mocked backend |
| Contract safe | a test from a consumer (or a fixture acting as one) exercises it | the producer's own unit test |
| No new escape hatches | the diff grep below is empty, or each hit has its reason on the same line | "I didn't add any" |
| No retry-on-flake | no retry config and no added `sleep()` in the diff | "it passes for me" |
| Delegated work done | the diff, and evidence you read yourself | the agent says "success" |

## Positive control

**A check that cannot fail proves nothing.** Before you rely on a test, gate, lint or
script to catch something: break it on purpose, run it, watch it go red for the expected
reason, restore, watch it go green.

- Regression test: revert the fix, run (it must fail), restore, run (it passes).
- AC test: break the behaviour the AC promises and watch the test name the break.
- Gate or script: feed it the thing it exists to catch (a broken id, the forbidden
  pattern) and see it report it; use its `--self-test` where it has one.
- An empty result (no matches, 0 tests ran, skipped) is not green until you know the
  check ran on something: a filter that matches nothing passes silently.

## When to apply

Before any statement that work is done, fixed or passing, in any wording; before a
commit, push or PR; before marking a task done or moving to the next one; before
suggesting a sub-PR merge; before passing on an agent's result.

## At a per-PR merge gate

The checklist is the plan's merge gate (`swisper-superpowers:writing-plans`) and the
reviewer's (`swisper-superpowers:requesting-code-review`, `code-reviewer.md`). This skill
supplies the evidence for each line, on the commit being proposed:

```bash
git log -p <feature-branch>..HEAD                       # failing-test commit before each fix
<test runner> -t "B-AC-1"                               # the id appears in the output as run and passed
trace-check.sh <feature-branch>..HEAD                   # every new test names an id
git diff --name-only <feature-branch>..HEAD | grep -E '\.(tsx?|jsx?|vue|svelte|html|css|scss)$' | grep -vE '\.(test|spec)\.'
git diff <feature-branch>..HEAD | grep -nE '^\+.*(@ts-ignore|@ts-expect-error|eslint-disable|as any|as unknown as)'
git diff <feature-branch>..HEAD -- '*.config.*' | grep -nE '(retries|retry|retryTimes):\s*[1-9]'
```

A frontend file in the diff needs its front-to-back test (proving-acs.md); a contract
needs its consumer test, named; the project's quality gates need CI's result for this
SHA or a run of the gate commands on it. Any line without evidence means the PR is not
ready: fix it and verify again on the new commit.
