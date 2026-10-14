# Flutterwave Edge Functions — deployment

## Why this exists

`flutterwave_service.dart` uses the Flutterwave **inline JS SDK**, which reports
success **from the browser**. That result is browser-controlled: anyone can make
the page claim any reference succeeded.

The old flow was:

1. Browser SDK says "successful"
2. Client writes `status: 'paid'` to `orders` with the buyer's own JWT

Step 2 failed, because the buyer RLS policy only permits `status = 'cancelled'`.
So **no card payment ever persisted** — the user saw *"Payment received, but
order status is still syncing."*

Neither `flutterwave-pay` nor `flutterwave-verify` existed on the project
(both returned `404` from `https://<ref>.supabase.co/functions/v1/...`), so
payment could not even be initialised.

## What changed

The client no longer writes to `orders`. It asks `flutterwave-verify`, which:

1. calls Flutterwave's REST API with the **secret** key,
2. only if Flutterwave confirms, marks the orders paid using `service_role`.

The buyer RLS policy is left exactly as it is — it should not be loosened.
`service_role` is used only *after* Flutterwave confirms, which is the one
point where a trusted server knows the money arrived.

`flutterwave-pay` also re-reads `total_amount` from the database rather than
trusting the amount in the request body.

## Deploy

You need a **Supabase access token** (`sbp_…`, from Account Settings →
Access Tokens) — this is *not* the `service_role` JWT key, which cannot deploy.

```bash
cd /Users/mac/desby_app
supabase login
supabase link --project-ref sakmdeacligrqayfxyb
```

Then set the secrets (Dashboard → Project Settings → Edge Functions → Secrets,
or `supabase secrets set`):

| Secret | Value |
|---|---|
| `FLUTTERWAVE_SECRET_KEY` | `FLWSECK_TEST-…` (sandbox) / `FLWSECK-…` (live) |
| `FLUTTERWAVE_PUBLIC_KEY` | `FLWPUBK_TEST-…` / `FLWPUBK-…` |

`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are injected automatically.

Deploy both:

```bash
supabase functions deploy flutterwave-pay
supabase functions deploy flutterwave-verify
```

## Verify

```bash
U=https://sakmdeacligrqayfxyb.supabase.co
K=$(grep -E '^SUPABASE_ANON_KEY=' .env | cut -d= -f2-)

# must be 404 -> not 404 means deployed
curl -s -o /dev/null -w '%{http_code}\n' -X POST \
  "$U/functions/v1/flutterwave-verify?tx_ref=probe" \
  -H "apikey: $K" -H "Authorization: Bearer $K"
```

A real transaction check still needs a live checkout.

## Files

- `supabase/functions/flutterwave-verify/index.ts` — verify + settle
- `supabase/functions/flutterwave-pay/index.ts` — init, server-side amount
- `lib/features/payments/presentation/pages/checkout_page.dart` —
  `_confirmPaymentWithServer` replaces the old client-side `_markOrdersPaid`
- `lib/core/services/flutterwave_service.dart` — `verifyTransaction(txRef, orderId:)`

## Still open

- `subscription_plans_page.dart` also uses this service; confirm subscription
  payments settle the same way (they may reference `payment_reference` on a
  different table).
- Platform fee / tailor payout columns are no longer written from the client.
  If `platform_fee` and `tailor_payout` are needed on the order, compute them in
  `flutterwave-verify` from `PlatformMoneyConfig` rules.