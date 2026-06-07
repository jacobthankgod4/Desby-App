import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/payment.dart';
import '../providers/payment_provider.dart';
import '../providers/payment_state.dart';

/// Payment Page for checkout and payment processing
class PaymentPage extends ConsumerStatefulWidget {
  final String orderId;
  final double amount;
  final String description;
  final String? userEmail;
  final String? userName;
  final VoidCallback? onPaymentSuccess;
  final Function(String)? onPaymentError;

  const PaymentPage({
    Key? key,
    required this.orderId,
    required this.amount,
    required this.description,
    this.userEmail,
    this.userName,
    this.onPaymentSuccess,
    this.onPaymentError,
  }) : super(key: key);

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  PaymentMethod _selectedMethod = PaymentMethod.card;

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentStateProvider);
    final isProcessing = ref.watch(isPaymentInProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        centerTitle: true,
        elevation: 0,
      ),
      body: paymentState.when(
        initial: () => _buildPaymentForm(),
        loading: (message) => _buildLoadingState(message),
        initiated: (ref) => _buildLoadingState('Processing payment...'),
        verifying: (ref) => _buildLoadingState('Verifying payment...'),
        success: (transaction) => _buildSuccessState(transaction),
        error: (message, error) => _buildErrorState(message),
        cancelled: (message) => _buildCancelledState(message),
      ),
    );
  }

  /// Build payment form
  Widget _buildPaymentForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Summary Card
          _buildOrderSummaryCard(),
          const SizedBox(height: 24),

          // Payment Method Selection
          _buildPaymentMethodSection(),
          const SizedBox(height: 24),

          // Order Details
          _buildOrderDetailsSection(),
          const SizedBox(height: 32),

          // Pay Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Proceed to Payment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build order summary card
  Widget _buildOrderSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '₦${widget.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build payment method section
  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...[
          PaymentMethod.card,
          PaymentMethod.bankTransfer,
          PaymentMethod.mobileMoney,
        ].map((method) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPaymentMethodOption(method),
          );
        }).toList(),
      ],
    );
  }

  /// Build payment method option
  Widget _buildPaymentMethodOption(PaymentMethod method) {
    final isSelected = _selectedMethod == method;
    final icon = _getMethodIcon(method);
    final label = _getMethodLabel(method);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.blue.shade50 : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.blue : Colors.grey.shade700,
              ),
            ),
            const Spacer(),
            Radio<PaymentMethod>(
              value: method,
              groupValue: _selectedMethod,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedMethod = value;
                  });
                }
              },
              activeColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  /// Build order details section
  Widget _buildOrderDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailRow('Order ID', widget.orderId),
        _buildDetailRow('Description', widget.description),
        if (widget.userEmail != null)
          _buildDetailRow('Email', widget.userEmail!),
        if (widget.userName != null)
          _buildDetailRow('Name', widget.userName!),
      ],
    );
  }

  /// Build detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build loading state
  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// Build success state
  Widget _buildSuccessState(dynamic transaction) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: 40,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Payment Successful!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₦${widget.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              widget.onPaymentSuccess?.call();
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error,
              size: 40,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Payment Failed',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  ref.read(paymentStateProvider.notifier).reset();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: const Text('Try Again'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  widget.onPaymentError?.call(message);
                  Navigator.pop(context, false);
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build cancelled state
  Widget _buildCancelledState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close,
              size: 40,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Payment Cancelled',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.read(paymentStateProvider.notifier).reset();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  /// Process payment
  void _processPayment() {
    ref.read(paymentStateProvider.notifier).processPayment(
      amount: widget.amount,
      method: _selectedMethod,
      orderId: widget.orderId,
    );
  }

  /// Get payment method icon
  IconData _getMethodIcon(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.card => Icons.credit_card,
      PaymentMethod.bankTransfer => Icons.account_balance,
      PaymentMethod.mobileMoney => Icons.phone_iphone,
      PaymentMethod.cash => Icons.money,
    };
  }

  /// Get payment method label
  String _getMethodLabel(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.card => 'Card Payment',
      PaymentMethod.bankTransfer => 'Bank Transfer',
      PaymentMethod.mobileMoney => 'Mobile Money',
      PaymentMethod.cash => 'Cash on Delivery',
    };
  }
}
