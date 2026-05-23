import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/stat_card.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/presentation/providers/logistics_provider.dart';
import '../../../../theme/colors.dart';

class FabricSellerDashboard extends ConsumerWidget {
  const FabricSellerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Note: Desktop shell is handled by MainPage on desktop
    return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildQuickActions(context),
            const SizedBox(height: 32),
            _buildStatsGrid(),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Recent Inventory Uploads', () {}),
            const SizedBox(height: 16),
            _buildRecentUploads(),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Marketplace Dispatch Requests', () {}),
            const SizedBox(height: 16),
            _buildDispatchRequests(context, ref),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Top Selling Fabrics', () {}),
            const SizedBox(height: 16),
            _buildTopFabrics(),
            const SizedBox(height: 40),
          ],
        ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, Merchant!',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        Text('Manage your inventory and orders.', style: TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/fabric-upload'),
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Upload Fabric'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkNavy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: const [
        StatCard(
          title: 'Monthly Sales',
          value: '\$4.2k',
          icon: Icons.monetization_on_outlined,
          color: Colors.green,
        ),
        StatCard(
          title: 'Active Orders',
          value: '12',
          icon: Icons.shopping_cart_outlined,
          color: Colors.orange,
        ),
        StatCard(
          title: 'Total Stock',
          value: '1.2k yd',
          icon: Icons.inventory_2_outlined,
          color: AppColors.amber,
        ),
        StatCard(
          title: 'Followers',
          value: '850',
          icon: Icons.people_outline,
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildRecentUploads() {
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[100]!),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: const Center(child: Icon(Icons.texture_outlined, color: AppColors.amber, size: 32)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Gold Damask', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      Text('45yd in stock', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
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

  Widget _buildDispatchRequests(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: AppColors.amber.withValues(alpha: 0.1), child: const Icon(Icons.local_shipping_rounded, color: AppColors.amber)),
              const SizedBox(width: 20),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pending Fabric Dispatch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                    Text('Bespoke Silk Request (Tailor ID: #442)', style: TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => _handleDispatch(context, ref),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: AppColors.darkNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text('SUMMON MERCHANT RIDER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDispatch(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('INITIATING MERCHANT DISPATCH...'), backgroundColor: Colors.blueAccent));
    
    try {
      // Logic for Seller Rider Summon
      // In a real scenario, we would pull the most recent marketplace order
      // For this audit pass, we simulate the dispatch of a pending order
      final orderEntity = OrderEntity(
        id: 'MKT_${DateTime.now().millisecondsSinceEpoch}',
        clientId: 'MARKETPLACE_BUYER',
        clientName: 'Luxury Fabric Buyer',
        items: const [],
        status: OrderStatus.bookingAccepted,
        totalAmount: 0.0,
        dueDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final result = await ref.read(logisticsRepositoryProvider).summonRider(orderEntity);
      
      result.fold(
        (failure) => messenger.showSnackBar(SnackBar(content: Text('DISPATCH FAILED: ${failure.message}'), backgroundColor: Colors.redAccent)),
        (fezOrderNo) => messenger.showSnackBar(SnackBar(content: Text('MERCHANT RIDER SUMMONED! WAYBILL: $fezOrderNo'), backgroundColor: Colors.greenAccent)),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('DISPATCH ERROR: $e'), backgroundColor: Colors.redAccent));
    }
  }

  Widget _buildTopFabrics() {
    return Column(
      children: [
        _buildFabricPerformanceItem('Premium Silk', 0.85, Colors.blue),
        _buildFabricPerformanceItem('Egyptian Cotton', 0.65, AppColors.amber),
        _buildFabricPerformanceItem('Italian Wool', 0.40, Colors.purple),
      ],
    );
  }

  Widget _buildFabricPerformanceItem(String name, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('${(progress * 100).toInt()}% popularity', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        TextButton(onPressed: onSeeAll, child: const Text('See All')),
      ],
    );
  }
}
