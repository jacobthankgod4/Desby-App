-- DESBY OS: FABRIC MERCHANT COMPREHENSIVE FIX (v6 - CORRECTED)

-- 1. ADD VARIANTS TABLE
-- Fixed: Changed reference from products(id) to fabrics(id) and ensured TEXT type for FAB_... IDs
CREATE TABLE IF NOT EXISTS public.fabric_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fabric_id TEXT REFERENCES public.fabrics(id) ON DELETE CASCADE,
    color_name TEXT NOT NULL,
    color_code TEXT, -- Hex code
    stock_quantity DOUBLE PRECISION DEFAULT 0,
    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.fabric_variants ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public variants viewable" ON public.fabric_variants;
CREATE POLICY "Public variants viewable" ON public.fabric_variants FOR SELECT USING (true);
DROP POLICY IF EXISTS "Sellers manage own variants" ON public.fabric_variants;
CREATE POLICY "Sellers manage own variants" ON public.fabric_variants FOR ALL USING (
    EXISTS (SELECT 1 FROM public.fabrics f WHERE f.id = fabric_id AND f.seller_id::text = auth.uid()::text)
);

-- 2. ADD WHOLESALE PRICING TABLE
CREATE TABLE IF NOT EXISTS public.fabric_wholesale_tiers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fabric_id TEXT REFERENCES public.fabrics(id) ON DELETE CASCADE,
    min_quantity DOUBLE PRECISION NOT NULL,
    unit_price DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.fabric_wholesale_tiers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public tiers viewable" ON public.fabric_wholesale_tiers;
CREATE POLICY "Public tiers viewable" ON public.fabric_wholesale_tiers FOR SELECT USING (true);

-- 3. MERCHANT SETTLEMENTS (Wallet)
CREATE TABLE IF NOT EXISTS public.merchant_wallets (
    user_id UUID REFERENCES public.users(id) PRIMARY KEY,
    balance DOUBLE PRECISION DEFAULT 0,
    pending_payout DOUBLE PRECISION DEFAULT 0,
    currency TEXT DEFAULT 'NGN',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.merchant_wallets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own wallet" ON public.merchant_wallets;
CREATE POLICY "Users can view own wallet" ON public.merchant_wallets FOR SELECT USING (auth.uid() = user_id);

-- 4. MERCHANT PAYOUT REQUESTS
CREATE TABLE IF NOT EXISTS public.payout_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id UUID REFERENCES public.users(id),
    amount DOUBLE PRECISION NOT NULL,
    status TEXT DEFAULT 'pending', -- pending, processed, failed
    bank_details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.payout_requests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Sellers view own payouts" ON public.payout_requests;
CREATE POLICY "Sellers view own payouts" ON public.payout_requests FOR SELECT USING (auth.uid() = seller_id);

-- 5. RPC FOR MERCHANT DASHBOARD ANALYTICS
CREATE OR REPLACE FUNCTION get_merchant_stats(merchant_id UUID)
RETURNS JSON AS $$
DECLARE
    total_gmv DOUBLE PRECISION;
    order_count INT;
    sku_count INT;
BEGIN
    -- Fix: Ensure we filter by tailor_id (which acts as merchant_id in orders)
    SELECT COALESCE(SUM(total_amount), 0) INTO total_gmv FROM public.orders WHERE tailor_id = merchant_id AND status = 'completed';
    SELECT COUNT(*) INTO order_count FROM public.orders WHERE tailor_id = merchant_id;
    -- Fix: fabrics use seller_id
    SELECT COUNT(*) INTO sku_count FROM public.fabrics WHERE seller_id = merchant_id;

    RETURN json_build_object(
        'total_gmv', total_gmv,
        'order_count', order_count,
        'sku_count', sku_count
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
