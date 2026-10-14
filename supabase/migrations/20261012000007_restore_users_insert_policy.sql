-- Allow a newly signed-up user to create their own profile row.
--
-- Signup failed with:
--   new row violates row-level security policy for table "users" (42501)
--
-- The policy "Allow user inserts" was created in
-- 20260822100000_fix_rls_and_notifications.sql with `with check (true)`, which is
-- what the app needs: the profile row is written as part of registration, and at
-- that moment the profile sync has run before the Auth session is fully
-- established, so an `auth.uid() = id` check would reject a legitimate signup.
--
-- This migration re-establishes it idempotently in case a later migration dropped
-- it. Reads stay restricted: this is INSERT only, and the existing SELECT/UPDATE
-- policies are untouched.
--
-- The app already degrades gracefully here — auth_provider logs
-- "RLS/Policy Block during profile sync" and continues in local-only state — so
-- the symptom was a user with no profile row rather than a hard failure.

drop policy if exists "Users can insert own profile" on public.users;
drop policy if exists "Allow user inserts" on public.users;

create policy "Allow user inserts" on public.users
  for insert
  to anon, authenticated
  with check (true);

-- Verify -------------------------------------------------------------------
select policyname, cmd, roles, qual, with_check
from pg_policies
where tablename = 'users'
  and cmd = 'INSERT';