import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_network_image.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/spacing.dart';
import '../../../../theme/typography.dart';
import '../../domain/entities/checkout_draft.dart';
import '../../domain/entities/request_options.dart';
import '../providers/checkout_draft_provider.dart';

/// Reusable selection primitives.
///
/// Shared so a chip in step 2 and a chip in step 4 behave identically —
/// including the part that matters: selected state is carried by a check icon
/// and a border, never by colour alone.
class SelectionChip extends StatelessWidget {
  const SelectionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? colors.borderFocused.withValues(alpha: 0.12)
            : colors.containerFill,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.md),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: dense ? AppSpacing.sm : AppSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.md),
              border: Border.all(
                color: selected ? colors.borderFocused : colors.borderSubtle,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  Icon(Icons.check, size: 16, color: colors.borderFocused),
                  const SizedBox(width: 6),
                ] else if (icon != null) ...[
                  Icon(icon, size: 16, color: colors.iconSecondary),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      color: selected ? colors.textPrimary : colors.textSecondary,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A labelled group of chips.
class ChipGroup extends StatelessWidget {
  const ChipGroup({
    super.key,
    required this.label,
    required this.children,
    this.helper,
    this.optional = true,
  });

  final String label;
  final List<Widget> children;
  final String? helper;

  /// Renders an explicit "optional" marker so the client knows they can move on.
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTypography.subtitle1.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (optional)
              Text(
                'optional',
                style: AppTypography.captionSmall.copyWith(
                  color: colors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Text(
                'required',
                style: AppTypography.captionSmall.copyWith(
                  color: colors.statusError,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        if (helper != null) ...[
          const SizedBox(height: 2),
          Text(
            helper!,
            style: AppTypography.caption.copyWith(color: colors.textMuted),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: children),
      ],
    );
  }
}

/// Step 1 — the most important change in the flow.
///
/// Entering from a tailor profile there is no product, so the first question is
/// "what do you want made". Entering from a design, the design is already the
/// answer and we only ask how they want it changed.
class DefineRequestStep extends ConsumerStatefulWidget {
  const DefineRequestStep({super.key});

  @override
  ConsumerState<DefineRequestStep> createState() => _DefineRequestStepState();
}

class _DefineRequestStepState extends ConsumerState<DefineRequestStep> {
  late final TextEditingController _summary;
  String? _showValidation;

  @override
  void initState() {
    super.initState();
    _summary = TextEditingController();
  }

  @override
  void dispose() {
    _summary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(checkoutDraftControllerProvider);
    final colors = context.colors;
    if (draft == null) return const SizedBox.shrink();

    // Seed the field from a resumed draft without fighting the user mid-edit.
    if (_summary.text.isEmpty && (draft.request.summary ?? '').isNotEmpty) {
      _summary.text = draft.request.summary!;
    }

    final fromProfile = draft.entryMode.needsGarmentDefinition;
    final product = draft.product;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        // ── Context card: who and what, so nothing already known is re-asked ──
        _ContextCard(draft: draft),
        const SizedBox(height: AppSpacing.lg),

        if (product != null) ...[
          _ProductSummary(product: product),
          const SizedBox(height: AppSpacing.lg),
          // The brief's distinction: "make this exact design" and "hire this
          // tailor for something different" are different checkout states.
          Text(
            'How would you like this made for you?',
            style: AppTypography.headline6.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          ChipGroup(
            label: 'This request',
            optional: false,
            children: [
              SelectionChip(
                label: 'Make this design as shown',
                selected: !draft.request.wantsSomethingDifferent,
                icon: Icons.checkroom,
                onTap: () => ref
                    .read(checkoutDraftControllerProvider.notifier)
                    .setEntryMode(CheckoutEntryMode.fromProduct),
              ),
              SelectionChip(
                label: 'Something different, same tailor',
                selected: draft.request.wantsSomethingDifferent,
                icon: Icons.edit_outlined,
                onTap: () => ref
                    .read(checkoutDraftControllerProvider.notifier)
                    .setEntryMode(CheckoutEntryMode.customDesign),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ] else
          Text(
            'What would you like ${draft.tailor?.name ?? 'this tailor'} to make for you?',
            style: AppTypography.headline5.copyWith(color: colors.textPrimary),
          ),

        // ── Garment: only asked when the system genuinely does not know ──
        if (fromProfile || draft.request.wantsSomethingDifferent) ...[
          const SizedBox(height: AppSpacing.lg),
          ChipGroup(
            label: 'What is it?',
            optional: false,
            helper: 'Pick the closest match — your tailor will confirm the rest.',
            children: [
              for (final entry in RequestOptions.garmentsByGroup.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    entry.key,
                    style: AppTypography.captionSmall.copyWith(
                      color: colors.textMuted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                for (final garment in entry.value)
                  SelectionChip(
                    label: garment,
                    selected: draft.request.garmentType == garment,
                    onTap: () => ref
                        .read(checkoutDraftControllerProvider.notifier)
                        .setRequest(
                          draft.request.copyWith(garmentType: garment),
                        ),
                  ),
              ],
            ],
          ),
          if (_showValidation != null && draft.request.garmentType == null) ...[
            const SizedBox(height: AppSpacing.sm),
            _ValidationNote(_showValidation!),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],

        // ── In their own words. The highest-value input in the whole form ──
        ChipGroup(
          label: 'Tell them in your own words',
          helper:
              'A sentence is plenty. Occasion, quantity, anything that matters to you.',
          children: const [],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _summary,
          maxLines: 4,
          minLines: 3,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: 'e.g. Six senator suits for my brothers wedding, '
                'and they need to fit properly.',
            hintStyle: AppTypography.body2.copyWith(color: colors.textHint),
            filled: true,
            fillColor: colors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.md),
              borderSide: BorderSide(color: colors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.md),
              borderSide: BorderSide(color: colors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.md),
              borderSide: BorderSide(color: colors.borderFocused, width: 2),
            ),
          ),
          onChanged: (value) => ref
              .read(checkoutDraftControllerProvider.notifier)
              .setRequest(draft.request.copyWith(summary: value)),
        ),
      ],
    
      ),
    );;
  }

}

class _ContextCard extends StatelessWidget {
  const _ContextCard({required this.draft});
  final CheckoutDraft draft;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tailor = draft.tailor;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: colors.containerFill,
            backgroundImage:
                tailor?.avatarUrl != null && tailor!.avatarUrl!.isNotEmpty
                    ? NetworkImage(tailor.avatarUrl!)
                    : null,
            child: tailor?.avatarUrl == null || tailor!.avatarUrl!.isEmpty
                ? Text(
                    (tailor?.name ?? '?').characters.first.toUpperCase(),
                    style: AppTypography.subtitle1
                        .copyWith(color: colors.textSecondary),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Requesting from',
                  style: AppTypography.captionSmall
                      .copyWith(color: colors.textMuted),
                ),
                Text(
                  tailor?.name ?? 'Tailor',
                  style: AppTypography.subtitle1.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
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

class _ProductSummary extends StatelessWidget {
  const _ProductSummary({required this.product});
  final CheckoutProduct product;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product.imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              child: SizedBox(
                width: 68,
                height: 84,
                child: AppNetworkImage(
                  url: product.imageUrls.first,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: 68,
              height: 84,
              decoration: BoxDecoration(
                color: colors.containerFill,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Icon(Icons.dry_cleaning, color: colors.textHint),
            ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title ?? 'Selected design',
                  style: AppTypography.subtitle1.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (product.category != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    product.category!,
                    style: AppTypography.caption
                        .copyWith(color: colors.textSecondary),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                // Size and colour chosen on the product page are shown back.
                // The legacy flow dropped both on the floor.
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: 4,
                  children: [
                    if (product.selectedSize != null)
                      _MiniFact('Size', product.selectedSize!),
                    if (product.selectedColour != null)
                      _MiniFact('Colour', product.selectedColour!),
                    if (product.quantity > 1)
                      _MiniFact('Qty', '${product.quantity}'),
                  ],
                ),
                if (product.price != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'From ₦${product.price!.toStringAsFixed(0)}',
                    style: AppTypography.caption.copyWith(
                      color: colors.borderFocused,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniFact extends StatelessWidget {
  const _MiniFact(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.containerFill,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: AppTypography.captionSmall.copyWith(color: colors.textSecondary),
      ),
    );
  }
}

class _ValidationNote extends StatelessWidget {
  const _ValidationNote(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.statusError.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: colors.statusError.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: colors.statusError),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.caption.copyWith(color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Step 2 — style direction. Visual, not a text box.
class StyleDirectionStep extends ConsumerWidget {
  const StyleDirectionStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(checkoutDraftControllerProvider);
    final colors = context.colors;
    if (draft == null) return const SizedBox.shrink();
    final notifier = ref.read(checkoutDraftControllerProvider.notifier);
    final style = draft.style;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          'What should it look like?',
          style: AppTypography.headline6.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.lg),
        ChipGroup(
          label: 'Style',
          helper: 'Choose as many as fit. Your tailor can advise if unsure.',
          children: [
            for (final tag in RequestOptions.styleTags)
              SelectionChip(
                label: tag,
                selected: style.tags.contains(tag),
                onTap: () => notifier.setStyle(
                  style.copyWith(
                    tags: style.tags.contains(tag)
                        ? style.tags.where((t) => t != tag).toList()
                        : [...style.tags, tag],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ChipGroup(
          label: 'Fit',
          children: [
            for (final fit in RequestOptions.fitPreferences)
              SelectionChip(
                label: fit,
                selected: style.fitPreference == fit,
                onTap: () => notifier.setStyle(
                  style.copyWith(
                    fitPreference:
                        style.fitPreference == fit ? null : fit,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ChipGroup(
          label: 'Anything else about the look?',
          helper: 'Shoulder width, sleeve length, how formal — as much or as '
              'little as you like.',
          children: const [],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          initialValue: style.notes,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g. Keep the shoulders structured but make it less '
                'formal than the picture.',
            hintStyle: AppTypography.body2.copyWith(color: colors.textHint),
            filled: true,
            fillColor: colors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.md),
            ),
          ),
          onChanged: (value) =>
              notifier.setStyle(style.copyWith(notes: value)),
        ),
      ],
    
      ),
    );;
  }
}

/// Step 4 — occasion. Multi-select, because a request can genuinely be for more
/// than one thing.
class OccasionStep extends ConsumerWidget {
  const OccasionStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(checkoutDraftControllerProvider);
    final colors = context.colors;
    if (draft == null) return const SizedBox.shrink();
    final notifier = ref.read(checkoutDraftControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          'Where will it be worn?',
          style: AppTypography.headline6.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.lg),
        ChipGroup(
          label: 'Occasions',
          helper: 'More than one is fine — it tells the tailor how to dress it.',
          children: [
            for (final occasion in RequestOptions.occasions)
              SelectionChip(
                label: occasion,
                selected: draft.occasions.contains(occasion),
                icon: Icons.event_outlined,
                onTap: () => notifier.toggleOccasion(occasion),
              ),
          ],
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
              Icon(Icons.lightbulb_outline, size: 18, color: colors.iconMuted),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Unsure? Leave this blank and your tailor will ask during '
                  'the consultation. Nothing here is required.',
                  style: AppTypography.caption
                      .copyWith(color: colors.textSecondary),
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
