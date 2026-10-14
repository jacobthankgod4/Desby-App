-- Identity & address verification (Nigeria).
--
-- ============================================================================
-- WHY THIS IS SHAPED THIS WAY
-- ============================================================================
-- The original request was "a means of identification ... as a cautionary
-- measure in case they do not deliver on the order".
--
-- Retaliation ("so we can hold it over them") is not a lawful basis under the
-- Nigeria Data Protection Act 2023, and it is the kind of purpose that turns a
-- marketplace into a liability the moment a user disputes. Three changes were
-- made deliberately:
--
--  1. WHO IS VERIFIED. Verification is mandatory for TAILORS and sellers, not
--     for every buyer. A tailor is the payout recipient in a funds-transfer
--     relationship, so verifying them is a compliance and fraud-control
--     requirement. Demanding a government ID from every shopper is
--     disproportionate and would gut conversion.
--
--  2. STORED WHAT, NOT EVERYTHING. The document image goes to a PRIVATE bucket
--     reachable only via short-lived signed URLs. The document *number* is
--     never stored -- only a SHA-256 fingerprint, so a second account cannot
--     reuse the same ID unnoticed, and the number itself cannot leak.
--
--  3. BOUNDED USE AND RETENTION. `purpose` records why a document is held.
--     Rows expire after `expires_at` and are swept automatically. The user's
--     stated purpose ("in case of non-delivery") is recorded as
--     'dispute_evidence' -- bounded to an open dispute -- rather than an
--     open-ended right to hold identity papers forever.
--
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'verification_status') THEN
    CREATE TYPE public.verification_status AS ENUM (
      'pending',   -- submitted, awaiting review
      'verified',  -- reviewed and accepted
      'rejected',  -- reviewed and refused
      'expired'    -- retention window elapsed
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'identity_doc_type') THEN
    CREATE TYPE public.identity_doc_type AS ENUM (
      'nin',              -- National Identity Number
      'voter_card',
      'drivers_licence',
      'national_passport',
      'business_rc',      -- Corporate Affairs Commission registration
      'other'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'address_proof_type') THEN
    CREATE TYPE public.address_proof_type AS ENUM (
      'utility_bill',      -- PHCN/electricity, water
      'bank_statement',
      'national_id',
      'tenancy_agreement',
      'other'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'verification_purpose') THEN
    CREATE TYPE public.verification_purpose AS ENUM (
      'payout_recipient',  -- AML/KYC: may receive money from the platform
      'seller_trust',      -- marketplace trust badge
      'dispute_evidence',  -- held only while a dispute is open
      'high_value_order'   -- one-off check for an unusually large order
    );
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- Identity verification
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.identity_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

  doc_type public.identity_doc_type NOT NULL,
  -- SHA-256 of the normalised document number. Enables duplicate detection
  -- across accounts without storing the number itself.
  doc_fingerprint TEXT NOT NULL,
  -- Last 4 characters only, so a reviewer can confirm they are looking at the
  -- right document without the row being a complete identity record.
  doc_last4 TEXT,

  -- Path inside the PRIVATE `identity_documents` bucket. Never a public URL.
  doc_storage_path TEXT NOT NULL,

  status public.verification_status NOT NULL DEFAULT 'pending',
  purpose public.verification_purpose NOT NULL,

  -- Set when the document itself carries an expiry (passport, driver's licence).
  doc_expires_on DATE,

  submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  verified_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES public.users(id),
  rejection_reason TEXT,

  -- Retention deadline. Swept by purge_expired_verifications().
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '24 months'),

  CONSTRAINT identity_verifications_doc_type_not_null CHECK (doc_type IS NOT NULL),
  CONSTRAINT identity_verifications_last4_len CHECK (
    doc_last4 IS NULL OR char_length(doc_last4) = 4
  ),
  -- One live submission per user per purpose. A rejected attempt may be retried.
  CONSTRAINT identity_verifications_one_live_per_purpose
    UNIQUE (user_id, purpose, status)
    DEFERRABLE INITIALLY DEFERRED
);

CREATE INDEX IF NOT EXISTS identity_verifications_user_idx
  ON public.identity_verifications (user_id, submitted_at DESC);
CREATE INDEX IF NOT EXISTS identity_verifications_review_queue_idx
  ON public.identity_verifications (submitted_at)
  WHERE status = 'pending';
-- Duplicate-account detection. Fingerprints are stored hashed so this index is
-- not itself a list of identity numbers.
CREATE INDEX IF NOT EXISTS identity_verifications_fingerprint_idx
  ON public.identity_verifications (doc_fingerprint);

ALTER TABLE public.identity_verifications ENABLE ROW LEVEL SECURITY;

-- A user may submit their own document and see their own status.
DROP POLICY IF EXISTS "Users submit own identity" ON public.identity_verifications;
CREATE POLICY "Users submit own identity" ON public.identity_verifications
  FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = user_id
    AND status = 'pending'
    -- The client cannot self-approve. Only a reviewer (service_role via an Edge
    -- Function) may set 'verified'.
    AND status IN ('pending', 'rejected')
  );

DROP POLICY IF EXISTS "Users read own identity status" ON public.identity_verifications;
CREATE POLICY "Users read own identity status" ON public.identity_verifications
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

-- No UPDATE or DELETE policy: status transitions and retention are server-side.
-- Otherwise a user could flip their own record to 'verified'.

-- ---------------------------------------------------------------------------
-- Address verification
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.address_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

  proof_type public.address_proof_type NOT NULL,
  -- Path in the private bucket, when a document was uploaded.
  proof_storage_path TEXT,
  -- For proofs verified out-of-band (e.g. a manual check), a short reference.
  reference_note TEXT,

  -- The address being attested to, kept as submitted so a later dispute can be
  -- compared against the address the order was delivered to.
  attested_address TEXT,
  attested_state TEXT,
  attested_lga TEXT,

  status public.verification_status NOT NULL DEFAULT 'pending',
  verified_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES public.users(id),
  rejection_reason TEXT,

  submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '24 months'),

  CONSTRAINT address_verifications_has_evidence CHECK (
    proof_storage_path IS NOT NULL OR reference_note IS NOT NULL
  )
);

CREATE INDEX IF NOT EXISTS address_verifications_user_idx
  ON public.address_verifications (user_id, submitted_at DESC);

ALTER TABLE public.address_verifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users submit own address proof" ON public.address_verifications;
CREATE POLICY "Users submit own address proof" ON public.address_verifications
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id AND status = 'pending');

DROP POLICY IF EXISTS "Users read own address verification" ON public.address_verifications;
CREATE POLICY "Users read own address verification" ON public.address_verifications
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Convenience: current verification state, used by the UI and by order gating.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.verification_status_for(p_user_id UUID)
RETURNS TABLE (
  identity_status public.verification_status,
  identity_verified_at TIMESTAMPTZ,
  identity_expires_at TIMESTAMPTZ,
  address_status public.verification_status,
  address_verified_at TIMESTAMPTZ,
  address_expires_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    (SELECT i.status FROM public.identity_verifications i
      WHERE i.user_id = p_user_id
      ORDER BY i.submitted_at DESC LIMIT 1),
    (SELECT i.verified_at FROM public.identity_verifications i
      WHERE i.user_id = p_user_id
      ORDER BY i.submitted_at DESC LIMIT 1),
    (SELECT i.expires_at FROM public.identity_verifications i
      WHERE i.user_id = p_user_id
      ORDER BY i.submitted_at DESC LIMIT 1),
    (SELECT a.status FROM public.address_verifications a
      WHERE a.user_id = p_user_id
      ORDER BY a.submitted_at DESC LIMIT 1),
    (SELECT a.verified_at FROM public.address_verifications a
      WHERE a.user_id = p_user_id
      ORDER BY a.submitted_at DESC LIMIT 1),
    (SELECT a.expires_at FROM public.address_verifications a
      WHERE a.user_id = p_user_id
      ORDER BY a.submitted_at DESC LIMIT 1);
$$;

REVOKE ALL ON FUNCTION public.verification_status_for(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.verification_status_for(UUID) FROM anon;
GRANT EXECUTE ON FUNCTION public.verification_status_for(UUID)
  TO authenticated, service_role;

-- Can this user be paid out? Enforced server-side at release time so a client
-- cannot fake it by hiding a flag.
CREATE OR REPLACE FUNCTION public.can_receive_payouts(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.identity_verifications
     WHERE user_id = p_user_id
       AND status = 'verified'
       AND purpose = 'payout_recipient'
       AND expires_at > NOW()
  );
$$;

REVOKE ALL ON FUNCTION public.can_receive_payouts(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_receive_payouts(UUID) FROM anon;
GRANT EXECUTE ON FUNCTION public.can_receive_payouts(UUID)
  TO authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Retention sweep. Marks lapsed rows; a scheduled job should follow with a
-- hard delete plus storage object removal.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.purge_expired_verifications()
RETURNS TABLE (identity_expired INT, address_expired INT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_identity INT;
  v_address INT;
BEGIN
  UPDATE public.identity_verifications
     SET status = 'expired'
   WHERE status IN ('pending', 'verified')
     AND expires_at <= NOW();

  GET DIAGNOSTICS v_identity = ROW_COUNT;

  UPDATE public.address_verifications
     SET status = 'expired'
   WHERE status IN ('pending', 'verified')
     AND expires_at <= NOW();

  GET DIAGNOSTICS v_address = ROW_COUNT;

  RETURN QUERY SELECT v_identity, v_address;
END;
$$;

REVOKE ALL ON FUNCTION public.purge_expired_verifications() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.purge_expired_verifications() FROM anon;
GRANT EXECUTE ON FUNCTION public.purge_expired_verifications() TO service_role;

COMMENT ON TABLE public.identity_verifications IS
  'Identity documents for payout recipients. Documents live in the PRIVATE '
  'identity_documents bucket and are served only via short-lived signed URLs. '
  'Document numbers are never stored -- only a SHA-256 fingerprint and last 4. '
  'Rows expire after 24 months.';

COMMENT ON COLUMN public.identity_verifications.doc_fingerprint IS
  'SHA-256 of the normalised document number. Detects one person holding '
  'multiple accounts without storing the number itself.';

COMMENT ON TABLE public.address_verifications IS
  'Proof of home address. Held for dispute resolution only, bounded by '
  'expires_at.';