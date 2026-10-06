# Testing Anti-Patterns

**Load this reference when:** writing or changing tests, adding mocks, or tempted to add test-only methods to production code.

## Overview

Tests verify real behavior, not mock behavior. Mocks are a means to isolate, not the thing being tested. Writing the test first and watching it fail against real code prevents most of what follows.

## The three rules

```
1. Don't test mock behavior
2. Don't add test-only methods to production classes
3. Don't mock without understanding the dependency
```

## Anti-Pattern 1: Testing Mock Behavior

**The violation:**
```typescript
// ❌ BAD: asserts that the mock exists
test('B-AC-4: the page shows the navigation sidebar', () => {
  render(<Page />);
  expect(screen.getByTestId('sidebar-mock')).toBeInTheDocument();
});
```

**Why this is wrong:** it verifies the mock, not the component. It passes when the mock is present and tells you nothing about real behavior.

**your human partner's correction:** "Are we testing the behavior of a mock?"

**The fix:**
```typescript
// ✅ GOOD: the real sidebar, asserted by its role
test('B-AC-4: the page shows the navigation sidebar', () => {
  render(<Page />);
  expect(screen.getByRole('navigation')).toBeInTheDocument();
});
```

If the sidebar must be mocked for isolation, don't assert on the mock: test Page's own behavior with the sidebar present.

### Gate Function

```
BEFORE asserting on any mock element:
  Ask: "Am I testing real component behavior or just mock existence?"

  IF testing mock existence:
    STOP - Delete the assertion or unmock the component
```

## Anti-Pattern 2: Test-Only Methods in Production

**The violation:**
```typescript
// ❌ BAD: destroy() is only called from tests
class Session {
  async destroy() {
    await this._workspaceManager?.destroyWorkspace(this.id);
  }
}

afterEach(() => session.destroy());
```

**Why this is wrong:**
- Production class polluted with test-only code, which looks like production API
- Dangerous if accidentally called in production
- Confuses object lifecycle with entity lifecycle

**The fix:**
```typescript
// ✅ GOOD: test-utils/ owns the cleanup; Session has no destroy()
export async function cleanupSession(session: Session) {
  const workspace = session.getWorkspaceInfo();
  if (workspace) {
    await workspaceManager.destroyWorkspace(workspace.id);
  }
}

afterEach(() => cleanupSession(session));
```

### Gate Function

```
BEFORE adding any method to production class:
  Ask: "Is this only used by tests?"
  IF yes:
    Don't add it. Put it in test utilities instead.

  Ask: "Does this class own this resource's lifecycle?"
  IF no:
    Wrong class for this method.
```

## Anti-Pattern 3: Mocking Without Understanding

**The violation:**
```typescript
// ❌ BAD: the mock removes the config write the duplicate check depends on
vi.mock('ToolCatalog', () => ({
  discoverAndCacheTools: vi.fn().mockResolvedValue(undefined)
}));

test('FM-1: adding the same server twice is refused', async () => {
  await addServer(config);
  await expect(addServer(config)).rejects.toThrow('DUPLICATE_SERVER');
});
```

**Why this is wrong:** the mocked method had a side effect the test depended on, so the test passes for the wrong reason or fails mysteriously. Over-mocking "to be safe" breaks actual behavior.

**The fix:**
```typescript
// ✅ GOOD: mock only the slow server startup; the config write stays real
vi.mock('MCPServerManager');

test('FM-1: adding the same server twice is refused', async () => {
  await addServer(config);
  await expect(addServer(config)).rejects.toThrow('DUPLICATE_SERVER');
});
```

### Gate Function

```
BEFORE mocking any method:
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
// ❌ BAD: only the fields this test reads; downstream code reads metadata.requestId
const mockResponse = {
  status: 'success',
  data: { userId: '123', name: 'Alice' }
};
```

**Why this is wrong:** a partial mock hides structural assumptions. Downstream code may depend on fields you didn't include, so the test passes and the integration fails.

**The rule:** mock the complete data structure as it exists in reality, not just the fields your immediate test uses.

**The fix:**
```typescript
// ✅ GOOD: every field the real API returns
const mockResponse = {
  status: 'success',
  data: { userId: '123', name: 'Alice' },
  metadata: { requestId: 'req-789', timestamp: 1234567890 }
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

  If uncertain: Include all documented fields
```

## Anti-Pattern 5: Integration Tests as Afterthought

**The violation:**
```
✅ Implementation complete
❌ No tests written
"Ready for testing"
```

**Why this is wrong:** testing is part of implementation, not a follow-up. Work without its tests is not complete.

**The fix:** the TDD cycle: write the failing test, implement to pass, refactor, then claim complete.

## Anti-Pattern 6: Shared Global State Between Tests

**The violation:**
```typescript
// ❌ BAD: the second test passes only if the first ran before it
const cache = new Map<string, User>();

test('B-AC-6: a looked-up user is returned', async () => {
  await getUser('alice');
  expect(cache.has('alice')).toBe(true);
});

test('FM-3: a cached user is still returned when the user store is down', async () => {
  expect(cache.has('alice')).toBe(true);
});
```

**Why this is wrong:**
- The second test only passes if the first ran before it
- Random execution order (`vitest --shuffle`) breaks the suite
- It passes locally and fails in CI, and hides ordering bugs in the system under test

### Gate Function

```
BEFORE writing a test that reads existing state:
  Ask: "Does this state get reset between tests?"

  IF reset comes from beforeEach:
    OK — but verify the hook actually runs (forgotten beforeEach is common)

  IF reset comes from "the test that ran before":
    STOP — refactor. Each test sets up its own state.
```

**The fix:** each test owns its setup and asserts what the caller receives, not the cache's internals.

```typescript
// ✅ GOOD
test('B-AC-6: a looked-up user is returned', async () => {
  const store = fakeUserStore({ alice: { id: 'alice', name: 'Alice' } });
  expect(await getUser('alice', { cache: new Map(), store })).toEqual({ id: 'alice', name: 'Alice' });
});

test('FM-3: a cached user is still returned when the user store is down', async () => {
  const cache = new Map<string, User>();
  const store = fakeUserStore({ alice: { id: 'alice', name: 'Alice' } });
  await getUser('alice', { cache, store });
  store.goDown();

  expect(await getUser('alice', { cache, store })).toEqual({ id: 'alice', name: 'Alice' });
});
```

Configure the test runner to randomize order at least nightly. If random-order fails but sequential passes, you have hidden coupling.

## Anti-Pattern 7: Retry-on-Flake (Hiding Real Bugs)

**The violation:**
```typescript
// ❌ BAD: vitest.config.ts
export default defineConfig({
  test: { retry: 3, ... }
});

// ❌ BAD: playwright.config.ts
export default defineConfig({
  retries: 3,
  ...
});
```

**Why this is wrong:** a test that passes 1 time in 3 has a real bug, either in the test (a timing assumption) or in the system (a race). Retries hide it, train the team to ignore failures, and ship the bug to users, who get no retries.

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
// ❌ BAD: production code branches on a test env var
function authenticate(token: string) {
  if (process.env.NODE_ENV === 'test') {
    return { user: 'test-user', skipChecks: true };
  }
  return realAuthenticate(token);
}
```

**Why this is wrong:**
- The real code path is never exercised by the test suite, so its coverage is fake
- Forgetting the env var in some prod environment ships the bypass to production

**The fix:** inject the dependency. Tests pass a fake; production passes the real one.

```typescript
// ✅ GOOD
function authenticate(token: string, authProvider: AuthProvider) {
  return authProvider.verify(token);
}

const fakeAuthProvider = { verify: () => ({ user: 'test-user' }) };
authenticate('any', fakeAuthProvider);

authenticate(token, realAuthProvider);
```

## Anti-Pattern 9: Frontend Unit Test as Substitute for E2E

**The violation:**
```typescript
// ❌ BAD: frontend unit test against a mocked backend, claimed as the B-AC's proof
vi.mock('../api/chat', () => ({
  sendMessage: vi.fn().mockResolvedValue({ id: 1, text: 'reply' }),
}));

test('B-AC-1: a sent message is answered and stored', async () => {
  render(<ChatPage />);
  await userEvent.type(screen.getByRole('textbox'), 'hello');
  await userEvent.click(screen.getByRole('button', { name: /send/i }));
  expect(await screen.findByText('reply')).toBeVisible();
});
```

**Why this is wrong:**
- The mock replaces the system under test: the contract between frontend and backend
- A green frontend unit test against a mocked backend can co-exist with a broken contract
- The "B-AC-1" claim is false: the business AC is end-to-end, not "the frontend renders the right thing if the backend hypothetically returns the right shape"

### Gate Function

```
BEFORE labeling a frontend unit test as verifying a B-AC-N:
  Ask: "Does this test assert a back-end effect (DB record, real API response, downstream event)?"

  IF no:
    STOP — this verifies frontend rendering, not the business AC
    Add a Playwright (or equivalent) front-to-back E2E that drives the browser
    AND asserts the back-end effect
    Then DELETE the mocked test — unless it proves a different id (a UI rule
    the browser test cannot reach). An unlabelled test is not an option.
```

**The fix:** the B-AC is proved by a Playwright front-to-back test that exercises the real contract and asserts the back-end effect, which a frontend unit test can't; the mocked unit test goes in the same PR:

```typescript
// ✅ GOOD: front to back, through the real contract
test('B-AC-1: a sent message is answered and stored', async ({ page, request }) => {
  await page.goto('/chat');
  await page.getByRole('textbox').fill('hello');
  await page.getByRole('button', { name: /send/i }).click();

  await expect(page.getByTestId('reply')).toBeVisible();
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

**Why this is wrong:** coverage gamed up by tests that catch nothing. TDD-driven coverage of 80% catches bugs; gamed coverage of 95% catches nothing.

**The fix:** coverage is a regression floor, not a target. Run mutation testing on critical code (Stryker) to verify tests would catch real bugs. If TDD-driven coverage is far below the floor, that signals skipped tests or hard-to-reach branches that suggest design problems, not a "raise the number" project.

## Anti-Pattern 11: The Untraced Unit Test (the shadow)

**The violation:**
```typescript
// tests/orders.test.mjs — the AC test, at the route
test('B-AC-1: gold customer at the 100.00 threshold gets GOLD10, and reads it back', …);

// tests/pricing.test.mjs — the same rule again, one level down, naming nothing
test('pricing: gold tier gets GOLD10 at exactly the 100.00 threshold', …);
test('spec §4: roundTo05 rounds up to the nearest 0.05 CHF', …);
test('POST /orders calls store.save exactly once', …);
```

**Why this is wrong:**
- The second test proves what the first already proves: twice the run cost on every merge, for one proof
- It names a place ("pricing:", "spec §4") instead of a promise, so nobody can tell which AC breaks when it goes red
- The mock-count test passes while the order is saved with the wrong total

### Gate Function

```
BEFORE writing a test below the boundary:
  Name its id (AC / INV / FM). None → don't write it.
  Does a boundary test already exercise this case? → strengthen THAT test.
  Is this a pure core with too many combinations for the boundary?
    → ONE table-driven or property test, titled with the AC it serves.
  Otherwise → it belongs at the boundary.
```

**The fix:** add the threshold and rounding cases as rows of the B-AC-1 route test's table; delete the shadows.

## When Mocks Become Too Complex

**Warning signs:**
- Mock setup longer than test logic
- Mocking everything to make test pass
- Mocks missing methods real components have
- Test breaks when mock changes

**your human partner's question:** "Do we need to be using a mock here?"

**Consider:** integration tests with real components are often simpler than complex mocks.

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
| Untraced / shadow unit test | Name the id or delete; strengthen the boundary test's table |
