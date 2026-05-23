import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/order_provider.dart';
import '../../domain/entities/order.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/error_state_widget.dart';

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
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.amber,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.amber,
            tabs: [
              const Tab(text: 'All'),
              ...OrderStatus.values.map((status) => Tab(text: status.displayName)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const _OrderList(status: null),
                ...OrderStatus.values.map((status) => _OrderList(status: status)),
              ],
            ),
          ),
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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No orders found', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder:  (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  child: ListTile(
                    title: Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Client: ${order.clientName}\nDue: ${order.dueDate.toString().split(' ')[0]}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('\$${order.totalAmount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        _StatusBadge(status: order.status),
                      ],
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/order-detail', arguments: order.id);
                    },
                  ),
                );
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => const ErrorStateWidget(message: 'We could not fetch your orders at this time.'),
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
      case OrderStatus.inProgress: color = Colors.blue; break;
      case OrderStatus.ready: color = Colors.green; break;
      case OrderStatus.delivered: color = Colors.grey; break;
      case OrderStatus.cancelled: color = Colors.red; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
