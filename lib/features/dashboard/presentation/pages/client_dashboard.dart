import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/presentation/providers/order_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../theme/colors.dart';
import '../../../tailor/presentation/pages/tailor_discovery_page.dart';

class ClientDashboard extends ConsumerStatefulWidget {
  const ClientDashboard({super.key});

  @override
  ConsumerState<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends ConsumerState<ClientDashboard> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser?.id ?? '';

    // Guard: Use null status to fetch all orders (provider expects OrderStatus?, not userId)
    final ordersAsync = ref.watch(ordersProvider(null));

    // Note: Desktop shell is handled by MainPage on desktop
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(currentUser?.name),
              const SizedBox(height: 24),
              _buildStatsGrid(),
              const SizedBox(height: 32),
              _buildSectionHeader(context, 'Track My Garments', () {}),
              const SizedBox(height: 16),
              ordersAsync.when(
                data: (orders) => _buildOrdersList(orders),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => const ErrorStateWidget(message: 'Failed to sync orders.'),
              ),
              const SizedBox(height: 32),
              _buildSectionHeader(context, 'Design Portfolio', () {}),
              const SizedBox(height: 16),
              _buildDesignPortfolio(),
              const SizedBox(height: 32),
              _buildSectionHeader(context, 'Saved Measurements', () {}),
              const SizedBox(height: 16),
              _buildMeasurementSummary(),
              const SizedBox(height: 40),
            ],
          ),
      ),
    );
  }

  Widget _buildHeader(String? name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bespoke Style, ${name ?? 'Client'}!',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        Text('Elegance is an attitude.', style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 20),
        // UBER-STYLE: Find Tailor Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _findTailor(context),
            icon: const Icon(Icons.search),
            label: const Text('Find a Tailor'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: AppColors.darkNavy,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  // UBER-STYLE: Find Tailor navigation
  void _findTailor(BuildContext context) {
    Navigator.pushNamed(context, '/tailor-discovery');
  }

  Widget _buildStatsGrid() {
    final currentUser = ref.watch(currentUserProvider);
    final profileAsync = currentUser != null ? ref.watch(userProfileProvider(currentUser.id)) : null;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildMTNStatCard(
          title: 'My Orders',
          value: '2',
          icon: Icons.shopping_bag_outlined,
          color: Colors.blue,
        ),
        profileAsync?.when(
          data: (p) => _buildMTNStatCard(
            title: 'Loyalty Points',
            value: '${p?.loyaltyPoints ?? 0}',
            icon: Icons.star_outline,
            color: AppColors.amber,
          ),
          loading: () => _buildMTNStatCard(title: 'Points', value: '...', icon: Icons.star_outline, color: AppColors.amber),
          error: (_, __) => _buildMTNStatCard(title: 'Points', value: '0', icon: Icons.star_outline, color: AppColors.amber),
        ) ?? _buildMTNStatCard(title: 'Points', value: '0', icon: Icons.star_outline, color: AppColors.amber),
      ],
    );
  }

  Widget _buildMTNStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

Widget _buildOrdersList(List<dynamic> orders) {
    if (orders.isEmpty) return const Center(child: Text('No orders in progress'));
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        // Handle both Map and dynamic object access for safety
        final order = orders[index];
        final Map<String, dynamic>? orderMap = order is Map ? Map<String, dynamic>.from(order) : null;
        final String? fezNo = orderMap?['fezOrderNo'] as String?;
        final String status = orderMap?['status']?.toString() ?? 'pending';
        final String garmentType = orderMap?['garmentType']?.toString() ?? 'Garment Order';

        return GestureDetector(
          onTap: () {
            if (fezNo != null) {
              Navigator.pushNamed(context, '/delivery-tracking', arguments: fezNo);
            }
          },
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.darkNavy, child: Icon(Icons.checkroom, color: Colors.white, size: 20)),
              title: Text(garmentType, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Status: ${status.toUpperCase()}'),
              trailing: Icon(fezNo != null ? Icons.location_on_rounded : Icons.chevron_right, color: fezNo != null ? AppColors.amber : Colors.grey, size: 16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesignPortfolio() {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return Container(
            width: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              image: const DecorationImage(
                image: AssetImage('assets/images/logo.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                ),
              ),
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.all(8),
              child: const Text('Silk Gown', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMeasurementSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkNavy,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.straighten, color: AppColors.amber),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Body Measurements', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('8 metrics updated 2 days ago', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: () {},
            child: const Text('View', style: TextStyle(color: AppColors.amber)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        TextButton(onPressed: onSeeAll, child: const Text('See All')),
      ],
    );
  }
}
