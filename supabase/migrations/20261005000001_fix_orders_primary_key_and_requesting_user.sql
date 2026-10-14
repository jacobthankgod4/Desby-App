-- Make orders actually writable.
--
-- Proven against production on 2026-10-05 by replaying the exact payload
-- price_estimation_page.dart builds. orders held 0 rows:
--
--   INSERT (id='ORD_1757000000000')
--     -> 400 22P02 invalid input syntax for type uuid: "ORD_1757000000000"
--   INSERT (id=<uuid>, client_id=<users.id>)
--     -> 409 23503 Key (client_id)=(...) is not present in table "clients"
--
-- Three id schemes were in play (ORD_ / MKT_ / PUR_) and all three are rejected
-- by a uuid primary key. The real DDL is:
--
--   id            uuid PRIMARY KEY DEFAULT gen_random_uuid()
--   client_id     uuid REFERENCES clients(id) ON DELETE SET NULL
--   tailor_id     uuid REFERENCES users(id)      ON DELETE CASCADE
--
-- The old supabase_schema_fix.sql still describes id TEXT / client_id TEXT, so
-- the code and the schema agreed with each other and both disagreed with prod.
-- This migration keeps the live uuid PK and fixes the two columns the code had
-- wrong, plus the RLS policies that made a correct insert impossible.
--
-- Safe to re-run.

-- ===========================================================================
-- 1. reference — the human-readable handle
-- ===========================================================================
-- 'ORD_1757000000000' is what a tailor quotes, what support reads and what the
-- UI shows. Keeping it out of the PK means the PK stays a clean uuid while the
-- readable form stays indexed and searchable.
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS reference TEXT;

UPDATE public.orders
   SET reference = 'ORD_' || regexp_replace(id::text, '-', '', 'g')
 WHERE reference IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_orders_reference_unique
  ON public.orders (reference) WHERE reference IS NOT NULL;

-- ===========================================================================
-- 2. requesting_user_id — who actually placed the request
-- ===========================================================================
-- orders.client_id references clients(id): the tailor's own customer record.
-- A client browsing tailor profiles has no clients row, so the app wrote
-- user.id there and the FK rejected it. Two different entities:
--
--   requesting_user_id = the authenticated Desby account placing the request
--   client_id          = the tailor's customer record, created at fulfilment
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS requesting_user_id UUID REFERENCES public.users(id) ON DELETE SET NULL;

-- Backfill where the old code meant it by client_id. Only matches rows whose
-- client_id happens to be a users row; the clients FK means most do not, which
-- is exactly right — those rows are genuinely unbacked.
UPDATE public.orders o
   SET requesting_user_id = o.client_id
  FROM public.users u
 WHERE o.requesting_user_id IS NULL
   AND u.id = o.client_id;

-- ===========================================================================
-- 3. Access paths
-- ===========================================================================
CREATE INDEX IF NOT EXISTS idx_orders_requesting_user
  ON public.orders (requesting_user_id);

-- Partial: most rows have a tailor, but the index should not carry NULLs.
CREATE INDEX IF NOT EXISTS idx_orders_tailor
  ON public.orders (tailor_id) WHERE tailor_id IS NOT NULL;

-- Draft lookups during checkout. Partial so completed orders stay out.
CREATE INDEX IF NOT EXISTS idx_orders_draft
  ON public.orders (requesting_user_id)
  WHERE status = 'pending' AND paid_at IS NULL;

-- ===========================================================================
-- 4. RLS — the reason a correct insert still could not happen
-- ===========================================================================
-- The INSERT policy was:
--   WITH CHECK (auth.uid()::text = client_id::text
--            OR auth.uid()::text = tailor_id::text)
-- A client placing their own request matches neither term: they are neither the
-- tailor nor a clients row. Every legitimate checkout insert was rejected by
-- RLS before it could fail on the FK, so fixing only the FK was not enough.

DROP POLICY IF EXISTS "Users can create orders" ON public.orders;
CREATE POLICY "Users can create orders" ON public.orders
  FOR INSERT WITH CHECK (
    auth.uid() = requesting_user_id
    OR auth.uid()::text = tailor_id::text
  );

-- A buyer must not be able to complete their own order. Previously the UPDATE
-- policy allowed any row where auth.uid() = client_id, and the marketplace
-- wrote the BUYER's id into tailor_id, which combined to let a buyer set
-- status='delivered' and trigger a payout.
DROP POLICY IF EXISTS "Users can update relevant orders" ON public.orders;
CREATE POLICY "Users can update relevant orders" ON public.orders
  FOR UPDATE USING (
    auth.uid() = tailor_id
    OR auth.uid() = requesting_user_id
  )
  WITH CHECK (
    auth.uid() = tailor_id
    OR auth.uid() = requesting_user_id
  );

-- Reading: a client sees orders they placed, a tailor sees orders for them.
-- requester also needs to see the tailor's public name/category, which is
-- already available via the tailor_id join.
DROP POLICY IF EXISTS "Users can view relevant orders" ON public.orders;
CREATE POLICY "Users can view relevant orders" ON public.orders
  FOR SELECT USING (
    auth.uid() = tailor_id
    OR auth.uid() = requesting_user_id
    OR EXISTS (
      SELECT 1 FROM clients c
      WHERE c.id = orders.client_id
        AND c.email = (SELECT u.email FROM users u WHERE u.id = auth.uid())
    )
  );

-- "Tailors can manage own orders" is duplicated under two names; both are ALL
-- (which includes DELETE) and both allow a tailor to delete their own history,
-- including paid orders. Keep one, and stop DELETE being implicit.
DROP POLICY IF EXISTS "Tailors can manage own orders" ON public.orders;
DROP POLICY IF EXISTS "Tailors can manage their own orders" ON public.orders;
CREATE POLICY "Tailors can manage own orders" ON public.orders
  FOR ALL USING (auth.uid() = tailor_id)
  WITH CHECK (auth.uid() = tailor_id);

-- ===========================================================================
-- 5. Integrity — fail at the column, not silently
-- ===========================================================================
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_total_amount_nonneg;
ALTER TABLE public.orders ADD CONSTRAINT orders_total_amount_nonneg
  CHECK (total_amount >= 0);

ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_dispatch_fee_nonneg;
ALTER TABLE public.orders ADD CONSTRAINT orders_dispatch_fee_nonneg
  CHECK (dispatch_fee IS NULL OR dispatch_fee >= 0);

-- The Dart enum serialises camelCase; older rows and some SQL use snake_case.
-- Accept both plus the legacy 'completed', so a status write cannot be silently
-- rejected and strand an order. Unknown values still fail loudly here.
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_status_known;
ALTER TABLE public.orders ADD CONSTRAINT orders_status_known
  CHECK (status IN (
    'pending', 'paid',
    'bookingAccepted', 'booking_accepted',
    'materialsInTransit', 'materials_in_transit',
    'inProgress', 'in_progress',
    'ready', 'confirmed',
    'delivered', 'completed',
    'cancelled'
  ));

-- due_date is NOT NULL in OrderEntity but nullable here. A missing due date is
-- legitimate — the tailor confirms the timeline — so the DB stays permissive and
-- order.dart makes the field nullable to match reality.