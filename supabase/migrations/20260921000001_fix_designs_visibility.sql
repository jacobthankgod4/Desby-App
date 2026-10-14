-- Ensure designs table has is_visible column with proper default
ALTER TABLE designs ADD COLUMN IF NOT EXISTS is_visible BOOLEAN DEFAULT true;

-- Set all existing designs to visible (they were uploaded without explicit visibility)
UPDATE designs SET is_visible = true WHERE is_visible IS NULL;

-- Ensure RLS allows public read of visible designs
ALTER TABLE designs ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read visible designs
DROP POLICY IF EXISTS "Public read visible designs" ON designs;
CREATE POLICY "Public read visible designs" ON designs
  FOR SELECT USING (is_visible = true);

-- Allow authenticated users to manage their own designs
DROP POLICY IF EXISTS "Tailors manage own designs" ON designs;
CREATE POLICY "Tailors manage own designs" ON designs
  FOR ALL USING (auth.uid() = tailor_id);
