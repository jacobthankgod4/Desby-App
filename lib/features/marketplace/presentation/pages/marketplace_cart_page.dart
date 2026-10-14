import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/domain/entities/order_ids.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/widgets/shell_app_bar.dart';

class MarketplaceCartPage extends ConsumerStatefulWidget {
  const MarketplaceCartPage({super.key});

  @override
  ConsumerState<MarketplaceCartPage> createState() =>
      _MarketplaceCartPageState();
}

class _MarketplaceCartPageState extends ConsumerState<MarketplaceCartPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _cartItems = [];

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      final result = await supabase
          .from('carts')
          .select('items, user_id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (result != null) {
        final items = (result['items'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        setState(() {
          _cartItems = items;
        });
      }
    } catch (e) {
      debugPrint('[Cart] load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _totalPrice => _cartItems.fold(
    0.0,
    (sum, item) => sum + ((item['totalPrice'] as num?)?.toDouble() ?? 0.0),
  );

  Future<void> _removeItem(int index) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final removedItem = _cartItems.removeAt(index);
    setState(() {});

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('carts').upsert({
        'user_id': user.id,
        'items': _cartItems,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[Cart] remove error: $e');
      // Revert
      _cartItems.insert(index, removedItem);
      if (mounted) setState(() {});
    }
  }

  Future<void> _updateQuantity(int index, int delta) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final item = _cartItems[index];
    final currentQty = (item['quantity'] as num?)?.toInt() ?? 1;
    final newQty = currentQty + delta;
    if (newQty < 1) return;

    final pricePerYard = (item['pricePerYard'] as num?)?.toDouble() ?? 0.0;
    _cartItems[index] = {
      ...item,
      'quantity': newQty,
      'totalPrice': pricePerYard * newQty,
    };
    setState(() {});

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('carts').upsert({
        'user_id': user.id,
        'items': _cartItems,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[Cart] update qty error: $e');
    }
  }

  Future<void> _checkout() async {
    if (_cartItems.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = ctx.colors;
        return AlertDialog(
          backgroundColor: colors.dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'CONFIRM ORDER',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_cartItems.length} item(s) \u2014 \u20A6${_totalPrice.toStringAsFixed(0)}',
                style: TextStyle(color: colors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'This will create a marketplace order and redirect to payment.',
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: AppColors.darkNavy,
              ),
              child: const Text('PLACE ORDER'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      final supabase = Supabase.instance.client;
      const uuid = Uuid();

      final Map<String, List<Map<String, dynamic>>> sellerItems = {};
      for (final item in _cartItems) {
        final sellerId = (item['sellerId'] as String?) ?? '';
        sellerItems.putIfAbsent(sellerId, () => []).add(item);
      }

      final List<String> createdOrderIds = [];
      final Map<String, double> createdOrderAmounts = {};
      final Set<String> createdSellerIds = {};
      final List<String> failedSellers = [];

      for (final entry in sellerItems.entries) {
        final itemsTotal = entry.value.fold(
          0.0,
          (sum, item) =>
              sum + ((item['totalPrice'] as num?)?.toDouble() ?? 0.0),
        );

        try {
          // Three defects in one block, all verified against production:
          //  1. id was 'MKT_<uuid8>' — the column is uuid, so this was
          //     rejected with 22P02 and no order ever existed.
          //  2. client_id was user.id, but that column references clients(id)
          //     and failed the FK (23503).
          //  3. tailor_id was the BUYER's id, which combined with the old
          //     UPDATE policy to let a buyer mark their own order delivered
          //     and trigger a payout. The seller is fabric_seller_id; there is
          //     no tailor on a fabric order, so tailor_id stays null.
          final reference = OrderIds.marketplaceReference();
          final response = await supabase.from('orders').insert({
            'id': uuid.v4(),
            'reference': reference,
            'requesting_user_id': user.id,
            'client_id': null,
            'tailor_id': null,
            'fabric_seller_id': entry.key.isNotEmpty ? entry.key : null,
            'client_name': user.name ?? '',
            'status': 'pending',
            'total_amount': itemsTotal,
            'dispatch_fee': 0,
            'fabric_type': entry.value.first['fabricName'] ?? 'Fabric',
            'fabric_color': entry.value.first['selectedColor'],
            'items': entry.value
                .map(
                  (item) => {
                    'id': uuid.v4(),
                    'garmentType': item['fabricName'] ?? 'Fabric',
                    'price': item['totalPrice'],
                    'measurements': null,
                  },
                )
                .toList(),
          });
          final rows = response.data as List?;
          final savedId =
              (rows != null && rows.isNotEmpty && rows.first is Map)
                  ? (rows.first as Map)['id'] as String
                  : uuid.v4();
          createdOrderIds.add(savedId);
          createdOrderAmounts[savedId] = itemsTotal;
          createdSellerIds.add(entry.key);
        } catch (e) {
          debugPrint(
            '[Cart] Failed to create order for seller ${entry.key}: $e',
          );
          failedSellers.add(entry.key);
        }
      }

      // Partial failure used to be silent: the user saw a success screen for
      // the orders that worked while the failed sellers vanished.
      if (failedSellers.isNotEmpty) {
        debugPrint('[Cart] ${failedSellers.length} seller order(s) failed');
      }

      if (createdOrderIds.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No orders could be created. Please try again.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      final remainingItems = _cartItems.where((item) {
        final sellerId = (item['sellerId'] as String?) ?? '';
        return !createdSellerIds.contains(sellerId);
      }).toList();
      try {
        final cartResponse = await supabase.from('carts').upsert({
          'user_id': user.id,
          'items': remainingItems,
          'updated_at': DateTime.now().toIso8601String(),
        });
        if (cartResponse.error != null) {
          debugPrint('[Cart] Failed to update cart: ${cartResponse.error}');
        }
      } catch (e) {
        debugPrint('[Cart] Failed to update cart: $e');
      }

      if (mounted) {
        final checkoutTotal = createdOrderAmounts.values.fold(
          0.0,
          (sum, amount) => sum + amount,
        );
        final checkoutOrderId = createdOrderIds.first;
        setState(() => _cartItems = remainingItems);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              remainingItems.isEmpty
                  ? 'ORDER PLACED'
                  : 'Some orders could not be created. Complete the remaining items separately.',
            ),
            backgroundColor: remainingItems.isEmpty
                ? AppColors.successGreen
                : Colors.orangeAccent,
          ),
        );

        ref.pushShell('/checkout', {
          'amount': checkoutTotal,
          'orderId': checkoutOrderId,
          'orderIds': createdOrderIds,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(
        context,
        title: 'MY CART',
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep_rounded, color: colors.textMuted),
              onPressed: () async {
                final user = ref.read(currentUserProvider);
                if (user == null) return;
                try {
                  await Supabase.instance.client.from('carts').upsert({
                    'user_id': user.id,
                    'items': <dynamic>[],
                    'updated_at': DateTime.now().toIso8601String(),
                  });
                  if (mounted) setState(() => _cartItems = []);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to clear cart'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
            ),
        ],
        iconTheme: const IconThemeData(color: AppColors.amber),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.amber),
            )
          : _cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: _cartItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) => _buildCartItem(index),
                  ),
                ),
                _buildCheckoutBar(),
              ],
            ),
    );
  }

  Widget _buildEmptyCart() {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: colors.textMuted),
          const SizedBox(height: 24),
          Text(
            'CART EMPTY',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse fabrics and add to cart',
            style: TextStyle(color: colors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(int index) {
    final colors = context.colors;
    final item = _cartItems[index];
    final name = (item['fabricName'] as String?) ?? 'Fabric';
    final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
    final pricePerYard = (item['pricePerYard'] as num?)?.toDouble() ?? 0.0;
    final totalPrice = (item['totalPrice'] as num?)?.toDouble() ?? 0.0;
    final color = item['selectedColor'] as String?;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          // Fabric icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.texture_rounded,
              color: AppColors.amber,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toUpperCase(),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (color != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceHover,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          color,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      '\u20A6${pricePerYard.toStringAsFixed(0)}/yard',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Quantity controls
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 14),
                  color: colors.textMuted,
                  onPressed: () => _updateQuantity(index, -1),
                ),
                Text(
                  '$quantity',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 14),
                  color: AppColors.amber,
                  onPressed: () => _updateQuantity(index, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\u20A6${totalPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  color: AppColors.amber,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _removeItem(index),
                child: Icon(
                  Icons.close_rounded,
                  color: colors.textMuted,
                  size: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBar() {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.scaffoldBg,
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '\u20A6${_totalPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _cartItems.isEmpty ? null : _checkout,
              icon: const Icon(Icons.payment_rounded, size: 20),
              label: const Text(
                'PROCEED TO PAYMENT',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: AppColors.darkNavy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: colors.surfaceHover,
                disabledForegroundColor: colors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
