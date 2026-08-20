import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/order.dart';
import '../providers/order_provider.dart';

class PriceEstimationPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> tailor;

  const PriceEstimationPage({super.key, required this.tailor});

  @override
  ConsumerState<PriceEstimationPage> createState() => _PriceEstimationPageState();
}

class _PriceEstimationPageState extends ConsumerState<PriceEstimationPage> {
  bool _isCreating = false;

  Future<void> _confirmBooking() async {
    setState(() => _isCreating = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final orderId = 'ORD_${DateTime.now().millisecondsSinceEpoch}';
      final order = OrderEntity(
        id: orderId,
        clientId: user.id,
        tailorId: widget.tailor['id'] ?? widget.tailor['tailorId'],
        clientName: user.name,
        status: OrderStatus.pending,
        totalAmount: 85000.0, // Fixed estimate for MVP
        dueDate: DateTime.now().add(const Duration(days: 14)),
        createdAt: DateTime.now(),
        items: const [
          OrderItem(id: 'item_1', garmentType: 'Suit', price: 85000.0),
        ],
      );

      final result = await ref.read(createOrderUsecaseProvider)(order);
      
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking Failed: $failure'), backgroundColor: Colors.redAccent));
        },
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('BOOKING SENT TO MASTER!'), backgroundColor: Colors.greenAccent));
          ref.setShell('/main');
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      );
    } catch (e) {
      debugPrint('Booking Error: $e');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        title: const Text('PRICE ESTIMATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.calculate_rounded, color: AppColors.amber, size: 48),
                  const SizedBox(height: 24),
                  const Text('ARCHITECTURAL ESTIMATE', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  const SizedBox(height: 12),
                  const Text('₦85,000', style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -2)),
                  const SizedBox(height: 8),
                  Text('ESTIMATED WITH ${widget.tailor['name']?.toUpperCase()}', style: const TextStyle(color: AppColors.amber, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildCostLine('Base Stitching', '₦45,000'),
            _buildCostLine('Material Logistics', '₦15,000'),
            _buildCostLine('Premium Finishing', '₦25,000'),
            const Divider(color: Colors.white10, height: 48),
            _buildCostLine('Total Amount', '₦85,000', isTotal: true),
            
            const SizedBox(height: 56),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: AppColors.darkNavy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: _isCreating 
                  ? const CircularProgressIndicator()
                  : const Text('CONFIRM BOOKING', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostLine(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isTotal ? Colors.white : Colors.white60, fontSize: isTotal ? 14 : 12, fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600)),
          Text(value, style: TextStyle(color: isTotal ? AppColors.amber : Colors.white, fontSize: isTotal ? 20 : 13, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
