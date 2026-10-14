import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../../../orders/presentation/providers/order_provider.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/presentation/widgets/uber_tracking_map.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SellerOrdersPage extends ConsumerWidget {
  const SellerOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';
    final ordersAsync = ref.watch(ordersProvider(null));

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: ordersAsync.when(
        data: (orders) {
          // ordersProvider already filters by fabric_seller_id for fabric_seller users
          final sellerOrders = orders
              .where((o) => o.id.startsWith('MKT'))
              .toList();

          if (sellerOrders.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildOrdersList(context, ref, sellerOrders, userId);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                color: colors.textMuted,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'ORDERS UNAVAILABLE',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check your connection and try again.',
                style: TextStyle(color: colors.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => ref.invalidate(ordersProvider(null)),
                child: const Text(
                  'RETRY',
                  style: TextStyle(
                    color: AppColors.amber,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 64, color: colors.textMuted),
          const SizedBox(height: 24),
          Text(
            'NO MERCHANT ORDERS',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Wait for tailors to summon your fabrics.',
            style: TextStyle(color: colors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(
    BuildContext context,
    WidgetRef ref,
    List<OrderEntity> orders,
    String sellerId,
  ) {
    final colors = context.colors;
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final order = orders[index];
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ORDER #${order.id.split('_').last}',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                  _buildStatusBadge(order.status),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.amber.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.amber,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.clientName,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        order.fabricType ?? 'Fabric Order',
                        style: TextStyle(color: colors.textMuted, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (order.fabricType != null) ...[
                Row(
                  children: [
                    _buildInfoChip(context, 'Fabric', order.fabricType!),
                    const SizedBox(width: 8),
                    if (order.fabricColor != null)
                      _buildInfoChip(context, 'Color', order.fabricColor!),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              Text(
                '\u20A6${order.totalAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  color: AppColors.amber,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              if (order.trackingUrl != null) ...[
                const Text(
                  'DISPATCH ACTIVE',
                  style: TextStyle(
                    color: AppColors.successGreen,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                UberTrackingMap(trackingUrl: order.trackingUrl!),
              ] else
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _arrangePickup(context, ref, order, sellerId),
                    icon: const Icon(Icons.local_shipping_rounded, size: 18),
                    label: const Text('ARRANGE PICKUP'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: AppColors.darkNavy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, String value) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceHover,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _arrangePickup(
    BuildContext context,
    WidgetRef ref,
    OrderEntity order,
    String sellerId,
  ) async {
    final colors = context.colors;
    // Show pickup details dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'ARRANGE PICKUP',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order #${order.id.split('_').last}',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Text(
              'Pickup details will be sent to the buyer. Confirm to arrange logistics.',
              style: TextStyle(color: colors.textMuted, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: AppColors.darkNavy,
            ),
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      try {
        final usecase = ref.read(updateOrderStatusUsecaseProvider);
        await usecase(order.id, OrderStatus.inProgress);
        ref.invalidate(ordersProvider(null));

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PICKUP ARRANGED'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to arrange pickup: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color color;
    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        break;
      case OrderStatus.inProgress:
        color = Colors.blueAccent;
        break;
      case OrderStatus.delivered:
        color = AppColors.successGreen;
        break;
      default:
        color = AppColors.amber;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
