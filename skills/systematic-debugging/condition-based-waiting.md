# Condition-Based Waiting

A test that sleeps for a guessed duration passes on a fast machine and fails under load
or in CI. **Wait for the condition you care about, not for a guess at how long it
takes.**

Use it when a test has an arbitrary delay (`setTimeout`, `sleep`, `time.sleep()`), is
flaky, times out when run in parallel, or waits for async work to finish.

The exception is a test of timing itself (debounce, throttle intervals): there a timed
wait is the point. See the end of this page.

## Pattern

```typescript
// Before: a guess
await new Promise(r => setTimeout(r, 50));
expect(getResult()).toBeDefined();

// After: the condition
await waitFor(() => getResult() !== undefined, 'a result');
expect(getResult()).toBeDefined();
```

| Waiting for | Condition |
|---|---|
| an event | `waitFor(() => events.find(e => e.type === 'DONE'), 'DONE')` |
| a state | `waitFor(() => machine.state === 'ready', 'state ready')` |
| a count | `waitFor(() => items.length >= 5, '5 items')` |
| a file | `waitFor(() => fs.existsSync(path), path)` |
| a compound condition | `waitFor(() => obj.ready && obj.value > 10, 'ready, value > 10')` |

## Implementation

```typescript
async function waitFor<T>(
  condition: () => T | undefined | null | false,
  description: string,
  timeoutMs = 5000,
): Promise<T> {
  const start = Date.now();
  while (true) {
    const result = condition();
    if (result) return result;
    if (Date.now() - start > timeoutMs) {
      throw new Error(`Timeout waiting for ${description} after ${timeoutMs}ms`);
    }
    await new Promise(r => setTimeout(r, 10));
  }
}
```

- Always set a timeout, and name what was awaited in its error.
- Read the state inside the loop; a value cached before the loop never changes.
- Poll at about 10 ms. Polling every 1 ms burns CPU and slows the thing you wait for.
- With fake timers, advance the clock instead of polling.

`condition-based-waiting-example.ts` has event helpers (`waitForEvent`,
`waitForEventCount`, `waitForEventMatch`) built the same way.

## When a timed wait is right

```typescript
await waitForEvent(manager, threadId, 'TOOL_STARTED');
// The tool emits output every 100 ms; two ticks prove partial output is captured.
await new Promise(r => setTimeout(r, 200));
```

All three must hold: first wait for the triggering condition; the duration comes from
known timing, not a guess; a comment states that timing.
