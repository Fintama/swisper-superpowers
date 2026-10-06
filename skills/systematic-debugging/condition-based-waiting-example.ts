import type { ThreadManager } from '~/threads/thread-manager';
import type { LaceEvent, LaceEventType } from '~/threads/types';

const POLL_MS = 10;

function pollUntil<T>(
  check: () => T | undefined,
  describeTimeout: () => string,
  timeoutMs: number,
): Promise<T> {
  return new Promise((resolve, reject) => {
    const start = Date.now();
    const tick = () => {
      const found = check();
      if (found !== undefined) {
        resolve(found);
      } else if (Date.now() - start > timeoutMs) {
        reject(new Error(describeTimeout()));
      } else {
        setTimeout(tick, POLL_MS);
      }
    };
    tick();
  });
}

/** Resolves with the first event of `eventType` in the thread. */
export function waitForEvent(
  threadManager: ThreadManager,
  threadId: string,
  eventType: LaceEventType,
  timeoutMs = 5000,
): Promise<LaceEvent> {
  return pollUntil(
    () => threadManager.getEvents(threadId).find((e) => e.type === eventType),
    () => `Timeout waiting for ${eventType} event after ${timeoutMs}ms`,
    timeoutMs,
  );
}

/** Resolves with all events of `eventType` once there are at least `count`. */
export function waitForEventCount(
  threadManager: ThreadManager,
  threadId: string,
  eventType: LaceEventType,
  count: number,
  timeoutMs = 5000,
): Promise<LaceEvent[]> {
  const matching = () =>
    threadManager.getEvents(threadId).filter((e) => e.type === eventType);
  return pollUntil(
    () => {
      const events = matching();
      return events.length >= count ? events : undefined;
    },
    () =>
      `Timeout waiting for ${count} ${eventType} events after ${timeoutMs}ms (got ${matching().length})`,
    timeoutMs,
  );
}

/** Resolves with the first event matching `predicate`; `description` names it in the timeout error. */
export function waitForEventMatch(
  threadManager: ThreadManager,
  threadId: string,
  predicate: (event: LaceEvent) => boolean,
  description: string,
  timeoutMs = 5000,
): Promise<LaceEvent> {
  return pollUntil(
    () => threadManager.getEvents(threadId).find(predicate),
    () => `Timeout waiting for ${description} after ${timeoutMs}ms`,
    timeoutMs,
  );
}

// Usage. Before, the test guessed durations and failed under load:
//
//   const done = agent.sendMessage('Execute tools');
//   await new Promise(r => setTimeout(r, 300));
//   agent.abort();
//   await done;
//   await new Promise(r => setTimeout(r, 50));
//   expect(toolResults.length).toBe(2);
//
// After, it waits for the events the assertions depend on:
//
//   const done = agent.sendMessage('Execute tools');
//   await waitForEventCount(threadManager, threadId, 'TOOL_CALL', 2);
//   agent.abort();
//   await done;
//   await waitForEventCount(threadManager, threadId, 'TOOL_RESULT', 2);
//   expect(toolResults.length).toBe(2);
