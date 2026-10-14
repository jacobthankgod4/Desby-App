import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/shell_app_bar.dart';

class AiPricingPage extends ConsumerStatefulWidget {
  const AiPricingPage({super.key});

  @override
  ConsumerState<AiPricingPage> createState() => _AiPricingPageState();
}

class _AiPricingPageState extends ConsumerState<AiPricingPage> {
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _originController = TextEditingController();
  final _weightController = TextEditingController();
  String _suggestion = '';
  bool _isLoading = false;

  Future<void> _getSuggestion() async {
    if (_nameController.text.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      // Use a simple heuristic-based pricing suggestion
      final name = _nameController.text.toLowerCase();
      final origin = _originController.text.toLowerCase();

      double basePrice = 2000; // Default ₦2,000/yard

      // Category adjustments
      if (name.contains('silk') || name.contains('lace'))
        basePrice = 8000;
      else if (name.contains('damask'))
        basePrice = 5000;
      else if (name.contains('ankara'))
        basePrice = 2500;
      else if (name.contains('cotton'))
        basePrice = 2000;
      else if (name.contains('linen'))
        basePrice = 3500;
      else if (name.contains('wool'))
        basePrice = 6000;
      else if (name.contains('velvet'))
        basePrice = 4500;
      else if (name.contains('chiffon'))
        basePrice = 3000;
      else if (name.contains('satin'))
        basePrice = 3500;
      else if (name.contains('crepe'))
        basePrice = 2800;

      // Origin adjustments
      if (origin.contains('italy') || origin.contains('milan'))
        basePrice *= 1.5;
      else if (origin.contains('india'))
        basePrice *= 0.8;
      else if (origin.contains('nigeria') || origin.contains('local'))
        basePrice *= 0.9;

      // Weight adjustments
      final weight =
          double.tryParse(
            _weightController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ??
          0;
      if (weight > 300) basePrice *= 1.2;

      final suggested = basePrice.round();
      final minPrice = (suggested * 0.8).round();
      final maxPrice = (suggested * 1.3).round();

      setState(() {
        _suggestion =
            'Suggested: ₦${suggested.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}/yard\n'
            'Range: ₦${minPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} - '
            '₦${maxPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}/yard\n\n'
            'This is based on category, origin, and market rates. Adjust as needed for your shop.';
      });
    } catch (e) {
      setState(
        () => _suggestion = 'Could not generate suggestion. Please try again.',
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(
        context,
        title: 'AI PRICING',
        foregroundColor: colors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Get a smart price suggestion for your fabric based on category, origin, and market rates.',
            style: TextStyle(
              fontSize: 13,
              color: colors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          _buildField(
            _nameController,
            'Fabric name',
            'e.g. Premium Silk Lace',
            colors,
          ),
          const SizedBox(height: 12),
          _buildField(
            _categoryController,
            'Category',
            'e.g. Lace, Silk, Ankara',
            colors,
          ),
          const SizedBox(height: 12),
          _buildField(
            _originController,
            'Origin',
            'e.g. Italy, Nigeria, India',
            colors,
          ),
          const SizedBox(height: 12),
          _buildField(
            _weightController,
            'Weight (optional)',
            'e.g. 200gsm',
            colors,
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _isLoading ? null : _getSuggestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: colors.textOnAmber,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'GET PRICE SUGGESTION',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
          ),

          if (_suggestion.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.amber.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: AppColors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SUGGESTED PRICING',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: AppColors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _suggestion,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textPrimary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    String hint,
    dynamic colors,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.textMuted, fontSize: 13),
        hintText: hint,
        hintStyle: TextStyle(color: colors.textHint, fontSize: 13),
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.borderDefault),
        ),
      ),
    );
  }
}
