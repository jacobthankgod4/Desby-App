import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/shop_provider.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../domain/entities/shop_product.dart';

class VirtualAtelierPage extends ConsumerStatefulWidget {
  const VirtualAtelierPage({super.key});

  @override
  ConsumerState<VirtualAtelierPage> createState() => _VirtualAtelierPageState();
}

class _VirtualAtelierPageState extends ConsumerState<VirtualAtelierPage> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';
    
    final profileAsync = ref.watch(userProfileProvider(userId));
    final productsAsync = ref.watch(shopNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        title: const Text('VIRTUAL ATELIER', 
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 20),
          onPressed: () {
            if (ref.read(navigationProvider).route != '/main') {
              ref.read(navigationProvider.notifier).state = const NavigationState('/main');
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.amber),
            onPressed: () => _showAddProductDialog(context),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 1. SHOP HEADER
          SliverToBoxAdapter(
            child: profileAsync.when(
              data: (profile) => Padding(
                padding: const EdgeInsets.all(24.0),
                child: _buildShopHeader(profile?.businessName ?? 'Bespoke Atelier', profile?.bio ?? 'No bio established yet.'),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Profile sync failed: $err'),
            ),
          ),

          // 2. PRODUCT GRID
          _buildSectionHeader('YOUR MASTERPIECES'),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: productsAsync.when(
              data: (products) => products.isEmpty
                ? const SliverToBoxAdapter(child: Center(child: Text('YOUR SHOP IS EMPTY', style: TextStyle(color: Colors.white12, fontWeight: FontWeight.w900))))
                : SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildProductCard(context, products[index]),
                      childCount: products.length,
                    ),
                  ),
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: AppColors.amber))),
              error: (err, _) => SliverToBoxAdapter(child: Text('Sync Error: $err', style: const TextStyle(color: Colors.red))),
            ),
          ),
          
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildShopHeader(String name, String bio) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: AppColors.amber, size: 20),
                onPressed: () => Navigator.pushNamed(context, '/shop-setup'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(bio, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Text(title, style: const TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ShopProduct product) {
    return Container(
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
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: product.imageUrls.isNotEmpty
                ? ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), child: Image.network(product.imageUrls.first, fit: BoxFit.cover))
                : const Icon(Icons.checkroom_rounded, color: Colors.white10, size: 40),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('₦${product.price.toInt()}', style: const TextStyle(color: AppColors.amber, fontSize: 13, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                  onPressed: () => _deleteProduct(product.id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A1921),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('NEW MASTERPIECE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.white38)),
              ),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Price (₦)', labelStyle: TextStyle(color: Colors.white38)),
              ),
              TextField(
                controller: descController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: Colors.white38)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () {
              final product = ShopProduct(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                tailorId: ref.read(currentUserProvider)!.id,
                name: nameController.text,
                price: double.tryParse(priceController.text) ?? 0.0,
                description: descController.text,
                createdAt: DateTime.now(),
              );
              ref.read(shopNotifierProvider.notifier).addProduct(product);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber),
            child: const Text('ADD TO SHOP', style: TextStyle(color: AppColors.darkNavy, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _deleteProduct(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A1921),
        title: const Text('DELETE PRODUCT?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
        content: const Text('This action cannot be undone.', style: TextStyle(color: Colors.white38, fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white24))),
          TextButton(
            onPressed: () {
              ref.read(shopNotifierProvider.notifier).deleteProduct(id);
              Navigator.pop(context);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
