-- Add missing columns to orders table that OrderEntity expects
-- delivery_address and tracking_url are used in the order flow but missing from schema

ALTER TABLE public.orders
ADD COLUMN IF NOT EXISTS delivery_address TEXT,
ADD COLUMN IF NOT EXISTS tracking_url TEXT;
