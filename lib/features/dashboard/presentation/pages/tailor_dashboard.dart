import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/stat_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/presentation/providers/logistics_provider.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../theme/colors.dart';

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

    // Guard: Only fetch if valid userId to prevent red screen errors
    final statsAsync = userId.isNotEmpty ? ref.watch(dashboardStatsProvider(userId)) : const AsyncValue.loading();
    final recentOrdersAsync = userId.isNotEmpty ? ref.watch(recentOrdersProvider(userId)) : const AsyncValue<List<dynamic>>.data([]);
    final recentClientsAsync = userId.isNotEmpty ? ref.watch(recentClientsProvider(userId)) : const AsyncValue<List<dynamic>>.data([]);

    return statsAsync.when(
      data: (stats) => Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. NEURAL WELCOME
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dashboard'.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      Text(
                        'Welcome, ${currentUser?.name ?? 'Designer'}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFF00FF7F).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF00FF7F).withValues(alpha: 0.3))),
                    child: const Row(
                      children: [
                        Icon(Icons.wifi_tethering_rounded, color: Color(0xFF00FF7F), size: 12),
                        SizedBox(width: 8),
                        Text('SYSTEM LIVE', style: TextStyle(color: Color(0xFF00FF7F), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            
// 2. RAPID ACTIONS (MTN STYLE) - Compact 3-column grid
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.35, // Flattened further
                children: [
                  _buildActionCard('Add Client', Icons.person_add_rounded, () => Navigator.pushNamed(context, '/unified-add-client')),
                  _buildActionCard('Active Tasks', Icons.assignment_turned_in_rounded, () => Navigator.pushNamed(context, '/orders')),
                  _buildActionCard('Invite Talent', Icons.school_rounded, () => Navigator.pushNamed(context, '/apprentice-onboarding')),
                  _buildActionCard('Setup Shop', Icons.storefront_rounded, () => Navigator.pushNamed(context, '/shop-setup')),
                  _buildActionCard('Marketplace', Icons.shopping_bag_rounded, () => Navigator.pushNamed(context, '/marketplace')),
                  _buildActionCard('Payments Hub', Icons.account_balance_wallet_rounded, () => Navigator.pushNamed(context, '/insights')),
                ],
              ),
              const SizedBox(height: 20),

              // 3. OPERATIONAL STATS
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.4, // Extremely compact/flat
                children: [
                  StatCard(title: 'Active Orders', value: stats.pendingOrders.toString(), icon: Icons.description_rounded, color: AppColors.amber),
                  StatCard(title: 'Revenue', value: '₦${stats.totalRevenue.toInt()}', icon: Icons.payments_rounded, color: AppColors.amber),
                  StatCard(title: 'Total Bookings', value: stats.totalClients.toString(), icon: Icons.handshake_rounded, color: AppColors.amber),
                  StatCard(title: 'Urgent Alerts', value: stats.urgentDeadlines.toString(), icon: Icons.bolt_rounded, color: AppColors.amber),
                ],
              ),
              const SizedBox(height: 40),

              // 4. HANDSHAKE FLOW (UBER-STYLE)
              _buildSectionHeader(context, 'Pending Bookings', () {}),
              const SizedBox(height: 12),
              recentOrdersAsync.when(
                data: (orders) => _buildOrdersList(orders),
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
                error: (err, _) => const ErrorStateWidget(message: 'Dossier sync failed.'),
              ),
              const SizedBox(height: 40),

              _buildSectionHeader(context, 'Top Clients', () {}),
              const SizedBox(height: 12),
              recentClientsAsync.when(
                data: (clients) => _buildClientsGrid(clients),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => const ErrorStateWidget(message: 'Client sync failed.'),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
      error: (error, _) => const ErrorStateWidget(message: 'Booking request timeout.'),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white38)),
        TextButton(onPressed: onSeeAll, child: const Text('SEE ALL', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900, fontSize: 11))),
      ],
    );
  }

  Widget _buildActionCard(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.08), width: 1.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.amber, size: 18),
            const SizedBox(height: 6),
            Text(label.toUpperCase(), 
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<dynamic> orders) {
    if (orders.isEmpty) return const Center(child: Text('NO ORDERS PENDING', style: TextStyle(color: Colors.white12, fontWeight: FontWeight.w900, fontSize: 16)));
    
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length > 5 ? 5 : orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        final status = order['status'] ?? 'pending';
        final isPending = status == 'pending';
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isPending ? AppColors.amber.withValues(alpha: 0.3) : Colors.white10),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 20, backgroundColor: AppColors.amber.withValues(alpha: 0.1), child: const Icon(Icons.description_rounded, color: AppColors.amber, size: 18)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order['clientName']?.toString().toUpperCase() ?? 'NEW BOOKING', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                        Text('STATUS: ${status.toString().toUpperCase()}', style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  if (!isPending)
                    IconButton(
                      icon: Icon(order['fezOrderNo'] != null ? Icons.location_on_rounded : Icons.arrow_forward_ios_rounded, 
                        color: order['fezOrderNo'] != null ? AppColors.amber : Colors.white10, size: 14),
                      onPressed: () {
                        if (order['fezOrderNo'] != null) {
                          Navigator.pushNamed(context, '/delivery-tracking', arguments: order['fezOrderNo']);
                        }
                      },
                    ),
                ],
              ),
              if (isPending) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => _handleHandshake(order, false),
                        child: const Text('REJECT', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleHandshake(order, true),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: AppColors.darkNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('ACCEPT BOOKING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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
        const SnackBar(content: Text('BOOKING ACCEPTED. SUMMONING FEZ RIDER...'), backgroundColor: Colors.greenAccent),
      );
      
      try {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        
        // Map dynamic map to OrderEntity for the repository
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

        final result = await ref.read(logisticsRepositoryProvider).summonRider(orderEntity);
        
        result.fold(
          (failure) {
            messenger.showSnackBar(
              SnackBar(content: Text('RIDER SUMMON FAILED: ${failure.message}'), backgroundColor: Colors.redAccent),
            );
          },
          (fezOrderNo) {
            messenger.showSnackBar(
              SnackBar(content: Text('FEZ RIDER ON THE WAY! TRACK NO: $fezOrderNo'), backgroundColor: Colors.blueAccent),
            );
            // Refresh dashboard data
            final userId = ref.read(currentUserProvider)?.id ?? '';
            ref.invalidate(recentOrdersProvider(userId));
          },
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('SYSTEM ERROR: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('BOOKING CANCELLED.'), backgroundColor: Colors.redAccent),
      );
      // Logic for cancelling booking in Firestore...
    }
  }

  Widget _buildClientsGrid(List<dynamic> clients) {
    if (clients.isEmpty) return const Center(child: Text('NO CLIENTS YET', style: TextStyle(color: Colors.white12, fontWeight: FontWeight.w900)));
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: clients.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final client = clients[index];
          final String name = client['name']?.toString() ?? 'T';
          final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'T';
          
          return Column(
            children: [
              CircleAvatar(
                radius: 30, 
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                child: Text(initial, style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 8),
              Text(name.toUpperCase(), style: const TextStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ],
          );
        },
      ),
    );
  }
}
