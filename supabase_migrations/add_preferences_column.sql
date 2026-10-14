-- Add preferences JSONB column to users table for storing theme and style preferences
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS preferences JSONB DEFAULT '{}'::jsonb;
