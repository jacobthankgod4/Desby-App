-- Shopping cart table for marketplace
CREATE TABLE IF NOT EXISTS carts (
  user_id TEXT PRIMARY KEY,
  items JSONB DEFAULT '[]'::jsonb,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS
ALTER TABLE carts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "carts_select" ON carts;
CREATE POLICY "carts_select" ON carts FOR SELECT USING (auth.uid()::text = user_id);
DROP POLICY IF EXISTS "carts_insert" ON carts;
CREATE POLICY "carts_insert" ON carts FOR INSERT WITH CHECK (auth.uid()::text = user_id);
DROP POLICY IF EXISTS "carts_update" ON carts;
CREATE POLICY "carts_update" ON carts FOR UPDATE USING (auth.uid()::text = user_id);
