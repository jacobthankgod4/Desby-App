import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/order_provider.dart';
import '../../domain/entities/order.dart';
import '../../../chat/presentation/pages/chat_detail_page.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/luxury_glass_card.dart';

class OrderDetailPage extends ConsumerWidget {
  final String orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: const Color(0xFF0A1921),
      appBar: AppBar(
        title: const Text('ORDER DOSSIER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.forum_rounded, color: AppColors.amber, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailPage(
                    conversationId: 'CONV_$orderId', 
                    orderId: orderId,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: orderAsync.when(
        data: (order) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildStatusHUD(context, order, ref),
              const SizedBox(height: 32),
              _buildClientDossier(context, order, ref),
              const SizedBox(height: 32),
              _buildGarmentList(context, order),
              const SizedBox(height: 32),
              _buildFinancialSummary(context, order),
              const SizedBox(height: 60),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2)),
        error: (err, _) => Center(child: Text('Dossier sync failed: $err', style: const TextStyle(color: Colors.redAccent, fontSize: 10))),
      ),
    );
  }

  Widget _buildStatusHUD(BuildContext context, OrderEntity order, WidgetRef ref) {
    return LuxuryGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('PIPELINE STATUS', style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(order.status.displayName.toUpperCase(), style: const TextStyle(color: AppColors.amber, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(2))),
              FractionallySizedBox(
                widthFactor: 0.45,
                child: Container(height: 4, decoration: BoxDecoration(color: AppColors.amber, borderRadius: BorderRadius.circular(2))),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _showStatusUpdateDialog(context, order, ref),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.03), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white10)), elevation: 0),
              child: const Text('UPDATE MANIFEST STATUS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientDossier(BuildContext context, OrderEntity order, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('CLIENT CORRESPONDENCE', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 16),
        LuxuryGlassCard(
          padding: const EdgeInsets.all(16),
          child: InkWell(
            onTap: () => ref.pushShell('/client-detail', {'clientId': order.clientId}),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
                  child: Center(child: Text(order.clientName[0].toUpperCase(), style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.clientName.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                      const Text('VIEW COMPLETE DOSSIER', style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGarmentList(BuildContext context, OrderEntity order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('GARMENT SPECIFICATIONS', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 16),
        ...order.items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LuxuryGlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.checkroom_rounded, color: AppColors.amber, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.garmentType.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                      const Text('CUSTOM MEASUREMENTS ACTIVE', style: TextStyle(color: Color(0xFF00FF7F), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                Text('₦${item.price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildFinancialSummary(BuildContext context, OrderEntity order) {
    return LuxuryGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildPriceRow('SUBTOTAL', '₦${order.totalAmount.toStringAsFixed(0)}'),
          const SizedBox(height: 12),
          _buildPriceRow('DISPATCH FEE', '₦${order.dispatchFee.toStringAsFixed(0)}'),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 16),
          _buildPriceRow('TOTAL SETTLEMENT', '₦${(order.totalAmount + order.dispatchFee).toStringAsFixed(0)}', isHighlight: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isHighlight ? Colors.white : Colors.white24, fontSize: isHighlight ? 11 : 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
        Text(value, style: TextStyle(color: isHighlight ? AppColors.amber : Colors.white, fontSize: isHighlight ? 18 : 13, fontWeight: FontWeight.w900)),
      ],
    );
  }

  void _showStatusUpdateDialog(BuildContext context, OrderEntity order, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1921),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('UPDATE PIPELINE STATUS', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 24),
            ...OrderStatus.values.map((status) => ListTile(
              title: Text(status.displayName.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900)),
              onTap: () => Navigator.pop(context),
            )),
          ],
        ),
      ),
    );
  }
}
