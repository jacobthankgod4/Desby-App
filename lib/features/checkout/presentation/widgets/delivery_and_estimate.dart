import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/nigeria_lga_data.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/spacing.dart';
import '../../../../theme/typography.dart';
import 'carrier_picker.dart';
import '../../../orders/domain/entities/delivery_booking.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/presentation/providers/logistics_provider.dart';
import '../../../orders/presentation/providers/order_provider.dart';
import '../../../orders/presentation/widgets/material_upload_station.dart';
import '../../domain/entities/checkout_draft.dart';
import '../providers/checkout_draft_provider.dart';

/// Cloth / design references, shown as cards.
///
/// Several, not one: a tailor usually needs the front, the back and a detail of
/// the trim. Each is uploaded to the existing `orders/materials` storage path and
/// stored on the draft, so they survive a refresh and reach the order on submit.
/// An empty set blocks the step — a request with no picture of the cloth is the
/// single biggest source of "this is not what I asked for".
class MaterialReferencePicker extends ConsumerWidget {
  const MaterialReferencePicker({super.key});

  static const _maxImages = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(checkoutDraftControllerProvider);
    final colors = context.colors;
    if (draft == null) return const SizedBox.shrink();
    final notifier = ref.read(checkoutDraftControllerProvider.notifier);
    final urls = draft.hasMaterialReference
        ? (draft.materialAssetUrls.isNotEmpty
            ? draft.materialAssetUrls
            : [draft.materialAssetUrl!])
        : const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Show your tailor what you mean',
          style: AppTypography.subtitle1.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          urls.isEmpty
              ? 'Add at least one photo of the cloth, a sketch, or the outfit you '
                  'have in mind. You can add up to $_maxImages.'
              : '${urls.length} of $_maxImages added. Tap a photo to remove it.',
          style: AppTypography.caption.copyWith(
            color: urls.isEmpty ? colors.statusWarning : colors.textMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final url in urls) _card(context, ref, url, notifier),
            if (urls.length < _maxImages)
              _addTile(context, ref, notifier),
          ],
        ),
      ],
    );
  }

  Widget _card(
    BuildContext context,
    WidgetRef ref,
    String url,
    dynamic notifier,
  ) {
    final colors = context.colors;
    return SizedBox(
      width: 104,
      height: 132,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.md),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => Container(
                color: colors.containerFill,
                child: Icon(Icons.broken_image_outlined,
                    color: colors.textHint, size: 20),
              ),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () => notifier.removeMaterialAssetUrl(url),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 13, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addTile(BuildContext context, WidgetRef ref, dynamic notifier) {
    final colors = context.colors;
    return SizedBox(
      width: 104,
      height: 132,
      child: MaterialUploadStation(
        isCompleted: false,
        compact: true,
        onImagePicked: (file) async {
          if (file == null) return;
          final bytes = await file.readAsBytes();
          final url = await _upload(context, file.name, bytes);
          if (url != null) notifier.addMaterialAssetUrl(url);
        },
      ),
    );
  }

  Future<String?> _upload(
      BuildContext context, String name, Uint8List bytes) async {
    final colors = context.colors;
    try {
      final safe = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final path = 'orders/materials/${DateTime.now().millisecondsSinceEpoch}_$safe';
      await Supabase.instance.client.storage.from('images').uploadBinary(path, bytes);
      return Supabase.instance.client.storage.from('images').getPublicUrl(path);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not upload that reference: $e'),
            backgroundColor: colors.statusError,
          ),
        );
      }
      return null;
    }
  }
}

/// Delivery address plus an honest cost estimate.
///
/// Two things it deliberately does NOT do:
///  * it does not ask the client to choose a courier. Dispatch is the tailor's
///    call once the garment is ready — `order_detail_page` already summons the
///    Fez rider at that point. The client only supplies where it goes, which is
///    what `requiresDispatch` needs in order to activate that flow.
///  * it does not present a guaranteed price. The tailor quotes; this is an
///    indication built from their starting price and the delivery fee.
class DeliveryAndEstimate extends ConsumerStatefulWidget {
  const DeliveryAndEstimate({super.key});

  @override
  ConsumerState<DeliveryAndEstimate> createState() => _DeliveryAndEstimateState();
}

class _DeliveryAndEstimateState extends ConsumerState<DeliveryAndEstimate> {
  late final TextEditingController _address;
  double? _dispatchFee;
  bool _loadingFee = false;

  /// Customer's carrier choice. null means "cheapest", which is the default and
  /// what the order records when nothing is chosen.
  DeliveryQuote? _selectedCarrier;

  /// Carrier slug to persist on the order, or null for cheapest.
  String? get selectedCarrierSlug => _selectedCarrier?.carrierSlug;

  /// True once an address is known but the delivery estimate has not resolved
  /// (still loading, or the courier could not be reached).
  bool get _feePending =>
      _address.text.trim().isNotEmpty &&
      _dispatchFee == null;
  String? _feeError;
  double _tailorStartingPrice = 0;
  int _request = 0;

  /// Saved profile address, offered as a one-tap fill.
  String? _profileAddress;
  bool _loadingProfileAddress = true;

  @override
  void initState() {
    super.initState();
    _address = TextEditingController();
    final draft = ref.read(checkoutDraftControllerProvider);
    _address.text = draft?.deliveryAddress ?? '';
    _loadTailorPrice(draft);
    _loadProfileAddress();
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  /// Reads the client's saved address so the common case — same address as
  /// always — costs one tap instead of retyping it for every order.
  Future<void> _loadProfileAddress() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _loadingProfileAddress = false);
        return;
      }
      final row = await Supabase.instance.client
          .from('users')
          .select('address, state')
          .eq('id', userId)
          .maybeSingle();
      if (!mounted) return;
      final address = row?['address'] as String?;
      final state = row?['state'] as String?;
      final combined = _joinAddress(address, state);
      setState(() {
        _profileAddress = combined;
        _loadingProfileAddress = false;
      });
    } catch (_) {
      // No saved address is a normal state, not an error.
      if (mounted) setState(() => _loadingProfileAddress = false);
    }
  }

  /// Combines the free-text address with the state into a single line, avoiding
  /// a duplicate when the address already names the state.
  String? _joinAddress(String? address, String? state) {
    final a = (address ?? '').trim();
    final s = (state ?? '').trim();
    if (a.isEmpty && s.isEmpty) return null;
    if (a.isEmpty) return s;
    if (s.isEmpty) return a;
    if (a.toLowerCase().contains(s.toLowerCase())) return a;
    return '$a, $s';
  }

  /// A saved profile address is only worth suggesting once it is specific
  /// enough to dispatch a rider to — a bare city or state would be ambiguous.
  bool _isUsableProfileAddress(String address) {
    final trimmed = address.trim();
    if (trimmed.length < 8) return false;
    // Needs more than just a place name: a number or a street/building cue.
    final hasNumber = RegExp(r'\d').hasMatch(trimmed);
    final streetWords = trimmed.toLowerCase().split(RegExp(r'[\s,]+'));
    final cues = {
      'street', 'st', 'road', 'rd', 'avenue', 'ave', 'boulevard', 'blvd',
      'lane', 'ln', 'drive', 'dr', 'close', 'estate', 'junction',
      'plaza', 'mall', 'complex', 'building', 'flat', 'apartment', 'block',
    };
    final hasCue = streetWords.any((word) => cues.contains(word));
    return hasNumber || hasCue;
  }

  void _useProfileAddress() {
    final profileAddress = _profileAddress;
    if (profileAddress == null) return;
    _address.text = profileAddress;
    final notifier = ref.read(checkoutDraftControllerProvider.notifier);
    notifier.setDeliveryAddress(profileAddress);
    _fetchFee(profileAddress);
    FocusScope.of(context).unfocus();
  }

  /// The tailor's published starting price — the only figure the client can be
  /// shown before the tailor quotes.
  Future<void> _loadTailorPrice(CheckoutDraft? draft) async {
    final id = draft?.tailor?.id;
    if (id == null) return;
    try {
      final rows = await Supabase.instance.client
          .from('users')
          .select('starting_price')
          .eq('id', id)
          .maybeSingle();
      if (!mounted) return;
      final v = rows?['starting_price'];
      setState(() => _tailorStartingPrice = (v as num?)?.toDouble() ?? 0);
    } catch (_) {
      // A missing starting price is fine — the estimate just shows less.
    }
  }

  /// One-tap button that fills the address field with the one saved on the
  /// profile — unmistakable, rather than a checkbox you have to notice.
  ///
  /// Only offered when the saved address looks specific enough to deliver to
  /// (contains a house number or a street cue), so we never auto-suggest a bare
  /// city and send a rider to the wrong place.
  Widget _buildUseProfileButton(DesbyThemeColors colors) {
    final applied = _address.text.trim() == _profileAddress!.trim();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: applied ? null : _useProfileAddress,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.containerFill,
            borderRadius: BorderRadius.circular(AppSpacing.md),
            border: Border.all(
              color: applied ? colors.borderFocused : colors.cardBorder,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              Icon(
                applied
                    ? Icons.check_circle_rounded
                    : Icons.bookmark_added_outlined,
                size: 20,
                color: applied ? colors.statusSuccess : colors.borderFocused,
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      applied
                          ? 'Using your profile address'
                          : 'USE MY PROFILE ADDRESS',
                      style: AppTypography.caption.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _profileAddress!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption
                          .copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              if (!applied)
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  String _stateFrom(String address) {
    final normalized = address.toLowerCase().trim();
    final states = [...NigeriaLgaData.states]
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final s in states) {
      if (normalized.contains(s.toLowerCase())) return s;
    }
    if (normalized.contains('abuja')) return 'FCT';
    return '';
  }

  Future<void> _fetchFee(String address) async {
    final state = _stateFrom(address);
    if (state.isEmpty) {
      setState(() {
        _dispatchFee = null;
        _feeError = null;
      });
      return;
    }
    final requestId = ++_request;
    setState(() {
      _loadingFee = true;
      _feeError = null;
    });
    try {
      final result = await ref.read(logisticsRepositoryProvider).estimateCost(state);
      if (!mounted || requestId != _request) return;
      result.fold(
        (failure) => setState(() {
          _feeError = failure.message;
          _dispatchFee = null;
          _loadingFee = false;
        }),
        (cost) => setState(() {
          _dispatchFee = cost;
          _loadingFee = false;
        }),
      );
    } catch (e) {
      if (!mounted || requestId != _request) return;
      setState(() {
        _feeError = 'Could not estimate delivery';
        _loadingFee = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final notifier = ref.read(checkoutDraftControllerProvider.notifier);
    final total = _tailorStartingPrice + (_dispatchFee ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where should it be delivered?',
          style: AppTypography.subtitle1.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Needed to arrange a rider once your tailor confirms the garment is '
          'ready. Your tailor arranges the collection — you only tell us where '
          'it goes.',
          style: AppTypography.caption.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _address,
          decoration: InputDecoration(
            hintText: 'e.g. 12 Allen Avenue, Ikeja, Lagos',
            hintStyle: AppTypography.body2.copyWith(color: colors.textHint),
            filled: true,
            fillColor: colors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.md),
            ),
          ),
          onChanged: (value) {
            notifier.setDeliveryAddress(value.isEmpty ? null : value);
            _fetchFee(value);
          },
        ),
        if (!_loadingProfileAddress &&
            _profileAddress != null &&
            _isUsableProfileAddress(_profileAddress!) &&
            _address.text.trim() != _profileAddress!.trim()) ...[
          const SizedBox(height: AppSpacing.sm),
          _buildUseProfileButton(colors),
        ],
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.containerFill,
            borderRadius: BorderRadius.circular(AppSpacing.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INDICATIVE COST',
                style: AppTypography.overline.copyWith(
                  fontSize: 12,
                  color: colors.borderFocused,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // P17/P18: the customer picks who delivers. Terminal returns a
              // competing offer per carrier; showing only the cheapest hides
              // the aggregator's value.
              CarrierPicker(
                destinationState: _stateFrom(_address.text),
                selected: _selectedCarrier?.carrierSlug,
                weightKg: 2,
                itemValue: _tailorStartingPrice,
                description: 'Custom garment',
                onChanged: (quote) {
                  setState(() {
                    _selectedCarrier = quote;
                    if (quote != null) {
                      // The chosen carrier's price is authoritative — never
                      // leave the summary showing a different carrier's fee.
                      _dispatchFee = quote.amount;
                      _feeError = null;
                    }
                  });
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _line(context, 'Tailor’s starting price',
                  _tailorStartingPrice > 0 ? _tailorStartingPrice : null),
              _line(
                context,
                _selectedCarrier == null
                    ? 'Estimated delivery'
                    : 'Delivery — ${_selectedCarrier!.carrierName}',
                _dispatchFee != null && _dispatchFee! > 0 ? _dispatchFee! : null,
              ),
              if (_loadingFee)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Working out delivery…',
                      style: AppTypography.caption
                          .copyWith(color: colors.textMuted)),
                ),
              if (_feeError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(_feeError!,
                      style: AppTypography.caption
                          .copyWith(color: colors.statusWarning)),
                ),
              const Divider(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Roughly',
                      style: AppTypography.subtitle1.copyWith(
                          color: colors.textPrimary)),
                  // When the delivery estimate could not be resolved, showing
                  // the item price alone reads as the full cost — an
                  // understated total on a real order. Say delivery is pending
                  // rather than quietly dropping the fee.
                  Text(
                    _feePending
                        ? '₦${_tailorStartingPrice.toStringAsFixed(0)} + delivery'
                        : total > 0
                            ? '₦${total.toStringAsFixed(0)}'
                            : '—',
                    style: AppTypography.headline6.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Never imply this is the price they will pay.
              Text(
                'This is a guide, not a quote. Your tailor sets the final '
                'price once they have seen your request, and nothing is '
                'charged until you approve it.',
                style: AppTypography.caption.copyWith(color: colors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _line(BuildContext context, String label, double? value) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.caption.copyWith(color: colors.textSecondary)),
          Text(
            value == null ? '—' : '₦${value.toStringAsFixed(0)}',
            style: AppTypography.caption.copyWith(
              color: value == null ? colors.textHint : colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
