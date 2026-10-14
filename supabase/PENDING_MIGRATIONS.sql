-- =============================================
-- DESBY OS: ALL PENDING MIGRATIONS (COMBINED)
-- Run this entire script in Supabase SQL Editor
-- =============================================

-- 1. Add all missing columns to clients table
ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS invite_sent_at TIMESTAMPTZ;
ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS order_details JSONB DEFAULT '{}'::jsonb;
ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS tailor_id UUID;
ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS completed_fields JSONB DEFAULT '{}'::jsonb;
ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS style_preferences JSONB DEFAULT '{}'::jsonb;
ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS invite_token TEXT;
ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS invite_status TEXT DEFAULT 'pending';
ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

CREATE INDEX IF NOT EXISTS idx_clients_invite_token ON public.clients(invite_token);
CREATE INDEX IF NOT EXISTS idx_clients_tailor_id ON public.clients(tailor_id);

CREATE OR REPLACE FUNCTION update_clients_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_clients_updated_at ON public.clients;
CREATE TRIGGER set_clients_updated_at
  BEFORE UPDATE ON public.clients
  FOR EACH ROW
  EXECUTE FUNCTION update_clients_updated_at();

DROP POLICY IF EXISTS "Allow invite token read" ON public.clients;
CREATE POLICY "Allow invite token read" ON public.clients
  FOR SELECT
  USING (invite_token IS NOT NULL AND invite_status = 'pending');

DROP POLICY IF EXISTS "Allow invite token update" ON public.clients;
CREATE POLICY "Allow invite token update" ON public.clients
  FOR UPDATE
  USING (invite_token IS NOT NULL AND invite_status = 'pending')
  WITH CHECK (invite_token IS NOT NULL);

-- 2. Add missing columns to orders table
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_address TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS tracking_url TEXT;

-- 3. Add apprentice invite system columns
ALTER TABLE public.apprenticeships ADD COLUMN IF NOT EXISTS invite_token TEXT UNIQUE;
ALTER TABLE public.apprenticeships ADD COLUMN IF NOT EXISTS invite_status TEXT DEFAULT 'pending' CHECK (invite_status IN ('pending', 'accepted', 'expired'));
ALTER TABLE public.apprenticeships ADD COLUMN IF NOT EXISTS apprentice_name TEXT;
ALTER TABLE public.apprenticeships ADD COLUMN IF NOT EXISTS apprentice_phone TEXT;
ALTER TABLE public.apprenticeships ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

DROP POLICY IF EXISTS "Anonymous can read apprenticeship by invite token" ON public.apprenticeships;
CREATE POLICY "Anonymous can read apprenticeship by invite token" ON public.apprenticeships
    FOR SELECT USING (invite_token IS NOT NULL);

DROP POLICY IF EXISTS "Anonymous can update apprenticeship by invite token" ON public.apprenticeships;
CREATE POLICY "Anonymous can update apprenticeship by invite token" ON public.apprenticeships
    FOR UPDATE USING (invite_token IS NOT NULL);

CREATE OR REPLACE FUNCTION update_apprenticeships_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_apprenticeships_updated_at ON public.apprenticeships;
CREATE TRIGGER set_apprenticeships_updated_at
    BEFORE UPDATE ON public.apprenticeships
    FOR EACH ROW EXECUTE FUNCTION update_apprenticeships_updated_at();

-- 4. Add level column to apprenticeships
ALTER TABLE apprenticeships ADD COLUMN IF NOT EXISTS level TEXT;
UPDATE apprenticeships SET level = 'Beginner' WHERE level IS NULL;

-- 4b. Add skill_ids column to apprenticeships
ALTER TABLE apprenticeships ADD COLUMN IF NOT EXISTS skill_ids JSONB DEFAULT '[]'::jsonb;

-- 4c. Fix RLS on apprenticeships — add policies for authenticated users
DROP POLICY IF EXISTS "Authenticated users can insert apprenticeship" ON public.apprenticeships;
CREATE POLICY "Authenticated users can insert apprenticeship" ON public.apprenticeships
    FOR INSERT WITH CHECK (auth.uid() = apprentice_id);

DROP POLICY IF EXISTS "Authenticated users can view own apprenticeship" ON public.apprenticeships;
CREATE POLICY "Authenticated users can view own apprenticeship" ON public.apprenticeships
    FOR SELECT USING (auth.uid() = apprentice_id OR auth.uid() = tailor_id);

DROP POLICY IF EXISTS "Authenticated users can update own apprenticeship" ON public.apprenticeships;
CREATE POLICY "Authenticated users can update own apprenticeship" ON public.apprenticeships
    FOR UPDATE USING (auth.uid() = apprentice_id OR auth.uid() = tailor_id);

DROP POLICY IF EXISTS "Authenticated users can delete own apprenticeship" ON public.apprenticeships;
CREATE POLICY "Authenticated users can delete own apprenticeship" ON public.apprenticeships
    FOR DELETE USING (auth.uid() = apprentice_id OR auth.uid() = tailor_id);

-- 5. Lesson progress tracking table
CREATE TABLE IF NOT EXISTS public.lesson_progress (
    id TEXT PRIMARY KEY,
    apprenticeship_id UUID NOT NULL REFERENCES public.apprenticeships(id) ON DELETE CASCADE,
    lesson_id TEXT NOT NULL REFERENCES public.curriculum_lessons(id) ON DELETE CASCADE,
    completed_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(apprenticeship_id, lesson_id)
);

ALTER TABLE public.lesson_progress ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can manage own lesson_progress" ON public.lesson_progress;
CREATE POLICY "Authenticated users can manage own lesson_progress" ON public.lesson_progress
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.apprenticeships
            WHERE id = lesson_progress.apprenticeship_id
            AND (apprentice_id::text = auth.uid()::text OR tailor_id::text = auth.uid()::text)
        )
    );

-- 5b. Add tailor_id to curriculum_modules for per-tailor scoping
ALTER TABLE public.curriculum_modules ADD COLUMN IF NOT EXISTS tailor_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- 5c. Fix curriculum RLS — restrict writes to owner tailor
DROP POLICY IF EXISTS "Public curriculum viewable by everyone" ON public.curriculum_modules;
CREATE POLICY "Public curriculum viewable by everyone" ON public.curriculum_modules FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can manage curriculum modules" ON public.curriculum_modules;
CREATE POLICY "Tailors can manage own curriculum modules" ON public.curriculum_modules
    FOR ALL USING (auth.uid() = tailor_id);

DROP POLICY IF EXISTS "Public lessons viewable by everyone" ON public.curriculum_lessons;
CREATE POLICY "Public lessons viewable by everyone" ON public.curriculum_lessons FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can manage curriculum lessons" ON public.curriculum_lessons;
CREATE POLICY "Tailors can manage own curriculum lessons" ON public.curriculum_lessons
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.curriculum_modules
            WHERE id = curriculum_lessons.module_id
            AND tailor_id = auth.uid()
        )
    );

-- 6. Shopping cart table
CREATE TABLE IF NOT EXISTS carts (
  user_id TEXT PRIMARY KEY,
  items JSONB DEFAULT '[]'::jsonb,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE carts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "carts_select" ON carts;
CREATE POLICY "carts_select" ON carts FOR SELECT USING (auth.uid()::text = user_id);
DROP POLICY IF EXISTS "carts_insert" ON carts;
CREATE POLICY "carts_insert" ON carts FOR INSERT WITH CHECK (auth.uid()::text = user_id);
DROP POLICY IF EXISTS "carts_update" ON carts;
CREATE POLICY "carts_update" ON carts FOR UPDATE USING (auth.uid()::text = user_id);

-- 6. Add fabric_seller_id to orders
ALTER TABLE orders ADD COLUMN IF NOT EXISTS fabric_seller_id UUID REFERENCES users(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_orders_fabric_seller ON orders(fabric_seller_id);

-- 7. Curriculum tables
CREATE TABLE IF NOT EXISTS public.curriculum_modules (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    order_index INTEGER NOT NULL,
    masterclass_thumbnail TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.curriculum_modules ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public curriculum viewable by everyone" ON public.curriculum_modules;
CREATE POLICY "Public curriculum viewable by everyone" ON public.curriculum_modules FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can manage curriculum modules" ON public.curriculum_modules;
CREATE POLICY "Authenticated users can manage curriculum modules" ON public.curriculum_modules
    FOR ALL USING (auth.role() = 'authenticated');

CREATE TABLE IF NOT EXISTS public.curriculum_lessons (
    id TEXT PRIMARY KEY,
    module_id TEXT REFERENCES public.curriculum_modules(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT,
    video_url TEXT,
    order_index INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.curriculum_lessons ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public lessons viewable by everyone" ON public.curriculum_lessons;
CREATE POLICY "Public lessons viewable by everyone" ON public.curriculum_lessons FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can manage curriculum lessons" ON public.curriculum_lessons;
CREATE POLICY "Authenticated users can manage curriculum lessons" ON public.curriculum_lessons
    FOR ALL USING (auth.role() = 'authenticated');

-- Seed starter modules
INSERT INTO public.curriculum_modules (id, title, description, order_index) VALUES
('module_1', 'Working With Clients', 'How to consult with clients, understand their style, and deliver a great experience every time.', 0),
('module_2', 'Taking Perfect Measurements', 'How to take accurate body measurements, spot posture differences, and get a flawless fit.', 1),
('module_7', 'Professional Finishing Touches', 'Hand-stitched buttonholes, neat top-stitching, and the small details that make your work stand out.', 6)
ON CONFLICT (id) DO NOTHING;

-- Seed starter lessons
INSERT INTO public.curriculum_lessons (id, module_id, title, content, order_index) VALUES
('l1', 'module_1', 'Your First Client Consultation', 'How to guide a client through fabric and style choices without overwhelming them.', 0),
('l2', 'module_1', 'Keeping Measurements Private', 'Why client measurements must stay confidential and how to source materials ethically.', 1),
('l3', 'module_2', 'Finding the Right Body Points', 'The 12 key body points to measure for a comfortable, well-fitting garment every time.', 0),
('l4', 'module_2', 'Adjusting for Posture', 'How to make pattern adjustments when a client stands or sits differently than expected.', 1)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.curriculum_lessons (id, module_id, title, content, order_index, video_url) VALUES
('l13', 'module_7', 'The Milanese Buttonhole', 'A step-by-step guide to sewing the cleanest hand-stitched buttonhole using silk thread.', 0, 'https://desby-os.storage/masterclasses/milanese_buttonhole.mp4')
ON CONFLICT (id) DO NOTHING;
