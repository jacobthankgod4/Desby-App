-- Phase 3 groundwork: money rules + consistent tailor pricing.
--
-- COMMISSION ECONOMICS (decided 2026-10-07)
--   Commission is 1.5% of the tailor charge. Flutterwave's ~1.4% transaction
--   fee is absorbed BY THE TAILOR.
--
--   Client pays G.   Platform must retain 1.5%.   Tailor must net G - 1.4%G.
--   => tailor share = 97.1% of GROSS.
--
--   This matters for the Flutterwave subaccount `split_value`. Flutterwave
--   applies its transaction fee to the settlement BEFORE distributing the
--   split, so the percentage is taken from the NET. Configuring 98.5% would
--   quietly leave the platform paying the 1.4% instead of the tailor. The
--   stored `split_value` is therefore 0.971, kept explicit so nobody
--   "simplifies" it back to 0.985.
--
-- COMMISSION BASIS: on the tailor charge only (stitching + alteration + custom
--   + express). Material is pass-through -- the tailor is not the platform's
--   agent for cloth, and charging commission on fabric the client already owns
--   would penalise the common "I have my own fabric" case.
--
-- REFUND POLICY
--   * Full refund before the tailor accepts the booking.
--   * From `inProgress`, no refund: work has begun, material may be cut.
--   * Flutterwave's charge is non-refundable. On a pre-acceptance refund the
--     platform absorbs it. After acceptance, whoever caused it absorbs it.

INSERT INTO public.platform_config (key, value) VALUES
  ('commission', jsonb_build_object(
      'rate', 0.015,
      'basis', 'service_only',
      'label', 'Platform commission',
      'fee_bearer', 'tailor',
      'payment_fee_pct', 0.014,
      'split_value', 0.971,
      'tailor_share_pct', 97.1,
      'note', 'split_value = 1 - commission - payment_fee, applied to GROSS because the fee is charged to the tailor.'
    ))
ON CONFLICT (key) DO UPDATE SET
  value = EXCLUDED.value,
  updated_at = NOW();

-- Money that is not the tailor's service. Material is conditional on whether
-- the client already owns their cloth, so it is never charged commission.
INSERT INTO public.platform_config (key, value) VALUES
  ('material_policy', jsonb_build_object(
      'charges_commission', false,
      'client_can_supply_own', true,
      'label', 'Fabric handling'
    ))
ON CONFLICT (key) DO UPDATE SET
  value = EXCLUDED.value,
  updated_at = NOW();

INSERT INTO public.platform_config (key, value) VALUES
  ('refund_policy', jsonb_build_object(
      'full_refund_before', 'bookingAccepted',
      'no_refund_from', 'inProgress',
      'fee_absorbed_by_platform_until', 'bookingAccepted',
      'label', 'Refund rules'
    ))
ON CONFLICT (key) DO UPDATE SET
  value = EXCLUDED.value,
  updated_at = NOW();

-- ---------------------------------------------------------------------------
-- Tailor pricing consistency.
--
-- `starting_price` is what a shopper sees as "from NGN X", so it must be the
-- MINIMUM chargeable amount for the service. Material is conditional (the
-- client may already own their cloth), so it can never be part of the floor.
--
-- Rita Andrews had starting_price=20000 with stitching=15000 and
-- material=20000. Two problems: the advertised price sat below stitch+material
-- (so the order would be quoted under cost), and material should not appear in
-- a "from" price at all. The correct floor is the stitching price.
-- ---------------------------------------------------------------------------
UPDATE public.users
   SET starting_price = base_stitching_price
 WHERE base_stitching_price IS NOT NULL
   AND base_stitching_price > 0
   AND (starting_price IS NULL
        OR starting_price <> base_stitching_price);

-- Cloth ownership. Nullable tri-state: an order can exist before the question
-- is answered.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_schema = 'public' AND table_name = 'orders'
       AND column_name = 'client_supplies_material'
  ) THEN
    ALTER TABLE public.orders ADD COLUMN client_supplies_material BOOLEAN;
  END IF;
END $$;

COMMENT ON COLUMN public.orders.client_supplies_material IS
  'TRUE: client owns their cloth, material_cost is not charged. '
  'FALSE: tailor must source fabric, material_cost applies. '
  'NULL: not yet answered.';

-- Which line items were actually charged, frozen at checkout so settlement does
-- not depend on the tailor's current rates and disputes can be reconstructed.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_schema = 'public' AND table_name = 'orders'
       AND column_name = 'price_breakdown'
  ) THEN
    ALTER TABLE public.orders
      ADD COLUMN price_breakdown JSONB NOT NULL DEFAULT '{}'::jsonb;
  END IF;
END $$;

COMMENT ON COLUMN public.orders.price_breakdown IS
  'Keys: stitching, alteration, custom, express, material, delivery, commission, payment_fee. '
  'Frozen at checkout so settlement does not depend on the tailor current rates.';