-- See users without subscription
SELECT id, email, name, user_type, subscription_plan_id, subscription_expiry
FROM users 
WHERE subscription_plan_id IS NULL 
   OR subscription_expiry IS NULL
   OR subscription_expiry < NOW();

-- Activate ALL users with no plan
UPDATE users 
SET subscription_plan_id = 'client_pro', 
    subscription_expiry = NOW() + INTERVAL '30 days'
WHERE subscription_plan_id IS NULL;

-- Verify
SELECT id, email, name, subscription_plan_id, subscription_expiry
FROM users 
WHERE subscription_plan_id IS NOT NULL;