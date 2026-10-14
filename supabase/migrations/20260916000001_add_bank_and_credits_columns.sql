-- Add bank details and AI credits columns to users table
-- These columns are referenced in code but were never applied

ALTER TABLE public.users ADD COLUMN IF NOT EXISTS ai_credits INTEGER DEFAULT 5;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS bank_account_number TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS bank_code TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS bank_name TEXT;
