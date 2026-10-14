import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/order_provider.dart';
import '../providers/logistics_provider.dart';
import '../../domain/entities/order.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../../../core/widgets/shell_app_bar.dart';

class OrderDetailPage extends ConsumerWidget {
  final String orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(
        context,
        title: 'Order Details',
        actions: [
          IconButton(
            icon: const Icon(
              Icons.forum_rounded,
              color: AppColors.amber,
              size: 20,
            ),
            onPressed: () async {
              if (user == null) return;
              final repo = ref.read(chatRepositoryProvider);
              final tailorId = orderAsync.valueOrNull?.tailorId ?? '';
              if (tailorId.isEmpty) return;
              final result = await repo.createConversation([user.id, tailorId]);
              result.fold(
                (failure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to start conversation: ${failure.message}',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                },
                (conversation) => ref.pushShell('/chat-detail', {
                  'conversationId': conversation.id,
                  'peerId': tailorId,
                  'orderId': orderId,
                }),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: orderAsync.when(
        data: (order) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildStatusHUD(context, order, ref, user?.userType ?? ''),
              const SizedBox(height: 32),
              _buildClientDossier(context, order, ref),
              const SizedBox(height: 32),
              _buildGarmentList(context, order),
              const SizedBox(height: 32),
              _buildFinancialSummary(context, order),
              const SizedBox(height: 32),
              // Review section for completed orders
              if (order.status == OrderStatus.delivered)
                _buildReviewSection(context, ref, order, user?.id ?? ''),
              const SizedBox(height: 60),
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.amber,
            strokeWidth: 2,
          ),
        ),
        error: (err, _) => Center(
          child: Text(
            'Dossier sync failed: $err',
            style: TextStyle(color: colors.statusError, fontSize: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHUD(
    BuildContext context,
    OrderEntity order,
    WidgetRef ref,
    String userType,
  ) {
    final colors = context.colors;
    final isClient = userType == 'client';
    // Clients can only view; tailors and fabric_sellers can update
    final canUpdateStatus = !isClient;

    return LuxuryGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PIPELINE STATUS',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order.status.displayName.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.amber,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: colors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: order.status == OrderStatus.pending
                    ? 0.15
                    : order.status == OrderStatus.inProgress
                    ? 0.45
                    : order.status == OrderStatus.delivered
                    ? 1.0
                    : 0.75,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.amber,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (canUpdateStatus)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _showStatusUpdateDialog(context, order, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.surface,
                  foregroundColor: colors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colors.borderSubtle),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'UPDATE MANIFEST STATUS',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                // Confirm Receipt button for clients when order is delivered and paid
                if (order.status == OrderStatus.delivered &&
                    order.paymentStatus == 'paid' &&
                    isClient)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _confirmDelivery(context, order, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: AppColors.darkNavy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'CONFIRM RECEIPT & RELEASE PAYMENT',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (order.status == OrderStatus.delivered &&
                    order.paymentStatus == 'paid' &&
                    isClient)
                  const SizedBox(height: 12),
                // Payment status indicator
                if (order.paymentStatus == 'paid')
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.greenAccent,
                          size: 12,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Payment secured by Desby — released on delivery confirmation',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colors.textMuted,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.status == OrderStatus.pending
                              ? 'Awaiting tailor to begin work'
                              : order.status == OrderStatus.inProgress
                              ? 'Your tailor is working on this order'
                              : order.status == OrderStatus.ready
                              ? 'Your order is ready — confirm receipt when delivered'
                              : order.status == OrderStatus.delivered &&
                                    order.paymentStatus != 'paid'
                              ? 'Order delivered — awaiting payment'
                              : order.status == OrderStatus.delivered
                              ? 'Order delivered — confirm receipt below to release payment'
                              : 'Order status: ${order.status.displayName}',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildClientDossier(
    BuildContext context,
    OrderEntity order,
    WidgetRef ref,
  ) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CLIENT CORRESPONDENCE',
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        LuxuryGlassCard(
          padding: const EdgeInsets.all(16),
          child: InkWell(
            onTap: () =>
                ref.pushShell('/client-detail', {'clientId': order.clientId}),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.surfaceHover,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      order.clientName.isNotEmpty
                          ? order.clientName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: AppColors.amber,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.clientName.toUpperCase(),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'View full details',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: colors.borderSubtle,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGarmentList(BuildContext context, OrderEntity order) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GARMENT SPECIFICATIONS',
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        ...order.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LuxuryGlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.checkroom_rounded,
                    color: AppColors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.garmentType.toUpperCase(),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'CUSTOM MEASUREMENTS ACTIVE',
                          style: TextStyle(
                            color: AppColors.successGreen,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₦${item.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialSummary(BuildContext context, OrderEntity order) {
    // order.totalAmount already includes the dispatch fee (stored separately
    // only for breakdown purposes). Show a fee row only when it is safe to
    // factor the fee back out of the total.
    final hasDispatchFee =
        order.dispatchFee > 0 && order.totalAmount > order.dispatchFee;
    final subtotal = hasDispatchFee
        ? order.totalAmount - order.dispatchFee
        : order.totalAmount;
    final colors = context.colors;
    return LuxuryGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildPriceRow(
            context,
            'SUBTOTAL',
            '₦${subtotal.toStringAsFixed(0)}',
          ),
          if (hasDispatchFee) ...[
            const SizedBox(height: 12),
            _buildPriceRow(
              context,
              'DISPATCH FEE',
              '₦${order.dispatchFee.toStringAsFixed(0)}',
            ),
          ],
          const SizedBox(height: 16),
          Divider(color: colors.divider),
          const SizedBox(height: 16),
          _buildPriceRow(
            context,
            'TOTAL SETTLEMENT',
            '₦${order.totalAmount.toStringAsFixed(0)}',
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    BuildContext context,
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isHighlight ? colors.textPrimary : colors.textMuted,
            fontSize: isHighlight ? 11 : 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isHighlight ? AppColors.amber : colors.textPrimary,
            fontSize: isHighlight ? 18 : 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewSection(
    BuildContext context,
    WidgetRef ref,
    OrderEntity order,
    String userId,
  ) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REVIEW & RATING',
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        LuxuryGlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.rate_review_rounded,
                color: AppColors.amber.withValues(alpha: 0.3),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Rate your experience',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your feedback helps build trust in the community',
                style: TextStyle(color: colors.textMuted, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.pushShell('/review-submit', {
                      'orderId': order.id,
                      'revieweeId': order.tailorId,
                      'reviewType': 'client_to_tailor',
                    });
                  },
                  icon: const Icon(Icons.star_rounded, size: 20),
                  label: const Text(
                    'LEAVE A REVIEW',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: AppColors.darkNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDelivery(
    BuildContext context,
    OrderEntity order,
    WidgetRef ref,
  ) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.greenAccent,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Confirm Receipt?',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'By confirming, you verify that you received your order. This will release payment to the tailor.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _processDeliveryConfirmation(context, order, ref);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: AppColors.darkNavy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'YES, CONFIRM RECEIPT',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Not yet',
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processDeliveryConfirmation(
    BuildContext context,
    OrderEntity order,
    WidgetRef ref,
  ) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.greenAccent),
      ),
    );

    try {
      // 1. Get tailor's bank details from their profile
      final tailorId = order.tailorId;
      if (tailorId == null || tailorId.isEmpty) {
        throw Exception('No tailor associated with this order');
      }

      final tailorProfile = await Supabase.instance.client
          .from('users')
          .select('bank_account_number, bank_code, name, business_name')
          .eq('id', tailorId)
          .maybeSingle();

      // 2. Mark delivered. payment_status is NOT set here — release_order_payout()
      //    owns that transition, so the money flag can never disagree with whether
      //    a payout actually exists.
      await Supabase.instance.client
          .from('orders')
          .update({
            'status': 'delivered',
            'metadata': {
              ...(order.metadata ?? {}),
              'delivery_confirmed_at': DateTime.now().toIso8601String(),
              'delivery_confirmed_by': order.clientId,
            },
          })
          .eq('id', order.id);

      // 3. Queue the payout with one transactional DB call that records the
      //    payout row and flips payment_status together, idempotently. The actual
      //    bank transfer is initiated server-side by an Edge Function — the client
      //    never holds the Flutterwave secret and never moves money itself.
      //
      //    Bank details are context for that server-side transfer, not a
      //    precondition: a tailor without them still gets a payout row, which
      //    surfaces to support for follow-up rather than silently failing.
      final hasBank = tailorProfile != null &&
          tailorProfile['bank_account_number'] != null &&
          tailorProfile['bank_code'] != null;

      final payoutResult = await Supabase.instance.client.rpc(
        'release_order_payout',
        params: {'p_order_id': order.id},
      );
      final queued = payoutResult is Map && payoutResult['status'] != null;
      if (!queued) {
        debugPrint('[ORDER] release_order_payout returned: $payoutResult');
      }
      if (!hasBank) {
        debugPrint('[ORDER] Payout queued without bank details — support follow-up');
      }

      // Refresh order
      ref.invalidate(orderDetailProvider(order.id));

      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss loading
        if (!queued) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                "Receipt saved, but we couldn't queue the payout. "
                "Our team has it flagged — nothing more is needed from you.",
              ),
              backgroundColor: Colors.amber,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Receipt confirmed! Payment released to tailor.',
            ),
            backgroundColor: Colors.greenAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to confirm receipt: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _dispatchReadyRider(
    BuildContext context,
    WidgetRef ref,
    OrderEntity order,
  ) async {
    try {
      final usecase = ref.read(updateOrderStatusUsecaseProvider);
      final statusResult = await usecase(order.id, OrderStatus.ready);
      final statusFailure = statusResult.getFailureOrNull()?.failure;
      if (statusFailure != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not mark the order READY: ${statusFailure.message}',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not mark the order READY: $error'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    ref.invalidate(orderDetailProvider(order.id));
    ref.invalidate(ordersProvider);

    final hasWaybill = order.shipmentId?.trim().isNotEmpty == true;
    final shouldDispatch = order.requiresDispatch && !hasWaybill;
    if (!shouldDispatch) return;

    try {
      final result = await ref
          .read(logisticsRepositoryProvider)
          .summonRider(order);
      if (!context.mounted) return;
      result.fold(
        (failure) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order marked READY, but dispatch failed: ${failure.message}',
            ),
            backgroundColor: Colors.orangeAccent,
          ),
        ),
        (waybill) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order marked READY. Fez rider dispatched — waybill $waybill',
            ),
            backgroundColor: Colors.greenAccent,
          ),
        ),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order marked READY, but dispatch failed: $error'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    } finally {
      ref.invalidate(orderDetailProvider(order.id));
      ref.invalidate(ordersProvider);
    }
  }

  void _showStatusUpdateDialog(
    BuildContext context,
    OrderEntity order,
    WidgetRef ref,
  ) {
    final colors = context.colors;
    final hasWaybill = order.shipmentId?.trim().isNotEmpty == true;
    final canDispatchNow = order.requiresDispatch && !hasWaybill;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bottomSheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'UPDATE PIPELINE STATUS',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            if (order.requiresDispatch) ...[
              Text(
                'Tailors: a rider is dispatched only when you mark the order READY.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textMuted, fontSize: 10),
              ),
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 16),
            if (canDispatchNow) ...[
              ListTile(
                tileColor: AppColors.amber.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: AppColors.amber.withValues(alpha: 0.35),
                  ),
                ),
                leading: const Icon(
                  Icons.local_shipping_rounded,
                  color: AppColors.amber,
                ),
                title: Text(
                  'MARK ORDER READY & DISPATCH RIDER',
                  style: TextStyle(
                    color: AppColors.amber,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: Text(
                  'Marks the order READY and dispatches a Fez rider',
                  style: TextStyle(color: colors.textMuted, fontSize: 9),
                ),
                onTap: () async {
                  await _dispatchReadyRider(sheetContext, ref, order);
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
              ),
              const Divider(height: 24),
            ],
            ...OrderStatus.values.map(
              (status) => ListTile(
                title: Text(
                  status.displayName.toUpperCase(),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                onTap: () async {
                  if (status == OrderStatus.ready && canDispatchNow) {
                    await _dispatchReadyRider(sheetContext, ref, order);
                  } else {
                    try {
                      final usecase = ref.read(
                        updateOrderStatusUsecaseProvider,
                      );
                      final statusResult = await usecase(order.id, status);
                      final statusFailure = statusResult
                          .getFailureOrNull()
                          ?.failure;
                      if (statusFailure != null && sheetContext.mounted) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Status update failed: ${statusFailure.message}',
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    } catch (error) {
                      if (sheetContext.mounted) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(
                            content: Text('Status update failed: $error'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                    ref.invalidate(orderDetailProvider(order.id));
                    ref.invalidate(ordersProvider);
                  }
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
