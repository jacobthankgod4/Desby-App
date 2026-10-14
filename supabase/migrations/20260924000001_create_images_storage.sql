insert into storage.buckets (id, name, public)
values ('images', 'images', true)
on conflict (id) do nothing;

drop policy if exists "Public read images" on storage.objects;
create policy "Public read images" on storage.objects
  for select
  using (bucket_id = 'images');

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
        'garments'
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
