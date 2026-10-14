-- ===========================================================================
-- Make tailor KYC mandatory at the database layer
-- ===========================================================================
-- The onboarding UI already refuses to finish unless an identity document AND
-- a proof of address are both on file. That gate is client-side only: the
-- "onboarded" flag was written to local storage and `public.users` carried no
-- completion marker at all, so the requirement was bypassable by anyone who
-- edited local storage or called the profile update directly.
--
-- This adds a real completion marker and refuses to set it without both
-- documents. It does NOT touch `can_receive_payouts()`, which still requires
-- *approval* rather than submission — onboarding completion and receiving money
-- are deliberately different gates.
--
-- Grandfathering: `onboarding_completed_at` is left NULL for everyone who
-- already onboarded, and the trigger only fires on the NULL -> NOT NULL
-- transition. Existing tailors are therefore unaffected and are never locked
-- out of the app by a rule that postdates them.
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- 1. Completion marker
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_schema = 'public'
       AND table_name   = 'users'
       AND column_name  = 'onboarding_completed_at'
  ) THEN
    ALTER TABLE public.users
      ADD COLUMN onboarding_completed_at TIMESTAMPTZ;
  END IF;
END $$;

COMMENT ON COLUMN public.users.onboarding_completed_at IS
  'When the tailor finished onboarding. NULL means either not finished or '
  'finished before this requirement existed (grandfathered).';

CREATE INDEX IF NOT EXISTS users_onboarding_completed_at_idx
  ON public.users (onboarding_completed_at)
  WHERE onboarding_completed_at IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 2. Enforce the requirement
-- ---------------------------------------------------------------------------
-- SECURITY DEFINER so the check reads the verification tables directly. Under
-- the invoker's rights the tailor's own RLS policies would decide what the
-- check can see, which is not something a compliance control should depend on.
CREATE OR REPLACE FUNCTION public.enforce_tailor_onboarding_kyc()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_identity_ok BOOLEAN;
  v_address_ok  BOOLEAN;
BEGIN
  -- Only the act of completing onboarding is gated. Later profile edits, and
  -- every row that was already complete, pass straight through.
  IF NEW.onboarding_completed_at IS NULL THEN
    RETURN NEW;
  END IF;
  IF TG_OP = 'UPDATE' AND OLD.onboarding_completed_at IS NOT NULL THEN
    RETURN NEW;
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.identity_verifications
     WHERE user_id = NEW.id
       AND status IN ('pending', 'verified')
       AND (expires_at IS NULL OR expires_at > NOW())
  ) INTO v_identity_ok;

  SELECT EXISTS (
    SELECT 1 FROM public.address_verifications
     WHERE user_id = NEW.id
       AND status IN ('pending', 'verified')
  ) INTO v_address_ok;

  IF NOT (v_identity_ok AND v_address_ok) THEN
    RAISE EXCEPTION
      'Tailor onboarding requires an identity document and a proof of address. Missing: %',
      CASE
        WHEN NOT v_identity_ok AND NOT v_address_ok
          THEN 'identity document and proof of address'
        WHEN NOT v_identity_ok THEN 'identity document'
        ELSE 'proof of address'
      END
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS enforce_tailor_onboarding_kyc ON public.users;
CREATE TRIGGER enforce_tailor_onboarding_kyc
  BEFORE INSERT OR UPDATE OF onboarding_completed_at ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_tailor_onboarding_kyc();

-- ---------------------------------------------------------------------------
-- 3. Client-callable helpers
-- ---------------------------------------------------------------------------

-- What is still missing, so the app can prompt precisely instead of failing
-- the write and showing a raw Postgres error.
CREATE OR REPLACE FUNCTION public.tailor_onboarding_requirements(
  p_user_id UUID
)
RETURNS TABLE (
  identity_on_file BOOLEAN,
  address_on_file  BOOLEAN,
  can_complete     BOOLEAN,
  missing          TEXT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH i AS (
    SELECT EXISTS (
      SELECT 1 FROM public.identity_verifications
       WHERE user_id = p_user_id
         AND status IN ('pending', 'verified')
         AND (expires_at IS NULL OR expires_at > NOW())
    ) AS ok
  ),
  a AS (
    SELECT EXISTS (
      SELECT 1 FROM public.address_verifications
       WHERE user_id = p_user_id
         AND status IN ('pending', 'verified')
    ) AS ok
  )
  SELECT i.ok,
         a.ok,
         (i.ok AND a.ok),
         CASE
           WHEN NOT i.ok AND NOT a.ok THEN 'identity document and proof of address'
           WHEN NOT i.ok               THEN 'identity document'
           WHEN NOT a.ok               THEN 'proof of address'
           ELSE NULL
         END
    FROM i, a;
$$;

REVOKE ALL ON FUNCTION public.tailor_onboarding_requirements(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.tailor_onboarding_requirements(UUID) FROM anon;
GRANT EXECUTE ON FUNCTION public.tailor_onboarding_requirements(UUID)
  TO authenticated, service_role;

-- The supported way to finish onboarding. Lets the trigger above validate,
-- so the rule lives in one place instead of being restated in Dart.
CREATE OR REPLACE FUNCTION public.complete_tailor_onboarding()
RETURNS TIMESTAMPTZ
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_done    TIMESTAMPTZ;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not signed in' USING ERRCODE = 'insufficient_privilege';
  END IF;

  UPDATE public.users
     SET onboarding_completed_at = NOW()
   WHERE id = v_user_id
  RETURNING onboarding_completed_at INTO v_done;

  IF v_done IS NULL THEN
    RAISE EXCEPTION 'Profile not found' USING ERRCODE = 'no_data_found';
  END IF;

  RETURN v_done;
END;
$$;

REVOKE ALL ON FUNCTION public.complete_tailor_onboarding() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.complete_tailor_onboarding() FROM anon;
GRANT EXECUTE ON FUNCTION public.complete_tailor_onboarding()
  TO authenticated;
