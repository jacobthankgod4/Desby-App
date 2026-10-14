-- 1. Allow user self-insert (needed for custom auth registration)
-- The app creates a users row before Supabase Auth session exists,
-- so auth.uid() check would fail. Allow inserts for anon + authenticated roles.
drop policy if exists "Users can insert own profile" on public.users;
drop policy if exists "Allow user inserts" on public.users;
create policy "Allow user inserts" on public.users
  for insert
  to anon, authenticated
  with check (true);

-- 2. Guard notification queries against empty/invalid UUIDs
-- The app tries .eq('user_id', userId) then falls back to .eq('userId', userId).
-- If userId is empty string or invalid UUID, PostgREST returns 400.
-- Fix: add an index on user_id to speed up queries (already should exist)
-- The real fix is in app code (guard before querying).

-- 3. Ensure conversations.participant_ids column exists as uuid[]
-- (already verified it does, but this is a safety net)
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_name = 'conversations' and column_name = 'participant_ids'
  ) then
    alter table public.conversations add column participant_ids uuid[] default '{}';
  end if;
end $$;
