-- A durable checkout draft.
--
-- The legacy flow kept the whole booking in an untyped Map passed through
-- Navigator.push, so a refresh or a deep link lost everything — which is why
-- booking_cart_page.dart had to render a "CART STARTED ELSEWHERE" recovery
-- screen. This table makes the in-progress request survive that, and across
-- devices, without touching the orders table until the client actually submits.
--
-- Design notes:
--  * One live draft per (user, tailor|product). A second request to the same
--    tailor updates the existing row instead of littering the table.
--  * request_step is the furthest step reached, so re-entry resumes rather than
--    restarting. Steps before it are already answered.
--  * Everything is nullable except the owner. A draft is by definition partial.
--  * RLS is owner-only: a client can read and write their own draft and nobody
--    else's, including tailors looking at other clients.

CREATE TABLE IF NOT EXISTS public.order_drafts (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requesting_user_id  UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

  -- Who the request is for. tailor_id may be null for a product-only browse.
  tailor_id           UUID REFERENCES public.users(id) ON DELETE CASCADE,
  design_id           UUID REFERENCES public.designs(id) ON DELETE CASCADE,
  product_id          UUID REFERENCES public.products(id) ON DELETE CASCADE,

  -- Cached display context, so the journey can render before the tailor/product
  -- fetch resolves and so a deleted product still shows something meaningful.
  tailor_name         TEXT,
  tailor_avatar_url   TEXT,
  product_title       TEXT,
  product_image_urls  JSONB DEFAULT '[]'::jsonb,
  product_category    TEXT,
  product_price       NUMERIC(12,2),

  -- Step 1: what the client actually wants made
  garment_type        TEXT,
  request_summary     TEXT,
  -- 'from_profile' = client is defining the garment from scratch
  -- 'from_product' = client is customising a design that is already chosen
  -- 'custom_design' = product chosen, but they want something different
  entry_mode          TEXT CHECK (entry_mode IN ('from_profile','from_product','custom_design')),

  -- Step 2: visual direction
  style_tags          JSONB DEFAULT '[]'::jsonb,
  fit_preference      TEXT,
  reference_image_url TEXT,
  style_notes         TEXT,

  -- Step 3: fabric. fabric_id links to the real catalogue; the text fields are
  -- the free-text fallback for clients describing fabric the seller does not list.
  -- fabrics.id is uuid in production (the SQL file says TEXT; verified against
  -- the live schema 2026-10-05). Matching the real type, not the stale file.
  fabric_id           UUID REFERENCES public.fabrics(id) ON DELETE SET NULL,
  fabric_name         TEXT,
  fabric_colour       TEXT,

  -- Step 4: occasion. Text[] because a request can be for more than one thing.
  occasions           JSONB DEFAULT '[]'::jsonb,

  -- Step 5: fit. source records which measurement set was used so an order can
  -- always be traced back to a specific scan.
  measurement_source  TEXT CHECK (measurement_source IN ('body_scan','manual','profile','none')),
  measurement_scan_id TEXT,
  measurements        JSONB,

  -- Step 6 + free text
  additional_notes    TEXT,
  material_asset_url  TEXT,
  delivery_address    TEXT,
  due_date            TIMESTAMPTZ,

  -- Index of the furthest step ANSWERED, or -1 when nothing has been answered.
  -- Not 0: a fresh draft and a draft whose step 1 is done are different states,
  -- and resuming a fresh draft at step 2 would skip the question the client has
  -- not answered. Re-entry resumes at request_step + 1.
  request_step        SMALLINT NOT NULL DEFAULT -1,

  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT order_drafts_step_range CHECK (request_step >= -1 AND request_step <= 5),

  -- "One live draft per target", collapsed into a single scalar so it can be an
  -- ON CONFLICT target. A plain unique index over COALESCE(...) does not work:
  -- PostgREST sends the conflict target as column names and Postgres rejects an
  -- expression index with 23505 on the second write. Verified 2026-10-05.
  target_key TEXT GENERATED ALWAYS AS (
      coalesce(tailor_id::text, '')
      || '|' || coalesce(design_id::text, '')
      || '|' || coalesce(product_id::text, '')
  ) STORED
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_order_drafts_owner_target
  ON public.order_drafts (requesting_user_id, target_key);

-- "What do I have in progress?"
CREATE INDEX IF NOT EXISTS idx_order_drafts_owner_updated
  ON public.order_drafts (requesting_user_id, updated_at DESC);

ALTER TABLE public.order_drafts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own order drafts" ON public.order_drafts;
CREATE POLICY "Users manage own order drafts" ON public.order_drafts
  FOR ALL USING (auth.uid() = requesting_user_id)
  WITH CHECK (auth.uid() = requesting_user_id);

-- updated_at upkeep
CREATE OR REPLACE FUNCTION public.touch_order_drafts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS order_drafts_touch_updated_at ON public.order_drafts;
CREATE TRIGGER order_drafts_touch_updated_at
  BEFORE UPDATE ON public.order_drafts
  FOR EACH ROW EXECUTE FUNCTION public.touch_order_drafts_updated_at();