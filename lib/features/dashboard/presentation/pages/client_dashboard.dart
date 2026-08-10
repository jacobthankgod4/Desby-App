import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:desby_app/features/orders/presentation/providers/order_provider.dart';
import 'package:desby_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:desby_app/core/widgets/error_state_widget.dart';
import 'package:desby_app/core/widgets/luxury_glass_card.dart';
import 'package:desby_app/theme/colors.dart';
import 'package:desby_app/features/dashboard/presentation/widgets/luxury_stat_card.dart';
import 'package:desby_app/core/providers/navigation_provider.dart';

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
    final ordersAsync = ref.watch(ordersProvider(null));
    final profileAsync = userId.isNotEmpty ? ref.watch(userProfileProvider(userId)) : null;

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(currentUser?.name),
              const SizedBox(height: 32),
              
              // 1. STYLE & LOYALTY HUD
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  LuxuryStatCard(title: 'Active Suits', value: '03', icon: Icons.checkroom_rounded),
                  profileAsync?.when(
                    data: (p) => LuxuryStatCard(title: 'Style Points', value: '${p?.loyaltyPoints ?? 0}', icon: Icons.auto_awesome_rounded, color: Colors.purpleAccent),
                    loading: () => const LuxuryStatCard(title: '...', value: '...', icon: Icons.auto_awesome_rounded),
                    error: (_, __) => const LuxuryStatCard(title: 'Points', value: '0', icon: Icons.auto_awesome_rounded),
                  ) ?? const LuxuryStatCard(title: 'Points', value: '0', icon: Icons.auto_awesome_rounded),
                ],
              ),
              const SizedBox(height: 32),

              // 2. FITTING STATION HUB (Upgraded from Neural Scan)
              _buildFittingStationCard(),
              const SizedBox(height: 32),

              // 3. ACTIVE GARMENT TRACKER
              _buildSectionHeader('In Production', '/orders'),
              const SizedBox(height: 16),
              ordersAsync.when(
                data: (orders) => _buildOrdersManifest(orders),
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (error, _) => const ErrorStateWidget(message: 'Failed to sync manifests.'),
              ),
              
              const SizedBox(height: 32),

              // 4. STYLE INSPO / CATALOG
              _buildSectionHeader('Trending Silhouettes', '/marketplace'),
              const SizedBox(height: 16),
              _buildStyleCatalog(),
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
        const Text('ATELIER ACCESS', style: TextStyle(color: AppColors.amber, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 4),
        Text(
          'Elegance, ${name ?? 'Client'}',
          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => ref.read(navigationProvider.notifier).state = const NavigationState('/tailor-discovery'),
          icon: const Icon(Icons.architecture_rounded, size: 18),
          label: const Text('COMMISSION A DESIGNER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.amber,
            foregroundColor: AppColors.darkNavy,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildFittingStationCard() {
    return InkWell(
      onTap: () => ref.read(navigationProvider.notifier).state = const NavigationState('/measurements-hub'),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Image.asset(
                  'assets/images/african-tailor-taking-measurements-client-255059921.webp', 
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.black),
                ),
              ),
              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withValues(alpha: 0.9), Colors.black.withValues(alpha: 0.2)],
                    ),
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.accessibility_new_rounded, color: AppColors.amber, size: 20),
                    ),
                    const SizedBox(height: 12),
                    const Text('FITTING HUB', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.0, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    const Text('Capture your body measurements remotely', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              
              // Action Arrow
              const Positioned(
                top: 20, right: 20,
                child: Icon(Icons.north_east_rounded, color: Colors.white, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersManifest(List<dynamic> orders) {
    if (orders.isEmpty) {
      return const LuxuryGlassCard(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('NO ORDERS IN QUEUE', style: TextStyle(color: Colors.white10, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5))),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length > 2 ? 2 : orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        final String status = order is Map ? (order['status']?.toString() ?? 'pending') : 'in-progress';
        final String type = order is Map ? (order['garmentType']?.toString() ?? 'Bespoke Item') : 'Bespoke Item';

        return LuxuryGlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: AppColors.amber, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(type.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                    Text('PIPELINE: ${status.toUpperCase()}', style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStyleCatalog() {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return Container(
            width: 130,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.05),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: const Center(child: Icon(Icons.style_rounded, color: AppColors.amber, size: 24)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LUXURY KAFTAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 9)),
                      Text('By Master Tailor', style: TextStyle(color: Colors.white38, fontSize: 8)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, String route) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white38)),
        GestureDetector(
          onTap: () => ref.read(navigationProvider.notifier).state = NavigationState(route),
          child: const Text('EXPLORE', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
        ),
      ],
    );
  }
}
