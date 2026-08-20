-- ============================================================================
-- Desby OS — body_scans table migration + korra_api_key column
-- Run this in Supabase SQL Editor to enable scan result persistence.
-- ============================================================================

-- 0. Add korra_api_key column to users table (for API key auto-provisioning)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'users'
      AND column_name = 'korra_api_key'
  ) THEN
    ALTER TABLE public.users ADD COLUMN korra_api_key TEXT;
  END IF;
END $$;

-- 1. Create the body_scans table
CREATE TABLE IF NOT EXISTS public.body_scans (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  measurements  JSONB NOT NULL DEFAULT '{}'::jsonb,
  gender        TEXT NOT NULL CHECK (gender IN ('male', 'female')),
  height_cm     NUMERIC(5,1) NOT NULL CHECK (height_cm > 0 AND height_cm < 300),
  accuracy_mode TEXT NOT NULL DEFAULT 'dual_photo',
  accuracy      TEXT,
  measurement_count INTEGER NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Indexes for fast queries
CREATE INDEX IF NOT EXISTS idx_body_scans_user_id
  ON public.body_scans(user_id);

CREATE INDEX IF NOT EXISTS idx_body_scans_user_created
  ON public.body_scans(user_id, created_at DESC);

-- 3. Row-level security — users can only read/write their own scans
ALTER TABLE public.body_scans ENABLE ROW LEVEL SECURITY;

-- Allow users to read their own scans
DROP POLICY IF EXISTS "Users read own body_scans" ON public.body_scans;
CREATE POLICY "Users read own body_scans"
  ON public.body_scans
  FOR SELECT
  USING (auth.uid() = user_id);

-- Allow users to insert their own scans
DROP POLICY IF EXISTS "Users insert own body_scans" ON public.body_scans;
CREATE POLICY "Users insert own body_scans"
  ON public.body_scans
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own scans
DROP POLICY IF EXISTS "Users update own body_scans" ON public.body_scans;
CREATE POLICY "Users update own body_scans"
  ON public.body_scans
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Allow users to delete their own scans
DROP POLICY IF EXISTS "Users delete own body_scans" ON public.body_scans;
CREATE POLICY "Users delete own body_scans"
  ON public.body_scans
  FOR DELETE
  USING (auth.uid() = user_id);

-- 4. Auto-update updated_at trigger
CREATE OR REPLACE FUNCTION public.handle_body_scan_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS body_scans_updated_at ON public.body_scans;
CREATE TRIGGER body_scans_updated_at
  BEFORE UPDATE ON public.body_scans
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_body_scan_updated_at();

-- 5. Grant service_role full access (for admin/API operations)
GRANT ALL ON public.body_scans TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.body_scans TO authenticated;
