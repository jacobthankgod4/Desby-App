import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Merges [patch] into the authenticated user's `preferences` JSONB column.
///
/// PostgREST replaces the whole JSON value when a column is updated, so
/// writing a single key directly would silently wipe every other key
/// (theme mode, style preferences, feature flags, ...). This helper does an
/// explicit read-modify-write so features never clobber each other's data.
Future<void> updateUserPreferences(Map<String, dynamic> patch) async {
  try {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    // A 401 here means the request went out with no JWT, not that RLS denied
    // it — `users` policies are open to `public`. It happens when a preference
    // is written during boot, before the stored session has been restored, so
    // `currentUser` is populated but no Authorization header is attached yet.
    // The symptom was silent: the tour completed flag never reached the server,
    // so the tour reappeared on the next device with no visible error.
    final response = await _selectWithSessionRetry(client, userId);

    final existing = response?['preferences'];
    final merged = <String, dynamic>{
      if (existing is Map<String, dynamic>) ...existing,
      ...patch,
    };

    await client.from('users').update({'preferences': merged}).eq('id', userId);
  } catch (e) {
    debugPrint('[USER_PREFERENCES] failed to merge $patch: $e');
  }
}

/// Reads `users.preferences`, waiting briefly for the session and retrying once
/// if the first attempt is rejected for want of a token.
Future<Map<String, dynamic>?> _selectWithSessionRetry(
  SupabaseClient client,
  String userId,
) async {
  Future<Map<String, dynamic>?> attempt() => client
      .from('users')
      .select('preferences')
      .eq('id', userId)
      .maybeSingle();

  var hasToken = client.auth.currentSession?.accessToken != null;
  if (!hasToken) {
    // Give session restore a beat, then force one if the SDK offers it.
    for (var i = 0; i < 10 && !hasToken; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      hasToken = client.auth.currentSession?.accessToken != null;
    }
    if (!hasToken) {
      try {
        await client.auth.refreshSession();
        hasToken = client.auth.currentSession?.accessToken != null;
      } catch (_) {
        // Refresh can legitimately fail offline; the retry below will report it.
      }
    }
  }

  try {
    return await attempt();
  } catch (e) {
    if (e is AuthException || '$e'.contains('401')) {
      debugPrint('[USER_PREFERENCES] 401 — refreshing session and retrying once');
      try {
        await client.auth.refreshSession();
        return await attempt();
      } catch (e2) {
        debugPrint('[USER_PREFERENCES] retry failed: $e2');
        rethrow;
      }
    }
    rethrow;
  }
}
