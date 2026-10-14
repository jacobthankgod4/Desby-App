-- Extends storage access for the folders/buckets the app uploads to.
-- Verified against the client code:
--   images/products/...        -> add_product_page
--   images/lessons/...         -> lesson_create_page
--   images/material_photos/... -> reserved client material uploads
--   avatars/, profiles/, scan_photos/ buckets -> profile photos,
--   storefront logos/banners and body-scan photos (pre-existing buckets
--   that had no policies in this repo).

-- 1) images bucket: widen the authenticated upload folder allow-list.
drop policy if exists "Authenticated users upload images" on storage.objects;
create policy "Authenticated users upload images" on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'images'
    and (
      coalesce((storage.foldername(name))[1], '') in (
        'chats',
        'designs',
        'fabrics',
        'orders',
        'measurements',
        'avatars',
        'tryon_photos',
        'profiles',
        'tasks',
        'models',
        'garments',
        'products',
        'lessons',
        'material_photos'
      )
      or (
        coalesce((storage.foldername(name))[1], '') = 'tryon'
        and (
          (storage.foldername(name))[2] is null
          or coalesce((storage.foldername(name))[2], '') in ('models', 'garments')
        )
      )
    )
  );

-- 2) Ensure the supporting public buckets exist (no-op if already there).
insert into storage.buckets (id, name, public)
values
  ('avatars', 'avatars', true),
  ('profiles', 'profiles', true),
  ('scan_photos', 'scan_photos', true)
on conflict (id) do nothing;

-- 3) Public read access for those buckets.
drop policy if exists "Public read profile media" on storage.objects;
create policy "Public read profile media" on storage.objects
  for select
  using (bucket_id in ('avatars', 'profiles', 'scan_photos'));

-- 4) Authenticated uploads for those buckets.
drop policy if exists "Authenticated users upload profile media" on storage.objects;
create policy "Authenticated users upload profile media" on storage.objects
  for insert
  to authenticated
  with check (bucket_id in ('avatars', 'profiles', 'scan_photos'));
