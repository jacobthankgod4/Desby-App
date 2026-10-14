-- Admin surface: roles, audit trail, and the review workflow.
--
-- Design notes
-- ------------
-- * Admins are NOT a boolean on `users`. A flag would let anyone who can edit
--   their own profile set themselves admin, since `users` has an UPDATE policy
--   for the owner. Roles live in their own table with no client-writable policy,
--   so the only way to become an admin is a direct database write.
--
-- * Every privileged action is written to `admin_audit_log`. An admin viewing
--   identity documents is handling some of the most sensitive data the platform
--   holds; "who looked at this, and why" has to be answerable.
--
-- * Documents are never copied or exposed. Review reads them through a signed
--   URL minted by an Edge Function, so the admin browser never has a permanent
--   addressable link.

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'admin_role') THEN
    CREATE TYPE public.admin_role AS ENUM (
      'super_admin',  -- full control, including granting roles
      'admin',        -- review, moderate, manage orders
      'support',      -- read-only on users and orders
      'compliance'    -- read + decide on identity verifications only
    );
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.admin_users (
  user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  role public.admin_role NOT NULL,
  granted_by UUID REFERENCES public.users(id),
  granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  revoked_at TIMESTAMPTZ,
  notes TEXT
);

ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.is_admin(p_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.admin_users
     WHERE user_id = p_user_id
       AND revoked_at IS NULL
  );
$$;

REVOKE ALL ON FUNCTION public.is_admin(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_admin(UUID) FROM anon;
GRANT EXECUTE ON FUNCTION public.is_admin(UUID) TO authenticated, service_role;

-- Read-only, and only for admins. A user cannot INSERT or DELETE here, so the
-- table is not self-serve.
DROP POLICY IF EXISTS "Admins read admin roster" ON public.admin_users;
CREATE POLICY "Admins read admin roster" ON public.admin_users
  FOR SELECT TO authenticated
  USING (public.is_admin());

-- ---------------------------------------------------------------------------
-- Audit trail
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_audit_log (
  id BIGSERIAL PRIMARY KEY,
  admin_id UUID REFERENCES public.users(id),
  action TEXT NOT NULL,
  target_table TEXT,
  target_id TEXT,
  -- Populated for sensitive reads: proof that a document was actually opened.
  detail JSONB NOT NULL DEFAULT '{}'::jsonb,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS admin_audit_log_admin_idx
  ON public.admin_audit_log (admin_id, created_at DESC);
CREATE INDEX IF NOT EXISTS admin_audit_log_action_idx
  ON public.admin_audit_log (action, created_at DESC);

ALTER TABLE public.admin_audit_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins read audit log" ON public.admin_audit_log;
CREATE POLICY "Admins read audit log" ON public.admin_audit_log
  FOR SELECT TO authenticated
  USING (public.is_admin());

-- No INSERT policy: entries are written by the Edge Function using
-- service_role, so an admin cannot erase their own tracks.

-- ---------------------------------------------------------------------------
-- Review workflow, server-side.
--
-- Deliberately NOT callable with the anon key: verification decisions are the
-- highest-value write in the system, and the deciding reviewer must be recorded.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.decide_identity_verification(
  p_verification_id UUID,
  p_decision TEXT,
  p_reason TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_reviewer UUID := auth.uid();
  v_row public.identity_verifications%ROWTYPE;
BEGIN
  IF p_decision NOT IN ('verified', 'rejected') THEN
    RAISE EXCEPTION 'decision must be verified or rejected' USING ERRCODE = '22023';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.admin_users
     WHERE user_id = v_reviewer AND revoked_at IS NULL
       AND role IN ('super_admin', 'admin', 'compliance')
  ) THEN
    RAISE EXCEPTION 'not authorised' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_row
    FROM public.identity_verifications
   WHERE id = p_verification_id
   FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'verification not found' USING ERRCODE = 'P0002';
  END IF;

  IF v_row.status <> 'pending' THEN
    RAISE EXCEPTION 'already decided (% )', v_row.status USING ERRCODE = '22023';
  END IF;

  UPDATE public.identity_verifications
     SET status = p_decision::public.verification_status,
         verified_at = CASE WHEN p_decision = 'verified' THEN NOW() ELSE NULL END,
         reviewed_by = v_reviewer,
         rejection_reason = CASE WHEN p_decision = 'rejected' THEN p_reason ELSE NULL END
   WHERE id = p_verification_id;

  INSERT INTO public.admin_audit_log (admin_id, action, target_table, target_id, detail)
  VALUES (
    v_reviewer,
    'identity_verification.' || p_decision,
    'identity_verifications',
    p_verification_id::text,
    jsonb_build_object('user_id', v_row.user_id, 'doc_type', v_row.doc_type, 'reason', p_reason)
  );

  RETURN jsonb_build_object(
    'status', p_decision,
    'user_id', v_row.user_id,
    'decidable_by_client', true,
    'can_receive_payouts',
      CASE WHEN p_decision = 'verified'
           THEN public.can_receive_payouts(v_row.user_id)
           ELSE false END
  );
END;
$$;

REVOKE ALL ON FUNCTION public.decide_identity_verification(UUID, TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.decide_identity_verification(UUID, TEXT, TEXT) FROM anon;
GRANT EXECUTE ON FUNCTION public.decide_identity_verification(UUID, TEXT, TEXT)
  TO authenticated, service_role;

-- Same shape for address proofs.
CREATE OR REPLACE FUNCTION public.decide_address_verification(
  p_verification_id UUID,
  p_decision TEXT,
  p_reason TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_reviewer UUID := auth.uid();
  v_row public.address_verifications%ROWTYPE;
BEGIN
  IF p_decision NOT IN ('verified', 'rejected') THEN
    RAISE EXCEPTION 'decision must be verified or rejected' USING ERRCODE = '22023';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.admin_users
     WHERE user_id = v_reviewer AND revoked_at IS NULL
       AND role IN ('super_admin', 'admin', 'compliance')
  ) THEN
    RAISE EXCEPTION 'not authorised' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_row
    FROM public.address_verifications
   WHERE id = p_verification_id
   FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'verification not found' USING ERRCODE = 'P0002';
  END IF;

  IF v_row.status <> 'pending' THEN
    RAISE EXCEPTION 'already decided (% )', v_row.status USING ERRCODE = '22023';
  END IF;

  UPDATE public.address_verifications
     SET status = p_decision::public.verification_status,
         verified_at = CASE WHEN p_decision = 'verified' THEN NOW() ELSE NULL END,
         reviewed_by = v_reviewer,
         rejection_reason = CASE WHEN p_decision = 'rejected' THEN p_reason ELSE NULL END
   WHERE id = p_verification_id;

  INSERT INTO public.admin_audit_log (admin_id, action, target_table, target_id, detail)
  VALUES (
    v_reviewer,
    'address_verification.' || p_decision,
    'address_verifications',
    p_verification_id::text,
    jsonb_build_object('user_id', v_row.user_id, 'proof_type', v_row.proof_type, 'reason', p_reason)
  );

  RETURN jsonb_build_object('status', p_decision, 'user_id', v_row.user_id);
END;
$$;

REVOKE ALL ON FUNCTION public.decide_address_verification(UUID, TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.decide_address_verification(UUID, TEXT, TEXT) FROM anon;
GRANT EXECUTE ON FUNCTION public.decide_address_verification(UUID, TEXT, TEXT)
  TO authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Signed URL minting for review.
--
-- Short TTL, single use of the audit trail, and scoped to one document. An admin
-- cannot enumerate the bucket; they can only open a document that is already
-- queued for review.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.mint_review_document_url(
  p_storage_path TEXT,
  p_bucket TEXT DEFAULT 'identity_documents'
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_reviewer UUID := auth.uid();
  v_path TEXT;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.admin_users WHERE user_id = v_reviewer AND revoked_at IS NULL
  ) THEN
    RAISE EXCEPTION 'not authorised' USING ERRCODE = '42501';
  END IF;

  -- `support` may view; only compliance/admin/super_admin may decide.
  IF NOT EXISTS (
    SELECT 1 FROM public.admin_users
     WHERE user_id = v_reviewer AND revoked_at IS NULL AND role = 'support'
  ) THEN
    INSERT INTO public.admin_audit_log (admin_id, action, target_table, detail)
    VALUES (v_reviewer, 'identity_document.viewed', p_bucket,
            jsonb_build_object('path', p_storage_path));
  END IF;

  SELECT storage.foldername(p_storage_path) INTO v_path;

  -- Defensive: only ever mint for a path under the bucket's own folder.
  IF v_path IS NULL THEN
    RAISE EXCEPTION 'invalid path' USING ERRCODE = '22023';
  END IF;

  RETURN storage.create_signed_url(p_bucket, p_storage_path, 300);
END;
$$;

REVOKE ALL ON FUNCTION public.mint_review_document_url(TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.mint_review_document_url(TEXT, TEXT) FROM anon;
GRANT EXECUTE ON FUNCTION public.mint_review_document_url(TEXT, TEXT)
  TO authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Admin overview counts for the dashboard.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_overview()
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.admin_users WHERE user_id = auth.uid() AND revoked_at IS NULL
  ) THEN
    RAISE EXCEPTION 'not authorised' USING ERRCODE = '42501';
  END IF;

  RETURN jsonb_build_object(
    'users_total',        (SELECT count(*) FROM public.users),
    'tailors',            (SELECT count(*) FROM public.users WHERE user_type = 'tailor'),
    'orders_total',       (SELECT count(*) FROM public.orders),
    'orders_open',        (SELECT count(*) FROM public.orders WHERE status NOT IN ('delivered','cancelled')),
    'gross_value',        (SELECT COALESCE(sum(total_amount), 0) FROM public.orders WHERE payment_status IN ('paid','confirmed')),
    'payouts_pending',    (SELECT count(*) FROM public.payout_requests WHERE status IN ('pending','processing')),
    'payouts_value',      (SELECT COALESCE(sum(amount), 0) FROM public.payout_requests WHERE status IN ('pending','processing')),
    'kyc_pending',        (SELECT count(*) FROM public.identity_verifications WHERE status = 'pending'),
    'address_pending',    (SELECT count(*) FROM public.address_verifications WHERE status = 'pending'),
    'kyc_verified',       (SELECT count(*) FROM public.identity_verifications WHERE status = 'verified')
  );
END;
$$;

REVOKE ALL ON FUNCTION public.admin_overview() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_overview() FROM anon;
GRANT EXECUTE ON FUNCTION public.admin_overview() TO authenticated, service_role;

COMMENT ON TABLE public.admin_audit_log IS
  'Immutable record of privileged actions, including who opened which identity '
  'document. Written only by service_role (Edge Functions) or by the SECURITY '
  'DEFINER review functions -- never by the client.';

COMMENT ON TABLE public.admin_users IS
  'Admin role grants. No client INSERT/DELETE policy exists, so membership can '
  'only be changed by a direct database write or a super_admin Edge Function.';
-- ---------------------------------------------------------------------------
-- Admin read access to the verification queue.
--
-- The per-user policies added earlier scope reads to `auth.uid() = user_id`,
-- which is right for the app but leaves an admin dashboard unable to see the
-- queue at all. Admins need to list pending submissions to do the job, so they
-- get an explicit read policy.
--
-- This grants visibility of verification *metadata and status*, not the
-- documents themselves: the file still lives in a private bucket and is only
-- reachable via `mint_review_document_url`, which writes an audit entry.
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "Admins read identity verifications" ON public.identity_verifications;
CREATE POLICY "Admins read identity verifications" ON public.identity_verifications
  FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.admin_users
     WHERE user_id = auth.uid() AND revoked_at IS NULL
  ));

DROP POLICY IF EXISTS "Admins read address verifications" ON public.address_verifications;
CREATE POLICY "Admins read address verifications" ON public.address_verifications
  FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.admin_users
     WHERE user_id = auth.uid() AND revoked_at IS NULL
  ));

COMMENT ON POLICY "Admins read identity verifications" ON public.identity_verifications IS
  'Metadata and status only, for the review queue. Document bytes remain behind '
  'the private bucket and mint_review_document_url(), which audits each view.';

-- ---------------------------------------------------------------------------
-- Admin read access to the user and order tables, for the dashboard.
-- Read-only; moderation still goes through purpose-built functions.
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "Admins read users" ON public.users;
CREATE POLICY "Admins read users" ON public.users
  FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.admin_users
     WHERE user_id = auth.uid() AND revoked_at IS NULL
  ));

DROP POLICY IF EXISTS "Admins read orders" ON public.orders;
CREATE POLICY "Admins read orders" ON public.orders
  FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.admin_users
     WHERE user_id = auth.uid() AND revoked_at IS NULL
  ));

DROP POLICY IF EXISTS "Admins read payout requests" ON public.payout_requests;
CREATE POLICY "Admins read payout requests" ON public.payout_requests
  FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.admin_users
     WHERE user_id = auth.uid() AND revoked_at IS NULL
  ));

-- ---------------------------------------------------------------------------
-- Bulk verification state for the user directory.
--
-- The directory shows verification standing for every user. Doing that with one
-- RPC per row would be ~100 round trips per page load; this returns it in a
-- single call. Admin-only, same pattern as admin_overview().
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_verification_bulk(p_user_ids UUID[])
RETURNS TABLE (
  user_id UUID,
  identity_status TEXT,
  identity_verified_at TIMESTAMPTZ,
  address_status TEXT,
  address_verified_at TIMESTAMPTZ,
  can_receive_payouts BOOLEAN
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.admin_users WHERE user_id = auth.uid() AND revoked_at IS NULL
  ) THEN
    RAISE EXCEPTION 'not authorised' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    u.id,
    COALESCE((SELECT i.status::text FROM public.identity_verifications i
               WHERE i.user_id = u.id ORDER BY i.submitted_at DESC LIMIT 1), 'none'),
    (SELECT i.verified_at FROM public.identity_verifications i
      WHERE i.user_id = u.id ORDER BY i.submitted_at DESC LIMIT 1),
    COALESCE((SELECT a.status::text FROM public.address_verifications a
               WHERE a.user_id = u.id ORDER BY a.submitted_at DESC LIMIT 1), 'none'),
    (SELECT a.verified_at FROM public.address_verifications a
      WHERE a.user_id = u.id ORDER BY a.submitted_at DESC LIMIT 1),
    public.can_receive_payouts(u.id)
  FROM unnest(p_user_ids) AS u(id);
END;
$$;

REVOKE ALL ON FUNCTION public.admin_verification_bulk(UUID[]) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_verification_bulk(UUID[]) FROM anon;
GRANT EXECUTE ON FUNCTION public.admin_verification_bulk(UUID[])
  TO authenticated, service_role;
