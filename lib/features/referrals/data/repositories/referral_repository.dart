import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class ReferralRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Generate a unique referral code for a user
  Future<String> generateCode(String userId) async {
    final code = userId.substring(0, 8).toUpperCase();

    // Check if code already exists
    final existing = await _supabase
        .from('referrals')
        .select()
        .eq('code', code)
        .maybeSingle();

    if (existing != null) return code;

    // Create referral record
    await _supabase.from('referrals').upsert({
      'id': userId,
      'referrer_id': userId,
      'code': code,
      'is_used': false,
      'created_at': DateTime.now().toIso8601String(),
    }, onConflict: 'id');

    return code;
  }

  /// Apply a referral code — credits both referrer and referee
  Future<bool> applyReferral(String code, String refereeId) async {
    try {
      // Find the referral
      final referral = await _supabase
          .from('referrals')
          .select()
          .eq('code', code)
          .eq('is_used', false)
          .maybeSingle();

      if (referral == null) return false;

      final referrerId = referral['referrer_id'];
      if (referrerId == refereeId) return false; // Can't refer yourself

      // Mark referral as used
      await _supabase
          .from('referrals')
          .update({
            'is_used': true,
            'referee_id': refereeId,
            'used_at': DateTime.now().toIso8601String(),
          })
          .eq('id', referral['id']);

      // Credit referrer: extend subscription by 30 days
      final referrerProfile = await _supabase
          .from('users')
          .select('subscription_expiry')
          .eq('id', referrerId)
          .maybeSingle();

      if (referrerProfile != null) {
        final currentExpiry = DateTime.tryParse(
          referrerProfile['subscription_expiry'] ?? '',
        );
        final baseDate =
            (currentExpiry != null && currentExpiry.isAfter(DateTime.now()))
            ? currentExpiry
            : DateTime.now();
        await _supabase
            .from('users')
            .update({
              'subscription_expiry': baseDate
                  .add(const Duration(days: 30))
                  .toIso8601String(),
            })
            .eq('id', referrerId);
      }

      // Credit referee: extend subscription by 30 days
      final refereeProfile = await _supabase
          .from('users')
          .select('subscription_expiry')
          .eq('id', refereeId)
          .maybeSingle();

      if (refereeProfile != null) {
        final currentExpiry = DateTime.tryParse(
          refereeProfile['subscription_expiry'] ?? '',
        );
        final baseDate =
            (currentExpiry != null && currentExpiry.isAfter(DateTime.now()))
            ? currentExpiry
            : DateTime.now();
        await _supabase
            .from('users')
            .update({
              'subscription_expiry': baseDate
                  .add(const Duration(days: 30))
                  .toIso8601String(),
            })
            .eq('id', refereeId);
      }

      return true;
    } catch (e) {
      debugPrint('[REFERRAL] Error applying code: $e');
      return false;
    }
  }

  /// Get referral stats for a user
  Future<Map<String, int>> getStats(String userId) async {
    try {
      final referrals = await _supabase
          .from('referrals')
          .select()
          .eq('referrer_id', userId);

      return {
        'total': (referrals as List).length,
        'used': referrals.where((r) => r['is_used'] == true).length,
      };
    } catch (e) {
      return {'total': 0, 'used': 0};
    }
  }
}
