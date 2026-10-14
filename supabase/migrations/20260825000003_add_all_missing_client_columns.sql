-- Combined migration: Add all missing columns to clients table
-- Run this in Supabase SQL Editor

-- 1. Add invite_sent_at column
ALTER TABLE public.clients
  ADD COLUMN IF NOT EXISTS invite_sent_at TIMESTAMPTZ;

-- 2. Add order_details column
ALTER TABLE public.clients
  ADD COLUMN IF NOT EXISTS order_details JSONB DEFAULT '{}'::jsonb;

-- 3. Add tailor_id column (if not exists from previous migration)
ALTER TABLE public.clients
  ADD COLUMN IF NOT EXISTS tailor_id UUID;

-- 4. Add completed_fields column (if not exists)
ALTER TABLE public.clients
  ADD COLUMN IF NOT EXISTS completed_fields JSONB DEFAULT '{}'::jsonb;

-- 5. Add style_preferences column (if not exists)
ALTER TABLE public.clients
  ADD COLUMN IF NOT EXISTS style_preferences JSONB DEFAULT '{}'::jsonb;

-- 6. Add invite_token column (if not exists)
ALTER TABLE public.clients
  ADD COLUMN IF NOT EXISTS invite_token TEXT;

-- 7. Add invite_status column (if not exists)
ALTER TABLE public.clients
  ADD COLUMN IF NOT EXISTS invite_status TEXT DEFAULT 'pending';

-- 8. Add updated_at column (if not exists)
ALTER TABLE public.clients
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- 9. Create indexes
CREATE INDEX IF NOT EXISTS idx_clients_invite_token ON public.clients(invite_token);
CREATE INDEX IF NOT EXISTS idx_clients_tailor_id ON public.clients(tailor_id);

-- 10. Updated_at trigger
CREATE OR REPLACE FUNCTION update_clients_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_clients_updated_at ON public.clients;
CREATE TRIGGER set_clients_updated_at
  BEFORE UPDATE ON public.clients
  FOR EACH ROW
  EXECUTE FUNCTION update_clients_updated_at();

-- 11. RLS policies for invite system
DROP POLICY IF EXISTS "Allow invite token read" ON public.clients;
CREATE POLICY "Allow invite token read" ON public.clients
  FOR SELECT
  USING (invite_token IS NOT NULL AND invite_status = 'pending');

DROP POLICY IF EXISTS "Allow invite token update" ON public.clients;
CREATE POLICY "Allow invite token update" ON public.clients
  FOR UPDATE
  USING (invite_token IS NOT NULL AND invite_status = 'pending')
  WITH CHECK (invite_token IS NOT NULL);
