import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/flutterwave_service.dart';
import '../../../../theme/colors.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  final double amount;
  final String orderId;

  const CheckoutPage({super.key, required this.amount, required this.orderId});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final FlutterwaveService _flutterwaveService = FlutterwaveService();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        title: const Text('CHECKOUT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderSummary(),
            const SizedBox(height: 48),
            const Text('PAYMENT ARCHITECTURE', style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 24),
            _buildPaymentMethodTile('SECURE DEBIT/CREDIT CARD', Icons.shield_rounded),
            _buildPaymentMethodTile('MOBILE MONEY GATEWAY', Icons.phone_android_rounded),
            _buildPaymentMethodTile('DIRECT BANK VERIFICATION', Icons.account_balance_rounded),
            const Spacer(),
            _buildPayButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL PAYABLE', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
              Text('₦${widget.amount.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.amber, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ORDER REFERENCE', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
              Text(widget.orderId.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.amber, size: 22),
          const SizedBox(width: 20),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5)),
          const Spacer(),
          const Icon(Icons.lock_outline_rounded, color: Colors.white24, size: 16),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _handlePayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.darkNavy,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: _isProcessing
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.darkNavy))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('INITIATE SECURE PAYMENT', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
                  const SizedBox(width: 12),
                  const Icon(Icons.bolt_rounded, size: 20),
                ],
              ),
      ),
    );
  }

  void _handlePayment() async {
    setState(() => _isProcessing = true);
    
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('Session Expired. Please log in.');
      }

      // DESBY REVENUE ARCHITECTURE: Check if this is a logistics transaction
      // For this audit, we assume ₦500 split if orderId contains 'ORD'
      final String? subaccount = widget.orderId.startsWith('ORD') ? 'DESBY_LOGISTICS_ACCOUNT' : null;

      // FLUTTERWAVE IMPLEMENTATION
      await _flutterwaveService.checkout(
        context: context,
        email: user.email,
        fullName: user.name,
        amount: widget.amount,
        orderId: widget.orderId,
        subAccountCode: subaccount,
        onSuccess: (txId) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PAYMENT VERIFIED: $txId'), backgroundColor: Colors.greenAccent),
          );
          Navigator.pop(context, true);
        },
        onCancel: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction Terminated by User.')),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('System Error: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
