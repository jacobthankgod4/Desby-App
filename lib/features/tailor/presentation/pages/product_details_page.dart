import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/services/flutterwave_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/domain/entities/order_ids.dart';
import '../../../orders/presentation/providers/order_provider.dart';
import '../../domain/entities/shop_product.dart';
import '../../../../core/widgets/shell_scope.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../payments/domain/platform_money_config.dart';

class ProductDetailsPage extends ConsumerWidget {
  final ShopProduct product;

  const ProductDetailsPage({super.key, required this.product});

  /// Persist the verified payment. Returns false when nothing was written, so the
  /// caller can warn the user with the reference rather than silently losing it.
  static Future<bool> _recordPayment(
    WidgetRef ref,
    OrderEntity order,
    String txRef,
    double amount,
  ) async {
    final split = PlatformMoneyConfig.splitGross(amount);
    try {
      final response = await Supabase.instance.client
          .from('orders')
          .update({
            'status': 'paid',
            'payment_status': 'paid',
            'payment_reference': txRef,
            'platform_fee': split.commission,
            'tailor_payout': split.tailorPayout,
            'paid_at': DateTime.now().toIso8601String(),
          })
          .eq('id', order.id)
          .select('id');
      return (response as List).isNotEmpty;
    } catch (e) {
      debugPrint('[PRODUCT_PURCHASE] payment record failed: $e');
      return false;
    }
  }

  Future<void> _processPayment(BuildContext context, WidgetRef ref) async {
    final double amount = product.price;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid product price architecture.'),
          backgroundColor: context.colors.statusError,
        ),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to complete purchase.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // A shop product purchase created NO order row at all: this file contained
    // zero `from('orders')` calls, so Flutterwave collected the money and the
    // platform kept no record. Create the order first, then pay, then mark it
    // paid with the verified reference.
    final reference = OrderIds.purchaseReference();
    final order = OrderEntity(
      id: OrderIds.newUuid()!,
      reference: reference,
      requestingUserId: user.id,
      clientId: null,
      tailorId: product.tailorId,
      clientName: user.name ?? '',
      status: OrderStatus.pending,
      totalAmount: amount,
      dispatchFee: 0,
      createdAt: DateTime.now(),
      items: [
        OrderItem(
          id: OrderIds.newUuid()!,
          garmentType: product.category.isNotEmpty ? product.category : 'Product',
          price: amount,
        ),
      ],
    );

    final savedOrder = (await ref.read(createOrderUsecaseProvider)(order)).fold(
      (failure) {
        debugPrint('[PRODUCT_PURCHASE] order create failed: $failure.message');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not start this purchase: ${failure.message}\n\n'
                'You have not been charged.',
              ),
              backgroundColor: context.colors.statusError,
            ),
          );
        }
        return null;
      },
      (saved) => saved,
    );
    // fold() cannot express early-return, so re-check.
    if (savedOrder == null) return;
    ref.invalidate(ordersProvider);

    try {
      await FlutterwaveService().checkout(
        context: context,
        email: user.email,
        fullName: user.name,
        amount: amount,
        orderId: savedOrder.displayReference,
        onSuccess: (txId) async {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment initiated — verifying...'),
              backgroundColor: Colors.blueAccent,
            ),
          );
          for (var i = 0; i < 10; i++) {
            await Future.delayed(const Duration(seconds: 3));
            if (!context.mounted) return;
            final verified = await FlutterwaveService().verifyTransaction(txId);
            if (!context.mounted) return;
            if (verified) {
              // Record the payment against the real order row. Only after this
              // succeeds do we tell the user the purchase is complete.
              final recorded = await _recordPayment(
                ref,
                savedOrder,
                txId,
                amount,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    recorded
                        ? 'PAYMENT CONFIRMED: $txId'
                        : 'Payment taken ($txId) but we could not save it to '
                              'your orders. Please contact support with this '
                              'reference: ${savedOrder.displayReference}',
                  ),
                  backgroundColor: recorded
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                ),
              );
              ref.invalidate(ordersProvider);
              if (recorded) ref.popShell();
              return;
            }
          }
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment initiated — please check your email for confirmation.',
              ),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        },
        onCancel: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction Terminated.'),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('❌ [FLUTTERWAVE] Failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment failed. Please try again.'),
            backgroundColor: context.colors.statusError,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final String name = product.name;
    final String price = '\u20A6${product.price.toInt()}';
    final String description = product.description;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          if (!ShellScope.isInside(context))
            SliverAppBar(
              pinned: true,
              backgroundColor: colors.scaffoldBg,
              elevation: 0,
              toolbarHeight: 60,
              leading: MediaQuery.of(context).size.width > 1000
                  ? const SizedBox.shrink()
                  : IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.amber,
                        size: 20,
                      ),
                      onPressed: () => ref.popShell(),
                    ),
              title: Text(
                'PRODUCT DETAILS',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.8,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(10),
                child: Container(height: 10, color: AppColors.amber),
              ),
            ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                height: 380,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: colors.surface,
                  border: Border.all(
                    color: AppColors.amber.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.checkroom_rounded,
                          color: AppColors.amber.withValues(alpha: 0.1),
                          size: 180,
                        ),
                      ),
                      if (product.imageUrls.isNotEmpty)
                        Positioned.fill(
                          child: AppNetworkImage(
                            url: product.imageUrls.first,
                            fit: BoxFit.cover,
                          ),
                        ),
                      Positioned(
                        bottom: 32,
                        left: 32,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.toUpperCase(),
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              price,
                              style: TextStyle(
                                color: AppColors.amber,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DESIGN NARRATIVE',
                    style: TextStyle(
                      color: AppColors.amber,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    description.isNotEmpty
                        ? description
                        : 'Professionally tailored using high-density premium fabrics. Features reinforced stitching and digital-precision alignment for a world-class bespoke finish.',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 15,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: colors.surface,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RESOURCES',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildGlassAction('MEASUREMENT GUIDE', colors),
                    const SizedBox(height: 12),
                    _buildGlassAction('FABRIC AVAILABILITY', colors),
                  ],
                ),
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
      ),
      bottomSheet: _buildBottomAction(context, ref),
    );
  }

  Widget _buildGlassAction(String title, DesbyThemeColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: colors.textMuted,
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(24),
      color: colors.scaffoldBg,
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: () => _processPayment(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: colors.scaffoldBg,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'BUY NOW',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                SizedBox(width: 12),
                Icon(Icons.bolt_rounded, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
