import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';
import '../widgets/specification_table.dart';
import '../widgets/product_narrative.dart';
import '../widgets/seller_trust_card.dart';
import '../widgets/trust_action_footer.dart';

class FabricDetailsPage extends StatelessWidget {
  final String fabricName;
  final double price;

  const FabricDetailsPage({super.key, required this.fabricName, required this.price});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1921), // Unified True Dark Navy
      appBar: AppBar(
        title: const Text('LISTING DETAILS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Branding Orbs
          Positioned(top: -50, right: -50, child: _buildOrb(AppColors.darkGreen.withValues(alpha: 0.15), 300)),
          Positioned(bottom: 200, left: -100, child: _buildOrb(AppColors.amber.withValues(alpha: 0.1), 300)),

          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ZONE A: DISCOVERY ZONE
                _buildDiscoveryZone(context),
                
                // ZONE B: EVALUATION ZONE
                _buildEvaluationZone(context),
                
                // ZONE C: TRUST & ACTION ZONE
                const SizedBox(height: 40),
                const TrustActionFooter(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb(Color color, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)),
    );
  }

  Widget _buildDiscoveryZone(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Gallery with Glassmorphism
          Container(
            height: 400, width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Center(child: Icon(Icons.texture_rounded, size: 120, color: AppColors.amber)),
          ),
          const SizedBox(height: 32),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fabricName, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: AppColors.darkGreen.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                          child: const Text('PREMIUM GRADE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.darkGreen, letterSpacing: 1)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Text('VERIFIED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.amber, letterSpacing: 1)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text('₦${price.toStringAsFixed(0)} / yard', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.amber)),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              const SizedBox(width: 340, child: SellerTrustCard()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationZone(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          const Text('TECHNICAL SPECIFICATIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 3, color: Colors.white38)),
          const SizedBox(height: 20),
          const SpecificationTable(),
          
          const SizedBox(height: 60),
          const ProductNarrative(),
          
          const SizedBox(height: 60),
          _buildStoreInformation(),
        ],
      ),
    );
  }

  Widget _buildStoreInformation() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront_outlined, color: AppColors.amber, size: 22),
              const SizedBox(width: 16),
              Text('Global Distribution Hub', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              Spacer(),
              Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white24),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Mainland Tech District, Lagos • Verified Desby Location', style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}
