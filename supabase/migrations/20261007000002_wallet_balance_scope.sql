-- Security follow-up found during Phase 1 verification.
--
-- wallet_balance(p_user_id) accepted an arbitrary user id and was executable by
-- `anon`, so anyone could read any tailor's balance by guessing a UUID. The
-- REVOKE in the first migration only removed the implicit PUBLIC grant; Supabase
-- had also granted EXECUTE explicitly to anon/authenticated at creation.
--
-- Fix: no argument. The function derives the user from auth.uid(), so it can
-- only ever return the caller's own balance.

DROP FUNCTION IF EXISTS public.wallet_balance(UUID);
DROP FUNCTION IF EXISTS public.wallet_balance();

CREATE OR REPLACE FUNCTION public.wallet_balance()
RETURNS NUMERIC
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT balance FROM public.merchant_wallets WHERE user_id = auth.uid()),
    0
  );
$$;

-- Belt and braces: drop from PUBLIC *and* from anon explicitly.
REVOKE ALL ON FUNCTION public.wallet_balance() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.wallet_balance() FROM anon;

GRANT EXECUTE ON FUNCTION public.wallet_balance() TO authenticated;
GRANT EXECUTE ON FUNCTION public.wallet_balance() TO service_role;

-- release_order_payout must not be reachable by an unauthenticated caller.
REVOKE ALL ON FUNCTION public.release_order_payout(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.release_order_payout(UUID) FROM anon;

GRANT EXECUTE ON FUNCTION public.release_order_payout(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.release_order_payout(UUID) TO service_role;