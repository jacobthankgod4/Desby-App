-- Terminal Shipping persistence for Desby.
-- Run in Supabase SQL Editor: https://supabase.com/dashboard/project/sakmdeacligrqayfxyb/sql
--
-- Idempotent — safe to re-run.
--
-- Context: `fez_order_no` already exists and is reused as the shipment
-- reference column (Terminal replaces Fez). The columns below are additive
-- detail columns so the customer tracking page and operations dashboards can
-- read carrier + tracking without a Terminal API round-trip.

-- 1. Detail columns -------------------------------------------------------
alter table orders
  add column if not exists shipping_carrier text,
  add column if not exists shipping_amount numeric,
  add column if not exists shipping_tracking_number text,
  add column if not exists shipping_carrier_slug text,
  add column if not exists shipping_shipment_status text;

-- 2. Lookup index ---------------------------------------------------------
-- Tracking-number lookups are the hot path for the customer tracking page.
create index if not exists idx_orders_shipping_tracking
  on orders (shipping_tracking_number)
  where shipping_tracking_number is not null;

-- 3. Verify ---------------------------------------------------------------
select column_name, data_type
from information_schema.columns
where table_name = 'orders'
  and column_name like 'shipping_%'
order by column_name;

-- 4. Audit: report WITH CHECK on the buyer UPDATE policy -------------------
-- "Buyers can cancel own pending orders" is USING-only in pg_policies. If
-- WITH CHECK is also absent, a buyer may rewrite arbitrary columns on their
-- own pending, unpaid order — including total_amount. Run the SELECT below
-- and paste the result before shipping production payments.
select policyname, cmd, qual, with_check
from pg_policies
where tablename = 'orders'
  and cmd = 'UPDATE';