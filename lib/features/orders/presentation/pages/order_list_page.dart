import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/order_provider.dart';
import '../../domain/entities/order.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/luxury_glass_card.dart';

class OrderListPage extends ConsumerStatefulWidget {
  const OrderListPage({super.key});

  @override
  ConsumerState<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends ConsumerState<OrderListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: OrderStatus.values.length + 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1921),
      appBar: AppBar(
        title: const Text('GARMENT PIPELINE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.amber,
          unselectedLabelColor: Colors.white24,
          indicatorColor: AppColors.amber,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
          tabs: [
            const Tab(text: 'ALL MANIFESTS'),
            ...OrderStatus.values.map((status) => Tab(text: status.displayName.toUpperCase())),
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
      floatingActionButton: Consumer(
        builder: (context, ref, child) => FloatingActionButton.extended(
          onPressed: () => ref.read(navigationProvider.notifier).state = const NavigationState('/order-create'),
          backgroundColor: AppColors.amber,
          icon: const Icon(Icons.add_rounded, color: AppColors.darkNavy),
          label: const Text('NEW ORDER', style: TextStyle(color: AppColors.darkNavy, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
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
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final order = orders[index];
                return _OrderCard(order: order);
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2)),
      error: (err, _) => const ErrorStateWidget(message: 'Pipeline sync failed.'),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checkroom_outlined, size: 64, color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 24),
          const Text('PIPELINE CLEAR', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
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
    return LuxuryGlassCard(
      padding: const EdgeInsets.all(20),
      child: Consumer(
        builder: (context, ref, child) => InkWell(
          onTap: () => ref.read(navigationProvider.notifier).state = NavigationState('/order-detail', {'orderId': order.id}),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MANIFEST #${order.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.clientName.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  _StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoBit('GARMENTS', order.items.length.toString()),
                  _buildInfoBit('DUE DATE', '${order.dueDate.day}/${order.dueDate.month}'),
                  _buildInfoBit('VALUE', '₦${order.totalAmount.toStringAsFixed(0)}'),
                ],
              ),
              if (order.requiresDispatch) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.amber.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, color: AppColors.amber, size: 14),
                      const SizedBox(width: 12),
                      const Text(
                        'LOGISTICS ACTIVE',
                        style: TextStyle(color: AppColors.amber, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                      const Spacer(),
                      Text(
                        order.fezOrderNo ?? 'PENDING UBER',
                        style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w700),
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

  Widget _buildInfoBit(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case OrderStatus.pending: color = Colors.orange; break;
      case OrderStatus.bookingAccepted: color = Colors.greenAccent; break;
      case OrderStatus.materialsInTransit: color = Colors.blueAccent; break;
      case OrderStatus.inProgress: color = AppColors.amber; break;
      case OrderStatus.ready: color = Colors.green; break;
      case OrderStatus.delivered: color = Colors.grey; break;
      case OrderStatus.cancelled: color = Colors.red; break;
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
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }
}
