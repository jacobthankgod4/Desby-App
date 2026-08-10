import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';

class SellerTrustCard extends StatelessWidget {
  final String? sellerId;
  const SellerTrustCard({super.key, this.sellerId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 30, backgroundColor: AppColors.darkNavy, child: Text('IT', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold, fontSize: 18))),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Italian Silk Masters', style: TextStyle(color: AppColors.darkNavy, fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -0.5)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.amber, size: 16),
                        const SizedBox(width: 4),
                        const Text('4.9', style: TextStyle(color: AppColors.darkNavy, fontSize: 12, fontWeight: FontWeight.w900)),
                        const SizedBox(width: 4),
                        Text('(128 Reviews)', style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Divider(color: Colors.grey[100]),
          const SizedBox(height: 20),
          _buildTrustStat('Response Rate', '98%', Colors.green),
          _buildTrustStat('Avg. Delivery', '3 days', AppColors.amber),
          _buildTrustStat('Merchant Tier', 'Master', Colors.blue),
          const SizedBox(height: 28),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              side: const BorderSide(color: AppColors.darkNavy),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              backgroundColor: const Color(0xFFF8F9FA),
            ),
            child: const Text('VIEW MERCHANT PORTFOLIO', style: TextStyle(color: AppColors.darkNavy, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustStat(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label.toUpperCase(), style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: color)),
        ],
      ),
    );
  }
}
