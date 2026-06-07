import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class MarketplaceCartPage extends ConsumerStatefulWidget {
  const MarketplaceCartPage({super.key});

  @override
  ConsumerState<MarketplaceCartPage> createState() => _MarketplaceCartPageState();
}

class _MarketplaceCartPageState extends ConsumerState<MarketplaceCartPage> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login to view cart')));
    }

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        title: const Text('MARKETPLACE CART', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('carts').doc(user.id).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.amber));
          
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildEmptyState();
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final items = (data['items'] as List? ?? []).cast<Map<String, dynamic>>();

          if (items.isEmpty) return _buildEmptyState();

          double total = 0;
          for (var item in items) {
            total += (item['totalPrice'] as num).toDouble();
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _CartItemTile(
                      item: item,
                      onUpdate: (qty) => _updateQuantity(user.id, items, index, qty),
                      onRemove: () => _removeItem(user.id, items, index),
                    );
                  },
                ),
              ),
              _buildCheckoutFooter(total),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          const Text('CART EMPTY', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('EXPLORE FABRICS', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutFooter(double total) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL AMOUNT', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                Text('₦${total.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.amber, fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/checkout', arguments: {
                    'amount': total,
                    'orderId': 'MKT_CART_${DateTime.now().millisecondsSinceEpoch}',
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: AppColors.darkNavy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('PROCEED TO CHECKOUT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateQuantity(String userId, List<Map<String, dynamic>> items, int index, double newQty) async {
    if (newQty <= 0) return;
    final updatedItems = List<Map<String, dynamic>>.from(items);
    final item = updatedItems[index];
    updatedItems[index] = {
      ...item,
      'quantity': newQty,
      'totalPrice': (item['pricePerYard'] as num).toDouble() * newQty,
    };

    await FirebaseFirestore.instance.collection('carts').doc(userId).update({
      'items': updatedItems,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _removeItem(String userId, List<Map<String, dynamic>> items, int index) async {
    final updatedItems = List<Map<String, dynamic>>.from(items);
    updatedItems.removeAt(index);

    await FirebaseFirestore.instance.collection('carts').doc(userId).update({
      'items': updatedItems,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }
}

class _CartItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final Function(double) onUpdate;
  final VoidCallback onRemove;

  const _CartItemTile({required this.item, required this.onUpdate, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.texture_rounded, color: AppColors.amber),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['fabricName'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                Text('₦${(item['pricePerYard'] as num).toInt()} / yd', style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _QtyBtn(icon: Icons.remove, onTap: () => onUpdate((item['quantity'] as num).toDouble() - 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('${(item['quantity'] as num).toInt()} YDS', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                    ),
                    _QtyBtn(icon: Icons.add, onTap: () => onUpdate((item['quantity'] as num).toDouble() + 1)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(onPressed: onRemove, icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20)),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.white38, size: 14),
      ),
    );
  }
}
