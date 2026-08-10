import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/luxury_stat_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/presentation/providers/logistics_provider.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
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
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser?.id ?? '';

    // If no userId, we are likely in a transitional auth state - show loader
    if (userId.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.amber));
    }

    final statsAsync = ref.watch(dashboardStatsProvider(userId));
    final recentOrdersAsync = ref.watch(recentOrdersProvider(userId));
    final recentClientsAsync = ref.watch(recentClientsProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
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
              // 1. NEURAL WELCOME HUD
              _buildHeader(currentUser?.name),
              const SizedBox(height: 24),
            
              // 2. INDUSTRIALIZED STATS GRID
              statsAsync.when(
                data: (stats) => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    LuxuryStatCard(title: 'Active Orders', value: stats.pendingOrders.toString(), icon: Icons.description_rounded, trend: '+12%'),
                    LuxuryStatCard(title: 'Net Revenue', value: '₦${stats.totalRevenue.toInt()}', icon: Icons.payments_rounded, color: Colors.greenAccent),
                    LuxuryStatCard(title: 'Total Bookings', value: stats.totalClients.toString(), icon: Icons.handshake_rounded, color: Colors.blueAccent),
                    LuxuryStatCard(title: 'Urgent Alerts', value: stats.urgentDeadlines.toString(), icon: Icons.bolt_rounded, color: Colors.redAccent),
                  ],
                ),
                loading: () => _buildStatsLoadingPlaceholder(),
                error: (error, _) => _buildStatsErrorPlaceholder(error.toString()),
              ),
              const SizedBox(height: 32),

              // 3. RAPID OPERATION TILES
              const Text('RAPID OPERATIONS', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 16),
              _buildOperationsGrid(),
              
              const SizedBox(height: 32),

              // 4. PENDING BOOKING MANIFESTS
              _buildSectionHeader(context, 'Pipeline Handshakes', '/orders'),
              const SizedBox(height: 16),
              recentOrdersAsync.when(
                data: (orders) => _buildOrdersManifest(orders),
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2)),
                error: (err, _) => Center(child: Text('Manifest sync offline.', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 10))),
              ),
              
              const SizedBox(height: 32),

              // 5. CLIENT PORTFOLIO
              _buildSectionHeader(context, 'Elite Clients', '/clients'),
              const SizedBox(height: 16),
              recentClientsAsync.when(
                data: (clients) => _buildClientsStrip(clients),
                loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                error: (err, _) => const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String? name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('COMMAND CENTER v2.1', style: TextStyle(color: AppColors.amber, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 4),
            Text(
              'Welcome, ${name ?? 'Designer'}',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF00FF7F).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00FF7F).withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield_moon_rounded, color: Color(0xFF00FF7F), size: 14),
              SizedBox(width: 8),
              Text('SECURE', style: TextStyle(color: Color(0xFF00FF7F), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsLoadingPlaceholder() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: List.generate(4, (index) => const LuxuryGlassCard(child: Center(child: CircularProgressIndicator(strokeWidth: 1, color: Colors.white10)))),
    );
  }

  Widget _buildStatsErrorPlaceholder(String error) {
    return LuxuryGlassCard(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.white10, size: 32),
            const SizedBox(height: 12),
            const Text('DATA SYNC OFFLINE', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(error, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.redAccent, fontSize: 8)),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationsGrid() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: [
        _buildOpTile(Icons.person_add_rounded, 'CLIENT', () => ref.read(navigationProvider.notifier).state = const NavigationState('/unified-add-client')),
        _buildOpTile(Icons.add_shopping_cart_rounded, 'ORDER', () => ref.read(navigationProvider.notifier).state = const NavigationState('/order-create')),
        _buildOpTile(Icons.storefront_rounded, 'SHOP', () => ref.read(navigationProvider.notifier).state = const NavigationState('/virtual-atelier')),
        _buildOpTile(Icons.bar_chart_rounded, 'HUB', () => ref.read(navigationProvider.notifier).state = const NavigationState('/insights')),
      ],
    );
  }

  Widget _buildOpTile(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.amber, size: 20),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String route) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white38)),
        GestureDetector(
          onTap: () {
            ref.read(navigationProvider.notifier).state = NavigationState(route);
          },
          child: const Text('VIEW ALL', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
        ),
      ],
    );
  }

  Widget _buildOrdersManifest(List<dynamic> orders) {
    if (orders.isEmpty) {
      return const LuxuryGlassCard(
        padding: EdgeInsets.all(40),
        child: Center(child: Text('NO PENDING MANIFESTS', style: TextStyle(color: Colors.white10, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2))),
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
        
        return LuxuryGlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.checkroom_rounded, color: AppColors.amber, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order['clientName']?.toString().toUpperCase() ?? 'ANONYMOUS', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                        Text('MANIFEST #${order['id'].toString().substring(0, 8).toUpperCase()}', style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ],
                    ),
                  ),
                  _StatusBadge(status: isPending ? OrderStatus.pending : OrderStatus.inProgress),
                ],
              ),
              if (isPending) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleHandshake(order, false),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('REJECT', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleHandshake(order, true),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: AppColors.darkNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                        child: const Text('ACCEPT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleHandshake(Map<String, dynamic> order, bool accepted) async {
    if (accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('BOOKING ACCEPTED. CALIBRATING LOGISTICS...'), backgroundColor: Colors.greenAccent),
      );
      try {
        final orderEntity = OrderEntity(
          id: order['id'],
          clientId: order['clientId'] ?? '',
          clientName: order['clientName'] ?? 'Unknown',
          items: const [], 
          status: OrderStatus.bookingAccepted,
          totalAmount: (order['totalAmount'] as num?)?.toDouble() ?? 0.0,
          dueDate: DateTime.now(),
          createdAt: DateTime.now(),
        );
        await ref.read(logisticsRepositoryProvider).summonRider(orderEntity);
        ref.invalidate(recentOrdersProvider(ref.read(currentUserProvider)?.id ?? ''));
      } catch (e) {
        debugPrint('Handshake Error: $e');
      }
    }
  }

  Widget _buildClientsStrip(List<dynamic> clients) {
    if (clients.isEmpty) return const SizedBox();
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: clients.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final client = clients[index];
          final String name = client['name']?.toString() ?? 'T';
          
          return Column(
            children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.amber.withValues(alpha: 0.2), width: 1.5),
                  color: Colors.white.withValues(alpha: 0.03),
                ),
                child: Center(child: Text(name[0].toUpperCase(), style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900, fontSize: 18))),
              ),
              const SizedBox(height: 8),
              Text(name.split(' ').first.toUpperCase(), style: const TextStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ],
          );
        },
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = status == OrderStatus.pending ? Colors.orange : AppColors.amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text(status.name.toUpperCase(), style: TextStyle(color: color, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }
}
