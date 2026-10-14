import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/providers/user_preferences_provider.dart';
import '../../../../core/services/flutterwave_service.dart';
import '../../../../core/widgets/price_text_field.dart';
import '../../../../theme/colors.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/widgets/shell_app_bar.dart';
import '../../../payments/domain/platform_money_config.dart';
import '../../../payments/domain/payment_session.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  final double amount;
  final String orderId;
  final List<String> orderIds;

  const CheckoutPage({
    super.key,
    required this.amount,
    required this.orderId,
    this.orderIds = const [],
  });

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final FlutterwaveService _flutterwaveService = FlutterwaveService();
  bool _isProcessing = false;
  int _verificationSession = 0;

  /// Non-null when this order already has a payment in flight. Restoring
  /// checkout after a reload lands here instead of a fresh Pay button, so a
  /// reload cannot become a second charge for the same order.
  PaymentSession? _resumableSession;

  // Multi-step checkout: 0 = choose how to pay, 1 = confirm & pay.
  int _step = 0;
  int _selectedMethod = 0;

  static const _methodLabels = [
    'Debit or Credit Card',
    'Mobile Money',
    'Bank Transfer',
  ];
  static const _methodIcons = [
    Icons.shield_rounded,
    Icons.phone_android_rounded,
    Icons.account_balance_rounded,
  ];

  // Coach tour for first-time users; completion persisted in
  // users.preferences.checkoutTourCompleted.
  final _summaryKey = GlobalKey();
  final _methodsKey = GlobalKey();
  final _primaryActionKey = GlobalKey();
  bool _tourChecked = false;

  @override
  void initState() {
    super.initState();
    // Restore an in-flight payment before the first frame so a reload shows the
    // resume state immediately.
    _resumableSession = PaymentSession.activeFor(widget.orderId);
    if (_resumableSession != null) _step = 1;
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTour());
  }

  Future<void> _maybeShowTour() async {
    if (_tourChecked) return;
    _tourChecked = true;
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final response = await Supabase.instance.client
          .from('users')
          .select('preferences')
          .eq('id', userId)
          .maybeSingle();
      final prefs = response?['preferences'];
      if (prefs is Map<String, dynamic> &&
          prefs['checkoutTourCompleted'] == true) {
        return;
      }
    } catch (e) {
      debugPrint('[CHECKOUT] tour preference read failed: $e');
      return;
    }
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted || _isProcessing) return;

    // A payment for this order is already in flight (typically the user
    // reloaded mid-checkout). Never mint a second charge for the same order.
    final existing = PaymentSession.activeFor(widget.orderId);
    if (existing != null) {
      setState(() => _resumableSession = existing);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A payment for this order is already in progress. '
            'Check your email or your bank statement before paying again.',
          ),
        ),
      );
      return;
    }
    _showTour();
  }

  void _showTour() {
    final targets = <TargetFocus>[
      if (_summaryKey.currentContext != null)
        TargetFocus(
          identify: 'checkout-summary',
          keyTarget: _summaryKey,
          alignSkip: Alignment.topRight,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: const _TourCard(
                title: 'Order Summary',
                body:
                    'The total amount due and your order number always stay in view while you check out.',
              ),
            ),
          ],
        ),
      if (_methodsKey.currentContext != null)
        TargetFocus(
          identify: 'checkout-methods',
          keyTarget: _methodsKey,
          alignSkip: Alignment.topRight,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: const _TourCard(
                title: 'Payment Method',
                body:
                    'Pick how you want to pay. Cards, mobile money and bank transfers are all handled securely by our payment partner.',
              ),
            ),
          ],
        ),
      if (_primaryActionKey.currentContext != null)
        TargetFocus(
          identify: 'checkout-primary-action',
          keyTarget: _primaryActionKey,
          alignSkip: Alignment.topRight,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: const _TourCard(
                title: 'One Tap From Here',
                body:
                    'Continue to review, then pay. We will verify your payment and start production right away.',
              ),
            ),
          ],
        ),
    ];
    if (targets.isEmpty) return;

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.8,
      paddingFocus: 12,
      textStyleSkip: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
      onFinish: _completeTour,
      onSkip: () {
        _completeTour();
        return true;
      },
    ).show(context: context);
  }

  Future<void> _completeTour() async {
    await updateUserPreferences({'checkoutTourCompleted': true});
  }

  List<String> get _orderIds {
    final ids = widget.orderIds
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList();
    return ids.isNotEmpty ? ids : [widget.orderId];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(context, title: 'Checkout'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          if (isWide) {
            // Split-screen: step flow on the left, sticky order summary rail.
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 5, child: _buildStepPanel(isWide: true)),
                Container(width: 1, color: colors.borderDefault),
                Expanded(flex: 4, child: _buildSummaryRail()),
              ],
            );
          }
          return _buildMobileLayout();
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderSummary(),
          const SizedBox(height: 24),
          _buildStepPanel(isWide: false),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSummaryRail() {
    final colors = context.colors;
    return Container(
      height: double.infinity,
      color: colors.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderSummary(),
            const SizedBox(height: 24),
            _secureNote(colors),
          ],
        ),
      ),
    );
  }

  Widget _secureNote(dynamic colors) {
    return Row(
      children: [
        Icon(Icons.lock_outline_rounded, color: colors.textHint, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Payments are processed securely. Your card details never touch our servers.',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepPanel({required bool isWide}) {
    final colors = context.colors;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 40 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIndicator(colors),
          const SizedBox(height: 32),
          if (_step == 0) ...[
            const Text(
              'PAYMENT METHOD',
              style: TextStyle(
                color: AppColors.amber,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            _buildPaymentMethods(),
            const SizedBox(height: 32),
            _buildPrimaryButton(),
          ] else ...[
            const Text(
              'CONFIRM & PAY',
              style: TextStyle(
                color: AppColors.amber,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            _buildConfirmDetails(),
            const SizedBox(height: 24),
            if (!isWide) ...[_secureNote(colors), const SizedBox(height: 24)],
            _buildPrimaryButton(),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => setState(() => _step = 0),
                child: Text(
                  'Back to payment methods',
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepIndicator(dynamic colors) {
    return Row(
      children: [
        _stepBadge(colors, 0, 'Payment'),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: _step >= 1 ? AppColors.amber : colors.borderDefault,
          ),
        ),
        _stepBadge(colors, 1, 'Confirm'),
      ],
    );
  }

  Widget _stepBadge(dynamic colors, int index, String label) {
    final active = _step >= index;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.amber : colors.borderDefault,
          ),
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: active ? AppColors.darkNavy : colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: active ? colors.textPrimary : colors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    return KeyedSubtree(
      key: _methodsKey,
      child: Column(
        children: List.generate(_methodLabels.length, (i) {
          return _buildPaymentMethodTile(
            _methodLabels[i],
            _methodIcons[i],
            selected: _selectedMethod == i,
            onTap: () => setState(() => _selectedMethod = i),
          );
        }),
      ),
    );
  }

  Widget _buildConfirmDetails() {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        children: [
          _confirmRow(
            'Paying with',
            _methodLabels[_selectedMethod],
            colors,
            highlight: true,
          ),
          Divider(color: colors.divider, height: 24),
          _confirmRow('Amount due', _amountLabel(), colors, highlight: true),
          Divider(color: colors.divider, height: 24),
          _confirmRow('Order number', widget.orderId.toUpperCase(), colors),
        ],
      ),
    );
  }

  Widget _confirmRow(
    String label,
    String value,
    dynamic colors, {
    bool highlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: highlight ? AppColors.amber : colors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: highlight ? 14 : 11,
            ),
          ),
        ),
      ],
    );
  }

  String _amountLabel() =>
      '\u20A6${formatPriceDigits(widget.amount.toStringAsFixed(0))}';

  Widget _buildOrderSummary() {
    final colors = context.colors;
    return Container(
      key: _summaryKey,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Amount Due',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              Text(
                _amountLabel(),
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: colors.divider),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Number',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              Text(
                widget.orderId.toUpperCase(),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(
    String label,
    IconData icon, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.amber.withValues(alpha: 0.08)
              : colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.amber : colors.cardBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.amber, size: 22),
            const SizedBox(width: 20),
            Text(
              label,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            selected
                ? const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.amber,
                    size: 20,
                  )
                : Icon(
                    Icons.lock_outline_rounded,
                    color: colors.textHint,
                    size: 16,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    final colors = context.colors;
    final isPayStep = _step == 1;
    return SizedBox(
      key: _primaryActionKey,
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: _isProcessing
            ? null
            : isPayStep
            ? _handlePayment
            : () => setState(() => _step = 1),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.darkNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: _isProcessing
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: colors.textOnAmber,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isPayStep ? 'Pay ${_amountLabel()}' : 'Continue to Payment',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    isPayStep
                        ? Icons.bolt_rounded
                        : Icons.arrow_forward_rounded,
                    size: 20,
                  ),
                ],
              ),
      ),
    );
  }

  void _handlePayment() async {
    bool successCalled = false;
    setState(() => _isProcessing = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('Session Expired. Please log in.');
      }

      // DESBY REVENUE ARCHITECTURE: Split payment for logistics orders
      final String? subaccount =
          null; // TODO: Configure real Paystack subaccount

      // FLUTTERWAVE IMPLEMENTATION
      await _flutterwaveService.checkout(
        context: context,
        email: user.email,
        fullName: user.name,
        amount: widget.amount,
        orderId: widget.orderId,
        subAccountCode: subaccount,
        onSuccess: (txRef) {
          successCalled = true;
          // Record before the redirect so a reload cannot mint a second
          // reference for this order.
          PaymentSession.record(widget.orderId, txRef);
          if (mounted) {
            setState(() => _resumableSession = PaymentSession.activeFor(widget.orderId));
          }
          if (!mounted) return;
          // Show verifying overlay after payment link is opened
          _showVerifyingOverlay(txRef);
        },
        onCancel: () {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Payment cancelled')));
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment could not be processed. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted && !successCalled) setState(() => _isProcessing = false);
    }
  }

  void _showVerifyingOverlay(String txRef) {
    final session = ++_verificationSession;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'verifying',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (_, anim, _, _) => FadeTransition(
        opacity: anim,
        child: _VerifyingOverlay(
          txRef: txRef,
          flutterwaveService: _flutterwaveService,
          onVerified: () async {
            if (!mounted || session != _verificationSession) return;
            final orderIds = _orderIds;
            final updated = await _confirmPaymentWithServer(txRef, orderIds);
            if (!mounted || session != _verificationSession) return;
            _verificationSession++;
            Navigator.of(context).pop();
            if (!updated) {
              setState(() => _isProcessing = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Payment received, but order status is still syncing. Please try again shortly.',
                  ),
                ),
              );
              return;
            }
            _showOrderConfirmation(orderId: orderIds.first);
          },
          onFailed: () {
            if (!mounted || session != _verificationSession) return;
            _verificationSession++;
            Navigator.of(context).pop();
            setState(() => _isProcessing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Payment verification pending. Please check your email for receipt.',
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Confirms the transaction with the server, which verifies it against
  /// Flutterwave using the secret key and settles the order.
  ///
  /// The browser SDK cannot be trusted to report the real outcome - it can be
  /// made to claim success for any reference. `flutterwave-verify` is the only
  /// authority, and it is also what writes `status='paid'`, so the client never
  /// needs write access to the order (which its RLS correctly denies).
  Future<bool> _confirmPaymentWithServer(
    String txRef,
    List<String> orderIds,
  ) async {
    if (orderIds.isEmpty || orderIds.any((id) => id.trim().isEmpty)) return false;
    for (final id in orderIds) {
      final ok = await _flutterwaveService.verifyTransaction(
        txRef,
        orderId: id,
      );
      if (!ok) return false;
    }
    return true;
  }
  void _showOrderConfirmation({required String orderId}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final colors = ctx.colors;
        return Dialog(
          backgroundColor: colors.dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.greenAccent,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ORDER CONFIRMED',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: AppColors.amber,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  orderId.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.amber,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_amountLabel()} paid successfully',
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceHover,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _NextStep(text: 'Tailor will accept your booking'),
                      _NextStep(text: 'Your fabric rider will be arranged'),
                      _NextStep(
                        text: 'Order goes into production, typically 2-4 weeks',
                      ),
                      _NextStep(
                        text:
                            'Your finished garment will be dispatched when the tailor marks it READY',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      ref.pushShell('/order-detail', {'orderId': orderId});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: AppColors.darkNavy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'TRACK ORDER',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ref.setShell('/main');
                  },
                  child: Text(
                    'Done',
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NextStep extends StatelessWidget {
  final String text;
  const _NextStep({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, color: AppColors.successGreen, size: 7),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifyingOverlay extends StatefulWidget {
  final String txRef;
  final FlutterwaveService flutterwaveService;
  final VoidCallback onVerified;
  final VoidCallback onFailed;

  const _VerifyingOverlay({
    required this.txRef,
    required this.flutterwaveService,
    required this.onVerified,
    required this.onFailed,
  });

  @override
  State<_VerifyingOverlay> createState() => _VerifyingOverlayState();
}

class _VerifyingOverlayState extends State<_VerifyingOverlay> {
  int _attempts = 0;
  static const int _maxAttempts = 15;

  @override
  void initState() {
    super.initState();
    _pollVerification();
  }

  Future<void> _pollVerification() async {
    while (_attempts < _maxAttempts) {
      if (!mounted) return;
      await Future.delayed(const Duration(seconds: 3));
      _attempts++;

      try {
        final verified = await widget.flutterwaveService.verifyTransaction(
          widget.txRef,
        );
        if (verified && mounted) {
          widget.onVerified();
          return;
        }
      } catch (e) {
        debugPrint('Verify attempt $_attempts failed: $e');
      }
    }
    if (mounted) widget.onFailed();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.scaffoldBg,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  color: AppColors.amber,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Verifying Payment',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Processing your payment...',
                style: TextStyle(color: colors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Text(
                'Please complete payment in the form above.',
                style: TextStyle(color: colors.textHint, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => widget.onFailed(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  final String title;
  final String body;

  const _TourCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10222B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.amber,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
