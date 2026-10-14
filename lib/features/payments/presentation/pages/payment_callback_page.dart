import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:html' as html;
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/models/plan_registry.dart';

class PaymentCallbackPage extends ConsumerStatefulWidget {
  const PaymentCallbackPage({super.key});

  @override
  _PaymentCallbackPageState createState() => _PaymentCallbackPageState();
}

class _PaymentCallbackPageState extends ConsumerState<PaymentCallbackPage> {
  bool _processed = false;
  bool _navigated = false;
  String? _txRef;
  String? _status;

  @override
  void initState() {
    super.initState();
    _parseCallbackParams();
    _processCallback();
  }

  void _parseCallbackParams() {
    final uri = Uri.base;
    _status = uri.queryParameters['status'];
    _txRef = uri.queryParameters['tx_ref'];
  }

  Future<void> _processCallback() async {
    if (_processed) return;
    _processed = true;

    // Refresh Supabase session — JWT may have expired during Flutterwave redirect
    try {
      await Supabase.instance.client.auth.refreshSession();
    } catch (_) {}

    // Wait for auth state to settle
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted || _navigated) return;

    // If no tx_ref or not successful, just navigate
    if (_txRef == null || _status != 'successful') {
      _navigate();
      return;
    }

    // Try to activate subscription
    await _activateSubscription();

    if (!mounted || _navigated) return;
    _navigate();
  }

  Future<void> _activateSubscription() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Parse plan from tx_ref
      final planId = _parsePlanFromTxRef(_txRef);
      final userType = user.userMetadata?['user_type'] as String? ?? 'client';
      const validUserTypes = [
        'client',
        'tailor',
        'apprentice',
        'fabric_seller',
      ];
      final safeUserType = validUserTypes.contains(userType)
          ? userType
          : 'client';
      final resolvedPlanId = planId ?? '${safeUserType}_pro';

      // Verify amount matches expected plan
      final expectedPlan = PlanRegistry.getPlanById(resolvedPlanId);
      if (expectedPlan != null && expectedPlan.amount > 0) {
        final paidAmountStr = Uri.base.queryParameters['amount'];
        if (paidAmountStr != null) {
          final paidAmount = double.tryParse(paidAmountStr);
          if (paidAmount != null && paidAmount.round() != expectedPlan.amount) {
            debugPrint(
              '⚠️ [PAYMENT-CALLBACK] Amount mismatch: expected ${expectedPlan.amount}, got $paidAmount',
            );
            return;
          }
        }
      }

      // Try fetching profile — fall back to upsert with auth metadata
      final profile = await ref
          .read(userProfileProvider(user.id).future)
          .catchError((_) => null);

      final expiry = DateTime.now().add(const Duration(days: 30));

      if (profile != null) {
        final updatedProfile = profile.copyWith(
          subscriptionPlanId: resolvedPlanId,
          subscriptionExpiry: expiry,
        );
        await ref.read(updateProfileUsecaseProvider)(updatedProfile);
      } else {
        // Profile fetch failed (401) — activate via direct upsert
        await Supabase.instance.client.from('users').upsert({
          'id': user.id,
          'subscription_plan_id': resolvedPlanId,
          'subscription_expiry': expiry.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'id');
      }

      ref.invalidate(userProfileProvider(user.id));
    } catch (e) {
      debugPrint('⚠️ [PAYMENT-CALLBACK] Activation error: $e');
    }
  }

  /// Attempts to parse a plan ID from the tx_ref string.
  /// Returns null if no known plan ID is found.
  String? _parsePlanFromTxRef(String? txRef) {
    if (txRef == null) return null;
    const knownPlanIds = [
      'tailor_pro',
      'client_pro',
      'apprentice_pro',
      'seller_pro',
      'tailor_starter',
      'client_starter',
      'apprentice_starter',
      'seller_starter',
    ];
    for (final planId in knownPlanIds) {
      if (txRef.toLowerCase().contains(planId)) return planId;
    }
    return null;
  }

  void _navigate() {
    if (_navigated) return;
    _navigated = true;

    // Sync browser URL so it doesn't stay stuck on payment-callback
    if (kIsWeb) {
      try {
        html.window.history.replaceState(null, '', '/#/main');
      } catch (_) {}
    }

    final authState = ref.read(authStateProvider);
    final isAuthenticated = authState.maybeMap(
      authenticated: (_) => true,
      orElse: () => false,
    );

    if (isAuthenticated) {
      Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    ref.listen(authStateProvider, (previous, next) {
      if (_navigated) return;
      final isAuthenticated = next.maybeMap(
        authenticated: (_) => true,
        orElse: () => false,
      );
      final isInitial = next.maybeMap(
        initial: (_) => true,
        orElse: () => false,
      );
      if (!isInitial && !isAuthenticated) {
        _navigated = true;
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      } else if (isAuthenticated && !_navigated) {
        _processCallback();
      }
    });

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.amber),
            const SizedBox(height: 24),
            Text(
              'Activating your subscription...',
              style: TextStyle(color: colors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
