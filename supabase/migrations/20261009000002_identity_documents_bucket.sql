-- Private bucket for identity documents.
--
-- `public = false` is the load-bearing part. A public bucket would put a
-- permanent, guessable URL for every user's government ID on the open
-- internet. Nothing in the app should ever build such a URL.
--
-- Storage RLS is keyed on the first folder segment being the caller's uid, the
-- same pattern used for avatars: a user can only write inside their own folder.

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'identity_documents',
  'identity_documents',
  false,
  8388608, -- 8 MB: a photographed ID page, not a 40MP scan
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
)
ON CONFLICT (id) DO UPDATE
  SET public = false,
      file_size_limit = EXCLUDED.file_size_limit,
      allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Enforce the private flag even if someone edits the bucket later.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'identity_documents' AND public) THEN
    RAISE EXCEPTION 'identity_documents must never be public';
  END IF;
END $$;

-- A verified user may upload their own document and read back their own files
-- (for preview). Nothing here grants access to anyone else's documents.
DROP POLICY IF EXISTS "Users upload own identity documents" ON storage.objects;
CREATE POLICY "Users upload own identity documents" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'identity_documents'
    AND (auth.uid())::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS "Users read own identity documents" ON storage.objects;
CREATE POLICY "Users read own identity documents" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'identity_documents'
    AND (auth.uid())::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS "Users delete own identity documents" ON storage.objects;
CREATE POLICY "Users delete own identity documents" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'identity_documents'
    AND (auth.uid())::text = (storage.foldername(name))[1]
  );

-- No UPDATE policy: a document, once submitted for review, must not be swapped.
-- A resubmission creates a new object under a new path.