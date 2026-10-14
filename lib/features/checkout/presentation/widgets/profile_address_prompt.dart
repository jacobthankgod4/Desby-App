import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/nigeria_lga_data.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/typography.dart';

/// "Save this address to my profile?" — asked at checkout when the client
/// enters a delivery address that is not the one already stored on their
/// profile.
///
/// One helper, used by both the request journey and the shop checkout, so the
/// two flows ask the identical question, write the same `users.address` /
/// `users.state` columns, and never re-prompt for an address that is already
/// saved.
class ProfileAddressPrompt {
  const ProfileAddressPrompt._();

  /// Combines the free-text address with the state into a single line,
  /// avoiding a duplicate when the address already names the state.
  static String? joinAddress(String? address, String? state) {
    final a = (address ?? '').trim();
    final s = (state ?? '').trim();
    if (a.isEmpty && s.isEmpty) return null;
    if (a.isEmpty) return s;
    if (s.isEmpty) return a;
    if (a.toLowerCase().contains(s.toLowerCase())) return a;
    return '$a, $s';
  }

  /// A saved address is only worth prompting about once it is specific enough
  /// to dispatch a rider to — a bare city or state would be ambiguous.
  static bool isUsable(String address) {
    final trimmed = address.trim();
    if (trimmed.length < 8) return false;
    final hasNumber = RegExp(r'\d').hasMatch(trimmed);
    final words = trimmed.toLowerCase().split(RegExp(r'[\s,]+'));
    const streetCues = {
      'street', 'st', 'road', 'rd', 'avenue', 'ave', 'boulevard', 'blvd',
      'lane', 'ln', 'drive', 'dr', 'close', 'estate', 'junction',
      'plaza', 'mall', 'complex', 'building', 'flat', 'apartment', 'block',
    };
    final hasCue = words.any(streetCues.contains);
    return hasNumber || hasCue;
  }

  /// The state name embedded in a free-text address, if any.
  static String stateFrom(String address) {
    final normalized = address.toLowerCase().trim();
    final states = [...NigeriaLgaData.states]
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final s in states) {
      if (normalized.contains(s.toLowerCase())) return s;
    }
    if (normalized.contains('abuja')) return 'FCT';
    return '';
  }

  /// The client's saved address as one line, or null when nothing usable is
  /// stored. A missing address is a normal state, not an error.
  static Future<String?> loadProfileAddressLine() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return null;
      final row = await Supabase.instance.client
          .from('users')
          .select('address, state')
          .eq('id', userId)
          .maybeSingle();
      return joinAddress(row?['address'] as String?, row?['state'] as String?);
    } catch (_) {
      return null;
    }
  }

  /// Asks whether [address] should become the profile delivery address and
  /// saves it on confirmation.
  ///
  /// Returns silently when there is nothing to ask: the address is too vague
  /// to be worth saving, it matches what is already stored, the dialog was
  /// dismissed, or the save failed (surfaced as a snackbar, never thrown).
  static Future<void> askToSave(BuildContext context, String address) async {
    final trimmed = address.trim();
    if (!isUsable(trimmed)) return;

    final saved = await loadProfileAddressLine();
    if (saved != null && saved.toLowerCase() == trimmed.toLowerCase()) return;
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = ctx.colors;
        return AlertDialog(
          backgroundColor: colors.dialogBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(
            'Save this address?',
            style: AppTypography.subtitle1.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Use "$trimmed" as your delivery address for future orders? '
            'You can change it any time from your profile.',
            style: AppTypography.body2.copyWith(color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Not now',
                style: TextStyle(color: colors.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: AppColors.darkNavy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'SAVE TO PROFILE',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final colors = context.colors;
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not signed in');
      final payload = <String, dynamic>{'address': trimmed};
      final state = stateFrom(trimmed);
      if (state.isNotEmpty) payload['state'] = state;
      await Supabase.instance.client
          .from('users')
          .update(payload)
          .eq('id', userId);
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Address saved to your profile'),
          backgroundColor: colors.statusSuccess,
        ),
      );
    } catch (e) {
      debugPrint('[PROFILE-ADDRESS] save failed: $e');
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Could not save the address to your profile'),
          backgroundColor: colors.statusError,
        ),
      );
    }
  }
}
