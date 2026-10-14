// admin-invite-user — invite someone to create a Desby OS account by email.
//
// Sends the "Invite user" template (supabase/templates/invite.html). This is
// the only path in the app that triggers it: the client-facing "invite" flow
// shares a token so a *client* can submit measurements and never creates an
// auth account.
//
// The browser cannot call `admin.inviteUserByEmail` directly — that needs a
// service_role key, which must never reach a client. This function takes the
// caller's JWT, re-checks the admin role server-side with the SECURITY DEFINER
// `is_admin()` RPC, and only then performs the invite.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
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
  if (!supabaseUrl || !serviceRoleKey) {
    console.error('[admin-invite-user] missing server configuration');
    return json({ success: false, error: 'Server not configured' }, 500);
  }

  // The caller's own JWT — not the service key — so the admin check reflects
  // who is actually asking.
  const authHeader = req.headers.get('Authorization') ?? '';
  const jwt = authHeader.replace(/^Bearer\s+/i, '').trim();
  if (!jwt) {
    return json({ success: false, error: 'Sign in required' }, 401);
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // Verify the JWT and ask the database whether this user is an admin.
  const { data: claims, error: claimsError } = await admin.auth.getUser(jwt);
  if (claimsError || !claims?.user) {
    return json({ success: false, error: 'Invalid session' }, 401);
  }

  const { data: isAdmin, error: adminError } = await admin.rpc('is_admin', {
    p_user_id: claims.user.id,
  });
  if (adminError) {
    console.error('[admin-invite-user] is_admin failed', adminError);
    return json({ success: false, error: 'Could not verify permissions' }, 500);
  }
  if (isAdmin !== true) {
    console.warn('[admin-invite-user] denied non-admin', claims.user.id);
    return json({ success: false, error: 'Admin access required' }, 403);
  }

  let body: Record<string, unknown>;
  try {
    body = (await req.json()) as Record<string, unknown>;
  } catch {
    return json({ success: false, error: 'Invalid JSON body' }, 400);
  }

  const email = String(body.email ?? '').trim().toLowerCase();
  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return json({ success: false, error: 'Enter a valid email address' }, 400);
  }

  const redirectTo = typeof body.redirect_to === 'string' ? body.redirect_to : undefined;

  // Does an account already exist? inviting again would fail confusingly.
  const { data: existing } = await admin.auth.admin.listUsers({
    page: 1,
    perPage: 1000,
  });
  const already = (existing?.users ?? []).some(
    (u) => (u.email ?? '').toLowerCase() === email,
  );
  if (already) {
    return json(
      { success: false, error: 'That email already has a Desby OS account' },
      409,
    );
  }

  const { data, error } = await admin.auth.admin.inviteUserByEmail(email, {
    redirectTo,
  });

  if (error) {
    console.error('[admin-invite-user] invite failed', error);
    return json({ success: false, error: error.message }, 502);
  }

  console.log(`[admin-invite-user] invited ${email} (${data?.user?.id ?? 'unknown'})`);
  return json({ success: true, id: data?.user?.id ?? null });
});