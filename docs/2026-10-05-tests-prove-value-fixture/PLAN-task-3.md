# Plan — Task 3: POST /orders prices and stores an order; GET /orders/:id reads it

Goal served: G-1 (spec §0).
ACs verified: B-AC-1, B-AC-2. Failure modes: FM-1, FM-2. Invariant: INV-1.
Tests (named, from the plan):
- `B-AC-1: …` — route level, POST then GET.
- `B-AC-2: …` — route level, asserts 422 and store unchanged.
- `FM-1: …`, `FM-2: …` — route level.
- `INV-1: …` — property-style over generated orders (node:test, hand-rolled generator; no new deps).

may_edit: src/app.mjs, src/pricing.mjs (new), tests/orders.test.mjs (new), tests/pricing.test.mjs (new, only if needed)
must_not_edit: src/coupons.mjs, src/store.mjs, tests/health.test.mjs

Request body: `{ customerId, items: [{ sku, qty, unitPrice }], coupon? }`.
Run tests: `npm test` (node:test, no dependencies — do not npm install anything).
