---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
---

# Verification Before Completion

## Overview

Claiming work is complete without verification is dishonesty, not efficiency.

**Core principle:** Evidence before claims, always.

**Violating the letter of this rule is violating the spirit of this rule.**

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it passes.

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |
| TDD followed | `git log -p` shows failing-test commit before passing-test commit | "I followed TDD" claim |
| AC-N verified | Test named `test('B-AC-N: …'` or `test('T-AC-N: …'` is green | Some test exists in the area |
| Business AC verified | Integration / E2E (Playwright if frontend) green AND back-end effect asserted | Frontend unit test against mocked backend |
| Contract produced + safe | At least one test from a CONSUMER (or fixture acting as consumer) exercises the contract end-to-end | Producer's own unit test |
| Frontend touched safely | Playwright spec exists; spec drives browser; spec asserts back-end effect | Vitest component test |
| No new escape hatches | `git diff base..HEAD \| grep -E '@ts-ignore\|eslint-disable\|as any'` returns nothing (or every hit has an explicit justification comment) | "I didn't add any" claim |
| No retry-on-flake | Test runner config has `retries: 0` (or absent); no `sleep()` added | "It passes consistently for me" |
| Polis-bar / quality-bar gates green | `bun run typecheck && bun run lint --max-warnings 0 && bun run test --coverage && bun run benchmark` all exit 0 | Subset run |

## Red Flags - STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification
- Thinking "just this once"
- Tired and wanting work over
- **ANY wording implying success without having run verification**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |

## Key Patterns

**Tests:**
```
✅ [Run test command] [See: 34/34 pass] "All tests pass"
❌ "Should pass now" / "Looks correct"
```

**Regression tests (TDD Red-Green):**
```
✅ Write → Run (pass) → Revert fix → Run (MUST FAIL) → Restore → Run (pass)
❌ "I've written a regression test" (without red-green verification)
```

**Build:**
```
✅ [Run build] [See: exit 0] "Build passes"
❌ "Linter passed" (linter doesn't check compilation)
```

**Requirements:**
```
✅ Re-read plan → Create checklist → Verify each → Report gaps or completion
❌ "Tests pass, phase complete"
```

**Agent delegation:**
```
✅ Agent reports success → Check VCS diff → Verify changes → Report actual state
❌ Trust agent report
```

## Why This Matters

From 24 failure memories:
- your human partner said "I don't believe you" - trust broken
- Undefined functions shipped - would crash
- Missing requirements shipped - incomplete features
- Time wasted on false completion → redirect → rework
- Violates: "Honesty is a core value. If you lie, you'll be replaced."

## When To Apply

**ALWAYS before:**
- ANY variation of success/completion claims
- ANY expression of satisfaction
- ANY positive statement about work state
- Committing, PR creation, task completion
- Moving to next task
- Delegating to agents
- **Suggesting merge of a sub-PR into the feature branch** (the per-PR merge gate's verification is this skill's hardest application)
- **Marking a task DONE in TodoWrite** when working a plan

**Rule applies to:**
- Exact phrases
- Paraphrases and synonyms
- Implications of success
- ANY communication suggesting completion/correctness

## Per-PR merge gate verification (when working a plan with PR decomposition)

This skill is the **enforcer at the per-PR merge gate** defined in `superpowers:writing-plans` and orchestrated by `superpowers:executing-plans` / `superpowers:subagent-driven-development`. Before suggesting merge of any sub-PR, run every applicable verification below — fresh, in this session — and confirm each passes:

1. **TDD evidence** — `git log -p <feature-branch>..HEAD` shows, for each AC the PR verifies, a failing-test commit before the passing-test commit. If not, TDD was skipped — escalate.

2. **AC coverage** — for each B-AC-N / T-AC-N the PR claims, the test named with the AC ID is in the diff and is green. Run the test; read the output; verify the AC ID appears in the test name in the output.

   ```bash
   bun run test -- -t "B-AC-1"   # filter by AC ID; confirm it ran and passed
   bun run test -- -t "T-AC-9"
   ```

3. **Test level appropriate** — confirm by reading the test file:
   - Business AC tests are integration / E2E
   - Technical AC tests are unit / contract / CI-step
   - If the PR touched a frontend file, a Playwright spec exists, drives the browser, AND asserts a back-end effect

   Confirm frontend-touch via:
   ```bash
   git diff --name-only <feature-branch>..HEAD | grep -E '\.(tsx?|jsx?|vue|svelte|html|css|scss)$' | grep -v '\.test\.' | grep -v '\.spec\.'
   ```

   If the grep returns matches, find the corresponding Playwright spec. If none exists, **STOP** — this is a Critical merge-gate failure.

4. **Contracts exercised across consumer boundary** — for each contract the PR produces, identify the consumer-side test that uses the contract end-to-end. If the only test is the producer's unit test, the contract is unverified — escalate.

5. **Quality-bar gates green** — for projects with a quality bar (Polis-bar etc.), run the full gate command set fresh:

   ```bash
   bun run typecheck                                   # exit 0
   bun run lint --max-warnings 0                       # exit 0
   bun run test --coverage                             # exit 0; coverage thresholds met
   bun run benchmark                                   # exit 0; within baseline
   ! grep -rn 'eslint-disable' packages/*/src/         # exit 0 (no matches)
   ./scripts/check-license-headers.sh                  # exit 0
   ./scripts/check-adr-required.sh                     # exit 0 (or N/A)
   ```

   Each must exit 0 in this session. "CI was green yesterday" is not verification.

6. **No new escape hatches** —

   ```bash
   git diff <feature-branch>..HEAD | grep -nE '^\+.*(@ts-ignore|@ts-expect-error|eslint-disable|as any|as unknown as)'
   ```

   Returns nothing — or every match has an adjacent justification comment AND is permitted by the project's quality bar.

7. **No retry-on-flake config introduced** —

   ```bash
   git diff <feature-branch>..HEAD -- '*.config.*' | grep -nE '(retries|retry|retryTimes):\s*[1-9]'
   ```

   Returns nothing.

8. **ADR if non-obvious decision** — if the PR touched code at a project's "ADR-required" path (per the project's `check-adr-required.sh`), an ADR file is in the diff under the project's ADR directory and follows the project's template.

9. **CHANGELOG updated for user-facing change** — for any user-facing change, the CHANGELOG.md diff includes the entry.

If ANY of 1–9 fails, the PR is not ready. Fix it, then re-run the verification fresh — do not paper over with a rationalization or skip the failing check.

## The Bottom Line

**No shortcuts for verification.**

Run the command. Read the output. THEN claim the result.

This is non-negotiable.
