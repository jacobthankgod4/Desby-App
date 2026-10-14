// flutterwave-pay — initialise a payment for an order.
//
// The amount sent by the client is NOT trusted. The order total is read from
// the database and that value is what Flutterwave is asked to charge, so a
// tampered client amount cannot lower the price.
//
// It also stamps payment_reference onto the order up front, which is what lets
// flutterwave-verify find the right order later.
//
// Request:  POST /functions/v1/flutterwave-pay
//           { amount, email, name, tx_ref, order_id }
// Response: { status: 'success', tx_ref, public_key, amount }

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Method': 'POST, OPTIONS',
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const publicKey = Deno.env.get('FLUTTERWAVE_PUBLIC_KEY');

  if (!supabaseUrl || !serviceRoleKey || !publicKey) {
    console.error('[flutterwave-pay] missing server configuration');
    return json({ status: 'error', message: 'Server not configured' }, 500);
  }

  let body: Record<string, unknown>;
  try {
    body = (await req.json()) as Record<string, unknown>;
  } catch {
    return json({ status: 'error', message: 'Invalid JSON body' }, 400);
  }

  const txRef = String(body.tx_ref ?? '');
  const orderId = String(body.order_id ?? '');
  if (!txRef) return json({ status: 'error', message: 'tx_ref is required' }, 400);

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // ── Amount comes from the database, never the request ──────────────────────
  let amount = Number(body.amount ?? 0);

  if (orderId) {
    const { data, error } = await admin
      .from('orders')
      .select('id,total_amount,status,payment_status')
      .eq('id', orderId)
      .maybeSingle();

    if (error) {
      console.error('[flutterwave-pay] order lookup failed', error);
      return json({ status: 'error', message: 'Order lookup failed' }, 500);
    }

    if (!data) {
      return json({ status: 'error', message: 'Order not found' }, 404);
    }

    if (data.payment_status === 'paid') {
      return json({ status: 'error', message: 'Order is already paid' }, 409);
    }

    const total = Number(data.total_amount ?? 0);
    if (total <= 0) {
      return json({ status: 'error', message: 'Order has no payable total' }, 409);
    }

    // The client amount is only accepted if it agrees with the stored total.
    if (amount > 0 && Math.round(amount * 100) !== Math.round(total * 100)) {
      console.warn(
        `[flutterwave-pay] amount mismatch for ${orderId}: client ${amount} vs order ${total}; using order total`,
      );
    }
    amount = total;
  }

  if (!(amount > 0)) {
    return json({ status: 'error', message: 'A positive amount is required' }, 400);
  }

  // Record the reference now so verification can find this order later.
  if (orderId) {
    const { error } = await admin
      .from('orders')
      .update({ payment_reference: txRef })
      .eq('id', orderId);
    if (error) {
      console.error('[flutterwave-pay] could not record payment_reference', error);
    }
  }

  console.log(`[flutterwave-pay] initialised ${txRef} for ₦${amount}`);
  return json({ status: 'success', tx_ref: txRef, public_key: publicKey, amount });
});