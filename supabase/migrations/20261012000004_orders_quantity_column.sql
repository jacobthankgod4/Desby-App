-- Promote `quantity` from order metadata to a real column on `orders`.
--
-- Shop checkout recorded quantity only inside the `metadata` JSONB blob, so the
-- value could not be queried, indexed or aggregated for fulfilment, reports or
-- returns. The charge itself was already correct (`total_amount` has the
-- quantity multiplied in), so this is a storage/visibility change only.
--
-- The backfill copies existing shop quantities out of metadata so historical
-- orders are queryable immediately.

alter table public.orders
  add column if not exists quantity integer;

comment on column public.orders.quantity is
  'Units ordered. Backfilled from metadata->>quantity for shop orders.';

-- Backfill from metadata where it is recorded. Guarded so re-running is safe
-- and so rows with no recorded quantity stay null rather than silently
-- becoming 1.
update public.orders
set quantity = (metadata->>'quantity')::integer
where quantity is null
  and metadata is not null
  and metadata ? 'quantity'
  and (metadata->>'quantity') ~ '^[0-9]+$';

-- Backstop for orders that have items but no recorded quantity: a single unit.
update public.orders o
set quantity = 1
where o.quantity is null
  and exists (select 1 from jsonb_array_elements(coalesce(o.items, '[]'::jsonb)) item);

alter table public.orders
  alter column quantity set default 1;

-- Supports the fulfilment and reporting queries this column exists for.
create index if not exists idx_orders_quantity
  on public.orders (quantity)
  where quantity is not null;

-- Verify -------------------------------------------------------------------
select
  count(*)                                            as total_orders,
  count(quantity)                                     as with_quantity,
  count(*) filter (where quantity is null)            as without_quantity,
  count(*) filter (where quantity > 1)                as multi_unit
from public.orders;