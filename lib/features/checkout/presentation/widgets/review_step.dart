import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_network_image.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/spacing.dart';
import '../../../../theme/typography.dart';
import '../../domain/entities/checkout_draft.dart';
import 'delivery_and_estimate.dart';
import '../providers/checkout_draft_provider.dart';

/// Step 6 — the review.
///
/// Every section has an Edit that returns the client to exactly that step. The
/// point is that they can see the whole request as their tailor will read it
/// before it is sent.
class ReviewStep extends ConsumerWidget {
  const ReviewStep({super.key, required this.onEdit, required this.onSubmit});

  final ValueChanged<CheckoutStep> onEdit;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(checkoutDraftControllerProvider);
    final colors = context.colors;
    if (draft == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          'This is what you are requesting',
          style: AppTypography.headline5.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Read it as your tailor will. Nothing is sent until you confirm.',
          style: AppTypography.caption.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: AppSpacing.lg),

        _ReviewSection(
          label: 'Tailor',
          step: null,
          onEdit: null,
          rows: [
            _Row('Name', draft.tailor?.name ?? '—'),
          ],
        ),
        if (draft.product != null)
          _ReviewSection(
            label: 'Design',
            step: null,
            onEdit: null,
            leading: draft.product!.imageUrls.isEmpty
                ? null
                : AppNetworkImage(
                    url: draft.product!.imageUrls.first,
                    width: 56,
                    height: 70,
                  ),
            rows: [
              _Row('Design', draft.product!.title ?? '—'),
              if (draft.product!.category != null)
                _Row('Category', draft.product!.category!),
              if (draft.product!.selectedSize != null)
                _Row('Size', draft.product!.selectedSize!),
              if (draft.product!.selectedColour != null)
                _Row('Colour', draft.product!.selectedColour!),
              if (draft.product!.price != null)
                _Row('From', '₦${draft.product!.price!.toStringAsFixed(0)}'),
            ],
          ),

        _ReviewSection(
          label: 'What they want',
          step: CheckoutStep.defineRequest,
          onEdit: onEdit,
          rows: [
            _Row(
              'Garment',
              draft.entryMode.needsGarmentDefinition
                  ? (draft.request.garmentType ?? 'Not chosen yet')
                  : (draft.request.garmentType ??
                      '${draft.product?.title ?? 'Selected design'} (as shown)'),
            ),
            if (draft.request.wantsSomethingDifferent)
              const _Row('Note', 'Something different from the design'),
            if ((draft.request.summary ?? '').isNotEmpty)
              _Row('In your words', draft.request.summary!, multiline: true),
          ],
        ),

        _ReviewSection(
          label: 'Style',
          step: CheckoutStep.styleDirection,
          onEdit: onEdit,
          empty: draft.style.isEmpty,
          rows: [
            if (draft.style.tags.isNotEmpty)
              _Row('Direction', draft.style.tags.join(', ')),
            if (draft.style.fitPreference != null)
              _Row('Fit', draft.style.fitPreference!),
            if ((draft.style.notes ?? '').isNotEmpty)
              _Row('Notes', draft.style.notes!, multiline: true),
          ],
        ),

        _ReviewSection(
          label: 'Fabric',
          step: CheckoutStep.fabric,
          onEdit: onEdit,
          empty: draft.fabric.isEmpty,
          rows: [
            if (draft.fabric.name != null) _Row('Material', draft.fabric.name!),
            if (draft.fabric.colour != null)
              _Row('Colour', draft.fabric.colour!),
            if (draft.fabric.fabricId != null)
              const _Row('Source', 'Desby fabric catalogue'),
          ],
        ),

        _ReviewSection(
          label: 'Occasion',
          step: CheckoutStep.occasion,
          onEdit: onEdit,
          empty: draft.occasions.isEmpty,
          rows: [_Row('Worn for', draft.occasions.join(', '))],
        ),

        _ReviewSection(
          label: 'Measurements',
          step: CheckoutStep.measurements,
          onEdit: onEdit,
          empty: !draft.measurements.hasData,
          rows: [
            _Row(
              'Fit data',
              draft.measurements.hasData
                  ? '${draft.measurements.fieldCount} measurements '
                      '(${draft.measurements.source == MeasurementSource.bodyScan ? 'from your scan' : draft.measurements.source.name})'
                  : 'To be taken at fitting',
            ),
          ],
        ),

        // Delivery and indicative cost — presented at the point the client
        // decides whether to send, not buried earlier.
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: const DeliveryAndEstimate(),
        ),

        if ((draft.additionalNotes ?? '').isNotEmpty)
          _ReviewSection(
            label: 'Additional notes',
            step: CheckoutStep.measurements,
            onEdit: onEdit,
            rows: [_Row('Notes', draft.additionalNotes!, multiline: true)],
          ),

        const SizedBox(height: AppSpacing.lg),
        Container(
          decoration: BoxDecoration(
            color: colors.containerFill,
            borderRadius: BorderRadius.circular(AppSpacing.md),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: colors.iconMuted),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Sending this creates a request for '
                  '${draft.tailor?.name ?? 'your tailor'} to review. Nothing is '
                  'charged yet — they will come back to you with a quote.',
                  style: AppTypography.caption.copyWith(color: colors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    
      ),
    );;
  }
}

class _Row {
  const _Row(this.label, this.value, {this.multiline = false});
  final String label;
  final String value;
  final bool multiline;
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.label,
    required this.step,
    required this.onEdit,
    required this.rows,
    this.empty = false,
    this.leading,
  });

  final String label;
  final CheckoutStep? step;
  final ValueChanged<CheckoutStep>? onEdit;
  final List<_Row> rows;
  final bool empty;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.subtitle1.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onEdit != null && step != null)
                TextButton(
                  onPressed: () => onEdit!(step!),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Edit', style: AppTypography.caption.copyWith(
                    color: colors.borderFocused,
                    fontWeight: FontWeight.w600,
                  )),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (leading != null) ...[leading!, const SizedBox(height: AppSpacing.sm)],
          if (empty)
            Text(
              'Not specified — your tailor will ask.',
              style: AppTypography.caption.copyWith(color: colors.textMuted),
            )
          else
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment:
                      row.multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 104,
                      child: Text(
                        row.label,
                        style: AppTypography.captionSmall
                            .copyWith(color: colors.textMuted),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        style: AppTypography.caption.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
