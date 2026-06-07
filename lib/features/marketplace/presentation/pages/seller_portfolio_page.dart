import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../providers/fabric_provider.dart';
import '../widgets/fabric_card_grid.dart';

class SellerPortfolioPage extends ConsumerWidget {
  final String sellerId;

  const SellerPortfolioPage({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(fabricCatalogProvider('All')); // We'll filter this

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: CustomScrollView(
        slivers: [
          _buildHeroHeader(context),
          _buildStatsSection(),
          _buildInventoryHeader(),
          
          inventoryAsync.when(
            data: (allFabrics) {
              final sellerFabrics = allFabrics.where((f) => f.sellerId == sellerId).toList();
              if (sellerFabrics.isEmpty) {
                return const SliverFillRemaining(child: Center(child: Text('NO ACTIVE LISTINGS', style: TextStyle(color: Colors.white12, fontWeight: FontWeight.w900))));
              }
              return SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverToBoxAdapter(
                  child: FabricCardGrid(isGridView: true, fabrics: sellerFabrics),
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.amber))),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Merchant Offline', style: TextStyle(color: AppColors.amber)))),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 60)),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.darkNavy,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A1A), AppColors.darkNavy],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.amber.withValues(alpha: 0.1),
                child: const Icon(Icons.storefront_rounded, color: AppColors.amber, size: 40),
              ),
              const SizedBox(height: 16),
              const Text('VERIFIED MERCHANT', style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
              Text('ID: ${sellerId.substring(0, 8)}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const Text('Lagos, Nigeria • Established 2024', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildStatsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStat('Rating', '4.9', Icons.star_rounded, AppColors.amber),
            _buildStat('Orders', '1.2k', Icons.shopping_bag_rounded, Colors.blue),
            _buildStat('Response', '98%', Icons.bolt_rounded, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildInventoryHeader() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Text('COLLECTION INVENTORY', style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
    );
  }
}
