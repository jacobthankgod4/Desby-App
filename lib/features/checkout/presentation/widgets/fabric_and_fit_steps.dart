import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'delivery_and_estimate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../theme/colors.dart';
import '../../../../theme/spacing.dart';
import '../../../../theme/typography.dart';
import '../../../marketplace/domain/entities/fabric.dart';
import '../../../orders/presentation/widgets/body_scan_picker_widget.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../domain/entities/checkout_draft.dart';
import '../../domain/entities/request_options.dart';
import '../../../payments/domain/platform_money_config.dart';
import '../providers/checkout_draft_provider.dart';
import 'request_steps.dart';

/// Step 3 — fabric.
///
/// Reads the real `fabrics` catalogue rather than the four hardcoded entries
/// with invented prices that the legacy flow offered. Falls back to free text
/// when the catalogue has nothing, because a tailor can source cloth the
/// platform has not listed.
class FabricStep extends ConsumerStatefulWidget {
  const FabricStep({super.key});

  @override
  ConsumerState<FabricStep> createState() => _FabricStepState();
}

class _FabricStepState extends ConsumerState<FabricStep> {
  List<Fabric> _catalogue = const [];
  bool _loading = true;
  String _loadError = '';

  @override
  void initState() {
    super.initState();
    _loadCatalogue();
  }

  Future<void> _loadCatalogue() async {
    try {
      final rows = await Supabase.instance.client
          .from('fabrics')
          .select('id,name,category,price_per_yard,image_urls,available_colors')
          .eq('is_visible', true)
          .limit(40);
      if (!mounted) return;
      setState(() {
        _catalogue = rows
            .map((r) => Fabric(
                  id: r['id'].toString(),
                  name: r['name']?.toString() ?? '',
                  category: r['category']?.toString() ?? '',
                  pricePerYard:
                      (r['price_per_yard'] as num?)?.toDouble() ?? 0,
                  stockQuantity: 0,
                  sellerId: '',
                  imageUrls: r['image_urls'] is List
                      ? (r['image_urls'] as List).map((e) => '$e').toList()
                      : const [],
                  availableColors: r['available_colors'] is List
                      ? (r['available_colors'] as List).map((e) => '$e').toList()
                      : const [],
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ))
            .where((f) => f.name.isNotEmpty)
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Not fatal: the client can still describe the fabric they want.
      setState(() {
        _loadError = 'Could not load the fabric catalogue';
        _loading = false;
      });
    }
  }

  /// Cloth ownership. This has to be asked before anything else in this step
  /// because it decides whether the tailor's material cost is charged at all --
  /// a client who already owns their fabric should never be quoted for cloth.
  Widget _buildOwnershipChoice(
    BuildContext context,
    CheckoutFabric fabric,
    CheckoutDraftController notifier,
  ) {
    final current = fabric.ownership;
    final colors = context.colors;

    Widget option({
      required IconData icon,
      required String title,
      required String blurb,
      required FabricOwnership value,
    }) {
      final selected = current == value;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: InkWell(
          onTap: () => notifier.setFabric(fabric.copyWith(ownership: value)),
          borderRadius: BorderRadius.circular(AppSpacing.md),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.md),
              border: Border.all(
                color: selected ? colors.borderFocused : colors.borderSubtle,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? colors.borderFocused : colors.textMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.body2.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        blurb,
                        style: AppTypography.caption
                            .copyWith(color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle,
                      size: 18, color: colors.borderFocused),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Do you already have your fabric?',
          style: AppTypography.subtitle1.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'This decides whether fabric is added to your quote.',
          style: AppTypography.caption.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
        option(
          icon: Icons.checkroom_outlined,
          title: 'I already have my fabric',
          blurb: 'You bring the cloth. Fabric is not added to the price.',
          value: FabricOwnership.clientSupplied,
        ),
        option(
          icon: Icons.storefront_outlined,
          title: 'I need fabric sourced',
          blurb:
              'Your tailor buys the cloth. Their fabric price is added to the quote.',
          value: FabricOwnership.tailorSourced,
        ),
      ],
    );
  }

  Widget build(BuildContext context) {
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
          'What should it be made from?',
          style: AppTypography.headline6.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Fabric drives what they can actually cut, so it is worth getting '
          'right. If you are unsure, leave it and ask them.',
          style: AppTypography.caption.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: AppSpacing.lg),

        _buildOwnershipChoice(context, draft.fabric, notifier),
        const SizedBox(height: AppSpacing.lg),

        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),

        if (!_loading && _catalogue.isNotEmpty) ...[
          ChipGroup(
            label: 'From the Desby fabric catalogue',
            children: [
              for (final fabric in _catalogue)
                SelectionChip(
                  label: fabric.pricePerYard > 0
                      ? '${fabric.name} · ₦${fabric.pricePerYard.toStringAsFixed(0)}/yd'
                      : fabric.name,
                  selected: draft.fabric.fabricId == fabric.id,
                  // copyWith, not a fresh CheckoutFabric: rebuilding one here
                  // used to reset fabric ownership, so picking cloth silently
                  // undid the "I already have my fabric" answer above.
                  onTap: () {
                    final current = draft.fabric;
                    notifier.setFabric(
                      current.fabricId == fabric.id
                          // Tapping the selected cloth clears it again.
                          ? current.copyWith(
                              clearFabricId: true,
                              clearName: true,
                            )
                          : current.copyWith(
                              fabricId: fabric.id,
                              name: fabric.name,
                            ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        if (!_loading && _loadError.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              '$_loadError — you can still describe what you want below.',
              style: AppTypography.caption.copyWith(color: colors.statusWarning),
            ),
          ),

        ChipGroup(
          label: 'Or tell them what you have in mind',
          helper: 'Either pick above or type below. Both is fine.',
          children: [
            for (final suggestion in RequestOptions.fabricSuggestions.take(8))
              SelectionChip(
                label: suggestion,
                selected: draft.fabric.name == suggestion &&
                    draft.fabric.fabricId == null,
                // Same reason as the catalogue chips: this must not rebuild the
                // draft from scratch, or cloth ownership is lost on every tap.
                onTap: () {
                  final current = draft.fabric;
                  final isActive =
                      current.name == suggestion && current.fabricId == null;
                  notifier.setFabric(
                    isActive
                        ? current.copyWith(clearName: true)
                        // A free-text material replaces any catalogue pick, so
                        // the two never claim to both be selected.
                        : current.copyWith(
                            name: suggestion,
                            clearFabricId: true,
                          ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          key: ValueKey('fabric-${draft.fabric.name}'),
          initialValue: draft.fabric.name,
          decoration: InputDecoration(
            labelText: 'Fabric',
            hintStyle: AppTypography.body2.copyWith(color: colors.textHint),
            filled: true,
            fillColor: colors.inputFill,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.md)),
          ),
          onChanged: (value) {
            // Read the live draft, not the snapshot captured when this step was
            // built. The snapshot goes stale the moment any chip is tapped, so
            // typing here afterwards would write back the old colour/ownership.
            final current = notifier.currentFabric;
            notifier.setFabric(
              current.copyWith(name: value, clearFabricId: true),
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        ChipGroup(
          label: 'Common colours',
          children: [
            for (final colour in RequestOptions.colourSuggestions)
              SelectionChip(
                label: colour,
                dense: true,
                selected: draft.fabric.colour == colour,
                onTap: () {
                  final current = draft.fabric;
                  notifier.setFabric(
                    current.colour == colour
                        ? current.copyWith(clearColour: true)
                        : current.copyWith(colour: colour),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // The free-text colour sits *below* the swatches. Above them it read as
        // though it belonged to the fabric question, because two inputs were
        // stacked with no label explaining which question the second one
        // answered. Underneath, it is obviously "or name your own".
        TextFormField(
          // Keyed on the draft value: FormField only reads initialValue once,
          // so tapping a swatch used to update the state without ever showing
          // the choice in the field.
          key: ValueKey('colour-${draft.fabric.colour}'),
          initialValue: draft.fabric.colour,
          decoration: InputDecoration(
            labelText: 'Or name your own colour',
            hintStyle: AppTypography.body2.copyWith(color: colors.textHint),
            filled: true,
            fillColor: colors.inputFill,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.md)),
          ),
          onChanged: (value) {
            final current = notifier.currentFabric;
            notifier.setFabric(current.copyWith(colour: value));
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        // The cloth itself, right next to the fabric choice.
        const MaterialReferencePicker(),
      ],
    
      ),
    );
  }
}

/// Step 5 — fit. Reuses the existing body-scan picker rather than rebuilding a
/// measurement form, and reuses the client/product choices already made.
class MeasurementsStep extends ConsumerWidget {
  const MeasurementsStep({super.key, this.onStartScan});

  /// Host decides how the scan is presented — the journey keeps it inside the
  /// flow shell so the client doesn't lose their place.
  final VoidCallback? onStartScan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(checkoutDraftControllerProvider);
    final colors = context.colors;
    if (draft == null) return const SizedBox.shrink();
    final notifier = ref.read(checkoutDraftControllerProvider.notifier);
    final m = draft.measurements;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          'Measurements and fit',
          style: AppTypography.headline6.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Say why we are asking. The brief is explicit that measurements must
        // not appear without context.
        Container(
          decoration: BoxDecoration(
            color: colors.containerFill,
            borderRadius: BorderRadius.circular(AppSpacing.md),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.straighten, size: 18, color: colors.iconMuted),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Measurements are how your tailor cuts an outfit to fit you, '
                  'rather than to a size. If you already have a scan, we will '
                  'use it — there is nothing to enter twice.',
                  style: AppTypography.caption.copyWith(color: colors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        if (m.hasData) ...[
          Container(
            decoration: BoxDecoration(
              color: colors.statusSuccess.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.md),
              border: Border.all(
                  color: colors.statusSuccess.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 20, color: colors.statusSuccess),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${m.fieldCount} measurements ready '
                    '(${m.source == MeasurementSource.bodyScan ? 'from your scan' : m.source.name}).',
                    style: AppTypography.caption
                        .copyWith(color: colors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Reuse the existing, working picker instead of rebuilding measurement
        // input. It auto-selects when the client has exactly one saved scan,
        // which is the "do not ask what we already know" case.
        //
        // The picker does not surface the scan id, so the values are recorded
        // against the scan source without a specific id. The alternative was a
        // wrapper that added no behaviour and only obscured the reuse.
        BodyScanPickerWidget(
          onMeasurementsSelected: (values) => notifier.setMeasurements(
            CheckoutMeasurements(
              source: values.isEmpty
                  ? MeasurementSource.none
                  : MeasurementSource.bodyScan,
              values: values.isEmpty ? null : values,
            ),
          ),
          // Open the real scan, inside the shell, exactly as the rest of the app
          // does. This previously only cleared the measurement, so the button
          // looked broken — the most expensive kind of dead control.
          onStartNewScan: () {
            // Clear any stale selection first so returning from the scan shows a
            // clean "no scan" state rather than the previous scan's values.
            notifier.setMeasurements(
              const CheckoutMeasurements(source: MeasurementSource.none),
            );
            (onStartScan ?? () => ref.pushShell('/ai-body-scan'))();
          },
        ),

        const SizedBox(height: AppSpacing.md),
        ChipGroup(
          label: 'Anything about fit your tailor should know?',
          children: const [],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          initialValue: draft.additionalNotes,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g. I am broad-shouldered and need room in the chest.',
            hintStyle: AppTypography.body2.copyWith(color: colors.textHint),
            filled: true,
            fillColor: colors.inputFill,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.md)),
          ),
          onChanged: (value) => notifier.setAdditionalNotes(value),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'No scan? That is fine — your tailor will take measurements at '
          'fitting. This step is never required.',
          style: AppTypography.captionSmall.copyWith(color: colors.textMuted),
        ),
      ],
    
      ),
    );
  }
}
