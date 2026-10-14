-- Add invite columns to clients table
ALTER TABLE public.clients 
  ADD COLUMN IF NOT EXISTS invite_token TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS invite_status TEXT DEFAULT 'pending' CHECK (invite_status IN ('pending', 'accepted', 'expired')),
  ADD COLUMN IF NOT EXISTS completed_fields JSONB DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS style_preferences JSONB DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS tailor_id UUID,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Index for fast invite token lookups
CREATE INDEX IF NOT EXISTS idx_clients_invite_token ON public.clients(invite_token);
CREATE INDEX IF NOT EXISTS idx_clients_tailor_id ON public.clients(tailor_id);

-- Updated_at trigger
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

-- RLS policies for invite system
-- Allow anonymous users to read a client by invite token (for the invite landing page)
DROP POLICY IF EXISTS "Allow invite token read" ON public.clients;
CREATE POLICY "Allow invite token read" ON public.clients
  FOR SELECT
  USING (invite_token IS NOT NULL AND invite_status = 'pending');

-- Allow anonymous users to update a client via invite token (limited to invite-related fields)
DROP POLICY IF EXISTS "Allow invite token update" ON public.clients;
CREATE POLICY "Allow invite token update" ON public.clients
  FOR UPDATE
  USING (invite_token IS NOT NULL AND invite_status = 'pending')
  WITH CHECK (invite_token IS NOT NULL);
