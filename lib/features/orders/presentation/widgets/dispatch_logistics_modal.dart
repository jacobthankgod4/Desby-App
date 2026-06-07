import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/luxury_glass_card.dart';

class DispatchLogisticsModal extends StatefulWidget {
  const DispatchLogisticsModal({super.key});

  @override
  State<DispatchLogisticsModal> createState() => _DispatchLogisticsModalState();
}

class _DispatchLogisticsModalState extends State<DispatchLogisticsModal> {
  String _serviceLevel = 'Standard'; // Standard vs Luxury Express
  String _timeline = 'Next Day';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Color(0xFF0A1921),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_shipping_rounded, color: AppColors.amber, size: 24),
              SizedBox(width: 12),
              Text(
                'LOGISTICS CONFIGURATION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Secure Material Transfer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Desby OS manages the end-to-end custody of your fabrics. Select your preferred service level below.',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          
          const Text(
            'SERVICE LEVEL',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildServiceOption('Standard', '₦4,900', Icons.moped_rounded),
              const SizedBox(width: 16),
              _buildServiceOption('Luxury Express', '₦12,500', Icons.auto_awesome_rounded),
            ],
          ),
          
          const SizedBox(height: 32),
          const Text(
            'DISPATCH TIMELINE',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildTimelineSelector(),
          
          const SizedBox(height: 32),
          LuxuryGlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.shield_rounded, color: Color(0xFF00FF7F), size: 20),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SECURE CUSTODY GUARANTEE',
                        style: TextStyle(
                          color: Color(0xFF00FF7F),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'Full insurance coverage for high-value fabrics.',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text(
                  _serviceLevel == 'Standard' ? '₦4,900' : '₦12,500',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: AppColors.darkNavy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'SAVE CONFIGURATION',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceOption(String name, String price, IconData icon) {
    final bool isSelected = _serviceLevel == name;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _serviceLevel = name),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.amber.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.amber : Colors.white10,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: isSelected ? AppColors.amber : Colors.white24, size: 24),
              const SizedBox(height: 16),
              Text(
                name.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                price,
                style: TextStyle(
                  color: isSelected ? AppColors.amber : Colors.white24,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineSelector() {
    final options = ['Immediate', 'Next Day', 'Scheduled'];
    return Row(
      children: options.map((opt) {
        final bool isSelected = _timeline == opt;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _timeline = opt),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.amber : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  opt.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? AppColors.darkNavy : Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
