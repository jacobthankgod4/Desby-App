import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/luxury_stat_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../marketplace/presentation/providers/fabric_provider.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';

class FabricSellerDashboard extends ConsumerWidget {
  const FabricSellerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(merchantStatsProvider(user?.id ?? ''));

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, ref),
              const SizedBox(height: 32),
              
              // 1. COMMERCE HUD
              statsAsync.when(
                data: (stats) => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    LuxuryStatCard(
                      title: 'Total GMV', 
                      value: '₦${(stats['total_gmv'] as num).toInt()}', 
                      icon: Icons.monetization_on_rounded, 
                      color: Colors.greenAccent
                    ),
                    LuxuryStatCard(
                      title: 'Orders', 
                      value: '${stats['order_count']}', 
                      icon: Icons.local_shipping_rounded, 
                      color: Colors.orangeAccent
                    ),
                    LuxuryStatCard(
                      title: 'Total SKU', 
                      value: '${stats['sku_count']}', 
                      icon: Icons.inventory_2_rounded, 
                      color: AppColors.amber
                    ),
                    const LuxuryStatCard(
                      title: 'Global Rank', 
                      value: '#12', 
                      icon: Icons.workspace_premium_rounded, 
                      color: Colors.blueAccent
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
                error: (e, _) => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics_outlined, color: Colors.white24, size: 48),
                      SizedBox(height: 12),
                      Text('STATS UNAVAILABLE', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 2. DISPATCH COMMAND
              _buildSectionHeader('Logistics Radar', () {}),
              const SizedBox(height: 16),
              _buildDispatchHUD(context, ref),
              
              const SizedBox(height: 32),

              // 3. INVENTORY VELOCITY
              _buildSectionHeader('Stock Manifest', () {}),
              const SizedBox(height: 16),
              _buildRecentUploadsHUD(),
              
              const SizedBox(height: 32),

              // 4. PERFORMANCE ANALYTICS
              _buildSectionHeader('Material Popularity', () {}),
              const SizedBox(height: 16),
              _buildPerformanceHUD(),
              const SizedBox(height: 40),
            ],
          ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('MERCHANT TERMINAL', style: TextStyle(color: AppColors.amber, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2)),
            IconButton(
              onPressed: () => ref.pushShell('/merchant-wallet'),
              icon: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.amber, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Marketplace Live',
          style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => ref.pushShell('/fabric-upload'),
          icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
          label: const Text('UPLOAD NEW MATERIAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
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

  Widget _buildDispatchHUD(BuildContext context, WidgetRef ref) {
    return LuxuryGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.orangeAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.emergency_share_rounded, color: Colors.orangeAccent, size: 20),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PENDING DISPATCH', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                    Text('Bespoke Silk #442 • Lagos', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
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
              onPressed: () => _handleDispatch(context, ref),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: const Text('SUMMON MERCHANT RIDER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDispatch(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CALIBRATING LOGISTICS...'), backgroundColor: Colors.blueAccent));
  }

  Widget _buildRecentUploadsHUD() {
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
                    child: const Center(child: Icon(Icons.texture_rounded, color: AppColors.amber, size: 28)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GOLD DAMASK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 9)),
                      Text('45 YD REMAINING', style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
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

  Widget _buildPerformanceHUD() {
    return LuxuryGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildFabricItem('PREMIUM SILK', 0.85, Colors.blueAccent),
          const SizedBox(height: 16),
          _buildFabricItem('EGYPTIAN COTTON', 0.65, AppColors.amber),
          const SizedBox(height: 16),
          _buildFabricItem('ITALIAN WOOL', 0.40, Colors.purpleAccent),
        ],
      ),
    );
  }

  Widget _buildFabricItem(String name, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            Text('${(progress * 100).toInt()}%', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white38)),
        GestureDetector(onTap: onSeeAll, child: const Text('MANAGE', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1))),
      ],
    );
  }
}
