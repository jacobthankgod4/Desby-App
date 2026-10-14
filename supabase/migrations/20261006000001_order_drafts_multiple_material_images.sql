-- Desby · guided booking flow — multiple reference images + persisted scan data
--
-- Run this in the Supabase SQL editor. It is idempotent, so it is safe to run
-- more than once.
--
-- Why each piece exists:
--  * material_asset_urls — the cloth reference step now accepts SEVERAL images
--    per request. The old single `material_asset_url` text column could only
--    ever hold one, so a client could not show a tailor more than one angle.
--  * measurements      — already present; the scan writes 25 values here as
--    JSONB. Kept in this file so a fresh environment gets the same shape.
--  * measurement_*     — provenance, so the tailor can tell a real scan from
--    a typed-in estimate.
--  * body_scans lookup — the submitted order needs to point at the scan row so
--    the client's stored scan stays reachable from the booking.

begin;

-- ── 1. Multiple cloth/reference images ──────────────────────────────────────
alter table public.order_drafts
  add column if not exists material_asset_urls jsonb not null default '[]'::jsonb;

-- Backfill from the original single-image column so existing drafts keep their
-- reference instead of appearing to have none.
update public.order_drafts
   set material_asset_urls = jsonb_build_array(material_asset_url)
 where material_asset_url is not null
   and (material_asset_urls is null or material_asset_urls = '[]'::jsonb);

-- ── 2. Scan data (safe to re-run; the column already exists in production) ──
alter table public.order_drafts
  add column if not exists measurements jsonb;

alter table public.order_drafts
  add column if not exists measurement_source text;

alter table public.order_drafts
  add column if not exists measurement_scan_id text;

-- ── 3. Delivery, needed for the indicative cost + Fez dispatch ─────────────
alter table public.order_drafts
  add column if not exists delivery_address text;

alter table public.order_drafts
  add column if not exists due_date timestamptz;

-- ── 4. Guard: the column must always be an array ────────────────────────────
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'order_drafts_material_asset_urls_is_array'
  ) then
    alter table public.order_drafts
      add constraint order_drafts_material_asset_urls_is_array
      check (jsonb_typeof(material_asset_urls) = 'array');
  end if;
end
$$;

commit;

-- ── Verify ──────────────────────────────────────────────────────────────────
select column_name, data_type, column_default
  from information_schema.columns
 where table_schema = 'public'
   and table_name   = 'order_drafts'
   and column_name in ('material_asset_url', 'material_asset_urls',
                       'measurements', 'measurement_source',
                       'measurement_scan_id', 'delivery_address', 'due_date')
 order by column_name;
