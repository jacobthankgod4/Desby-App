-- AI Body Scan: `measurements` table for the KORRA measurement backend.
--
-- The backend (ai-body-scan-saas / api/services/database_service.py) inserts
-- into public.measurements with service_role. The table did not exist in this
-- project, so every scan completed extraction and then failed at persistence
-- with "Database save failed".
--
-- Columns are derived from the exact insert payload in save_measurement():
--   user_id, client_name, height, gender, biometrics, landmarks_3d, mesh_url,
--   mesh_storage_url, photo_front_url, photo_side_url, body_shape,
--   size_recommendation, clinical_realism_index, tpose_mesh_url, smpl_params,
--   joints_3d, source_of_truth, created_at
--
-- Idempotent — safe to re-run.

create table if not exists public.measurements (
  id                        uuid primary key default gen_random_uuid(),
  user_id                   uuid not null,
  client_name               text,
  height                    double precision,
  gender                    text,
  biometrics                jsonb default '{}'::jsonb,
  landmarks_3d              jsonb default '{}'::jsonb,
  mesh_url                  text,
  mesh_storage_url          text,
  photo_front_url           text,
  photo_side_url            text,
  body_shape                text,
  size_recommendation       text,
  clinical_realism_index    double precision,
  tpose_mesh_url            text,
  smpl_params               jsonb,
  joints_3d                 jsonb,
  source_of_truth           boolean default true,
  created_at                timestamptz default now()
);

-- Dual-account writes use the same client row for both merchant and client,
-- so (user_id, created_at) is the natural lookup order.
create index if not exists idx_measurements_user_created
  on public.measurements (user_id, created_at desc);

-- The Flutter app lists scans per user, newest first.
create index if not exists idx_measurements_user_id
  on public.measurements (user_id);

alter table public.measurements enable row level security;

-- Users read their own scans.
drop policy if exists "Users read own measurements" on public.measurements;
create policy "Users read own measurements"
  on public.measurements
  for select
  using (auth.uid() = user_id);

-- Users may delete their own scans (drives the delete endpoint in the app).
drop policy if exists "Users delete own measurements" on public.measurements;
create policy "Users delete own measurements"
  on public.measurements
  for delete
  using (auth.uid() = user_id);

-- Writes come only from the backend using service_role, which bypasses RLS.
-- Deliberately no INSERT/UPDATE policy for authenticated users: measurement
-- data must not be client-writable.

-- Verify -------------------------------------------------------------------
select column_name, data_type
from information_schema.columns
where table_schema = 'public'
  and table_name = 'measurements'
order by ordinal_position;