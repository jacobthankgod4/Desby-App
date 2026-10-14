import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../providers/logistics_provider.dart';

class DispatchLogisticsModule extends ConsumerStatefulWidget {
  /// Tailor-side dispatch summary.
///
/// [destinationState] must be the order's real delivery state — pricing a
/// Lagos fee for a Kano order understates/overstates the cost shown.
  const DispatchLogisticsModule({super.key, this.destinationState = 'Lagos'});

  final String destinationState;

  @override
  ConsumerState<DispatchLogisticsModule> createState() =>
      _DispatchLogisticsModuleState();
}

class _DispatchLogisticsModuleState
    extends ConsumerState<DispatchLogisticsModule> {
  bool _useDispatch = false;
  double _dispatchFee = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchFee();
  }

  Future<void> _fetchFee() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(logisticsRepositoryProvider);
      final result = await repo.estimateCost(widget.destinationState);
      result.fold(
        (failure) => setState(() => _isLoading = false),
        (cost) => setState(() {
          _dispatchFee = cost;
          _isLoading = false;
        }),
      );
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.amber.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_shipping_rounded,
                color: AppColors.amber,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'STEP 3: LOGISTICS & DISPATCH',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Switch.adaptive(
                value: _useDispatch,
                activeThumbColor: AppColors.amber,
                activeTrackColor: AppColors.amber.withValues(alpha: 0.3),
                onChanged: (v) => setState(() => _useDispatch = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Request a rider to pick up your fabric and deliver to the tailor.',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
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
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.moped_rounded,
              color: AppColors.amber,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DISPATCH FEE',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Calculated by distance',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _isLoading ? '...' : '₦${_dispatchFee.toInt()}',
            style: const TextStyle(
              color: AppColors.amber,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogisticsNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.successGreen.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.successGreen,
            size: 14,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your finished outfit will be dispatched once your tailor marks your order READY. A Fez rider is summoned automatically at that point — typically 2-4 weeks while your custom garment is being made.',
              style: TextStyle(
                color: AppColors.successGreen,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
