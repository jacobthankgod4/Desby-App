-- DESBY OS: APPRENTICESHIP CURRICULUM SCHEMA (v5)
-- Sets up the Academy curriculum tables for tailors and apprentices

-- 1. CURRICULUM MODULES
CREATE TABLE IF NOT EXISTS public.curriculum_modules (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    order_index INTEGER NOT NULL,
    masterclass_thumbnail TEXT,
    tailor_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.curriculum_modules ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public curriculum viewable by everyone" ON public.curriculum_modules;
CREATE POLICY "Public curriculum viewable by everyone" ON public.curriculum_modules FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can manage curriculum modules" ON public.curriculum_modules;
CREATE POLICY "Authenticated users can manage curriculum modules" ON public.curriculum_modules
    FOR ALL USING (auth.role() = 'authenticated');

-- 2. CURRICULUM LESSONS
CREATE TABLE IF NOT EXISTS public.curriculum_lessons (
    id TEXT PRIMARY KEY,
    module_id TEXT REFERENCES public.curriculum_modules(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT,
    short_description TEXT,
    video_url TEXT,
    thumbnail_url TEXT,
    duration_minutes INTEGER,
    lesson_type TEXT DEFAULT 'video',
    is_published BOOLEAN DEFAULT true,
    is_free_preview BOOLEAN DEFAULT false,
    attachments TEXT[] DEFAULT '{}',
    order_index INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.curriculum_lessons ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public lessons viewable by everyone" ON public.curriculum_lessons;
CREATE POLICY "Public lessons viewable by everyone" ON public.curriculum_lessons FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can manage curriculum lessons" ON public.curriculum_lessons;
CREATE POLICY "Authenticated users can manage curriculum lessons" ON public.curriculum_lessons
    FOR ALL USING (auth.role() = 'authenticated');

-- 3. SEED STARTER MODULES
INSERT INTO public.curriculum_modules (id, title, description, order_index) VALUES
('module_1', 'Working With Clients', 'How to consult with clients, understand their style, and deliver a great experience every time.', 0),
('module_2', 'Taking Perfect Measurements', 'How to take accurate body measurements, spot posture differences, and get a flawless fit.', 1),
('module_7', 'Professional Finishing Touches', 'Hand-stitched buttonholes, neat top-stitching, and the small details that make your work stand out.', 6)
ON CONFLICT (id) DO NOTHING;

-- 4. SEED STARTER LESSONS
INSERT INTO public.curriculum_lessons (id, module_id, title, content, order_index) VALUES
('l1', 'module_1', 'Your First Client Consultation', 'How to guide a client through fabric and style choices without overwhelming them.', 0),
('l2', 'module_1', 'Keeping Measurements Private', 'Why client measurements must stay confidential and how to source materials ethically.', 1),
('l3', 'module_2', 'Finding the Right Body Points', 'The 12 key body points to measure for a comfortable, well-fitting garment every time.', 0),
('l4', 'module_2', 'Adjusting for Posture', 'How to make pattern adjustments when a client stands or sits differently than expected.', 1)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.curriculum_lessons (id, module_id, title, content, order_index, video_url) VALUES
('l13', 'module_7', 'The Milanese Buttonhole', 'A step-by-step guide to sewing the cleanest hand-stitched buttonhole using silk thread.', 0, 'https://desby-os.storage/masterclasses/milanese_buttonhole.mp4')
ON CONFLICT (id) DO NOTHING;
