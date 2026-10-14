import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../../core/widgets/shell_app_bar.dart';
import '../../../../core/widgets/price_text_field.dart';

class PricingSetupPage extends ConsumerStatefulWidget {
  const PricingSetupPage({super.key});

  @override
  ConsumerState<PricingSetupPage> createState() => _PricingSetupPageState();
}

class _PricingSetupPageState extends ConsumerState<PricingSetupPage> {
  final _stitchingController = TextEditingController();
  final _materialController = TextEditingController();
  final _startingController = TextEditingController();

  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadPricing();
  }

  Future<void> _loadPricing() async {
    if (_isInitialized) return;

    final user = ref.read(currentUserProvider);
    if (user != null) {
      final profile = await ref.read(userProfileProvider(user.id).future);
      if (profile != null && mounted) {
        setState(() {
          // Real saved values are shown formatted; unset values stay empty so
          // the grey hint is displayed instead of a fake default price.
          _stitchingController.text = profile.baseStitchingPrice == null
              ? ''
              : formatPriceDigits(
                  profile.baseStitchingPrice!.toInt().toString(),
                );
          _materialController.text = profile.materialCost == null
              ? ''
              : formatPriceDigits(profile.materialCost!.toInt().toString());
          _startingController.text = profile.startingPrice == null
              ? ''
              : formatPriceDigits(profile.startingPrice!.toInt().toString());
          _isInitialized = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _stitchingController.dispose();
    _materialController.dispose();
    _startingController.dispose();
    super.dispose();
  }

  String _formatCurrency(double value) {
    final formatted = value.toStringAsFixed(0);
    final result = StringBuffer();
    for (int i = 0; i < formatted.length; i++) {
      if (i > 0 && (formatted.length - i) % 3 == 0) {
        result.write(',');
      }
      result.write(formatted[i]);
    }
    return '₦${result.toString()}';
  }

  Future<void> _savePricing() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null || user.id.isEmpty) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Your session expired. Please sign in again.',
              ),
              backgroundColor: context.colors.statusError,
            ),
          );
        return;
      }

      final currentProfile = await ref.read(
        userProfileProvider(user.id).future,
      );
      if (currentProfile == null) return;

      // Strip thousands separators; an empty field means "leave unchanged"
      // so hint text is never persisted as a real price.
      final stitchingText = priceToDigits(_stitchingController.text);
      final materialText = priceToDigits(_materialController.text);
      final startingText = priceToDigits(_startingController.text);

      final stitchingPrice = stitchingText.isEmpty
          ? currentProfile.baseStitchingPrice
          : double.tryParse(stitchingText);
      final materialCost = materialText.isEmpty
          ? currentProfile.materialCost
          : double.tryParse(materialText);
      final startingPrice = startingText.isEmpty
          ? currentProfile.startingPrice
          : double.tryParse(startingText);

      final hasAnyPrice =
          stitchingPrice != null ||
          materialCost != null ||
          startingPrice != null;
      if (!hasAnyPrice && !currentProfile.hasPricing) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Enter at least one price to continue.'),
              backgroundColor: context.colors.statusError,
            ),
          );
        }
        return;
      }

      final updatedProfile = currentProfile.copyWith(
        baseStitchingPrice: stitchingPrice,
        materialCost: materialCost,
        startingPrice: startingPrice,
        hasPricing: hasAnyPrice,
        userType: 'tailor', // ENSURE role is consistent
        updatedAt: DateTime.now(),
      );

      await ref.read(updateProfileUsecaseProvider)(updatedProfile);

      // REFRESH: Clear cached empty or stale profile
      ref.invalidate(userProfileProvider(user.id));
      await ref.read(userProfileProvider(user.id).future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pricing saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        if (ref.canPopShell) {
          ref.popShell();
        } else {
          ref.setShell('/main');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save pricing. Please try again.'),
            backgroundColor: context.colors.statusError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(context, title: 'Set Your Pricing'),
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
                border: Border.all(color: colors.borderDefault, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.attach_money_rounded,
                    color: AppColors.amber,
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set Your Pricing',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Configure your rates to receive bookings from clients',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Pricing Fields
            const Text(
              'Stitching Fee',
              style: TextStyle(
                color: AppColors.amber,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            _buildPriceField(
              _stitchingController,
              'Your standard stitching fee per garment',
            ),
            const SizedBox(height: 24),

            const Text(
              'Material Cost',
              style: TextStyle(
                color: AppColors.amber,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            _buildPriceField(
              _materialController,
              'Average fabric cost passed to client',
            ),
            const SizedBox(height: 24),

            const Text(
              'STARTING BOOKING PRICE',
              style: TextStyle(
                color: AppColors.amber,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            _buildPriceField(
              _startingController,
              'Minimum amount to start a bespoke project',
            ),
            const SizedBox(height: 32),

            // Preview
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What Clients Will See',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPreviewRow('Starting from', _startingController),
                  _buildPreviewRow('Base stitching', _stitchingController),
                  _buildPreviewRow('Material logistics', _materialController),
                  Divider(color: colors.borderSubtle, height: 24),
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
                  foregroundColor: colors.scaffoldBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : const Text(
                        'Save Pricing',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1.5,
                        ),
                      ),
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
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Logistics fees will be added at checkout based on client location.',
                      style: TextStyle(
                        color: Colors.blue.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hint,
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: priceInputFormatters,
          onChanged: (_) => setState(() {}),
          style: TextStyle(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
          decoration: InputDecoration(
            prefixText: '₦ ',
            prefixStyle: TextStyle(
              color: AppColors.amber,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
            filled: true,
            fillColor: context.colors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: context.colors.borderDefault),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: context.colors.borderDefault),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.amber, width: 2),
            ),
            hintText: 'e.g. 45,000',
            hintStyle: TextStyle(
              color: context.colors.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewRow(String label, TextEditingController controller) {
    final value = double.tryParse(priceToDigits(controller.text)) ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
          ),
          Text(
            _formatCurrency(value),
            style: TextStyle(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow() {
    final stitching =
        double.tryParse(priceToDigits(_stitchingController.text)) ?? 0;
    final material =
        double.tryParse(priceToDigits(_materialController.text)) ?? 0;
    final total = stitching + material;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'ESTIMATED TOTAL',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          _formatCurrency(total),
          style: TextStyle(
            color: AppColors.amber,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ],
    );
  }
}
