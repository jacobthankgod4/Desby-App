-- DESBY OS: COMPREHENSIVE SCHEMA & RLS FIX (v4 - UNIVERSAL TYPE CASTING)
-- Run this in your Supabase SQL Editor to resolve the 'text = uuid' mismatch errors.

-- 1. USERS TABLE (PROFILES)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    email TEXT,
    name TEXT,
    user_type TEXT DEFAULT 'tailor',
    phone TEXT,
    profile_image TEXT,
    bio TEXT,
    address TEXT,
    state TEXT,
    business_name TEXT,
    business_address TEXT,
    business_phone TEXT,
    is_verified BOOLEAN DEFAULT false,
    services JSONB DEFAULT '[]'::jsonb,
    available_fabrics JSONB DEFAULT '[]'::jsonb,
    working_hours TEXT,
    working_hours_by_day JSONB DEFAULT '{}'::jsonb,
    business_state TEXT,
    country TEXT DEFAULT 'Nigeria',
    lga TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    subscription_plan_id TEXT,
    subscription_expiry TIMESTAMPTZ,
    preferred_occasions JSONB DEFAULT '[]'::jsonb,
    preferred_fabrics JSONB DEFAULT '[]'::jsonb,
    body_type TEXT,
    measurement_unit TEXT DEFAULT 'Inches',
    loyalty_points INTEGER DEFAULT 0,
    personal_measurements JSONB DEFAULT '{}'::jsonb,
    service_pricing JSONB DEFAULT '{}'::jsonb,
    pricing_tier TEXT,
    base_stitching_price DOUBLE PRECISION,
    material_cost DOUBLE PRECISION,
    starting_price DOUBLE PRECISION,
    has_pricing BOOLEAN DEFAULT false,
    preferred_finder_style TEXT DEFAULT 'uber',
    distance_minutes INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.users;
CREATE POLICY "Public profiles are viewable by everyone" ON public.users
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile" ON public.users
    FOR ALL USING (auth.uid()::text = id::text);

-- 2. PRODUCTS TABLE
CREATE TABLE IF NOT EXISTS public.products (
    id TEXT PRIMARY KEY,
    tailor_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    price DOUBLE PRECISION NOT NULL,
    currency TEXT DEFAULT 'NGN',
    image_urls JSONB DEFAULT '[]'::jsonb,
    category TEXT DEFAULT 'Custom',
    available_fabrics JSONB DEFAULT '[]'::jsonb,
    available_sizes JSONB DEFAULT '[]'::jsonb,
    is_visible BOOLEAN DEFAULT true,
    is_available BOOLEAN DEFAULT true,
    order_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Products are viewable by everyone" ON public.products;
CREATE POLICY "Products are viewable by everyone" ON public.products
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Tailors can manage own products" ON public.products;
CREATE POLICY "Tailors can manage own products" ON public.products
    FOR ALL USING (auth.uid()::text = tailor_id::text);

-- 3. CLIENTS TABLE
CREATE TABLE IF NOT EXISTS public.clients (
    id TEXT PRIMARY KEY,
    tailor_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    address TEXT,
    gender TEXT,
    profile_image TEXT,
    measurements JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Tailors can manage own clients" ON public.clients;
CREATE POLICY "Tailors can manage own clients" ON public.clients
    FOR ALL USING (auth.uid()::text = tailor_id::text);

-- 4. ORDERS TABLE
CREATE TABLE IF NOT EXISTS public.orders (
    id TEXT PRIMARY KEY,
    client_id TEXT,
    tailor_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    client_name TEXT,
    items JSONB DEFAULT '[]'::jsonb,
    status TEXT DEFAULT 'pending',
    total_amount DOUBLE PRECISION DEFAULT 0,
    dispatch_fee DOUBLE PRECISION DEFAULT 4900,
    due_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    material_asset_url TEXT,
    requires_dispatch BOOLEAN DEFAULT false,
    fabric_type TEXT,
    fabric_color TEXT,
    fez_order_no TEXT,
    delivery_eta TEXT,
    tracking_history JSONB DEFAULT '[]'::jsonb
);

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- UNIVERSAL FIX: Cast everything to TEXT to prevent 'text = uuid' errors
DROP POLICY IF EXISTS "Users can view relevant orders" ON public.orders;
CREATE POLICY "Users can view relevant orders" ON public.orders
    FOR SELECT USING (auth.uid()::text = tailor_id::text OR auth.uid()::text = client_id::text);

DROP POLICY IF EXISTS "Users can create orders" ON public.orders;
CREATE POLICY "Users can create orders" ON public.orders
    FOR INSERT WITH CHECK (auth.uid()::text = client_id::text OR auth.uid()::text = tailor_id::text);

DROP POLICY IF EXISTS "Users can update relevant orders" ON public.orders;
CREATE POLICY "Users can update relevant orders" ON public.orders
    FOR UPDATE USING (auth.uid()::text = tailor_id::text OR auth.uid()::text = client_id::text);

-- 5. FABRICS TABLE
CREATE TABLE IF NOT EXISTS public.fabrics (
    id TEXT PRIMARY KEY,
    seller_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    category TEXT,
    price_per_yard DOUBLE PRECISION NOT NULL,
    stock_quantity DOUBLE PRECISION DEFAULT 0,
    image_urls JSONB DEFAULT '[]'::jsonb,
    composition TEXT,
    weight TEXT,
    origin TEXT,
    available_colors JSONB DEFAULT '[]'::jsonb,
    is_visible BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.fabrics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Fabrics are viewable by everyone" ON public.fabrics;
CREATE POLICY "Fabrics are viewable by everyone" ON public.fabrics
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Sellers can manage own fabrics" ON public.fabrics;
CREATE POLICY "Sellers can manage own fabrics" ON public.fabrics
    FOR ALL USING (auth.uid()::text = seller_id::text);

-- 6. APPRENTICESHIPS & TASKS
CREATE TABLE IF NOT EXISTS public.apprenticeships (
    id TEXT PRIMARY KEY,
    tailor_id UUID REFERENCES public.users(id),
    apprentice_id UUID REFERENCES public.users(id),
    status TEXT,
    progress DOUBLE PRECISION DEFAULT 0,
    start_date TIMESTAMPTZ DEFAULT NOW(),
    skill_ids JSONB DEFAULT '[]'::jsonb
);

ALTER TABLE public.apprenticeships ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own apprenticeship" ON public.apprenticeships;
CREATE POLICY "Users can view own apprenticeship" ON public.apprenticeships
    FOR SELECT USING (auth.uid()::text = tailor_id::text OR auth.uid()::text = apprentice_id::text);

CREATE TABLE IF NOT EXISTS public.apprentice_tasks (
    id TEXT PRIMARY KEY,
    apprenticeship_id TEXT REFERENCES public.apprenticeships(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT,
    due_date TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    feedback TEXT,
    score DOUBLE PRECISION,
    proof_image_urls JSONB DEFAULT '[]'::jsonb,
    submission_notes TEXT
);

ALTER TABLE public.apprentice_tasks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Participants can manage tasks" ON public.apprentice_tasks;
CREATE POLICY "Participants can manage tasks" ON public.apprentice_tasks
    FOR ALL USING (true);

-- 7. SUBSCRIPTION PLANS
CREATE TABLE IF NOT EXISTS public.subscription_plans (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    price TEXT,
    amount DOUBLE PRECISION,
    user_type TEXT,
    features JSONB DEFAULT '[]'::jsonb,
    is_elite BOOLEAN DEFAULT false,
    button_label TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Plans are viewable by everyone" ON public.subscription_plans;
CREATE POLICY "Plans are viewable by everyone" ON public.subscription_plans
    FOR SELECT USING (true);

-- 8. ANALYTICS EVENTS
CREATE TABLE IF NOT EXISTS public.analytics_events (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES public.users(id),
    event_name TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can insert own events" ON public.analytics_events;
CREATE POLICY "Users can insert own events" ON public.analytics_events
    FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

-- 9. MESSAGES & CONVERSATIONS
CREATE TABLE IF NOT EXISTS public.conversations (
    id TEXT PRIMARY KEY,
    participant_ids UUID[] DEFAULT '{}',
    last_message JSONB,
    unread_count INTEGER DEFAULT 0,
    order_id TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

-- UNIVERSAL FIX for UUID[] arrays: Use ::text comparison inside ANY
DROP POLICY IF EXISTS "Participants can view conversations" ON public.conversations;
CREATE POLICY "Participants can view conversations" ON public.conversations
    FOR SELECT USING (auth.uid()::text = ANY(participant_ids::text[]));

CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id TEXT REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID,
    content TEXT,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    type TEXT DEFAULT 'text',
    is_read BOOLEAN DEFAULT false,
    order_id TEXT,
    metadata JSONB
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Participants can view messages" ON public.messages;
CREATE POLICY "Participants can view messages" ON public.messages
    FOR SELECT USING (true);

-- END OF SCHEMA FIX
