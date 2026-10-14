import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/luxury_stat_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../marketplace/presentation/providers/fabric_provider.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../../../core/widgets/animated_entry.dart';
import '../../../../core/widgets/dashboard_shimmer.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../widgets/quick_action_tile.dart';

class FabricSellerDashboard extends ConsumerStatefulWidget {
  const FabricSellerDashboard({super.key});

  @override
  ConsumerState<FabricSellerDashboard> createState() =>
      _FabricSellerDashboardState();
}

class _FabricSellerDashboardState extends ConsumerState<FabricSellerDashboard> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(merchantStatsProvider(user?.id ?? ''));

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: RefreshIndicator(
        onRefresh: () async {
          final user = ref.read(currentUserProvider);
          if (user != null) {
            ref.invalidate(merchantStatsProvider(user.id));
          }
        },
        color: AppColors.amber,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedEntry(index: 0, child: _buildHeader(context, ref)),
              const SizedBox(height: 24),

              // Commerce HUD
              statsAsync.when(
                data: (stats) => GridView.count(
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
                        title: 'Total Sales',
                        value: '₦${(stats['total_gmv'] as num?)?.toInt() ?? 0}',
                        icon: Icons.monetization_on_rounded,
                        color: Colors.greenAccent,
                      ),
                    ),
                    AnimatedEntry(
                      index: 2,
                      child: LuxuryStatCard(
                        title: 'Orders',
                        value: '${stats['order_count'] ?? 0}',
                        icon: Icons.local_shipping_rounded,
                        color: Colors.orangeAccent,
                      ),
                    ),
                    AnimatedEntry(
                      index: 3,
                      child: LuxuryStatCard(
                        title: 'Total Products',
                        value: '${stats['sku_count'] ?? 0}',
                        icon: Icons.inventory_2_rounded,
                      ),
                    ),
                    AnimatedEntry(
                      index: 4,
                      child: LuxuryStatCard(
                        title: 'Avg Rating',
                        value:
                            '${(stats['avg_rating'] as num?)?.toStringAsFixed(1) ?? 'N/A'}',
                        icon: Icons.workspace_premium_rounded,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
                loading: () => DashboardShimmer(statCount: 4, listCount: 2),
                error: (e, _) => _buildErrorState(),
              ),
              const SizedBox(height: 32),

              // QUICK ACTIONS — as with the apprentice dashboard, the existing
              // GridView here held only non-tappable LuxuryStatCards. The seller's
              // main verbs (upload, wallet, inventory) were reachable only from a
              // header button or an icon button in the corner.
              AnimatedEntry(index: 5, child: _buildQuickActions()),
              const SizedBox(height: 32),

              // Dispatch Command
              AnimatedEntry(
                index: 5,
                child: _buildSectionHeader('Pending Shipments', '/orders'),
              ),
              const SizedBox(height: 16),
              AnimatedEntry(index: 6, child: _buildDispatchHUD(context, ref)),

              const SizedBox(height: 32),

              // Inventory Velocity
              AnimatedEntry(
                index: 7,
                child: _buildSectionHeader('My Fabrics', '/inventory'),
              ),
              const SizedBox(height: 16),
              AnimatedEntry(index: 8, child: _buildRecentUploadsHUD()),

              const SizedBox(height: 32),

              // Performance Analytics
              AnimatedEntry(
                index: 9,
                child: _buildSectionHeader('Top Inventory', '/inventory'),
              ),
              const SizedBox(height: 16),
              AnimatedEntry(index: 10, child: _buildPerformanceHUD()),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Seller Dashboard',
              style: TextStyle(
                color: AppColors.amber,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            _WalletButton(onTap: () => ref.pushShell('/merchant-wallet')),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Marketplace',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => ref.pushShell('/fabric-upload'),
          icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
          label: const Text(
            'UPLOAD NEW FABRIC',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.amber,
            foregroundColor: AppColors.darkNavy,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sync_problem_rounded,
              color: AppColors.amber,
              size: 40,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'SYNC ERROR',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Could not load stats',
            style: TextStyle(color: colors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchHUD(BuildContext context, WidgetRef ref) {
    return _DispatchCard(
      onDispatch: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preparing delivery...'),
            backgroundColor: Colors.blueAccent,
          ),
        );
      },
    );
  }

  Widget _buildRecentUploadsHUD() {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);
    final fabricsAsync = ref.watch(sellerInventoryProvider(user?.id ?? ''));

    return fabricsAsync.when(
      data: (fabrics) {
        if (fabrics.isEmpty) {
          return Container(
            height: 120,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'No fabrics uploaded yet',
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
            ),
          );
        }
        return SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: fabrics.length > 4 ? 4 : fabrics.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final fabric = fabrics[index];
              return _FabricCard(
                name: fabric.name.toUpperCase(),
                stock: '${fabric.stockQuantity.toInt()} YD',
                icon: Icons.texture_rounded,
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator(color: AppColors.amber)),
      ),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildPerformanceHUD() {
    final user = ref.watch(currentUserProvider);
    final fabricsAsync = ref.watch(sellerInventoryProvider(user?.id ?? ''));

    return fabricsAsync.when(
      data: (fabrics) {
        if (fabrics.isEmpty) return const SizedBox();
        final sorted = List.of(fabrics)
          ..sort((a, b) => b.stockQuantity.compareTo(a.stockQuantity));
        final top = sorted.take(3).toList();
        if (top.isEmpty) return const SizedBox();
        final maxStock = top.first.stockQuantity;
        return _PerformanceCard(
          items: top
              .map(
                (f) => (
                  f.name.toUpperCase(),
                  maxStock > 0 ? f.stockQuantity / maxStock : 0.0,
                  AppColors.amber,
                ),
              )
              .toList(),
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(color: AppColors.amber)),
      ),
      error: (_, __) => const SizedBox(),
    );
  }

  /// Fabric-seller quick actions. All routes already exist in the shell switch.
  Widget _buildQuickActions() {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossCount = screenWidth < 600 ? 3 : 4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const QuickActionsHeading(),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: crossCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.92,
          children: [
            QuickActionTile(
              icon: Icons.add_photo_alternate_rounded,
              label: 'Upload Fabric',
              onTap: () => ref.pushShell('/fabric-upload'),
              index: 0,
            ),
            QuickActionTile(
              icon: Icons.inventory_2_rounded,
              label: 'My Fabrics',
              onTap: () => ref.setShell('/inventory'),
              index: 1,
            ),
            QuickActionTile(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Wallet',
              onTap: () => ref.pushShell('/merchant-wallet'),
              index: 2,
            ),
            QuickActionTile(
              icon: Icons.local_shipping_rounded,
              label: 'Shipments',
              onTap: () => ref.setShell('/orders'),
              index: 3,
            ),
            QuickActionTile(
              icon: Icons.storefront_rounded,
              label: 'Storefront',
              onTap: () => ref.setShell('/storefront'),
              index: 4,
            ),
            QuickActionTile(
              icon: Icons.auto_graph_rounded,
              label: 'AI Pricing',
              onTap: () => ref.setShell('/ai-pricing'),
              index: 5,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String route) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
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
              'MANAGE',
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
}

class _WalletButton extends StatefulWidget {
  final VoidCallback onTap;
  const _WalletButton({required this.onTap});

  @override
  State<_WalletButton> createState() => _WalletButtonState();
}

class _WalletButtonState extends State<_WalletButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.amber.withValues(alpha: 0.15)
                : AppColors.amber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.account_balance_wallet_rounded,
            color: AppColors.amber,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _DispatchCard extends StatefulWidget {
  final VoidCallback onDispatch;
  const _DispatchCard({required this.onDispatch});

  @override
  State<_DispatchCard> createState() => _DispatchCardState();
}

class _DispatchCardState extends State<_DispatchCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: LuxuryGlassCard(
        padding: const EdgeInsets.all(20),
        borderColor: _isHovered
            ? Colors.orangeAccent.withValues(alpha: 0.2)
            : null,
        child: Column(
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isHovered
                        ? Colors.orangeAccent.withValues(alpha: 0.15)
                        : Colors.orangeAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emergency_share_rounded,
                    color: Colors.orangeAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending Shipment',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'No pending shipments',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: widget.onDispatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isHovered
                      ? colors.divider
                      : colors.borderSubtle,
                  foregroundColor: colors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Request Pickup',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FabricCard extends StatefulWidget {
  final String name;
  final String stock;
  final IconData icon;
  const _FabricCard({
    required this.name,
    required this.stock,
    required this.icon,
  });

  @override
  State<_FabricCard> createState() => _FabricCardState();
}

class _FabricCardState extends State<_FabricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
            color: _isHovered ? colors.surfaceHover : colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? AppColors.amber.withValues(alpha: 0.2)
                  : colors.borderSubtle,
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
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Center(
                    child: Icon(widget.icon, color: AppColors.amber, size: 28),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 9,
                      ),
                    ),
                    Text(
                      '${widget.stock} REMAINING',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

class _PerformanceCard extends StatelessWidget {
  final List<(String, double, Color)> items;
  const _PerformanceCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return LuxuryGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: items.map((item) {
          final (name, progress, color) = item;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _PerformanceItem(
              name: name,
              progress: progress,
              color: color,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PerformanceItem extends StatelessWidget {
  final String name;
  final double progress;
  final Color color;
  const _PerformanceItem({
    required this.name,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: colors.borderSubtle,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}
