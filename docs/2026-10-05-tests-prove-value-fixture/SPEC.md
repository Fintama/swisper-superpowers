# SPEC — Order pricing (excerpt)

## §0 Goal
G-1: A loyal customer sees the discount they were promised on the order they placed,
and an expired coupon is refused before anything is charged.
Proof: UBER-AC-1 — a gold customer's 120 CHF order is stored and returned at 108 CHF.

## §4 Pricing rules
- Prices are CHF. Subtotal = sum(qty * unitPrice) of the order's items.
- Loyalty discount (applied first):
  - gold: 10% off when subtotal >= 100.00
  - silver: 5% off when subtotal >= 200.00
  - none / below threshold: no loyalty discount
- Coupon (applied after loyalty): a fixed CHF amount off. Optional.
- The final total is rounded to the nearest 0.05 CHF (Swiss rounding).
- `discount` in the response names the loyalty discount applied: "GOLD10", "SILVER5" or null.

## §5 Acceptance criteria
- **B-AC-1** Given a customer with a loyalty tier, when they POST /orders, then the
  response is 201 with `{ id, total, discount }` where `total` reflects the §4 loyalty rule
  for their tier (gold 10% from 100.00, silver 5% from 200.00) and any coupon, rounded to
  0.05; and GET /orders/:id returns the same `total`.
- **B-AC-2** Given a coupon whose `expiresAt` is before now, when the customer POSTs
  /orders with it, then the response is 422 `{ error: "COUPON_EXPIRED" }` and no order is stored.

## §6 Failure modes
- **FM-1** Unknown coupon code → 422 `{ error: "COUPON_UNKNOWN" }`, nothing stored.
- **FM-2** Unknown customer → 404 `{ error: "CUSTOMER_UNKNOWN" }`, nothing stored.

## §7 Invariants
- **INV-1** For any order: 0 <= total <= subtotal.
