-- Payment ledger + escrow hardening (Phase 1)
-- Fixes, in order of severity:
--   1. buyers could UPDATE orders.status themselves (self-release)
--   2. merchant_wallets / payout_requests did not exist at all
--   3. no idempotent, transactional payout release path
-- Safe to re-run.

-- ---------------------------------------------------------------------------
-- 1. Close the buyer-can-release-their-own-money hole.
--
-- Previously the UPDATE policy allowed any row where
-- auth.uid() = tailor_id OR auth.uid() = requesting_user_id. A buyer matches
-- requesting_user_id, so a buyer could set status='delivered' and payment_status
-- to unlock a payout. The UI hid the button; RLS is the real boundary.
--
-- Tailors keep full control of their own orders. Buyers get no direct UPDATE on
-- lifecycle or money columns -- they go through release_order_payout() instead.
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can update relevant orders" ON public.orders;
DROP POLICY IF EXISTS "Tailors can manage own orders" ON public.orders;

CREATE POLICY "Tailors can manage own orders" ON public.orders
  FOR UPDATE TO authenticated
  USING (auth.uid() = tailor_id)
  WITH CHECK (auth.uid() = tailor_id);

-- Buyers may only withdraw their own order before any work has started.
-- Scoped to the minimum: cancellation of a pending/unpaid order.
DROP POLICY IF EXISTS "Buyers can cancel own pending orders" ON public.orders;

CREATE POLICY "Buyers can cancel own pending orders" ON public.orders
  FOR UPDATE TO authenticated
  USING (
    auth.uid() = requesting_user_id
    AND status IN ('pending')
    AND payment_status NOT IN ('paid', 'confirmed')
  )
  WITH CHECK (
    auth.uid() = requesting_user_id
    AND status = 'cancelled'
  );

-- ---------------------------------------------------------------------------
-- 2. Money is NUMERIC, never DOUBLE PRECISION.
-- Floating point cannot represent 0.10 exactly; on a payout ledger that
-- accumulates error across many rows. NUMERIC is exact decimal.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.merchant_wallets (
  user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  balance NUMERIC(12,2) NOT NULL DEFAULT 0,
  pending_payout NUMERIC(12,2) NOT NULL DEFAULT 0,
  currency TEXT NOT NULL DEFAULT 'NGN',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT merchant_wallets_balance_non_negative CHECK (balance >= 0),
  CONSTRAINT merchant_wallets_pending_non_negative CHECK (pending_payout >= 0)
);

ALTER TABLE public.merchant_wallets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own wallet" ON public.merchant_wallets;
CREATE POLICY "Users can view own wallet" ON public.merchant_wallets
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

-- Deliberately NO insert/update/delete policy: the wallet is written only by
-- service_role (Edge Functions) and by release_order_payout(). A client that can
-- credit itself is a client that can mint money.

CREATE TABLE IF NOT EXISTS public.payout_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
  amount NUMERIC(12,2) NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','processing','processed','failed','reversed')),
  bank_details JSONB,
  flutterwave_transfer_id TEXT,
  failure_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  processed_at TIMESTAMPTZ,
  CONSTRAINT payout_requests_amount_positive CHECK (amount > 0),
  -- One payout per order. This is the database-level guarantee against the
  -- double-pay where the wallet was credited AND a transfer was issued.
  CONSTRAINT payout_requests_one_per_order UNIQUE (order_id)
);

ALTER TABLE public.payout_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Sellers view own payouts" ON public.payout_requests;
CREATE POLICY "Sellers view own payouts" ON public.payout_requests
  FOR SELECT TO authenticated
  USING (auth.uid() = seller_id);

-- Same rule as the wallet: writes are server-side only.

CREATE INDEX IF NOT EXISTS payout_requests_seller_idx
  ON public.payout_requests (seller_id, created_at DESC);
CREATE INDEX IF NOT EXISTS payout_requests_status_idx
  ON public.payout_requests (status)
  WHERE status IN ('pending', 'processing');

-- ---------------------------------------------------------------------------
-- 3. Transactional, idempotent payout release.
--
-- FOR UPDATE serialises concurrent delivery confirmations (the old code did a
-- read-modify-write on the wallet balance and lost credits under contention).
-- The partial unique index makes a repeat call a no-op instead of a second
-- payout.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.release_order_payout(p_order_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_order   public.orders%ROWTYPE;
  v_actor   UUID := auth.uid();
  v_existing UUID;
  v_amount  NUMERIC(12,2);
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_order FROM public.orders WHERE id = p_order_id FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'order not found' USING ERRCODE = 'P0002';
  END IF;

  IF v_order.requesting_user_id <> v_actor THEN
    RAISE EXCEPTION 'not authorised for this order' USING ERRCODE = '42501';
  END IF;

  IF v_order.status <> 'delivered' THEN
    RAISE EXCEPTION 'order is not delivered' USING ERRCODE = '22023';
  END IF;

  IF v_order.payment_status NOT IN ('paid', 'confirmed') THEN
    RAISE EXCEPTION 'order is not paid' USING ERRCODE = '22023';
  END IF;

  -- Idempotency: if a payout already exists for this order, return it.
  SELECT id INTO v_existing
    FROM public.payout_requests
   WHERE order_id = p_order_id
     AND status IN ('pending','processing','processed');

  IF v_existing IS NOT NULL THEN
    RETURN jsonb_build_object(
      'status', 'already_released',
      'payout_id', v_existing
    );
  END IF;

  v_amount := COALESCE(v_order.tailor_payout,
                       v_order.total_amount * 0.90);

  IF v_order.tailor_id IS NULL THEN
    RAISE EXCEPTION 'order has no tailor' USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.payout_requests (seller_id, order_id, amount, status)
  VALUES (v_order.tailor_id, p_order_id, v_amount, 'pending');

  UPDATE public.orders
     SET payment_status = 'confirmed',
         updated_at = NOW()
   WHERE id = p_order_id;

  RETURN jsonb_build_object(
    'status', 'queued',
    'amount', v_amount,
    'tailor_id', v_order.tailor_id
  );
END;
$$;

REVOKE ALL ON FUNCTION public.release_order_payout(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.release_order_payout(UUID) TO authenticated;

-- ---------------------------------------------------------------------------
-- 4. wallet_balance(): single source of truth for the balance figure the client
-- renders. Kept in the DB so no client can compute its own number.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.wallet_balance(p_user_id UUID)
RETURNS NUMERIC
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(balance, 0) FROM public.merchant_wallets WHERE user_id = p_user_id;
$$;

REVOKE ALL ON FUNCTION public.wallet_balance(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.wallet_balance(UUID) TO authenticated;