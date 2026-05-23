import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';

class DispatchLogisticsModule extends StatefulWidget {
  const DispatchLogisticsModule({super.key});

  @override
  State<DispatchLogisticsModule> createState() => _DispatchLogisticsModuleState();
}

class _DispatchLogisticsModuleState extends State<DispatchLogisticsModule> {
  bool _useDispatch = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_rounded, color: AppColors.amber, size: 20),
              const SizedBox(width: 12),
              const Text(
                'STEP 3: LOGISTICS & DISPATCH',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Switch.adaptive(
                value: _useDispatch,
                activeTrackColor: AppColors.amber, // FIXED DEPRECATION
                onChanged: (v) => setState(() => _useDispatch = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Request a rider to pick up your fabric and deliver to the tailor.',
            style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w500),
          ),
          if (_useDispatch) ...[
            const SizedBox(height: 24),
            _buildDispatchCard(),
            const SizedBox(height: 16),
            _buildLogisticsNote(),
          ],
        ],
      ),
    );
  }

  Widget _buildDispatchCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFF141414),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.moped_rounded, color: AppColors.amber, size: 20),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('EXPRESS DISPATCH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                Text('Calculated by distance', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Text('₦4,900', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900, fontSize: 18)), // UPDATED PRICE
        ],
      ),
    );
  }

  Widget _buildLogisticsNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF00FF7F).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00FF7F).withValues(alpha: 0.1)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF00FF7F), size: 14),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Rider will be summoned automatically once the tailor accepts your booking.',
              style: TextStyle(color: Color(0xFF00FF7F), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
