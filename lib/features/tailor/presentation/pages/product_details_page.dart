import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../../../../core/services/paystack_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProductDetailsPage extends ConsumerWidget {
  final Map<String, dynamic> product;

  const ProductDetailsPage({super.key, required this.product});

  // --- REAL PAYSTACK INTEGRATION ---
  Future<void> _processPayment(BuildContext context, WidgetRef ref) async {
    final double amount = double.tryParse(product['price'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid product price architecture.'), backgroundColor: Colors.redAccent));
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to complete purchase.'), backgroundColor: Colors.orangeAccent));
      return;
    }

    try {
      await PaystackService().checkout(
        context: context,
        email: user.email,
        amount: amount,
        reference: 'PUR_${user.id.substring(0, 5)}_${DateTime.now().millisecondsSinceEpoch}',
        onSuccess: (refId) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PURCHASE SUCCESSFUL: $refId'), backgroundColor: Colors.greenAccent));
          Navigator.pop(context);
        },
        onCancel: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction Terminated.'), backgroundColor: Colors.orangeAccent));
        },
      );
    } catch (e) {
      debugPrint('❌ [PAYSTACK] Failed: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: CustomScrollView(
        slivers: [
          // 1. HEADER
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.darkNavy,
            elevation: 0,
            toolbarHeight: 60,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('PRODUCT DETAILS',
              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.8)),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(10),
              child: Container(height: 10, color: AppColors.amber),
            ),
          ),

          // 2. HERO IMAGE
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                height: 380,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: Colors.white.withValues(alpha: 0.03),
                  border: Border.all(color: AppColors.amber.withValues(alpha: 0.3), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    children: [
                      Center(child: Icon(Icons.checkroom_rounded, color: AppColors.amber.withValues(alpha: 0.1), size: 180)),
                      Positioned(
                        bottom: 32, left: 32,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product['name']?.toString().toUpperCase() ?? 'MASTERPIECE', 
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.0)),
                            const SizedBox(height: 8),
                            Text(product['price']?.toString() ?? 'N/A', 
                              style: const TextStyle(color: AppColors.amber, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. SPECIFICATION (DYNAMIC NARRATIVE)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DESIGN NARRATIVE', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12)),
                  const SizedBox(height: 16),
                  Text(
                    product['description'] != null && product['description'].toString().isNotEmpty 
                      ? product['description'] 
                      : 'Professionally tailored using high-density premium fabrics. Features reinforced stitching and digital-precision alignment for a world-class bespoke finish.',
                    style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.6, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),

          // 4. RESOURCES
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: Colors.white.withValues(alpha: 0.05),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('RESOURCES', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
                    const SizedBox(height: 20),
                    _buildGlassAction('MEASUREMENT GUIDE'),
                    const SizedBox(height: 12),
                    _buildGlassAction('FABRIC AVAILABILITY'),
                  ],
                ),
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
      ),
      bottomSheet: _buildBottomAction(context, ref),
    );
  }

  Widget _buildGlassAction(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.darkNavy,
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: () => _processPayment(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: AppColors.darkNavy,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('BUY NOW', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                SizedBox(width: 12),
                Icon(Icons.bolt_rounded, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
