import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/luxury_glass_card.dart';
import '../providers/logistics_provider.dart';

class DispatchLogisticsModal extends ConsumerStatefulWidget {
  /// Full-screen variant of the dispatch summary.
  const DispatchLogisticsModal({super.key, this.destinationState = 'Lagos'});

  final String destinationState;

  @override
  ConsumerState<DispatchLogisticsModal> createState() =>
      _DispatchLogisticsModalState();
}

class _DispatchLogisticsModalState extends ConsumerState<DispatchLogisticsModal> {
  String _serviceLevel = 'Standard';
  String _timeline = 'Next Day';
  double _standardFee = 0.0;
  double _expressFee = 0.0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchFees();
  }

  Future<void> _fetchFees() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(logisticsRepositoryProvider);
      final result = await repo.estimateCost(widget.destinationState);
      result.fold(
        (failure) {
          setState(() {
            _error = failure.message;
            _isLoading = false;
          });
        },
        (cost) {
          setState(() {
            _standardFee = cost;
            _expressFee = cost * 2.5;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch delivery estimates: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.bottomSheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_shipping_rounded,
                color: AppColors.amber,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Delivery Options',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'We will safely deliver your fabric',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Desby OS manages the end-to-end custody of your fabrics. Select your preferred service level below.',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.amber),
              ),
            )
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchFees,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amber,
                        foregroundColor: AppColors.darkNavy,
                      ),
                      child: const Text('RETRY',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Text(
              'Shipping Speed',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildServiceOption(
                    'Standard', '₦${_standardFee.toInt()}', Icons.moped_rounded),
                const SizedBox(width: 16),
                _buildServiceOption('Luxury Express',
                    '₦${_expressFee.toInt()}', Icons.auto_awesome_rounded),
              ],
            ),

            const SizedBox(height: 32),
            Text(
              'When should it arrive?',
              style: TextStyle(
                color: colors.textMuted,
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
                  const Icon(
                    Icons.shield_rounded,
                    color: AppColors.successGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Insurance included',
                          style: TextStyle(
                            color: AppColors.successGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          'Full insurance coverage for high-value fabrics.',
                          style:
                              TextStyle(color: colors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _serviceLevel == 'Standard'
                        ? '₦${_standardFee.toInt()}'
                        : '₦${_expressFee.toInt()}',
                    style: TextStyle(
                      color: colors.textPrimary,
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceOption(String name, String price, IconData icon) {
    final colors = context.colors;
    final bool isSelected = _serviceLevel == name;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _serviceLevel = name),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.amber.withValues(alpha: 0.1)
                : colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.amber : colors.borderSubtle,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.amber : colors.textMuted,
                size: 24,
              ),
              const SizedBox(height: 16),
              Text(
                name.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? colors.textPrimary : colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                price,
                style: TextStyle(
                  color: isSelected ? AppColors.amber : colors.textMuted,
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
    final colors = context.colors;
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
                color: isSelected ? AppColors.amber : colors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  opt.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? AppColors.darkNavy : colors.textMuted,
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
