-- Add order_details JSONB column to clients table
-- Stores garment type, due date, fabric, color, material photo, selected product info
-- Used by the invite flow so the client can fill order details before submitting

ALTER TABLE public.clients
  ADD COLUMN IF NOT EXISTS order_details JSONB DEFAULT '{}'::jsonb;
