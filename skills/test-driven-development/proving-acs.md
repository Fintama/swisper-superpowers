# Proving the promise — the method for every test

**Load this when:** writing ANY test, and always before a test that claims a
`B-AC-N`, `T-AC-N` or `UBER-AC-N`; or when a reviewer asks "is this AC actually
covered?"

**The one-line rule:** *a test proves a promise where the promise is received —
and the AC id in its name is a label, not proof.*

This file is rule R1 of `SKILL.md` worked out. The rest of the rules (ids in
titles, unit tests as the exception, strengthen before you add, delete what a
higher test covers) only make sense once this one is held.

---

## The measurement that earned this file

Foundry, 2026-07-29. The subscription-provider feature shipped with **7,800
backend tests green**. A UAT session found **four bugs by clicking**:

| Bug | What the code did | What the operator was told |
|---|---|---|
| `resolveBilledTo` had no `session` branch | fell through to its default | "billed to **the instance API key**" — for a plan paid by a personal subscription |
| the fix's own regression | keyed off the *descriptor*, not the row | *every* anthropic config, including plain API-key ones, claimed the Max subscription paid |
| `probeChildEnv` ran in the backend's env | answered "is a key present?" | a real Max session reported as **an API key** |
| the consent dialog rendered in page flow | `DialogRoot` emits no DOM | dialog **off the bottom of the viewport**; "Tick the acknowledgement above" pointed off-screen |

**Every one of them was the code doing exactly what it said, while saying
something false to the user.** The tests asserted the mechanism. Not one
asserted the claim.

That is the failure mode this file exists to prevent. It is not a coverage
problem — coverage was excellent. It is an **altitude** problem: the tests were
written one layer below the promise.

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

**A B-AC's assertion belongs on the artefact the user receives** — rendered
text, the API response a client actually consumes, the persisted state the next
screen reads. Not on the function that computes it.

```typescript
// ❌ Asserts the mechanism. Passes while the operator is told a lie.
expect(resolveBilledTo(row, userId, descriptor)).toBe('the instance API key');

// ✅ Asserts the promise, against ground truth.
// B-AC: the operator is told WHICH ACCOUNT PAID.
const res = await app.request('/api/admin/settings/providers/anthropic/test');
const { billedTo } = await res.json();
// The session — not the key — served this turn (arranged above), so:
expect(billedTo).toContain('subscription');
expect(billedTo).not.toContain('API key');
```

### The trap inside the trap: never assert the code's own claim as truth

The first example above is worse than useless — it is **the bug, frozen**. Had
it existed, it would have gone green on the broken code and red on the fix.

> **Derive the expected value from what actually happened, never from what the
> code says happened.**

Arrange the world so you *know* the ground truth (this credential served this
turn), then assert the user-facing claim matches it. If your expected value is
the string the code produces, you have written a mirror, and a mirror cannot
tell you the code is lying.

---

## The three altitudes, and which one an AC needs

| Altitude | Asserts | Catches | Right for |
|---|---|---|---|
| **Promise** | the user sees / receives the true thing | *the code being right and the claim being false* | **B-AC — always.** The default for every test |
| **Contract** | the response/payload a client consumes has shape+values | producer↔consumer drift | T-AC at a boundary; a B-AC only when no user surface exists |
| **Mechanism** | a function returns X | wrong branch, bad arithmetic | **Only the R3 exceptions** — one table or property test of a pure core, an invariant, a hard-to-reach failure mode |

**Start at the top row and descend only when the row above cannot reach the
case.** A mechanism test for a rule the promise test already exercises is the
same proof twice — the lower one is deleted (R7). Measured, 2026-10-05: an agent
working from the old pyramid wrote 7 route tests and 11 unit tests for one
pricing route; at least 5 of the 11 re-proved thresholds the route tests already
asserted, and none named a promise.

The four Foundry bugs were all invisible at mechanism altitude and all obvious
at promise altitude. Three of the four were **also** invisible at contract
altitude — the payload was well-formed and its contents were false.

⚠ **A layout truth has only one altitude.** The consent dialog rendered fine in
jsdom: the component returned correct markup. It was off-viewport in a real
browser. No unit or contract test can catch "the user cannot see it" — this is
why a frontend-touching PR requires a real browser test, and why a render-gate
against the approved mock is not ceremony.

### Front to back: the shape of a business AC with a UI

A PR that touches a UI proves its business AC in a real browser **and** asserts
the back-end effect. A frontend unit test against a mocked backend can be green
beside a broken contract — it does not satisfy a B-AC, and once the browser test
proves the AC, the mocked one is deleted unless it proves something else by id.

```typescript
test('B-AC-1: an operator sends a message and it is stored', async ({ page, request }) => {
  await page.goto('/epics/EPC_001/vision');
  await page.getByRole('textbox', { name: 'message' }).fill('Test message');
  await page.getByRole('button', { name: 'Send' }).click();

  await expect(page.getByTestId('chat-messages')).toContainText('Test message');   // what they see
  const messages = await (await request.get('/api/epics/EPC_001/messages')).json();  // what persisted
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

Step 4 is the one that would have caught all four bugs.

---

## Coverage of an AC set is a claim, and a claim is not a measurement

`grep -c "B-AC-11"` proving a test exists is exactly the false green this
programme keeps re-learning. A grep proves a *label*. To claim an AC is covered:

1. the test's assertion traces to the AC's Then-clause (not merely its topic),
2. the test fails when the promised behavior is broken — **verify by breaking
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
  no user-visible consequence anywhere. That is a spec smell — take it back to
  the spec rather than writing a mechanism test and calling it business
  coverage. *(Measured: a spec claimed "every MUST has at least one AC" while
  two MUSTs had none. The claim survived two review rounds.)*
- **The mocked promise.** A B-AC verified against a mocked backend. The mock
  agrees with the frontend; production does not. See
  `testing-anti-patterns.md` §9.
- **The shadow test.** A unit test of the rule the AC test already proves —
  "gold gets GOLD10 at 100.00" beside a route test that posts 100.00 as a gold
  customer. Twice the run cost, one proof. Delete the lower one.
- **The section-number title.** `"spec §4: silver at 200"` names a place, not a
  promise. If the rule matters it belongs to an AC — make it a row of that AC's
  table. If no AC covers it, that is a spec gap; take it upstream.

---

## Quick reference

| When you… | Do |
|---|---|
| Write any test | Name its AC / INV / FM id; start at the boundary |
| Write a `B-AC-N` test | Assert what the user sees/receives, against arranged ground truth |
| Write a `T-AC-N` test | At the boundary it is about (the route, the CLI, the persisted row); a mechanism test only under R3 |
| Find a gap (review, mutant) | Strengthen the test that claims the behaviour; add only if none sits at the right altitude |
| Land a higher test | Delete the lower tests it now covers, in the same PR |
| Build the expected value | Derive from the AC and the arranged world — never from the code |
| Claim an AC is covered | Break the behavior, watch that named test go red |
| See an AC with no user-visible consequence | Send it back to the spec |
| Touch anything rendered | Real browser; jsdom cannot see a viewport |
