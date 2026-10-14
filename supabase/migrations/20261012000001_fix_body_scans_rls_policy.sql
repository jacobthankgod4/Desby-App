-- Fix body_scans RLS policy: tailors_manage_own_scans
--
-- The old policy qualified on (current_setting('app.current_merchant_id'))::uuid.
-- That GUC is never set by PostgREST, so every anon/authenticated query against
-- body_scans raised SQLSTATE 42704 "unrecognized configuration parameter" and
-- the API returned HTTP 400 (Desby console E6, 2026-10-09, line 3793).
--
-- Scope rows to the signed-in owner instead, matching the convention already
-- used by virtual_tryons / users (auth.uid() checks, public role).
-- Service role bypasses RLS and keeps full access.

DROP POLICY IF EXISTS "tailors_manage_own_scans" ON public.body_scans;

CREATE POLICY "tailors_manage_own_scans" ON public.body_scans
  FOR ALL
  TO public
  USING (tailor_id = (auth.uid())::uuid)
  WITH CHECK (tailor_id = (auth.uid())::uuid);
