-- Explain the `fez_order_no` column, whose name predates the Terminal Africa switch.
--
-- The column is deliberately NOT renamed. It was created for Fez logistics and
-- is now written with a **Terminal** shipment id by
-- `TerminalShippingRepositoryImpl`, then read back through
-- `TerminalShippingRepositoryImpl.trackDelivery` (`GET /shipments/{ref}`).
--
-- Renaming it would require dual-writing (so existing rows and any older app
-- builds in circulation keep resolving) plus a backfill, for no functional gain.
-- Instead the Dart side is named `shipmentId` with `@JsonKey(name:
-- 'fez_order_no')`, so the code reads correctly while the wire format is
-- unchanged.
--
-- If this is ever renamed properly, use:
--   alter table public.orders rename column fez_order_no to shipment_id;
-- after dual-writing both columns and backfilling.

comment on column public.orders.fez_order_no is
  'Shipment reference. Named for the former Fez integration; now holds a Terminal Africa shipment id and is resolved via GET /shipments/{ref}. See OrderEntity.shipmentId.';