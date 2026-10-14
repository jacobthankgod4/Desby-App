-- Add new columns to curriculum_lessons for enhanced lesson features
-- Run this in Supabase SQL Editor

ALTER TABLE public.curriculum_lessons ADD COLUMN IF NOT EXISTS short_description TEXT;
ALTER TABLE public.curriculum_lessons ADD COLUMN IF NOT EXISTS thumbnail_url TEXT;
ALTER TABLE public.curriculum_lessons ADD COLUMN IF NOT EXISTS duration_minutes INTEGER;
ALTER TABLE public.curriculum_lessons ADD COLUMN IF NOT EXISTS lesson_type TEXT DEFAULT 'video';
ALTER TABLE public.curriculum_lessons ADD COLUMN IF NOT EXISTS is_published BOOLEAN DEFAULT true;
ALTER TABLE public.curriculum_lessons ADD COLUMN IF NOT EXISTS is_free_preview BOOLEAN DEFAULT false;
ALTER TABLE public.curriculum_lessons ADD COLUMN IF NOT EXISTS attachments JSONB DEFAULT '[]'::jsonb;
