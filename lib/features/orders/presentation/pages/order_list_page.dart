import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/order_provider.dart';
import '../../domain/entities/order.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../../../core/widgets/shell_app_bar.dart';

class OrderListPage extends ConsumerStatefulWidget {
  const OrderListPage({super.key});

  @override
  ConsumerState<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends ConsumerState<OrderListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: OrderStatus.values.length + 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(
        context,
        title: 'Orders',
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.amber,
          unselectedLabelColor: colors.textMuted,
          indicatorColor: AppColors.amber,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
          tabs: [
            const Tab(text: 'All Orders'),
            ...OrderStatus.values.map(
              (status) => Tab(text: status.displayName.toUpperCase()),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _OrderList(status: null),
          ...OrderStatus.values.map((status) => _OrderList(status: status)),
        ],
      ),
    );
  }
}

class _OrderList extends ConsumerWidget {
  final OrderStatus? status;
  const _OrderList({this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider(status));

    return ordersAsync.when(
      data: (orders) => orders.isEmpty
          ? _buildEmptyState(context)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final order = orders[index];
                return _OrderCard(order: order);
              },
            ),
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppColors.amber,
          strokeWidth: 2,
        ),
      ),
      error: (err, _) => const ErrorStateWidget(
        message: 'Could not load orders. Tap to retry.',
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checkroom_outlined, size: 64, color: colors.borderSubtle),
          const SizedBox(height: 24),
          Text(
            'No orders yet',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderEntity order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return LuxuryGlassCard(
      padding: const EdgeInsets.all(20),
      child: Consumer(
        builder: (context, ref, child) => InkWell(
          onTap: () => ref.pushShell('/order-detail', {'orderId': order.id}),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id.substring(0, 8).toUpperCase()}',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.clientName.toUpperCase(),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  _StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: colors.divider, height: 1),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoBit(
                    context,
                    'Items',
                    order.items.length.toString(),
                  ),
                  _buildInfoBit(
                    context,
                    'DUE DATE',
                    // due_date is nullable in the DB: the tailor confirms the
                    // timeline. Never invent one, and never crash on a missing
                    // date — this threw before and took the whole list with it.
                    order.dueDate == null
                        ? 'To confirm'
                        : '${order.dueDate!.day}/${order.dueDate!.month}',
                  ),
                  _buildInfoBit(
                    context,
                    'VALUE',
                    '₦${order.totalAmount.toStringAsFixed(0)}',
                  ),
                ],
              ),
              if (order.requiresDispatch) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.amber.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_shipping_outlined,
                        color: AppColors.amber,
                        size: 14,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Delivery Active',
                        style: TextStyle(
                          color: AppColors.amber,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        order.shipmentId ?? 'Awaiting pickup',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBit(BuildContext context, String label, String value) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 7,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Color color;
    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        break;
      case OrderStatus.bookingAccepted:
        color = Colors.greenAccent;
        break;
      case OrderStatus.materialsInTransit:
        color = Colors.blueAccent;
        break;
      case OrderStatus.inProgress:
        color = AppColors.amber;
        break;
      case OrderStatus.ready:
        color = Colors.green;
        break;
      case OrderStatus.delivered:
        color = colors.textMuted;
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        break;
      case OrderStatus.paid:
        color = Colors.greenAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
