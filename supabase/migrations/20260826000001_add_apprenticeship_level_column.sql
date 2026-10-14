-- Migration: Add level column to apprenticeships table
-- This column stores the apprentice's skill level (Beginner/Intermediate/Advanced)

ALTER TABLE apprenticeships ADD COLUMN IF NOT EXISTS level TEXT;

-- Update existing apprenticeships with null level to 'Beginner'
UPDATE apprenticeships SET level = 'Beginner' WHERE level IS NULL;
