// flutterwave-verify — authoritative payment verification + order settlement.
//
// The Flutterwave inline JS SDK reports success in the BROWSER, so the browser
// can be made to claim any outcome. This function is the only thing allowed to
// mark an order paid:
//
//   1. Ask Flutterwave's REST API about tx_ref using the SECRET key.
//   2. Only if Flutterwave confirms, mark the orders paid with service_role.
//
// service_role is used deliberately and only after Flutterwave confirms, so a
// client can never write status='paid' itself. That also keeps the buyer RLS
// policy (with_check -> status='cancelled') intact; we do not loosen it.
//
// Request:  POST /functions/v1/flutterwave-verify?tx_ref=<ref>[&order_id=<id>]
// Response: { verified: boolean, status?: string, amount?: number, orders?: [...] }

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const FLUTTERWAVE_VERIFY_URL = (txRef: string) =>
  `https://api.flutterwave.com/v3/transactions/verify/${encodeURIComponent(txRef)}`;

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

/** Amounts are compared in kobo to avoid float drift. */
const toKobo = (value: unknown): number => Math.round(Number(value) * 100);

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });

  const secretKey = Deno.env.get('FLUTTERWAVE_SECRET_KEY');
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

  if (!secretKey || !supabaseUrl || !serviceRoleKey) {
    console.error('[flutterwave-verify] missing server configuration');
    return json({ verified: false, message: 'Server not configured' }, 500);
  }

  const url = new URL(req.url);
  const txRef = url.searchParams.get('tx_ref');
  if (!txRef) return json({ verified: false, message: 'tx_ref is required' }, 400);

  // ── 1. Ask Flutterwave, using the secret key, never the client ──────────────
  let fw: Record<string, unknown>;
  try {
    const res = await fetch(FLUTTERWAVE_VERIFY_URL(txRef), {
      headers: { Authorization: `Bearer ${secretKey}` },
    });
    if (!res.ok) {
      console.warn(`[flutterwave-verify] flutterwave responded ${res.status}`);
      return json({ verified: false, message: 'Transaction not found' }, 404);
    }
    fw = (await res.json()) as Record<string, unknown>;
  } catch (err) {
    console.error('[flutterwave-verify] flutterwave call failed', err);
    return json({ verified: false, message: 'Verification unavailable' }, 502);
  }

  const data = (fw.data ?? {}) as Record<string, unknown>;
  const status = String(data.status ?? '').toLowerCase();
  const verified = status === 'successful';

  if (!verified) {
    console.log(`[flutterwave-verify] ${txRef} not successful (status=${status})`);
    return json({ verified: false, status });
  }

  const paidAmount = Number(data.amount ?? 0);
  const currency = String(data.currency ?? 'NGN');
  const customerEmail = String(
    (data.customer as Record<string, unknown> | undefined)?.email ?? '',
  );

  // ── 2. Settle the orders (only now, after Flutterwave confirmed) ───────────
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // Resolve the orders this transaction belongs to. Prefer an explicit id from
  // the caller, otherwise fall back to the reference recorded at payment time.
  const explicitOrderId = url.searchParams.get('order_id');
  let orderIds: string[] = [];

  const { data: found, error: findError } = await admin
    .from('orders')
    .select('id,total_amount,payment_reference,payment_status,status')
    .or(
      explicitOrderId
        ? `id.eq.${explicitOrderId},payment_reference.eq.${txRef}`
        : `payment_reference.eq.${txRef}`,
    );

  if (findError) {
    console.error('[flutterwave-verify] order lookup failed', findError);
    return json({ verified: false, message: 'Order lookup failed' }, 500);
  }

  for (const row of (found ?? []) as Record<string, unknown>[]) {
    const id = row.id as string | undefined;
    if (id) orderIds.push(id);
  }

  // The reference may not have been recorded before checkout completed, so fall
  // back to the order id the client sent us.
  if (orderIds.length === 0 && explicitOrderId) orderIds = [explicitOrderId];
  if (orderIds.length === 0) {
    // Flutterwave confirmed the money arrived, so the transaction is genuinely
    // valid even though we could not tie it to an order here. Report it as
    // verified and settle nothing: callers that already know their order id
    // record it themselves (and the tailor RLS policy allows a tailor to write
    // their own order). Saying "not verified" would make a real payment look
    // like a failure.
    console.warn(
      `[flutterwave-verify] ${txRef} verified but no order matched; settled nothing`,
    );
    return json({ verified: true, status, amount: paidAmount, orders: [], settled: false });
  }

  // Never double-apply a transaction.
  const unsettled = (found ?? []).filter(
    (r: Record<string, unknown>) => r.payment_status !== 'paid',
  );
  if (unsettled.length === 0) {
    return json({ verified: true, status, already_settled: true, orders: orderIds });
  }

  // Sanity-check the amount actually collected against what was charged. A
  // mismatch means partial payment or tampering — settle nothing and flag it.
  if (currency === 'NGN' && paidAmount > 0) {
    const expected = Number(unsettled[0].total_amount ?? 0);
    if (expected > 0 && toKobo(paidAmount) !== toKobo(expected)) {
      console.error(
        `[flutterwave-verify] amount mismatch for ${txRef}: paid ${paidAmount} vs order ${expected}`,
      );
      return json(
        { verified: false, status, message: 'Amount mismatch — not settled' },
        409,
      );
    }
  }

  const paidAt = new Date().toISOString();
  let settled: string[] = [];

  for (const row of unsettled as Record<string, unknown>[]) {
    const orderId = row.id as string;
    const { error } = await admin
      .from('orders')
      .update({
        status: 'paid',
        payment_status: 'paid',
        payment_reference: txRef,
        paid_at: paidAt,
      })
      .eq('id', orderId);

    if (error) {
      console.error(`[flutterwave-verify] settlement failed for ${orderId}`, error);
    } else {
      settled.push(orderId);
    }
  }

  console.log(
    `[flutterwave-verify] ${txRef} settled ${settled.length}/${unsettled.length} order(s)` +
      (customerEmail ? ` for ${customerEmail}` : ''),
  );

  return json({ verified: true, status, amount: paidAmount, orders: settled });
});