# Terminal Shipping — 30-Phase Logistics Integration Plan

## Context

Logistics was migrated from Fez (single courier, credentials never issued) to
Terminal Shipping (multi-carrier aggregator). Verified live on the sandbox
2026-10-10.

**What works today (verified, not assumed):**

| Step | Endpoint | Result |
|---|---|---|
| Carriers | `GET /carriers` | 200 — 42 carriers, 29 Nigeria-capable |
| Quote | `POST /rates/shipment/quotes` | 200 — 6 priced carriers |
| Shipment | `POST /shipments` | 200 — `SH-CHZV6RF6NKQD23HR` (draft) |
| **Arrange pickup** | **`POST /shipments/pickup`** | **200 — `SH-PHC24RR57YHHDI2S` (confirmed)** |
| Track | `GET /shipments/{id}` | 200 — reads state + events |

Non-obvious API constraints discovered by probing (each one cost a failed call):

1. `POST /shipments/pickup` requires a `rate_id` from a **persisted** quote
   (`persist_data: true`). A non-persisted quote yields no usable rate.
2. With `persist_data: true`, **every** address field is required —
   `line2`, `first_name`, `last_name`, `email` — and empty strings are rejected
   even for genuinely absent fields.
3. Shipment addresses must **match the quote's addresses exactly**. Reusing a
   pre-created shipment with a separately-quoted rate fails with
   "Shipment address details must match selected rate address details".
   The working flow is quote → pickup in one pass, letting Terminal create the
   shipment.
4. Phone numbers are validated against the address country: Nigerian numbers
   must be `+234…`, not `0803…`.

**KYC status:** live API returns `Complete KYC verification to access the API`.
Test keys work fully. Going live = flip two env vars, no code change.

---

## Track 1 — Correctness (P1–P8)

Fix defects found in the audit of the UI layer above the repository.

- [x] **P1** Map Terminal's `events` into the shape the tracking page renders.
      Page reads `order` / `history` / `deliveryEta`; Terminal returns
      `status` / `shipment_id` / `events`. Status alone overlaps; timeline and
      ETA silently render nothing. **Customer-facing breakage.**
- [x] **P2** Remove hardcoded `estimateCost('Lagos')` from
      `dispatch_logistics_module.dart` and `dispatch_logistics_modal.dart` —
      every order gets a Lagos price regardless of destination.
- [x] **P3** Add `delivery_eta` / `pickup_eta` (minutes) to the tracking payload
      so the page can show a real ETA instead of "—".
- [x] **P4** Normalise event statuses to the labels the UI already renders.
- [x] **P5** Guard tracking when `shipment_id` is a draft — show "awaiting
      dispatch" rather than a dead timeline.
- [x] **P6** Verify the tracking page renders a non-empty timeline end-to-end.
- [x] **P7** Keep Fez fully isolated: no `fez` identifiers in UI copy.
- [x] **P8** `fez_order_no` column retained as the shipment-ref store (no
      migration churn); document that it now holds Terminal refs.

## Track 2 — Dispatch completion (P9–P14)

Make `summonRider` actually complete a dispatch instead of leaving a draft.

- [x] **P9** Implement `arrangePickup` against `POST /shipments/pickup`.
- [x] **P10** Make quote→pickup atomic: persist the quote, then arrange using
      the same address objects so the match check passes.
- [x] **P11** Persist `rate_id` + carrier choice between quote and pickup.
- [x] **P12** Store the Terminal tracking number from `extras.tracking_number`
      on the order.
- [x] **P13** Write `fez_order_no` only after a **confirmed** (not draft)
      shipment, so the order never points at an unarranged shipment.
- [x] **P14** Verify end-to-end in sandbox: quote → pickup → confirmed →
      track.

## Track 3 — Multi-carrier value (P15–P21)

Currently 6 quotes collapse to the cheapest, throwing away the aggregator's
main advantage.

- [x] **P15** Return the full quote list from the repository, not just a price.
- [x] **P16** Introduce `DeliveryQuote` model (carrier, slug, price, eta,
      delivery_time, rateId).
- [x] **P17** Select cheapest by default; allow an explicit carrier choice.
- [x] **P18** Surface carrier + ETA in checkout so the customer sees who
      delivers and when.
- [x] **P19** Extend the interface to carry weight/dimensions — quotes currently
      assume a flat 1kg, underquoting heavy bundles.
- [x] **P20** Label COD availability per carrier (Terminal exposes
      `cash_to_collect` on rates that support it).
- [x] **P21** Fall back to cheapest when a chosen carrier becomes unavailable.

## Track 4 — UX integration (P22–P27)

One dispatch surface, not three ad-hoc call sites.

- [x] **P22** Extract a single shared dispatch component used by booking cart,
      order detail and tailor dashboard.
- [x] **P23** Wire it into `booking_cart_page` (replaces
      `DispatchLogisticsModule`).
- [x] **P24** Wire it into `order_detail_page`.
- [x] **P25** Wire it into `tailor_dashboard`.
- [x] **P26** Show dispatch state inline (draft / confirmed / in transit).
- [x] **P27** Disable the dispatch control once a shipment is confirmed.

## Track 5 — Hardening (P28–P30)

- [x] **P28** Sandbox-default in config; verify script refuses non-sandbox.
- [x] **P29** Extend `verify_terminal_shipping.sh` to cover quote → pickup →
      track, and fail loudly on drift.
- [x] **P30** Document the live cutover: complete KYC, flip two env vars, keep
      Fez for rollback.

---

## Definition of done

- [x] Tracking page shows a real timeline and ETA (P1–P6)
- [x] `summonRider` returns a **confirmed** shipment, not a draft (P9–P14)
- [x] Destination state drives pricing, no hardcoded Lagos (P2)
- [x] Carrier choice reaches the customer (P15–P21)
- [x] All 282 tests pass, analyze clean
- [x] `verify_terminal_shipping.sh` green against sandbox

## Rollout

1. Ship sandbox-backed dispatch (P1–P14) — usable today.
2. Complete Terminal KYC.
3. Flip `TERMINAL_API_SECRET_KEY` / `TERMINAL_API_BASE_URL` to live.
4. Roll back to Fez by editing one line in `logistics_provider.dart` if needed.