import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desby_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:desby_app/features/orders/presentation/providers/order_provider.dart';
import 'package:desby_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:desby_app/core/widgets/error_state_widget.dart';
import 'package:desby_app/core/widgets/luxury_glass_card.dart';
import 'package:desby_app/core/widgets/animated_entry.dart';
import 'package:desby_app/core/widgets/dashboard_shimmer.dart';
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
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ordersProvider);
          if (userId.isNotEmpty) ref.invalidate(userProfileProvider(userId));
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

              // Style & Loyalty HUD
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  AnimatedEntry(
                    index: 1,
                    child: LuxuryStatCard(
                      title: 'Active Suits',
                      value: '${ordersAsync.value?.length ?? 0}',
                      icon: Icons.checkroom_rounded,
                    ),
                  ),
                  AnimatedEntry(
                    index: 2,
                    child: profileAsync?.when(
                      data: (p) => LuxuryStatCard(
                        title: 'Style Points',
                        value: '${p?.loyaltyPoints ?? 0}',
                        icon: Icons.auto_awesome_rounded,
                        color: Colors.purpleAccent,
                      ),
                      loading: () => const LuxuryStatCard(title: '...', value: '...', icon: Icons.auto_awesome_rounded),
                      error: (_, __) => const LuxuryStatCard(title: 'Points', value: '0', icon: Icons.auto_awesome_rounded),
                    ) ?? const LuxuryStatCard(title: 'Points', value: '0', icon: Icons.auto_awesome_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Fitting Station Hub
              AnimatedEntry(index: 3, child: _buildFittingStationCard()),
              const SizedBox(height: 32),

              // Active Garment Tracker
              AnimatedEntry(
                index: 4,
                child: _buildSectionHeader('In Production', '/orders'),
              ),
              const SizedBox(height: 16),
              ordersAsync.when(
                data: (orders) => AnimatedEntry(index: 5, child: _buildOrdersManifest(orders)),
                loading: () => DashboardShimmer(listCount: 2),
                error: (error, _) => const ErrorStateWidget(message: 'Failed to sync manifests.'),
              ),

              const SizedBox(height: 32),

              // Style Inspo / Catalog
              AnimatedEntry(
                index: 6,
                child: _buildSectionHeader('Trending Silhouettes', '/marketplace'),
              ),
              const SizedBox(height: 16),
              AnimatedEntry(index: 7, child: _buildStyleCatalog()),
              const SizedBox(height: 40),
            ],
          ),
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
          onPressed: () => ref.pushShell('/tailor-discovery'),
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
    return _FittingCard(
      onTap: () => ref.pushShell('/measurements-hub'),
    );
  }

  Widget _buildOrdersManifest(List<dynamic> orders) {
    if (orders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long_rounded,
        title: 'NO ORDERS IN QUEUE',
        subtitle: 'Commission a designer to start',
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

        return _OrderTile(type: type, status: status);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return LuxuryGlassCard(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: Colors.white10, size: 36),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.white10, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.15), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleCatalog() {
    final styles = [
      ('LUXURY KAFTAN', 'By Master Tailor', Icons.checkroom_rounded),
      ('AGBADA ELEGANCE', 'Royal Collection', Icons.dry_cleaning_rounded),
      ('ANKARA Fusion', 'Modern Blend', Icons.palette_rounded),
      ('BOU BLOUSE', 'Classic Series', Icons.waves_rounded),
    ];

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: styles.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final (title, subtitle, icon) = styles[index];
          return _StyleCard(title: title, subtitle: subtitle, icon: icon);
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
          onTap: () => ref.setShell(route),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('EXPLORE', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
          ),
        ),
      ],
    );
  }
}

class _FittingCard extends StatefulWidget {
  final VoidCallback onTap;
  const _FittingCard({required this.onTap});

  @override
  State<_FittingCard> createState() => _FittingCardState();
}

class _FittingCardState extends State<_FittingCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _isHovered
                  ? AppColors.amber.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/african-tailor-taking-measurements-client-255059921.webp',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.black),
                  ),
                ),
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
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  top: 20,
                  right: _isHovered ? 16 : 20,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isHovered ? 1.0 : 0.7,
                    child: const Icon(Icons.north_east_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final String type;
  final String status;
  const _OrderTile({required this.type, required this.status});

  @override
  Widget build(BuildContext context) {
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
  }
}

class _StyleCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _StyleCard({required this.title, required this.subtitle, required this.icon});

  @override
  State<_StyleCard> createState() => _StyleCardState();
}

class _StyleCardState extends State<_StyleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 130,
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? AppColors.amber.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _isHovered
                        ? AppColors.amber.withValues(alpha: 0.1)
                        : AppColors.amber.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Center(child: Icon(widget.icon, color: AppColors.amber, size: 24)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 9)),
                    Text(widget.subtitle, style: TextStyle(color: Colors.white38, fontSize: 8)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
