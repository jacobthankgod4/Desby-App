import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/fabric_provider.dart';
import '../widgets/fabric_card.dart';

class SellerInventoryPage extends ConsumerWidget {
  const SellerInventoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: Text('User not found'));

    final inventoryAsync = ref.watch(fabricCatalogProvider(sellerId: user.id));

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: inventoryAsync.when(
        data: (fabrics) => fabrics.isEmpty
            ? _buildEmptyState(context)
            : _buildInventoryList(context, fabrics, ref),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
        error: (err, _) => Center(child: Text('Inventory sync failed: $err', style: const TextStyle(color: Colors.white38))),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/fabric-upload'),
        backgroundColor: AppColors.amber,
        child: const Icon(Icons.add_rounded, color: AppColors.darkNavy),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          const Text('NO FABRIC UPLOADED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
          const SizedBox(height: 8),
          const Text('Your digital shelf is empty.', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInventoryList(BuildContext context, List fabrics, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: fabrics.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final fabric = fabrics[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  fabric.imageUrls.first,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.white10, child: const Icon(Icons.texture_rounded, color: Colors.white24)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fabric.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text('${fabric.stockQuantity} yds remaining', style: TextStyle(color: fabric.stockQuantity < 5 ? Colors.redAccent : Colors.white38, fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('₦${fabric.pricePerYard.toStringAsFixed(0)}/yd', style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900, fontSize: 14)),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white38, size: 20),
                    onPressed: () {
                      // TODO: Implement Edit logic
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                    onPressed: () => _confirmDelete(context, ref, fabric.id),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String fabricId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkNavy,
        title: const Text('DELETE FABRIC?', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
        content: const Text('This action cannot be undone and will remove the material from the marketplace.', style: TextStyle(color: Colors.white38, fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900))
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(fabricRepositoryProvider).deleteFabric(fabricId);
    }
  }
}
