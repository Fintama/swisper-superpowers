# Testing Anti-Patterns

**Load this reference when:** writing or changing tests, adding mocks, or tempted to add test-only methods to production code.

## Overview

Tests must verify real behavior, not mock behavior. Mocks are a means to isolate, not the thing being tested.

**Core principle:** Test what the code does, not what the mocks do.

**Following strict TDD prevents these anti-patterns.**

## The Iron Laws

```
1. NEVER test mock behavior
2. NEVER add test-only methods to production classes
3. NEVER mock without understanding dependencies
```

## Anti-Pattern 1: Testing Mock Behavior

**The violation:**
```typescript
// ❌ BAD: Testing that the mock exists
test('renders sidebar', () => {
  render(<Page />);
  expect(screen.getByTestId('sidebar-mock')).toBeInTheDocument();
});
```

**Why this is wrong:**
- You're verifying the mock works, not that the component works
- Test passes when mock is present, fails when it's not
- Tells you nothing about real behavior

**your human partner's correction:** "Are we testing the behavior of a mock?"

**The fix:**
```typescript
// ✅ GOOD: Test real component or don't mock it
test('renders sidebar', () => {
  render(<Page />);  // Don't mock sidebar
  expect(screen.getByRole('navigation')).toBeInTheDocument();
});

// OR if sidebar must be mocked for isolation:
// Don't assert on the mock - test Page's behavior with sidebar present
```

### Gate Function

```
BEFORE asserting on any mock element:
  Ask: "Am I testing real component behavior or just mock existence?"

  IF testing mock existence:
    STOP - Delete the assertion or unmock the component

  Test real behavior instead
```

## Anti-Pattern 2: Test-Only Methods in Production

**The violation:**
```typescript
// ❌ BAD: destroy() only used in tests
class Session {
  async destroy() {  // Looks like production API!
    await this._workspaceManager?.destroyWorkspace(this.id);
    // ... cleanup
  }
}

// In tests
afterEach(() => session.destroy());
```

**Why this is wrong:**
- Production class polluted with test-only code
- Dangerous if accidentally called in production
- Violates YAGNI and separation of concerns
- Confuses object lifecycle with entity lifecycle

**The fix:**
```typescript
// ✅ GOOD: Test utilities handle test cleanup
// Session has no destroy() - it's stateless in production

// In test-utils/
export async function cleanupSession(session: Session) {
  const workspace = session.getWorkspaceInfo();
  if (workspace) {
    await workspaceManager.destroyWorkspace(workspace.id);
  }
}

// In tests
afterEach(() => cleanupSession(session));
```

### Gate Function

```
BEFORE adding any method to production class:
  Ask: "Is this only used by tests?"

  IF yes:
    STOP - Don't add it
    Put it in test utilities instead

  Ask: "Does this class own this resource's lifecycle?"

  IF no:
    STOP - Wrong class for this method
```

## Anti-Pattern 3: Mocking Without Understanding

**The violation:**
```typescript
// ❌ BAD: Mock breaks test logic
test('detects duplicate server', () => {
  // Mock prevents config write that test depends on!
  vi.mock('ToolCatalog', () => ({
    discoverAndCacheTools: vi.fn().mockResolvedValue(undefined)
  }));

  await addServer(config);
  await addServer(config);  // Should throw - but won't!
});
```

**Why this is wrong:**
- Mocked method had side effect test depended on (writing config)
- Over-mocking to "be safe" breaks actual behavior
- Test passes for wrong reason or fails mysteriously

**The fix:**
```typescript
// ✅ GOOD: Mock at correct level
test('detects duplicate server', () => {
  // Mock the slow part, preserve behavior test needs
  vi.mock('MCPServerManager'); // Just mock slow server startup

  await addServer(config);  // Config written
  await addServer(config);  // Duplicate detected ✓
});
```

### Gate Function

```
BEFORE mocking any method:
  STOP - Don't mock yet

  1. Ask: "What side effects does the real method have?"
  2. Ask: "Does this test depend on any of those side effects?"
  3. Ask: "Do I fully understand what this test needs?"

  IF depends on side effects:
    Mock at lower level (the actual slow/external operation)
    OR use test doubles that preserve necessary behavior
    NOT the high-level method the test depends on

  IF unsure what test depends on:
    Run test with real implementation FIRST
    Observe what actually needs to happen
    THEN add minimal mocking at the right level

  Red flags:
    - "I'll mock this to be safe"
    - "This might be slow, better mock it"
    - Mocking without understanding the dependency chain
```

## Anti-Pattern 4: Incomplete Mocks

**The violation:**
```typescript
// ❌ BAD: Partial mock - only fields you think you need
const mockResponse = {
  status: 'success',
  data: { userId: '123', name: 'Alice' }
  // Missing: metadata that downstream code uses
};

// Later: breaks when code accesses response.metadata.requestId
```

**Why this is wrong:**
- **Partial mocks hide structural assumptions** - You only mocked fields you know about
- **Downstream code may depend on fields you didn't include** - Silent failures
- **Tests pass but integration fails** - Mock incomplete, real API complete
- **False confidence** - Test proves nothing about real behavior

**The Iron Rule:** Mock the COMPLETE data structure as it exists in reality, not just fields your immediate test uses.

**The fix:**
```typescript
// ✅ GOOD: Mirror real API completeness
const mockResponse = {
  status: 'success',
  data: { userId: '123', name: 'Alice' },
  metadata: { requestId: 'req-789', timestamp: 1234567890 }
  // All fields real API returns
};
```

### Gate Function

```
BEFORE creating mock responses:
  Check: "What fields does the real API response contain?"

  Actions:
    1. Examine actual API response from docs/examples
    2. Include ALL fields system might consume downstream
    3. Verify mock matches real response schema completely

  Critical:
    If you're creating a mock, you must understand the ENTIRE structure
    Partial mocks fail silently when code depends on omitted fields

  If uncertain: Include all documented fields
```

## Anti-Pattern 5: Integration Tests as Afterthought

**The violation:**
```
✅ Implementation complete
❌ No tests written
"Ready for testing"
```

**Why this is wrong:**
- Testing is part of implementation, not optional follow-up
- TDD would have caught this
- Can't claim complete without tests

**The fix:**
```
TDD cycle:
1. Write failing test
2. Implement to pass
3. Refactor
4. THEN claim complete
```

## Anti-Pattern 6: Shared Global State Between Tests

**The violation:**
```typescript
// ❌ BAD: tests mutate module-level state
const cache = new Map<string, User>();

test('caches user on first lookup', async () => {
  await getUser('alice');
  expect(cache.has('alice')).toBe(true);
});

test('returns cached user on second lookup', async () => {
  // Depends on previous test having run! Flake-amplifier.
  expect(cache.has('alice')).toBe(true);
});
```

**Why this is wrong:**
- The second test only passes if the first ran before it
- Random execution order (`vitest --shuffle`) breaks the suite
- The fail mode is "passes on my machine, fails in CI" — debugging hell
- Hides ordering bugs in the system under test

### Gate Function

```
BEFORE writing a test that reads existing state:
  Ask: "Does this state get reset between tests?"

  IF reset comes from beforeEach:
    OK — but verify the hook actually runs (forgotten beforeEach is common)

  IF reset comes from "the test that ran before":
    STOP — refactor. Each test sets up its own state.
```

**The fix:**

```typescript
// ✅ GOOD: each test owns its setup
test('caches user on first lookup', async () => {
  const cache = new Map<string, User>();
  await getUser('alice', { cache });
  expect(cache.has('alice')).toBe(true);
});

test('returns cached user on second lookup', async () => {
  const cache = new Map<string, User>();
  await getUser('alice', { cache });
  await getUser('alice', { cache });
  expect(getUserCallCount('alice')).toBe(1);  // assert behavior, not internal state
});
```

Configure the test runner to randomize order at least nightly. If random-order fails but sequential passes, you have hidden coupling.

## Anti-Pattern 7: Retry-on-Flake (Hiding Real Bugs)

**The violation:**
```typescript
// ❌ BAD: retries hide a real race condition
// vitest.config.ts
export default defineConfig({
  test: { retry: 3, ... }
});

// playwright.config.ts
export default defineConfig({
  retries: 3,
  ...
});
```

**Why this is wrong:**
- A test that passes 1 time in 3 has a real bug — either in the test (timing assumption) or in the system (race condition)
- Retries hide the bug and train the team to ignore failures
- Production users don't get retries; the bug ships

### Gate Function

```
BEFORE adding `retry`, `retries`, `retryTimes`, or any retry config:
  STOP — the test is a bug, not the runner.

  Apply systematic-debugging Phase 1: find the root cause.
  Common causes:
    - Order coupling (Anti-Pattern 6)
    - Time / random / clock leakage
    - Real race condition in the system under test
    - sleep() instead of condition-based waiting

  IF you cannot find the cause:
    Delete the test. A flaky test is worse than no test.
```

**The fix:** zero retries in CI for the merge gate. Fix the flake's root cause, or delete it.

## Anti-Pattern 8: Test-Only Env Vars in Production Code

**The violation:**
```typescript
// ❌ BAD: production code branches on test env var
function authenticate(token: string) {
  if (process.env.NODE_ENV === 'test') {
    return { user: 'test-user', skipChecks: true };
  }
  return realAuthenticate(token);
}
```

**Why this is wrong:**
- Production code has paths that only execute in tests — coverage of "real" code is fake
- The "real" code path has never been exercised by the test suite
- Forgetting the env var in some prod environment ships the bypass to production

**The fix:** dependency-inject the dependency. Tests pass a fake; production passes the real.

```typescript
// ✅ GOOD: dependency-injected, no env-var branching
function authenticate(token: string, authProvider: AuthProvider) {
  return authProvider.verify(token);
}

// In tests
const fakeAuthProvider = { verify: () => ({ user: 'test-user' }) };
authenticate('any', fakeAuthProvider);

// In production
authenticate(token, realAuthProvider);
```

## Anti-Pattern 9: Frontend Unit Test as Substitute for E2E

**The violation:**
```typescript
// ❌ BAD: frontend unit test against mocked backend, claimed as full coverage
import { vi } from 'vitest';

vi.mock('../api/chat', () => ({
  sendMessage: vi.fn().mockResolvedValue({ id: 1, text: 'reply' }),
}));

test('B-AC-1: chat workflow works', async () => {
  render(<ChatPage />);
  await userEvent.type(screen.getByRole('textbox'), 'hello');
  await userEvent.click(screen.getByRole('button', { name: /send/i }));
  expect(await screen.findByText('reply')).toBeVisible();
});
```

**Why this is wrong:**
- The mock replaces the system under test (the contract between frontend and backend)
- A green frontend unit test against a mocked backend can co-exist with a broken contract
- The bug only surfaces when frontend and backend run together
- "B-AC-1" claim is false: the business AC is end-to-end, not "the frontend renders the right thing if the backend hypothetically returns the right shape"

### Gate Function

```
BEFORE labeling a frontend unit test as verifying a B-AC-N:
  Ask: "Does this test assert a back-end effect (DB record, real API response, downstream event)?"

  IF no:
    STOP — this verifies frontend rendering, not the business AC
    Add a Playwright (or equivalent) front-to-back E2E that drives the browser
    AND asserts the back-end effect
    Re-label this test as a frontend-only behavior test (T-AC-N or unlabelled)
```

**The fix:** keep the frontend unit test (it has value for fast iteration on UI logic), but the merge gate's B-AC verification is a Playwright front-to-back E2E that exercises the real contract:

```typescript
// ✅ GOOD: front-to-back; tests the real contract
test('B-AC-1: chat workflow works', async ({ page, request }) => {
  await page.goto('/chat');
  await page.getByRole('textbox').fill('hello');
  await page.getByRole('button', { name: /send/i }).click();

  // UI assertion
  await expect(page.getByTestId('reply')).toBeVisible();

  // Back-end effect — the part frontend unit tests can't prove
  const messages = await request.get('/api/chat/messages').then(r => r.json());
  expect(messages).toContainEqual(expect.objectContaining({ text: 'hello' }));
});
```

## Anti-Pattern 10: Coverage as Goal Instead of Outcome

**The violation:**
```
Sprint goal: raise coverage from 70% to 85%

Result: tests like
  test('getUser is defined', () => { expect(getUser).toBeDefined(); });
  test('User type has id field', () => { /* trivial */ });
```

**Why this is wrong:**
- Coverage gamed up by tests that catch nothing
- TDD-driven coverage of 80% catches bugs; gamed coverage of 95% catches nothing
- The team learns "coverage = checkbox" instead of "coverage = signal"

**The fix:** coverage is a regression-floor, not a target. Run mutation testing on critical code (Stryker) to verify tests would catch real bugs. If TDD-driven coverage is far below the floor, that's a signal of skipped tests OR hard-to-reach branches that suggest design problems — not a "raise the number" project.

## When Mocks Become Too Complex

**Warning signs:**
- Mock setup longer than test logic
- Mocking everything to make test pass
- Mocks missing methods real components have
- Test breaks when mock changes

**your human partner's question:** "Do we need to be using a mock here?"

**Consider:** Integration tests with real components often simpler than complex mocks

## TDD Prevents These Anti-Patterns

**Why TDD helps:**
1. **Write test first** → Forces you to think about what you're actually testing
2. **Watch it fail** → Confirms test tests real behavior, not mocks
3. **Minimal implementation** → No test-only methods creep in
4. **Real dependencies** → You see what the test actually needs before mocking

**If you're testing mock behavior, you violated TDD** - you added mocks without watching test fail against real code first.

## Quick Reference

| Anti-Pattern | Fix |
|--------------|-----|
| Assert on mock elements | Test real component or unmock it |
| Test-only methods in production | Move to test utilities |
| Mock without understanding | Understand dependencies first, mock minimally |
| Incomplete mocks | Mirror real API completely |
| Tests as afterthought | TDD - tests first |
| Over-complex mocks | Consider integration tests |
| Shared global state between tests | Each test owns its setup; randomize order in CI |
| Retry-on-flake | Fix the root cause or delete the test |
| Test-only env vars in production | Dependency-inject; fakes in tests, real in prod |
| Frontend unit as B-AC substitute | Playwright front-to-back asserting back-end effect |
| Coverage as goal | Coverage is outcome; mutation-test critical code |

## Red Flags

- Assertion checks for `*-mock` test IDs
- Methods only called in test files
- Mock setup is >50% of test
- Test fails when you remove mock
- Can't explain why mock is needed
- Mocking "just to be safe"

## The Bottom Line

**Mocks are tools to isolate, not things to test.**

If TDD reveals you're testing mock behavior, you've gone wrong.

Fix: Test real behavior or question why you're mocking at all.
