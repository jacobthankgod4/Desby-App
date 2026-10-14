-- Add invite system columns to apprenticeships table
-- Mirrors the client invite system for apprentice enrollment

ALTER TABLE public.apprenticeships
ADD COLUMN IF NOT EXISTS invite_token TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS invite_status TEXT DEFAULT 'pending' CHECK (invite_status IN ('pending', 'accepted', 'expired')),
ADD COLUMN IF NOT EXISTS apprentice_name TEXT,
ADD COLUMN IF NOT EXISTS apprentice_phone TEXT,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- RLS: Allow anonymous token-based reads for invite acceptance
DROP POLICY IF EXISTS "Anonymous can read apprenticeship by invite token" ON public.apprenticeships;
CREATE POLICY "Anonymous can read apprenticeship by invite token" ON public.apprenticeships
    FOR SELECT USING (invite_token IS NOT NULL);

-- RLS: Allow anonymous to update apprenticeship by invite token (for acceptance)
DROP POLICY IF EXISTS "Anonymous can update apprenticeship by invite token" ON public.apprenticeships;
CREATE POLICY "Anonymous can update apprenticeship by invite token" ON public.apprenticeships
    FOR UPDATE USING (invite_token IS NOT NULL);

-- Trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION update_apprenticeships_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_apprenticeships_updated_at ON public.apprenticeships;
CREATE TRIGGER set_apprenticeships_updated_at
    BEFORE UPDATE ON public.apprenticeships
    FOR EACH ROW EXECUTE FUNCTION update_apprenticeships_updated_at();
