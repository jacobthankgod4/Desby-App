# Payment & Escrow Hardening — Implementation Plan

Status: DRAFT for approval
Scope: `desby_app` Flutter web + Supabase (project `sakmdeacligraqayfxyb`) + KORRA API + Flutterwave
Prepared: 2026-10-07

## Current state

**0 orders exist. No money has moved.** Every finding below is therefore a design
defect to fix before first revenue, not a production incident. This is the
cheapest possible time to correct the architecture.

Money collected today: 100% up front, at checkout.
Money released to tailor: 90% (client-computed), on client-tapped confirmation.
Held in escrow: nothing — the UI claims otherwise.

---

## Findings

### Severity 1 — fix before any real order

| # | Finding | Evidence |
|---|---|---|
| S1.1 | Flutterwave **secret key ships to the browser** | `lib/core/services/flutterwave_transfer_service.dart:20` reads `FLUTTERWAVE_SECRET_KEY` from client env; 8 REST endpoints authenticate with it in-browser (`:52,84,118,150,168,186,204,227`) |
| S1.2 | Buyer can release their own money | Live RLS `orders`: `UPDATE USING (auth.uid() = tailor_id OR auth.uid() = requesting_user_id)` — buyer matches `requesting_user_id` and can set `status='delivered'` |
| S1.3 | Payout success is reported unconditionally | `order_detail_page.dart:774-801` — failure is `debugPrint`ed, then `SnackBar('Payment released to tailor.')` shows regardless |
| S1.4 | Wallet tables do not exist | `merchant_wallets` and `payout_requests` absent from live DB. Every payout throws |
| S1.5 | Double-pay on release | `supabase_merchant_repository.dart` credits wallet `:87-99` **and** transfers `:104-110` for the same `tailorPayout`; `:105` reverse-derives gross via `/ 0.90` |

### Severity 2 — fix before launch

| # | Finding | Evidence |
|---|---|---|
| S2.1 | "Escrow" is copy-only | `trust_action_footer.dart:42,120`; `product_narrative.dart:197`. Orders marked `paid` at `checkout_page.dart:741` |
| S2.2 | Commission hardcoded in 5 places, no source of truth | `flutterwave_transfer_service.dart:18`, `checkout_page.dart:735`, `product_details_page.dart:29`, `order_detail_page.dart:765,787`, `supabase_merchant_repository.dart:105` |
| S2.3 | Split is arithmetic, not enforced | `createSubaccount()` written (`:42-78`) but **never called**. No Flutterwave subaccount exists |
| S2.4 | No state machine | `order_detail_page.dart:973` spreads `OrderStatus.values` — any status, including backwards |
| S2.5 | No refund path | `PaymentStatus.refunded` declared, never written. No provider refund call |
| S2.6 | Non-atomic balance | `supabase_merchant_repository.dart:80-99` read-modify-write, race-prone |
| S2.7 | Tailor service charge does not exist | Zero `service_charge` matches. Only `starting_price`, set by 2 of 11 users |
| S2.8 | `ServicePricing` orphaned | `lib/features/auth/domain/entities/user.dart:2-105` never populated by `SupabaseProfileRepository` |

### Severity 3 — hygiene

| # | Finding | Evidence |
|---|---|---|
| S3.1 | Dead Paystack credentials in `.env` | `PAYSTACK_PUBLIC_KEY`, `PAYSTACK_SECRET_KEY` — no code reads them |
| S3.2 | `dart:html` breaks non-web builds | `payment_callback_page.dart:6` |
| S3.3 | `delivered` never reached automatically | `delivery_tracking_page.dart` read-only; `updateDeliveryStatus` (`:147-152`) has no caller |
| S3.4 | Referral commission promised in copy, unimplemented | `plan_registry.dart:112,158,218,260` |
| S3.5 | `get_merchant_stats()` filters `status='completed'` — never written by app | `fabric_merchant_v6_full_fix.sql:72` |

---

## Target architecture

```
CLIENT (browser)                    EDGE FUNCTIONS (server)              FLUTTERWAVE
─────────────────                   ──────────────────────              ───────────
checkout form                       flutterwave-create-intent  ──►     charge
  │                                 flutterwave-verify
  │◄── signed intent + subaccount code
  │                                 flutterwave-split-webhook  ──►     settlement
  │
order detail                        flutterwave-release-payout ──►    transfer
  │ (status only)                    flutterwave-refund
```

Rules:
1. The client never holds the Flutterwave secret. Ever.
2. Commission is defined once, server-side, in a DB row.
3. Money movement is server-initiated; the client only observes state.
4. Every money path is idempotent and transactional.

---

## Phase 1 — Stop the bleeding (no revenue risk, do immediately)

### 1.1 Rotate the exposed Flutterwave secret
- Issue new key in Flutterwave dashboard; revoke the old one.
- Remove `FLUTTERWAVE_SECRET_KEY` from `flutterwave_transfer_service.dart:20`.
- Delete the whole client-side transfer service; it moves server-side in Phase 3.
- Remove from `.env`, `assets/.env`, `.env.server.bak`.
- Rotate Paystack keys too (dead, but exposed).

Files: `lib/core/services/flutterwave_transfer_service.dart`, `.env`, `assets/.env`

### 1.2 Close the buyer-can-self-release hole
Buyers must read orders, not mutate lifecycle fields. Tighten to column-scoped
access via a dedicated RPC rather than a blanket UPDATE.

```sql
-- Replace the blanket UPDATE policy
DROP POLICY IF EXISTS "Users can update relevant orders" ON public.orders;

-- Tailors: full control of their own orders
CREATE POLICY "Tailors manage own orders" ON public.orders
  FOR UPDATE TO authenticated
  USING (auth.uid() = tailor_id)
  WITH CHECK (auth.uid() = tailor_id);

-- Buyers: may withdraw/cancel pre-work only, via RPC (Phase 3)
-- No direct UPDATE policy for requesting_user_id.
```

Verification: as a buyer, `UPDATE orders SET status='delivered'` must fail.

### 1.3 Stop lying about payout success
`order_detail_page.dart:774-801` — branch on the result:

- `Success` → "Payment released to tailor."
- `Failure` → "Couldn't release payment. We've queued it for support." (amber)

Never show success unconditionally.

### 1.4 Create the missing tables
```sql
CREATE TABLE IF NOT EXISTS public.merchant_wallets (
  user_id UUID PRIMARY KEY REFERENCES public.users(id),
  balance NUMERIC(12,2) NOT NULL DEFAULT 0,
  pending_payout NUMERIC(12,2) NOT NULL DEFAULT 0,
  currency TEXT NOT NULL DEFAULT 'NGN',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.payout_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id UUID NOT NULL REFERENCES public.users(id),
  order_id UUID REFERENCES public.orders(id),
  amount NUMERIC(12,2) NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','processing','processed','failed','reversed')),
  bank_details JSONB,
  flutterwave_transfer_id TEXT,
  failure_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ
);
```
RLS: SELECT own; **writes only via `service_role`** (Edge Functions). No client INSERT/UPDATE.

Migration file: `supabase/migrations/20261007000001_payment_ledger.sql`

---

## Phase 2 — Commission + service charge (needs your numbers)

### 2.1 Single source of truth
```sql
CREATE TABLE platform_config (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
INSERT INTO platform_config (key, value) VALUES
  ('commission', '{"rate": 0.10, "basis": "gross"}'),
  ('deposit_split', '{"deposit_pct": 0.40, "balance_pct": 0.60}');
```
All 5 hardcoded sites read from this. Rate change becomes a config edit.

### 2.2 Tailor service charge
Add to `users`:
```sql
ALTER TABLE users ADD COLUMN base_stitching_price NUMERIC(12,2);
ALTER TABLE users ADD COLUMN material_cost NUMERIC(12,2);
ALTER TABLE users ADD COLUMN alteration_price NUMERIC(12,2);
ALTER TABLE users ADD COLUMN express_fee NUMERIC(12,2);
```
Wire the existing orphaned `ServicePricing` entity to these. `starting_price`
becomes a derived fallback (`min` of non-zero tiers) for backward compat.

---

## Phase 3 — Server-side money movement

### 3.1 Edge Functions (new — `supabase/functions/`)
| Function | Role |
|---|---|
| `flutterwave-create-intent` | Creates charge + tailor subaccount; returns public-only payload |
| `flutterwave-verify` | Confirms charge, writes `payment_status='paid'` |
| `flutterwave-split-webhook` | Flutterwave settlement callback; idempotent |
| `flutterwave-release-payout` | Debits ledger, initiates transfer (idempotent) |
| `flutterwave-refund` | Full/partial refund with reason |

All use `Deno.serve` + service-role Supabase client. All idempotent on
`order_id` + `operation`.

### 3.2 Real subaccounts
Wire the existing `createSubaccount()` logic server-side. Each tailor gets one
subaccount (`split_type='percentage'`) on first order. Store `flutterwave_subaccount_id`
on `users`. Flutterwave then enforces the split at settlement — the client's
arithmetic stops mattering.

### 3.3 Transactional release RPC
```sql
CREATE FUNCTION release_order_payout(p_order_id UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_order orders%ROWTYPE; v_payout UUID;
BEGIN
  SELECT * INTO v_order FROM orders WHERE id = p_order_id FOR UPDATE;
  IF v_order.payment_status <> 'paid' THEN
    RAISE EXCEPTION 'order not paid';
  END IF;
  -- idempotency: skip if a payout already exists
  IF EXISTS (SELECT 1 FROM payout_requests WHERE order_id = p_order_id
             AND status IN ('pending','processing','processed')) THEN
    RETURN jsonb_build_object('status','already_released');
  END IF;
  INSERT INTO payout_requests (seller_id, order_id, amount, status)
  VALUES (v_order.tailor_id, p_order_id, v_order.tailor_payout, 'pending')
  RETURNING id INTO v_payout;
  UPDATE orders SET payment_status='confirmed' WHERE id = p_order_id;
  RETURN jsonb_build_object('status','queued','payout_id',v_payout);
END; $$;
```
`FOR UPDATE` closes the double-pay and race windows at once.

### 3.4 Replace client-side payout
`order_detail_page.dart` calls the RPC, then a Function initiates the transfer.
Remove `creditWalletAndPayout`'s wallet-credit-plus-transfer double path.

---

## Phase 4 — Staged payments (answering "what releases when")

Recommended model for made-to-order tailoring:

| Stage | Transfers to tailor | Client sees |
|---|---|---|
| Checkout | 0 | Paid — 40% held |
| Tailor accepts | **40% deposit** | "Tailor notified, work begins" |
| Materials in transit | 0 | Tracking |
| Ready for pickup | 0 | Awaiting delivery |
| Client confirms receipt | **remaining 60%** | Complete |

Requires `payment_status` to become a ledger, not a string. Optional Phase 4 —
Phase 1–3 make the platform safe without it.

---

## Phase 5 — Order lifecycle

Replace the free-form picker with an explicit transition map:

```dart
const Map<OrderStatus, List<OrderStatus>> allowedTransitions = {
  OrderStatus.pending:           {OrderStatus.paid, OrderStatus.cancelled},
  OrderStatus.paid:              {OrderStatus.bookingAccepted, OrderStatus.cancelled},
  OrderStatus.bookingAccepted:   {OrderStatus.materialsInTransit, OrderStatus.cancelled},
  OrderStatus.materialsInTransit:{OrderStatus.inProgress, OrderStatus.cancelled},
  OrderStatus.inProgress:       {OrderStatus.ready, OrderStatus.cancelled},
  OrderStatus.ready:             {OrderStatus.delivered},
  OrderStatus.delivered:         {},
  OrderStatus.cancelled:         {},
};
```
Enforced in the release RPC too, so RLS remains the real boundary.

---

## Open decisions for you

1. **Commission rate** — currently 10% of gross. Industry band 8–12%. Keep 10%?
2. **Deposit split** — propose 40/60. Preferred?
3. **Refund policy** — who absorbs Flutterwave's ~1.4% charge on refund?
4. **Refund window** — 24h before `inProgress`? At any stage?
5. **Tailor payout timing** — on client confirmation only, or auto on courier
   proof-of-delivery (safer for the client, faster for the tailor)?

---

## Execution order

Phase 1 immediately (no decisions needed, no revenue risk).
Phase 2 after you confirm rates.
Phase 3 after Phase 2.
Phase 4–5 as scheduled.

Each phase: change → SQL applied to live DB → build → deploy → verify.
---

## Progress log

### Phase 1 — COMPLETE (deployed 2026-10-07)
- [x] S1.1 Flutterwave secret key removed from client. `flutterwave_transfer_service.dart` deleted (was orphaned), `flutterwaveSecretKey` getter removed, keys stripped from `.env` / `assets/.env` / `.env.server.bak`. Verified `secret_key_in_bundle=0`.
- [x] S1.2 Buyer self-release hole closed. `orders` UPDATE split into "Tailors can manage own orders" + "Buyers can cancel own pending orders" (pending + unpaid only).
- [x] S1.4 `merchant_wallets` + `payout_requests` created. NUMERIC(12,2), one-payout-per-order unique constraint, no client write policies.
- [x] S1.3 Payout toast now truthful — success only when the payout was actually queued.
- [x] S1.5 Double-pay closed. `release_order_payout()` is transactional (`FOR UPDATE`) and idempotent.
- [x] Found and fixed during verification: `wallet_balance(UUID)` was readable by `anon` and accepted an arbitrary user id. Now takes no argument, derives caller from `auth.uid()`.
- Migration: `20261007000001_payment_ledger.sql`, `20261007000002_wallet_balance_scope.sql`

### Phase 2 — COMPLETE (deployed 2026-10-07)
- [x] `platform_config` table seeded: `commission` = 0.10, `deposit_split` = 40/60, `staged_payments_enabled` = false. Seeded at the CURRENT rate so deploy changes no economics.
- [x] `PlatformMoneyConfig` replaces all hardcoded commission literals. Boot-time load with safe fallback. Rounded to 2dp (NUMERIC parity).
- [x] `request_wallet_payout(amount)` RPC: self-service payout, ownership + balance checked server-side, moves balance→pending_payout in one transaction, blocks concurrent payouts. Replaces the direct client insert that Phase 1 had (correctly) broken.
- [x] `wallet_balance()` wired into `getWalletBalance`.
- [x] Tailor service charge columns present: `base_stitching_price`, `material_cost` (pre-existing) + `alteration_price`, `custom_price`, `express_fee` (added).
- Migration: `20261007000003_wallet_payouts_and_config.sql`

### Not yet done
- [ ] `ServicePricing` entity still not populated by `SupabaseProfileRepository` — needs a Phase 2.5 pass
- [ ] `pricing_setup_page.dart` writes 3 fields; needs the other 3
- [ ] Real escrow: Edge Functions + Flutterwave subaccounts (Phase 3)
- [ ] Order state machine (Phase 5)

### Data observation
`starting_price` understates real cost for at least one tailor: Rita Andrews has
`starting_price=20000` but `base_stitching_price=15000` + `material_cost=20000`
= ₦35,000 actual. The advertised price and the chargeable tiers disagree.

### Phase 2.5 / commission model — COMPLETE (deployed 2026-10-08)
- [x] Commission 10% -> **1.5%**, read from `platform_config`.
- [x] Flutterwave 1.4% recorded as **borne by the tailor** (`fee_bearer: tailor`).
- [x] **Critical**: subaccount `split_value` stored as **0.971**, not 0.985. Flutterwave deducts its fee from the settlement *before* distributing the split, so a 98.5% split would leave the platform paying the 1.4% that is meant to come from the tailor.
- [x] Commission basis = **service only** (stitching/alteration/custom/express). Material and delivery are pass-through.
- [x] Refund policy recorded: full refund before `bookingAccepted`, none from `inProgress`, platform absorbs the non-refundable fee pre-acceptance.
- [x] Rita Andrews data fixed: `starting_price` 20000 -> 15000 (= stitching). "From" price is now the service floor; material is only charged when the tailor sources it.
- [x] Fabric ownership added to the flow: "I already have my fabric" / "I need fabric sourced". Previously the tailor's material cost was baked into every order whether or not it applied.
- [x] `orders.client_supplies_material` (nullable tri-state) + `orders.price_breakdown` (frozen at checkout).
- [x] `test/platform_money_config_test.dart` — 14 tests, money conservation at awkward amounts, commission basis, ownership tri-state.

#### Bug caught by the test suite
`subaccountSplitValue` used `round2()` (cent rounding) on a **percentage**.
0.971 -> 0.97, i.e. 97% not 97.1% — silently overcharging the platform's take by
0.1% on every order. Now rounded to 6dp; regression test added.

### Still open
- [ ] `ServicePricing` population + pricing_setup_page: needs alteration/custom/express inputs (columns now exist)
- [ ] Phase 3 Edge Functions: subaccount creation, split, payout transfer, refund
- [ ] Order state machine
