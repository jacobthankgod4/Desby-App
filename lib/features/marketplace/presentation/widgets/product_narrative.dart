import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';

class ProductNarrative extends StatelessWidget {
  final String? fabricName;
  final String? composition;
  final String? weight;
  const ProductNarrative({super.key, this.fabricName, this.composition, this.weight});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('STORY & UTILITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 3, color: Colors.white38)),
        const SizedBox(height: 24),
        
        Text(
          'Elevate your craft with the finest ${fabricName ?? 'mulberry silk'} imported directly from the Lombardy region.',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1.4, letterSpacing: -0.5),
        ),
        const SizedBox(height: 24),
        
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This ${fabricName ?? 'Midnight Navy Charmeuse silk'} ${composition != null ? 'composed of $composition ' : ''}is engineered for high-end bespoke tailoring. It provides a substantial yet fluid drape, ideal for formal gowns and luxury lining. The high-sheen gloss finish ensures a professional aesthetic.',
                style: const TextStyle(fontSize: 16, color: AppColors.darkNavy, height: 1.8),
              ),
              const SizedBox(height: 48),
              
              const Text('DISTINGUISHING FEATURES', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2, color: AppColors.amber)),
              const SizedBox(height: 28),
              _buildHighlight('Master Grade', 'Tear-resistant and holds sharp creases for precision tailoring.', Icons.architecture_rounded),
              _buildHighlight('Sustainable Origin', 'Organic mulberry fibers harvested with eco-conscious protocols.', Icons.eco_outlined),
              _buildHighlight('Color Locked', 'Deep dye technology prevents fading after professional cleaning.', Icons.invert_colors_on_rounded),
            ],
          ),
        ),
        
        const SizedBox(height: 48),
        _buildProtectionSection(),
      ],
    );
  }

  Widget _buildHighlight(String title, String desc, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.darkGreen.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.darkGreen, size: 18),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.darkNavy)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtectionSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5), // Soft grey-white for the footer trust section
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DESBY PROTECTION TECHNOLOGY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blue, letterSpacing: 2)),
          const SizedBox(height: 16),
          const Text('Secure Fabric Sourcing', style: TextStyle(color: AppColors.darkNavy, fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 28),
          _buildTrustItem(Icons.verified_user_outlined, 'Merchant Verification', 'Every bolt is physically inspected.'),
          _buildTrustItem(Icons.security_outlined, 'Escrow Protection', 'Funds released only upon your quality approval.'),
          _buildTrustItem(Icons.replay_rounded, 'Quality Mandate', 'Direct return portal for material defects.'),
        ],
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.darkNavy)),
                  TextSpan(text: sub, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
