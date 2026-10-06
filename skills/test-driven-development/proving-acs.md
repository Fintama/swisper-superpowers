# Proving the promise — the method for every test

**Load this when:** writing any test, and always before a test that claims a
`B-AC-N`, `T-AC-N` or `UBER-AC-N`; or when a reviewer asks "is this AC actually
covered?"

**The one-line rule:** *a test proves a promise where the promise is received,
and the AC id in its name is a label, not proof.*

This file is rule R1 of `SKILL.md` worked out. The other rules (ids in titles,
unit tests as the exception, strengthen before you add, delete what a higher
test covers) only make sense once this one is held.

A suite can be large, green and well-covered while the product tells its users
something false: each function does exactly what it says, and no test asserts
what the user is told. That is an **altitude** problem, not a coverage problem.

---

## Principle: assert the promise, not the mechanism

Read the AC's **Then** clause and ask: *what does it promise a human?*

- "…then it is reported as `kind: "quota_exhausted"` **naming the config and
  carrying the vendor's verbatim message**" → the promise is what the operator
  *reads*. Assert the surfaced message.
- "…then the row is expanded **with its capacity panel visible**" → the promise
  is visibility. Assert the rendered result.
- "…then `resolved_at` is set" → this one *is* mechanism, and it is a T-AC.
  Fine.

**A B-AC's assertion belongs on the artefact the user receives**: rendered
text, the API response a client actually consumes, the persisted state the next
screen reads. Not on the function that computes it.

```typescript
// ❌ Asserts the mechanism. Passes while the operator is told a lie.
test('B-AC-5: the operator is told which account paid for the turn', () => {
  expect(resolveBilledTo(row, userId, descriptor)).toBe('the instance API key');
});

// ✅ Asserts the promise, against ground truth the test arranged.
test('B-AC-5: the operator is told which account paid for the turn', async () => {
  const app = createApp({ anthropic: subscriptionSessionOnly() });

  const res = await app.request('/api/admin/settings/providers/anthropic/test');
  const { billedTo } = await res.json();

  expect(billedTo).toContain('subscription');
  expect(billedTo).not.toContain('API key');
});
```

### The trap inside the trap: never assert the code's own claim as truth

The first example above is worse than useless: it is **the bug, frozen**. It
goes green on the broken code and red on the fix.

> **Derive the expected value from what actually happened, never from what the
> code says happened.**

Arrange the world so you *know* the ground truth (only a subscription session
can serve this turn), then assert the user-facing claim matches it. If your
expected value is the string the code produces, you have written a mirror, and
a mirror cannot tell you the code is lying.

---

## The three altitudes, and which one an AC needs

| Altitude | Asserts | Catches | Right for |
|---|---|---|---|
| **Promise** | the user sees / receives the true thing | *the code being right and the claim being false* | **B-AC, always.** The default for every test |
| **Contract** | the response/payload a client consumes has shape+values | producer↔consumer drift | T-AC at the boundary it is about (the route, the CLI, the persisted row); a B-AC only when no user surface exists |
| **Mechanism** | a function returns X | wrong branch, bad arithmetic | **Only the R3 exceptions**: one table or property test of a pure core, an invariant, a hard-to-reach failure mode |

**Start at the top row and descend only when the row above cannot reach the
case.** A mechanism test for a rule the promise test already exercises is the
same proof twice; the lower one is deleted (R7).

A well-formed payload can still carry false contents, so contract altitude does
not prove a B-AC either.

**A layout truth has only one altitude.** A dialog can render correct markup in
jsdom and sit off the viewport in a real browser. No unit or contract test can
catch "the user cannot see it", which is why a frontend-touching PR requires a
real browser test, and why a render-gate against the approved mock is not
ceremony.

### Front to back: the shape of a business AC with a UI

A PR that touches a UI proves its business AC in a real browser **and** asserts
the back-end effect. A frontend unit test against a mocked backend can be green
beside a broken contract: it does not satisfy a B-AC, and once the browser test
proves the AC, the mocked one is deleted unless it proves something else by id.

```typescript
test('B-AC-1: an operator sends a message, sees it, and it is stored', async ({ page, request }) => {
  await page.goto('/epics/EPC_001/vision');
  await page.getByRole('textbox', { name: 'message' }).fill('Test message');
  await page.getByRole('button', { name: 'Send' }).click();

  await expect(page.getByTestId('chat-messages')).toContainText('Test message');
  const messages = await (await request.get('/api/epics/EPC_001/messages')).json();
  expect(messages).toEqual(expect.arrayContaining([expect.objectContaining({ content: 'Test message' })]));
});
```

---

## Gate function — run this before writing an AC-mapped test

```
GIVEN an AC you are about to write a test for:

1. Quote the AC's Then-clause. Who is the subject — a function, or a person?
     a person  → this is a PROMISE. Assert what they see/receive.
     a function → mechanism is fine; confirm it is genuinely a T-AC.

2. Name the production change that would make this test fail.
     Cannot name one                → the test proves nothing; redesign it
     "the string constant changed"  → change detector; assert the behavior
                                      that depends on it

3. Where does your expected value come from?
     from the code under test / its helpers → MIRROR. Replace with a literal
       or with ground truth arranged by the test.
     from the AC's own words                → good

4. Could this test pass while the user is told something false?
     yes → you are one altitude too low. Move up.

5. For a B-AC: is the assertion on a surface a user actually reaches?
     no → it is not yet a business test, whatever its name says.

6. Does an existing test already prove this promise?
     yes → strengthen it (a row, a boundary value, an assertion). Do not add.
```

Step 4 is the one that catches the code being right while the claim is false.

---

## Coverage of an AC set is a claim, and a claim is not a measurement

`grep -c "B-AC-11"` proves a test with that *label* exists, nothing more. To
claim an AC is covered:

1. the test's assertion traces to the AC's Then-clause (not merely its topic),
2. the test fails when the promised behavior is broken: **verify by breaking
   it on purpose**, and
3. for a B-AC, the assertion is at promise altitude.

Positive-control the AC the same way you positive-control a CI gate: break the
behavior, watch the named test go red, restore it. An AC-mapped test that has
never been seen failing for its AC's reason is undischarged.

---

## Anti-patterns specific to AC-mapped tests

- **The renamed test.** An existing test gets `B-AC-14:` prefixed onto its name
  to close a coverage gap. Nothing about its assertions changed. The gap is
  still open; it is now also hidden.
- **The split AC.** One AC promises two things ("names the config **and**
  carries the vendor's message") and the test asserts the easier half.
- **The AC with no observer.** The AC describes an internal state change with
  no user-visible consequence anywhere. That is a spec smell: take it back to
  the spec rather than writing a mechanism test and calling it business
  coverage.
- **The mocked promise.** A B-AC verified against a mocked backend. The mock
  agrees with the frontend; production does not. See
  `testing-anti-patterns.md` Anti-Pattern 9.
- **The shadow test.** A unit test of the rule the AC test already proves:
  "gold gets GOLD10 at 100.00" beside a route test that posts 100.00 as a gold
  customer. Twice the run cost, one proof. Delete the lower one.
- **The section-number title.** `"spec §4: silver at 200"` names a place, not a
  promise. If the rule matters it belongs to an AC: make it a row of that AC's
  table. If no AC covers it, that is a spec gap; take it upstream.
