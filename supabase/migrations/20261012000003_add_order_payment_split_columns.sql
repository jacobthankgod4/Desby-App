-- Payment split columns. `CheckoutPage._markOrdersPaid` writes
-- platform_fee / tailor_payout once Flutterwave confirms the transaction
-- (PlatformMoneyConfig.splitGross, 1.5% commission). The columns existed on
-- the live database but had no migration in this repo — an empty database
-- would reject the split write. Idempotent: safe on live.
alter table public.orders
  add column if not exists platform_fee numeric default 0,
  add column if not exists tailor_payout numeric default 0;
