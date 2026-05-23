import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/order_provider.dart';
import '../../domain/entities/order.dart';
import '../../../chat/presentation/pages/chat_detail_page.dart';
import '../../../../theme/colors.dart';

class OrderDetailPage extends ConsumerWidget {
  final String orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        title: const Text('ORDER ARCHITECTURE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
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
              // EXPERT CHAT BRIDGE: Initiate context-aware chat
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusSection(context, order, ref),
              const SizedBox(height: 32),
              _buildClientInfo(context, order),
              const SizedBox(height: 32),
              _buildItemsList(context, order),
              const SizedBox(height: 32),
              _buildSummary(context, order),
              const SizedBox(height: 40),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
        error: (err, _) => Center(child: Text('Dossier sync failed: $err', style: const TextStyle(color: Colors.white38))),
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, OrderEntity order, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Current Status', style: TextStyle(color: Colors.grey)),
                Text(order.status.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 16),
            const LinearProgressIndicator(value: 0.4),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  _showStatusUpdateDialog(context, order, ref);
                },
                child: const Text('Update Status'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientInfo(BuildContext context, OrderEntity order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Client Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(order.clientName),
          subtitle: const Text('Tap to view profile'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pushNamed(context, '/client-detail', arguments: order.clientId);
          },
        ),
      ],
    );
  }

  Widget _buildItemsList(BuildContext context, OrderEntity order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        ...order.items.map((item) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(item.garmentType),
            subtitle: const Text('Standard size - Custom measurements'),
            trailing: Text('\$${item.price}', style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        )),
      ],
    );
  }

  Widget _buildSummary(BuildContext context, OrderEntity order) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 12),
        _PriceRow(label: 'Subtotal', value: '\$${order.totalAmount}'),
        const _PriceRow(label: 'Tax', value: '\$0.00'),
        const _PriceRow(label: 'Total', value: '\$250.00', isBold: true),
      ],
    );
  }

  void _showStatusUpdateDialog(BuildContext context, OrderEntity order, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: OrderStatus.values.map((status) => ListTile(
            title: Text(status.displayName),
            onTap: () {
              Navigator.pop(context);
              // Update status logic
            },
          )).toList(),
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  const _PriceRow({required this.label, required this.value, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
