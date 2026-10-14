-- Add missing columns to users table
-- These columns are referenced in code but were never applied
-- because the original CREATE TABLE IF NOT EXISTS didn't add new columns

ALTER TABLE public.users ADD COLUMN IF NOT EXISTS preferred_finder_style TEXT DEFAULT 'uber';
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS distance_minutes INTEGER;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS working_hours_by_day JSONB DEFAULT '{}'::jsonb;
