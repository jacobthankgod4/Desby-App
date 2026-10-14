-- Self-service wallet payouts (Phase 2, part 2).
--
-- Phase 1 removed all client write policies on merchant_wallets /
-- payout_requests, which correctly broke the "REQUEST PAYOUT" button: the
-- client was inserting a payout row directly, and now cannot. Rather than leave
-- a dead button, this gives the feature a safe server-side implementation.
--
-- Rules enforced here that the client cannot be trusted to enforce:
--   * you can only pay out from YOUR OWN wallet (auth.uid(), not an argument)
--   * you cannot pay out more than your settled balance
--   * the balance moves to pending_payout in the same transaction, so a
--     double-tap cannot drain the wallet
--   * payout_requests.order_id is NULL for wallet payouts, which the
--     one-payout-per-order constraint permits (multiple NULLs are allowed)

CREATE OR REPLACE FUNCTION public.request_wallet_payout(p_amount NUMERIC)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor  UUID := auth.uid();
  v_balance NUMERIC(12,2);
  v_pending NUMERIC(12,2);
  v_payout UUID;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '42501';
  END IF;

  IF p_amount IS NULL OR p_amount <= 0 THEN
    RAISE EXCEPTION 'amount must be positive' USING ERRCODE = '22023';
  END IF;

  -- Lock the wallet row for the duration of the transaction.
  SELECT balance, pending_payout INTO v_balance, v_pending
    FROM public.merchant_wallets
   WHERE user_id = v_actor
     FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'no wallet for this user' USING ERRCODE = 'P0002';
  END IF;

  IF v_balance < p_amount THEN
    RAISE EXCEPTION 'insufficient balance: % available, % requested',
      v_balance, p_amount USING ERRCODE = '22023';
  END IF;

  -- Guard against concurrent requests stacking up while one is still pending.
  IF COALESCE(v_pending, 0) > 0 THEN
    RAISE EXCEPTION 'a payout is already pending' USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.payout_requests (seller_id, order_id, amount, status)
  VALUES (v_actor, NULL, p_amount, 'pending')
  RETURNING id INTO v_payout;

  UPDATE public.merchant_wallets
     SET balance      = balance - p_amount,
         pending_payout = pending_payout + p_amount,
         updated_at   = NOW()
   WHERE user_id = v_actor;

  RETURN jsonb_build_object(
    'status', 'queued',
    'payout_id', v_payout,
    'amount', p_amount,
    'remaining_balance', v_balance - p_amount
  );
END;
$$;

REVOKE ALL ON FUNCTION public.request_wallet_payout(NUMERIC) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.request_wallet_payout(NUMERIC) FROM anon;
GRANT EXECUTE ON FUNCTION public.request_wallet_payout(NUMERIC)
  TO authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Central money config. Phase 2 replaces the 5 hardcoded 0.10s in the client.
--
-- Seeded with the CURRENT rate so nothing changes economically on deploy --
-- this is a mechanism, not a repricing. Edit the row to change the rate.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.platform_config (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT platform_config_rate_range
    CHECK (key <> 'commission'
           OR (value->>'rate')::NUMERIC BETWEEN 0 AND 0.5)
);

ALTER TABLE public.platform_config ENABLE ROW LEVEL SECURITY;

-- Read-only for authenticated users. Written by service_role only.
DROP POLICY IF EXISTS "Authenticated can read platform config" ON public.platform_config;
CREATE POLICY "Authenticated can read platform config" ON public.platform_config
  FOR SELECT TO authenticated
  USING (true);

INSERT INTO public.platform_config (key, value) VALUES
  ('commission', '{"rate": 0.10, "basis": "gross", "label": "Platform commission"}'::jsonb),
  ('deposit_split', '{"deposit_pct": 0.40, "balance_pct": 0.60, "staged_payments_enabled": false}'::jsonb)
ON CONFLICT (key) DO NOTHING;

COMMENT ON TABLE public.platform_config IS
  'Single source of truth for platform money rules. Replace the hardcoded 0.10 '
  'constants in the Flutter client; all computation moves server-side.';

-- ---------------------------------------------------------------------------
-- Tailor service charge.
--
-- `starting_price` alone cannot express "sewing 8k + fabric 15k". These columns
-- wire up the already-built-but-orphaned ServicePricing entity in
-- lib/features/auth/domain/entities/user.dart.
-- ---------------------------------------------------------------------------
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS base_stitching_price NUMERIC(12,2),
  ADD COLUMN IF NOT EXISTS alteration_price      NUMERIC(12,2),
  ADD COLUMN IF NOT EXISTS custom_price          NUMERIC(12,2),
  ADD COLUMN IF NOT EXISTS material_cost         NUMERIC(12,2),
  ADD COLUMN IF NOT EXISTS express_fee           NUMERIC(12,2);

-- starting_price stays authoritative for display; it is a floor derived from
-- whichever tier the tailor actually set. Backfill where possible so existing
-- tailors are not left blank.
UPDATE public.users
   SET base_stitching_price = starting_price
 WHERE starting_price IS NOT NULL
   AND starting_price > 0
   AND base_stitching_price IS NULL;