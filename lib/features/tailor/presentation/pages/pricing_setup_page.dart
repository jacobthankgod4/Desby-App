import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/onboarding_scaffold.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class PricingSetupPage extends ConsumerStatefulWidget {
  const PricingSetupPage({super.key});

  @override
  ConsumerState<PricingSetupPage> createState() => _PricingSetupPageState();
}

class _PricingSetupPageState extends ConsumerState<PricingSetupPage> {
  final _stitchingController = TextEditingController(text: '45000');
  final _materialController = TextEditingController(text: '12500');
  final _startingController = TextEditingController(text: '20000');
  bool _isLoading = false;

  @override
  void dispose() {
    _stitchingController.dispose();
    _materialController.dispose();
    _startingController.dispose();
    super.dispose();
  }

  String _formatCurrency(double value) {
    return '₦${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  Future<void> _savePricing() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final currentProfile = await ref.read(userProfileProvider(user.id).future);
      if (currentProfile == null) return;

      final stitchingPrice = double.tryParse(_stitchingController.text) ?? 45000;
      final materialCost = double.tryParse(_materialController.text) ?? 12500;
      final startingPrice = double.tryParse(_startingController.text) ?? 20000;

      final updatedProfile = currentProfile.copyWith(
        baseStitchingPrice: stitchingPrice,
        materialCost: materialCost,
        startingPrice: startingPrice,
        hasPricing: true,
        updatedAt: DateTime.now(),
      );

      await ref.read(updateProfileUsecaseProvider)(updatedProfile);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pricing saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving pricing: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        title: const Text('PRICING SETUP', 
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_money_rounded, color: AppColors.amber, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Set Your Pricing', 
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text('Configure your rates to receive bookings from clients',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Pricing Fields
            const Text('BASE STITCHING PRICE', 
              style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 8),
            _buildPriceField(_stitchingController, 'Your standard stitching fee per garment'),
            const SizedBox(height: 24),

            const Text('MATERIAL LOGISTICS COST', 
              style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 8),
            _buildPriceField(_materialController, 'Average fabric cost passed to client'),
            const SizedBox(height: 24),

            const Text('STARTING BOOKING PRICE', 
              style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 8),
            _buildPriceField(_startingController, 'Minimum amount to start a bespoke project'),
            const SizedBox(height: 32),

            // Preview
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CLIENT PRICE PREVIEW', 
                    style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  const SizedBox(height: 16),
                  _buildPreviewRow('Starting from', _startingController),
                  _buildPreviewRow('Base stitching', _stitchingController),
                  _buildPreviewRow('Material logistics', _materialController),
                  const Divider(color: Colors.white12, height: 24),
                  _buildTotalRow(),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePricing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: AppColors.darkNavy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3))
                    : const Text('SAVE PRICING', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
              ),
            ),
            const SizedBox(height: 16),

            // Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Logistics fees will be added at checkout based on client location.',
                      style: TextStyle(color: Colors.blue.withValues(alpha: 0.8), fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24),
      decoration: InputDecoration(
        prefixText: '₦ ', 
        prefixStyle: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900, fontSize: 24),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.amber),
        ),
      ),
    );
  }

  Widget _buildPreviewRow(String label, TextEditingController controller) {
    final value = double.tryParse(controller.text) ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(_formatCurrency(value), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildTotalRow() {
    final stitching = double.tryParse(_stitchingController.text) ?? 0;
    final material = double.tryParse(_materialController.text) ?? 0;
    final total = stitching + material;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('ESTIMATED TOTAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        Text(_formatCurrency(total), style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900, fontSize: 20)),
      ],
    );
  }
}
