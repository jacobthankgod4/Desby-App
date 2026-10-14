import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/luxury_stat_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/presentation/providers/order_provider.dart';
import '../../../orders/presentation/providers/logistics_provider.dart';
import '../../../apprenticeship/presentation/providers/apprenticeship_provider.dart';
import '../../../apprenticeship/domain/entities/apprenticeship.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../../../core/widgets/animated_entry.dart';
import '../../../../core/widgets/dashboard_shimmer.dart';
import '../../../../theme/colors.dart';
import '../../../../core/providers/navigation_provider.dart';

class TailorDashboard extends ConsumerStatefulWidget {
  const TailorDashboard({super.key});

  @override
  ConsumerState<TailorDashboard> createState() => _TailorDashboardState();
}

class _TailorDashboardState extends ConsumerState<TailorDashboard> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser?.id ?? '';

    if (userId.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.amber),
      );
    }

    final statsAsync = ref.watch(dashboardStatsProvider(userId));
    final recentOrdersAsync = ref.watch(recentOrdersProvider(userId));
    final recentClientsAsync = ref.watch(recentClientsProvider(userId));

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider(userId));
          ref.invalidate(recentOrdersProvider(userId));
          ref.invalidate(recentClientsProvider(userId));
        },
        color: AppColors.amber,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedEntry(index: 0, child: _buildHeader(currentUser?.name)),
              const SizedBox(height: 24),

              statsAsync.when(
                data: (stats) => Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedEntry(
                            index: 1,
                            child: LuxuryStatCard(
                              title: 'Active Orders',
                              value: stats.pendingOrders.toString(),
                              icon: Icons.description_rounded,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AnimatedEntry(
                            index: 2,
                            child: LuxuryStatCard(
                              title: 'Net Revenue',
                              value: '₦${stats.totalRevenue.toInt()}',
                              icon: Icons.payments_rounded,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedEntry(
                            index: 3,
                            child: LuxuryStatCard(
                              title: 'Total Bookings',
                              value: stats.totalClients.toString(),
                              icon: Icons.handshake_rounded,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AnimatedEntry(
                            index: 4,
                            child: LuxuryStatCard(
                              title: 'Urgent Alerts',
                              value: stats.urgentDeadlines.toString(),
                              icon: Icons.bolt_rounded,
                              color: Colors.redAccent,
                              isPositiveTrend: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                loading: () => DashboardShimmer(statCount: 4, listCount: 2),
                error: (error, _) =>
                    _buildStatsErrorPlaceholder('Could not load stats', userId),
              ),
              const SizedBox(height: 32),

              AnimatedEntry(
                index: 5,
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AnimatedEntry(index: 6, child: _buildOperationsGrid()),

              const SizedBox(height: 32),

              AnimatedEntry(
                index: 11,
                child: _buildSectionHeader(context, 'Your Academy', '/academy'),
              ),
              const SizedBox(height: 16),
              AnimatedEntry(
                index: 12,
                child: _buildApprenticeshipSection(userId),
              ),

              const SizedBox(height: 32),

              AnimatedEntry(
                index: 7,
                child: _buildSectionHeader(context, 'Recent Orders', '/orders'),
              ),
              const SizedBox(height: 16),
              recentOrdersAsync.when(
                data: (orders) => AnimatedEntry(
                  index: 8,
                  child: _buildOrdersManifest(orders),
                ),
                loading: () => DashboardShimmer(listCount: 2),
                error: (err, _) => _buildEmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'SYNC ERROR',
                  subtitle: 'Could not load orders. Pull down to retry.',
                ),
              ),

              const SizedBox(height: 32),

              AnimatedEntry(
                index: 9,
                child: _buildSectionHeader(context, 'Your Clients', '/clients'),
              ),
              const SizedBox(height: 16),
              recentClientsAsync.when(
                data: (clients) => AnimatedEntry(
                  index: 10,
                  child: _buildClientsStrip(clients),
                ),
                loading: () => const SizedBox(
                  height: 90,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.amber,
                    ),
                  ),
                ),
                error: (err, _) => const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String? name) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Welcome, ${name ?? 'Designer'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.successGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.successGreen.withValues(alpha: 0.2),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.shield_moon_rounded,
                color: AppColors.successGreen,
                size: 14,
              ),
              SizedBox(width: 8),
              Text(
                'Protected',
                style: TextStyle(
                  color: AppColors.successGreen,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsErrorPlaceholder(String error, String userId) {
    final colors = context.colors;
    return LuxuryGlassCard(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.cloud_off_rounded, color: colors.textMuted, size: 32),
            const SizedBox(height: 12),
            Text(
              'SYNC ERROR',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Could not load stats',
              style: TextStyle(color: colors.textMuted, fontSize: 9),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => ref.invalidate(dashboardStatsProvider(userId)),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.amber,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'RETRY',
                  style: TextStyle(
                    color: AppColors.darkNavy,
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationsGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossCount = screenWidth < 600 ? 3 : 5;
    return GridView.count(
      crossAxisCount: crossCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      // Portrait-biased: the artwork is the point of these tiles now, so the
      // old square-ish 1.0/1.1 left a small image floating in dead space.
      childAspectRatio: crossCount == 3 ? 0.82 : 0.9,
      children: [
        _buildOpTile(
          'assets/cards/client.webp',
          'Client',
          () => ref.setShell('/unified-add-client'),
        ),
        _buildOpTile(
          'assets/cards/orders.webp',
          'Orders',
          () => ref.setShell('/orders'),
        ),
        _buildOpTile(
          'assets/cards/body_scan.webp',
          'Body Scan',
          () => ref.setShell('/ai-body-scan'),
        ),
        _buildOpTile(
          'assets/cards/shop.webp',
          'Shop',
          () => ref.setShell('/virtual-atelier'),
        ),
        _buildOpTile(
          'assets/cards/try_on.webp',
          'Try-On',
          () => ref.setShell('/tailor-tryon'),
        ),
        _buildOpTile(
          'assets/cards/insights.webp',
          'Insights',
          () => ref.setShell('/insights'),
        ),
      ],
    );
  }

  Widget _buildOpTile(String asset, String label, VoidCallback onTap) {
    return _OpTile(asset: asset, label: label, onTap: onTap);
  }

  Widget _buildApprenticeshipSection(String tailorId) {
    final apprenticeshipsAsync = ref.watch(
      tailorApprenticeshipsProvider(tailorId),
    );
    return apprenticeshipsAsync.when(
      data: (apprenticeships) {
        if (apprenticeships.isEmpty) {
          return _buildEmptyState(
            icon: Icons.school_outlined,
            title: 'No apprentices yet',
            subtitle: 'Invite your first apprentice',
            actionLabel: 'INVITE APPRENTICE',
            onAction: () => ref.pushShell('/unified-add-apprentice'),
          );
        }
        final pendingCount = apprenticeships
            .where(
              (a) => a.status == ApprenticeshipStatus.awaitingMasterApproval,
            )
            .length;
        final activeCount = apprenticeships
            .where((a) => a.status == ApprenticeshipStatus.active)
            .length;
        final avgProgress = activeCount > 0
            ? apprenticeships
                      .where((a) => a.status == ApprenticeshipStatus.active)
                      .fold(0.0, (sum, a) => sum + a.progress) /
                  activeCount
            : 0.0;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: LuxuryStatCard(
                    title: 'Active Apprentices',
                    value: activeCount.toString(),
                    icon: Icons.school_rounded,
                    color: AppColors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LuxuryStatCard(
                    title: 'Pending Reviews',
                    value: pendingCount.toString(),
                    icon: Icons.pending_actions_rounded,
                    color: Colors.orangeAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LuxuryStatCard(
                    title: 'Avg Progress',
                    value: '${(avgProgress * 100).toInt()}%',
                    icon: Icons.trending_up_rounded,
                    color: Colors.greenAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LuxuryStatCard(
                    title: 'Total Enrolled',
                    value: apprenticeships.length.toString(),
                    icon: Icons.groups_rounded,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.amber,
          ),
        ),
      ),
      error: (err, _) => const SizedBox(),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String route) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: colors.textMuted,
          ),
        ),
        GestureDetector(
          onTap: () => ref.setShell(route),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'View All',
              style: TextStyle(
                color: AppColors.amber,
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersManifest(List<dynamic> orders) {
    if (orders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long_rounded,
        title: 'NO PENDING ORDERS',
        subtitle: 'No pending orders',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length > 3 ? 3 : orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        final status = order['status'] ?? 'pending';
        final isPending = status == 'pending';

        return _OrderCard(
          order: order,
          isPending: isPending,
          onAccept: () => _handleHandshake(order, true),
          onReject: () => _handleHandshake(order, false),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final colors = context.colors;
    return LuxuryGlassCard(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: colors.textMuted, size: 36),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: colors.textMuted,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: colors.textMuted, fontSize: 10),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.amber,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      color: AppColors.darkNavy,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<OrderItem> _parseOrderItems(dynamic rawItems) {
    if (rawItems is! List) return const [];

    return rawItems.whereType<Map>().map((rawItem) {
      final item = Map<String, dynamic>.from(rawItem);
      final rawMeasurements = item['measurements'];
      return OrderItem(
        id: item['id']?.toString() ?? '',
        garmentType:
            item['garmentType']?.toString() ??
            item['garment_type']?.toString() ??
            'Custom order',
        designId: item['designId']?.toString() ?? item['design_id']?.toString(),
        measurements: rawMeasurements is Map
            ? Map<String, dynamic>.from(rawMeasurements)
            : null,
        price:
            (item['price'] as num?)?.toDouble() ??
            double.tryParse(item['price']?.toString() ?? '') ??
            0.0,
      );
    }).toList();
  }

  Future<void> _handleHandshake(
    Map<String, dynamic> order,
    bool accepted,
  ) async {
    if (!accepted) return;

    try {
      final orderId = order['id']?.toString() ?? '';
      if (orderId.isEmpty) {
        throw StateError('Order id is missing');
      }

      final usecase = ref.read(updateOrderStatusUsecaseProvider);
      final statusResult = await usecase(orderId, OrderStatus.bookingAccepted);
      final statusFailure = statusResult.getFailureOrNull()?.failure;
      if (statusFailure != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Booking could not be confirmed: ${statusFailure.message}',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking confirmed'),
          backgroundColor: Colors.greenAccent,
        ),
      );

      final requiresDispatch =
          order['requiresDispatch'] == true || order['deliveryAddress'] != null;
      if (requiresDispatch) {
        final rawDeliveryAddress =
            order['deliveryAddress'] ?? order['delivery_address'];
        final rawMetadata = order['metadata'];
        final orderEntity = OrderEntity(
          id: orderId,
          // client_id is the tailor's customer record and may legitimately be
          // null; requester is separate. Never coerce a missing value to ''.
          clientId:
              order['clientId']?.toString() ?? order['client_id']?.toString(),
          requestingUserId: order['requestingUserId']?.toString() ??
              order['requesting_user_id']?.toString(),
          reference: order['reference']?.toString(),
          clientName:
              order['clientName']?.toString() ??
              order['client_name']?.toString() ??
              'Unknown',
          items: _parseOrderItems(order['items']),
          status: OrderStatus.bookingAccepted,
          totalAmount:
              (order['totalAmount'] as num?)?.toDouble() ??
              (order['total_amount'] as num?)?.toDouble() ??
              0.0,
          // due_date is nullable: the tailor confirms the timeline. Inventing
          // "now" made every undated order look due immediately.
          dueDate: DateTime.tryParse(
            order['dueDate']?.toString() ?? order['due_date']?.toString() ?? '',
          ),
          createdAt:
              DateTime.tryParse(
                order['createdAt']?.toString() ??
                    order['created_at']?.toString() ??
                    '',
              ) ??
              DateTime.now(),
          requiresDispatch: true,
          deliveryAddress: rawDeliveryAddress?.toString(),
          metadata: rawMetadata is Map
              ? Map<String, dynamic>.from(rawMetadata)
              : null,
        );

        try {
          final result = await ref
              .read(logisticsRepositoryProvider)
              .summonRider(orderEntity);
          if (!mounted) return;
          result.fold(
            (failure) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Dispatch could not be arranged: ${failure.message}',
                ),
                backgroundColor: Colors.orangeAccent,
              ),
            ),
            (waybill) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Fabric pickup rider assigned — waybill $waybill',
                ),
                backgroundColor: Colors.greenAccent,
              ),
            ),
          );
        } catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Dispatch could not be arranged: $error'),
                backgroundColor: Colors.orangeAccent,
              ),
            );
          }
        }
      }

      final userId = ref.read(currentUserProvider)?.id ?? '';
      ref.invalidate(recentOrdersProvider(userId));
      // Scope to the unfiltered instance: invalidating the whole family drops
      // the cache for every status tab and every client-facing orders list,
      // which turns one booking into a page-wide refetch.
      ref.invalidate(ordersProvider(null));
      ref.invalidate(dashboardStatsProvider(userId));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking confirmation failed: $error'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildClientsStrip(List<dynamic> clients) {
    if (clients.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_rounded,
        title: 'No clients yet',
        subtitle: 'Add your first client to get started',
        actionLabel: 'ADD A CLIENT',
        onAction: () => ref.pushShell('/unified-add-client'),
      );
    }
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: clients.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final client = clients[index];
          final String name = client['name']?.toString() ?? 'T';

          return _ClientAvatar(name: name);
        },
      ),
    );
  }
}

class _OpTile extends StatefulWidget {
  final String asset;
  final String label;
  final VoidCallback onTap;

  const _OpTile({required this.asset, required this.label, required this.onTap});

  @override
  State<_OpTile> createState() => _OpTileState();
}

class _OpTileState extends State<_OpTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: _isPressed
                ? AppColors.amber.withValues(alpha: 0.08)
                : colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isPressed
                  ? AppColors.amber.withValues(alpha: 0.2)
                  : colors.borderSubtle,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Fill the tile rather than sitting a fixed-size glyph in it.
              // Expanded so the artwork absorbs whatever height the grid gives
              // the tile, which keeps it large on both the 3-up mobile layout
              // and the 5-up desktop layout.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
                  child: Image.asset(
                    widget.asset,
                    fit: BoxFit.contain,
                    // These are 512px WebP under 50 KB, sized for 3x density.
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (context, error, stack) => const SizedBox.shrink(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 10),
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool isPending;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _OrderCard({
    required this.order,
    required this.isPending,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return LuxuryGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.checkroom_rounded,
                  color: AppColors.amber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['clientName']?.toString() ?? 'Unknown Client',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Order #${order['id'].toString().substring(0, 8).toUpperCase()}',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(
                status: isPending
                    ? OrderStatus.pending
                    : OrderStatus.inProgress,
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.borderSubtle),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      'REJECT',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: AppColors.darkNavy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'ACCEPT',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ClientAvatar extends StatefulWidget {
  final String name;
  const _ClientAvatar({required this.name});

  @override
  State<_ClientAvatar> createState() => _ClientAvatarState();
}

class _ClientAvatarState extends State<_ClientAvatar> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isHovered
                      ? AppColors.amber
                      : AppColors.amber.withValues(alpha: 0.2),
                  width: _isHovered ? 2.0 : 1.5,
                ),
                color: _isHovered
                    ? AppColors.amber.withValues(alpha: 0.08)
                    : colors.surface,
              ),
              child: Center(
                child: Text(
                  widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.amber,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.name.split(' ').first.toUpperCase(),
              style: TextStyle(
                fontSize: 8,
                color: colors.textMuted,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = status == OrderStatus.pending
        ? Colors.orange
        : AppColors.amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 7,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
