-- Add fabric_seller_id to orders table
-- This column was referenced in marketplace_cart_page.dart but never existed in the schema

ALTER TABLE orders ADD COLUMN IF NOT EXISTS fabric_seller_id UUID REFERENCES users(id) ON DELETE SET NULL;

-- Index for querying orders by seller
CREATE INDEX IF NOT EXISTS idx_orders_fabric_seller ON orders(fabric_seller_id);
