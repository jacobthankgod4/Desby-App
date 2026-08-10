import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';

class TrustActionFooter extends StatelessWidget {
  final double? amount;
  final String? orderId;
  const TrustActionFooter({super.key, this.amount, this.orderId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1921),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 40)],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Secure Ecosystem Guarantee', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                SizedBox(height: 8),
                Text('Your payments are held in secure escrow until you physically verify the fabric quality.', style: TextStyle(color: Colors.white38, fontSize: 14, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 60),
          ElevatedButton(
            onPressed: () {
              // COMMERCIAL BRIDGE: Marketplace to Checkout
              Navigator.pushNamed(
                context, 
                '/checkout', 
                arguments: {
                  'amount': amount ?? 85000.0, // Calibrated standard fabric purchase
                  'orderId': orderId ?? 'MKT_${DateTime.now().millisecondsSinceEpoch}',
                }
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: AppColors.darkNavy,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 22),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 0,
            ),
            child: const Text('PURCHASE NOW', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
          ),
          const SizedBox(width: 20),
          TextButton(
            onPressed: () {},
            child: const Text('MAKE AN OFFER', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }
}
