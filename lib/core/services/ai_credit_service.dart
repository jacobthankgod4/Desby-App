import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

const int kFreeAiCredits = 5;
const int kUnlimitedCredits = -1;

/// Checks and deducts AI credits for body scans and virtual try-ons.
/// Premium users (plan ending in '_pro') get unlimited credits.
/// Free users start with 5 credits.
class AiCreditService {
  final Ref ref;
  AiCreditService(this.ref);

  /// Returns remaining credits. Premium = -1 (unlimited).
  Future<int> getRemainingCredits() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return 0;

    final profile = await ref.read(userProfileProvider(user.id).future);
    if (profile == null) return 0;

    // Premium users get unlimited
    if (profile.subscriptionPlanId != null &&
        profile.subscriptionPlanId!.endsWith('_pro')) {
      return kUnlimitedCredits;
    }

    return profile.aiCredits;
  }

  /// Check if user can use an AI feature. Shows snackbar if not.
  Future<bool> canUseCredits() async {
    final remaining = await getRemainingCredits();
    if (remaining == kUnlimitedCredits) return true;
    if (remaining > 0) return true;

    debugPrint('[AI_CREDITS] No credits remaining');
    return false;
  }

  /// Deduct one credit. Returns true if successful.
  Future<bool> deductCredit({String feature = 'ai_feature'}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return false;

    final profile = await ref.read(userProfileProvider(user.id).future);
    if (profile == null) return false;

    // Premium users: no deduction needed
    if (profile.subscriptionPlanId != null &&
        profile.subscriptionPlanId!.endsWith('_pro')) {
      debugPrint('[AI_CREDITS] Premium user — no deduction for $feature');
      return true;
    }

    // Free user: check remaining
    if (profile.aiCredits <= 0) {
      debugPrint('[AI_CREDITS] No credits left for $feature');
      return false;
    }

    // Deduct one credit
    final newCredits = profile.aiCredits - 1;
    final updatedProfile = profile.copyWith(aiCredits: newCredits);
    await ref.read(updateProfileUsecaseProvider)(updatedProfile);
    ref.invalidate(userProfileProvider(user.id));

    debugPrint('[AI_CREDITS] Deducted 1 credit for $feature. Remaining: $newCredits');
    return true;
  }

  /// Initialize credits for a new user (called during onboarding).
  Future<void> initializeCredits(String userId) async {
    try {
      await Supabase.instance.client.from('users').update({
        'ai_credits': kFreeAiCredits,
      }).eq('id', userId);
      debugPrint('[AI_CREDITS] Initialized $kFreeAiCredits credits for $userId');
    } catch (e) {
      debugPrint('[AI_CREDITS] Failed to initialize credits: $e');
    }
  }
}

final aiCreditServiceProvider = Provider<AiCreditService>((ref) {
  return AiCreditService(ref);
});
