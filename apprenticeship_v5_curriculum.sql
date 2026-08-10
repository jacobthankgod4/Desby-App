-- DESBY OS: APPRENTICESHIP CURRICULUM SCHEMA (v5)

-- 1. CURRICULUM MODULES
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

-- 2. CURRICULUM LESSONS
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

-- 3. SEED INITIAL DATA (replacing hardcoded values)
INSERT INTO public.curriculum_modules (id, title, description, order_index) VALUES
('module_1', 'The Professional Designer Dossier', 'Professional ethics, client consultation, and the psychology of bespoke service.', 0),
('module_2', 'Advanced Measurement Science', 'Landmark identification, 3D postural analysis, and ergonomic fit theory.', 1),
('module_7', 'Luxury Finishing & Milanese Detail', 'The Milanese buttonhole, pick stitching, and invisible functional details.', 6)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.curriculum_lessons (id, module_id, title, content, order_index) VALUES
('l1', 'module_1', 'The Anatomy of Consultation', 'Learning how to guide a client through fabric selection without overwhelming their design intent.', 0),
('l2', 'module_1', 'Ethics of the Craft', 'Confidentiality of measurements and the integrity of premium material sourcing.', 1),
('l3', 'module_2', 'Postural Landmark IDs', 'Identifying the 12 key skeletal points for a perfect zero-gravity fit.', 0),
('l4', 'module_2', 'The Physics of Slope', 'Compensating for low shoulders and forward neck posture in pattern drafting.', 1)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.curriculum_lessons (id, module_id, title, content, order_index, video_url) VALUES
('l13', 'module_7', 'The Milanese Buttonhole', 'Step-by-step guide to the world most difficult hand-stitched buttonhole using silk gimp.', 0, 'https://desby-os.storage/masterclasses/milanese_buttonhole.mp4')
ON CONFLICT (id) DO NOTHING;
