-- FIX: Curriculum RLS policies for lessons and modules
-- Run this in Supabase SQL Editor

-- 1. Fix curriculum_modules — allow all authenticated users to manage
DROP POLICY IF EXISTS "Public curriculum viewable by everyone" ON public.curriculum_modules;
CREATE POLICY "Public curriculum viewable by everyone" ON public.curriculum_modules
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can manage curriculum modules" ON public.curriculum_modules;
DROP POLICY IF EXISTS "Tailors can manage own curriculum modules" ON public.curriculum_modules;
CREATE POLICY "Authenticated users can manage curriculum modules" ON public.curriculum_modules
    FOR ALL USING (auth.uid() IS NOT NULL);

-- 2. Fix curriculum_lessons — allow all authenticated users to manage
DROP POLICY IF EXISTS "Public lessons viewable by everyone" ON public.curriculum_lessons;
CREATE POLICY "Public lessons viewable by everyone" ON public.curriculum_lessons
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can manage curriculum lessons" ON public.curriculum_lessons;
DROP POLICY IF EXISTS "Tailors can manage own curriculum lessons" ON public.curriculum_lessons;
CREATE POLICY "Authenticated users can manage curriculum lessons" ON public.curriculum_lessons
    FOR ALL USING (auth.uid() IS NOT NULL);

-- 3. Ensure tailor_id column exists on curriculum_modules
ALTER TABLE public.curriculum_modules ADD COLUMN IF NOT EXISTS tailor_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
