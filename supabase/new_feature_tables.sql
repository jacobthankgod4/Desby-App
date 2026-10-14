-- ============================================================
-- NEW TABLES NEEDED FOR NEW FEATURES
-- Run these in Supabase SQL Editor
-- ============================================================

-- 1. REFERRALS TABLE (for referral rewards)
CREATE TABLE IF NOT EXISTS referrals (
  id TEXT PRIMARY KEY,
  referrer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  referee_id UUID REFERENCES users(id) ON DELETE SET NULL,
  code TEXT NOT NULL UNIQUE,
  is_used BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  used_at TIMESTAMPTZ
);

-- Index for fast code lookup
CREATE INDEX IF NOT EXISTS idx_referrals_code ON referrals(code);
CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON referrals(referrer_id);

-- RLS policies
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own referrals"
  ON referrals FOR SELECT
  USING (auth.uid() = referrer_id);

CREATE POLICY "System can insert referrals"
  ON referrals FOR INSERT
  WITH CHECK (true);

CREATE POLICY "System can update referrals"
  ON referrals FOR UPDATE
  USING (true);


-- 2. CERTIFICATES TABLE (for apprentice certificates)
CREATE TABLE IF NOT EXISTS certificates (
  id TEXT PRIMARY KEY,
  apprentice_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  level TEXT NOT NULL,
  tailor_name TEXT NOT NULL,
  apprentice_name TEXT NOT NULL,
  completed_at TIMESTAMPTZ DEFAULT NOW(),
  certificate_number TEXT NOT NULL UNIQUE
);

-- Index for fast lookup
CREATE INDEX IF NOT EXISTS idx_certificates_apprentice ON certificates(apprentice_id);

-- RLS policies
ALTER TABLE certificates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Apprentices can read own certificates"
  ON certificates FOR SELECT
  USING (auth.uid() = apprentice_id);

CREATE POLICY "System can insert certificates"
  ON certificates FOR INSERT
  WITH CHECK (true);


-- 3. ADD METADATA COLUMN TO ORDERS (for priority booking)
-- Run only if the column doesn't exist yet
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'orders' AND column_name = 'metadata'
  ) THEN
    ALTER TABLE orders ADD COLUMN metadata JSONB;
  END IF;
END $$;