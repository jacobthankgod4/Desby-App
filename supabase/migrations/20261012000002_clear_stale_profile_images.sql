-- Clear stale profile images that 400 with NoSuchKey (Desby console E2, 2026-10-09).
--
-- Both objects no longer exist in the `images` bucket, so every avatar render
-- logged: AppNetworkImage failed to load … 400 (Bad Request).
-- Nulling profile_image makes the app fall back to its default avatar.
--
-- Previous values (dead URLs, kept for provenance):
--   33d4f859-5367-417f-a371-e080fd8d9980 (Jacob money):
--     https://sakmdeacligraqayfxyb.supabase.co/storage/v1/object/public/images/profiles/33d4f859-5367-417f-a371-e080fd8d9980/33d4f859-5367-417f-a371-e080fd8d9980_1786468885937.jpg
--   de22b802-4e72-4ac3-a9cd-c4c4a8b0fdb4 (Jacob Chibueze):
--     https://sakmdeacligraqayfxyb.supabase.co/storage/v1/object/public/images/profiles/de22b802-4e72-4ac3-a9cd-c4c4a8b0fdb4/de22b802-4e72-4ac3-a9cd-c4c4a8b0fdb4_1787664353472.jpg

UPDATE users
SET profile_image = NULL
WHERE (id, profile_image) IN (
  (
    '33d4f859-5367-417f-a371-e080fd8d9980',
    'https://sakmdeacligraqayfxyb.supabase.co/storage/v1/object/public/images/profiles/33d4f859-5367-417f-a371-e080fd8d9980/33d4f859-5367-417f-a371-e080fd8d9980_1786468885937.jpg'
  ),
  (
    'de22b802-4e72-4ac3-a9cd-c4c4a8b0fdb4',
    'https://sakmdeacligraqayfxyb.supabase.co/storage/v1/object/public/images/profiles/de22b802-4e72-4ac3-a9cd-c4c4a8b0fdb4/de22b802-4e72-4ac3-a9cd-c4c4a8b0fdb4_1787664353472.jpg'
  )
);
