-- Delete all stale subscription plans and let the app reseed with correct data
-- Run this in Supabase Dashboard > SQL Editor

DELETE FROM public.subscription_plans;

-- The app will automatically reseed the correct plans on next load
-- Plan IDs: tailor_starter, tailor_pro, tailor_premium,
--           client_starter, client_pro, client_premium,
--           apprentice_starter, apprentice_pro, apprentice_premium,
--           seller_starter, seller_pro, seller_premium
