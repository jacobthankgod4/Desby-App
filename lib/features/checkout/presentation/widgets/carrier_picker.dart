import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/spacing.dart';
import '../../../../theme/typography.dart';
import '../../../orders/domain/entities/delivery_booking.dart';
import '../../../orders/presentation/providers/logistics_provider.dart';

/// Lets the customer choose who delivers their order.
///
/// Terminal returns a competing offer from every carrier it can reach. Showing
/// only the cheapest throws away the aggregator's main advantage: DHL may beat
/// GIG on speed, Redstar on price. Each option states who delivers, what it
/// costs and roughly when it arrives, so the choice is an informed one.
class CarrierPicker extends ConsumerStatefulWidget {
  const CarrierPicker({
    super.key,
    required this.destinationState,
    required this.selected,
    required this.onChanged,
    this.weightKg = 1,
    this.itemValue = 0,
    this.description = 'Garment',
  });

  final String destinationState;

  /// Currently chosen carrier slug, or null for "cheapest".
  final String? selected;
  /// Receives null for "cheapest", or the chosen quote.
  final ValueChanged<DeliveryQuote?> onChanged;
  final double weightKg;
  final double itemValue;
  final String description;

  @override
  ConsumerState<CarrierPicker> createState() => _CarrierPickerState();
}

class _CarrierPickerState extends ConsumerState<CarrierPicker> {
  List<DeliveryQuote> _quotes = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CarrierPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.destinationState != widget.destinationState ||
        oldWidget.weightKg != widget.weightKg) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _fetchQuotes();
      if (!mounted) return;
      result.fold(
        (failure) => setState(() {
          _error = failure.message;
          _quotes = const [];
          _loading = false;
        }),
        (list) => setState(() {
          _quotes = list;
          _loading = false;
          _applyFallback(list);
        }),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load delivery options';
        _loading = false;
      });
    }
  }

  /// Reads the repository at call time so a provider swap is picked up.
  Future<Result<List<DeliveryQuote>>> _fetchQuotes() {
    return ref
        .read(logisticsRepositoryProvider)
        .quotes(
          destinationState: widget.destinationState,
          weightKg: widget.weightKg,
          value: widget.itemValue,
          description: widget.description,
        );
  }

  /// P21: if a previously chosen carrier stops quoting, fall back to cheapest
  /// rather than leaving a stale selection.
  void _applyFallback(List<DeliveryQuote> list) {
    if (list.isEmpty) {
      widget.onChanged(null);
      return;
    }
    final chosen = widget.selected;
    if (chosen != null && chosen.isNotEmpty) {
      final stillOffered = list.any(
        (q) =>
            q.carrierSlug == chosen ||
            q.carrierName.toLowerCase() == chosen.toLowerCase(),
      );
      if (stillOffered) return;
    }
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DELIVERY OPTION',
              style: AppTypography.overline.copyWith(
                fontSize: 12,
                color: colors.borderFocused,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            if (!_loading && _quotes.length > 1)
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Refresh'),
                style: TextButton.styleFrom(
                  foregroundColor: colors.textMuted,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_loading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Checking couriers…',
              style: AppTypography.caption.copyWith(color: colors.textMuted),
            ),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _error!,
              style: AppTypography.caption.copyWith(color: colors.statusWarning),
            ),
          )
        else if (_quotes.isEmpty)
          Text(
            'No courier available for this destination yet.',
            style: AppTypography.caption.copyWith(color: colors.textMuted),
          )
        else
          ..._quotes.take(5).map(_option),
      ],
    );
  }

  Widget _option(DeliveryQuote q) {
    final colors = context.colors;
    final isCheapest = _quotes.isNotEmpty && q.rateId == _quotes.first.rateId;
    final isSelected = widget.selected == null
        ? isCheapest
        : (widget.selected == q.carrierSlug ||
            widget.selected!.toLowerCase() == q.carrierName.toLowerCase());

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => widget.onChanged(isCheapest ? null : q),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colors.overlayLight : colors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.md),
            border: Border.all(
              color: isSelected ? AppColors.amber : colors.borderSubtle,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 18,
                color: isSelected ? AppColors.amber : colors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            q.carrierName,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.subtitle1.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isCheapest) ...[
                          const SizedBox(width: 8),
                          _tag('CHEAPEST'),
                        ],
                        // P20: only surface COD when the carrier actually
                        // offers it — never imply it when it is unavailable.
                        if (q.supportsCod) ...[
                          const SizedBox(width: 6),
                          _tag('COD'),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      q.etaLabel,
                      style: AppTypography.caption
                          .copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '₦${q.amount.toStringAsFixed(0)}',
                style: AppTypography.headline6.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.amber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            fontSize: 9,
            color: AppColors.amber,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      );
}