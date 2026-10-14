import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Outcome of requesting a reauthentication challenge.
enum ReauthOutcome {
  /// A challenge was sent. The user must complete it before the sensitive
  /// operation proceeds.
  challengeSent,

  /// No signed-in session, so reauthentication is not possible.
  noSession,

  /// The challenge could not be sent.
  failed,
}

/// Confirms the current user's identity before a sensitive operation.
///
/// Supabase's `reauthenticate()` sends the **Reauthentication** email template
/// (`supabase/templates/reauthentication.html`), which is what makes that
/// template live. It returns `void` — it *requests* a challenge rather than
/// reporting a decision — so this service reports whether the request was
/// sent and leaves verification to the operation that follows.
///
/// Note: GoTrue's reauthenticate endpoint issues an OTP to the user's email.
/// Account deletion previously re-prompted for the password with
/// `signInWithPassword`, which proves identity inline and needs no round trip.
/// Prefer [confirmWithPassword] where an inline proof is acceptable and this
/// service where a fresh emailed challenge is wanted.
class ReauthService {
  ReauthService._();

  static final ReauthService instance = ReauthService._();

  /// Requests a reauthentication challenge for the signed-in user.
  ///
  /// Never throws: a failure here must block the sensitive operation rather
  /// than crash the caller.
  Future<ReauthOutcome> requestChallenge() async {
    try {
      if (Supabase.instance.client.auth.currentSession == null) {
        return ReauthOutcome.noSession;
      }
      await Supabase.instance.client.auth
          .reauthenticate()
          .timeout(const Duration(seconds: 30));
      debugPrint('[REAUTH] challenge sent');
      return ReauthOutcome.challengeSent;
    } catch (e) {
      debugPrint('[REAUTH] challenge failed: $e');
      return ReauthOutcome.failed;
    }
  }

  /// Proves identity inline by re-checking the password.
  ///
  /// Keeps the existing account-deletion behaviour intact while returning a
  /// typed result instead of a bare bool.
  Future<bool> confirmWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final res = await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password)
          .timeout(const Duration(seconds: 25));
      return res.user != null;
    } catch (e) {
      debugPrint('[REAUTH] password confirmation failed: $e');
      return false;
    }
  }
}