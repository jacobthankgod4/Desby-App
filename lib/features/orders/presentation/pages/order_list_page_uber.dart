import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/uber_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/tracking_progress.dart';
import '../../../../theme/colors.dart';
import '../../domain/entities/order.dart';
import '../providers/order_provider.dart';

/// OrderListPageUber - Ultra-modern Desby-style orders dashboard
/// Uses Desby brand theme (Dark Navy + Amber)
class OrderListPageUber extends ConsumerStatefulWidget {
  const OrderListPageUber({super.key});

  @override
  ConsumerState<OrderListPageUber> createState() => _OrderListPageUberState();
}

class _OrderListPageUberState extends ConsumerState<OrderListPageUber>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _filterChips = ['All', 'Active', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filterChips.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: Column(
        children: [
          // Custom App Bar
          _buildAppBar(),
          // Tab Filter
          _buildFilterTabs(),
          // Orders List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _filterChips
                  .map((filter) => _buildOrderList(filter))
                  .toList(),
            ),
          ),
        ],
      ),
// No FAB - new orders created via other flows
      // floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        bottom: 16,
      ),
      child: Row(
        children: [
          // Title
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ORDERS',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Real-time logistics dashboard',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Notification
          _buildIconButton(Icons.notifications_outlined),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.amber,
          borderRadius: BorderRadius.circular(20),
        ),
        labelColor: AppColors.darkNavy,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        tabs: _filterChips
            .map((chip) => Tab(text: chip.toUpperCase()))
            .toList(),
      ),
    );
  }

  Widget _buildOrderList(String filter) {
    // Map filter to status
    OrderStatus? statusFilter;
    if (filter == 'Active') {
      statusFilter = OrderStatus.inProgress;
    } else if (filter == 'Completed') {
      statusFilter = OrderStatus.delivered;
    } else if (filter == 'Cancelled') {
      statusFilter = OrderStatus.cancelled;
    }

    final ordersAsync = ref.watch(ordersProvider(statusFilter));

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return _emptyState(filter);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _UberOrderCard(
                order: orders[index],
                onTap: () => _openOrderDetail(orders[index].id),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.amber),
      ),
      error: (err, _) => _errorState(err.toString()),
    );
  }

  Widget _emptyState(String filter) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              filter == 'All'
                  ? Icons.shopping_bag_outlined
                  : Icons.inbox_outlined,
              size: 36,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No ${filter.toLowerCase()} orders',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your orders will appear here',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          const Text(
            'Unable to load orders',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

Widget _buildIconButton(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      margin: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.textPrimary, size: 20),
    );
  }

  // FAB removed - new orders created via other flows (Add Client -> Create Order)

  void _openOrderDetail(String orderId) {
    Navigator.pushNamed(context, '/order-detail', arguments: orderId);
  }
}

/// _UberOrderCard - Modern order card with progress
class _UberOrderCard extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback onTap;

  const _UberOrderCard({
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DesbyCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Order ID
                    Text(
                      '#${order.id.toUpperCase()}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    // Status pill
                    StatusPill(
                      status: order.status.displayName,
                      isLive: _isActiveOrder(order.status),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Client & Location
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.amber,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.clientName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  order.deliveryAddress ?? 'Location TBD',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₦${order.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.amber,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${order.items.length} items',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Progress Bar (only for active orders)
          if (_isActiveOrder(order.status))
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  CompactProgressBar(
                    progress: _getProgress(order.status),
                    color: _getStatusColor(order.status),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getStatusLabel(order.status),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '~${_getETAMinutes(order.status)} min',
                        style: const TextStyle(
                          color: AppColors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool _isActiveOrder(OrderStatus status) {
    return status == OrderStatus.pending ||
        status == OrderStatus.bookingAccepted ||
        status == OrderStatus.materialsInTransit ||
        status == OrderStatus.inProgress;
  }

  double _getProgress(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 0.1;
      case OrderStatus.bookingAccepted:
        return 0.3;
      case OrderStatus.materialsInTransit:
        return 0.5;
      case OrderStatus.inProgress:
        return 0.7;
      case OrderStatus.ready:
        return 0.9;
      case OrderStatus.delivered:
        return 1.0;
      default:
        return 0.0;
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.uberWarning;
      case OrderStatus.bookingAccepted:
        return AppColors.uberInfo;
      case OrderStatus.materialsInTransit:
      case OrderStatus.inProgress:
        return AppColors.amber;
      case OrderStatus.ready:
        return AppColors.uberLive;
      default:
        return AppColors.success;
    }
  }

  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Awaiting acceptance';
      case OrderStatus.bookingAccepted:
        return 'Materials being gathered';
      case OrderStatus.materialsInTransit:
        return 'On the way';
      case OrderStatus.inProgress:
        return 'Being crafted';
      case OrderStatus.ready:
        return 'Ready for pickup';
      default:
        return status.displayName;
    }
  }

  int _getETAMinutes(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 30;
      case OrderStatus.bookingAccepted:
        return 45;
      case OrderStatus.materialsInTransit:
        return 25;
      case OrderStatus.inProgress:
        return 15;
      case OrderStatus.ready:
        return 5;
      default:
        return 0;
    }
  }
}
