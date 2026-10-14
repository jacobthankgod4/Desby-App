import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/shell_app_bar.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../designs/domain/entities/design.dart';
import '../../../designs/presentation/pages/ai_body_scan_page.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/domain/entities/order_ids.dart';
import '../../../orders/presentation/providers/order_provider.dart';
import '../../../orders/presentation/widgets/body_scan_picker_widget.dart';
import '../widgets/profile_address_prompt.dart';

/// Ready-to-wear checkout from the Shop tab: exactly three questions —
/// measurements, delivery address, payment — then hand-off to the shared
/// [CheckoutPage] so the Flutterwave split (1.5% commission) is the same one
/// the request journey uses.
class ShopCheckoutPage extends ConsumerStatefulWidget {
  final Design design;
  final int quantity;
  final String? size;
  final int colorValue;

  const ShopCheckoutPage({
    super.key,
    required this.design,
    required this.quantity,
    this.size,
    this.colorValue = 0xFF1A1A2E,
  });

  @override
  ConsumerState<ShopCheckoutPage> createState() => _ShopCheckoutPageState();
}

class _ShopCheckoutPageState extends ConsumerState<ShopCheckoutPage> {
  int _step = 0;
  Map<String, double>? _measurements;
  bool _scanOpen = false;
  bool _scanExpanded = false;
  bool _loadingProfile = true;
  String? _profileAddress;
  bool _placing = false;
  late final TextEditingController _addressController;

  static const List<String> _stepLabels = [
    'Measurements',
    'Delivery',
    'Review',
  ];

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController();
    _loadProfileAddress();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  double get _total => widget.design.price * widget.quantity;

  String get _colorHex =>
      '#${(widget.colorValue & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  String _formatted(num n) => NumberFormat('#,##0').format(n);

  Future<void> _loadProfileAddress() async {
    final line = await ProfileAddressPrompt.loadProfileAddressLine();
    if (!mounted) return;
    setState(() {
      _profileAddress = line;
      _loadingProfile = false;
    });
  }

  void _selectMeasurements(Map<String, double> measurements) {
    setState(() => _measurements = measurements);
  }

  Future<void> _onScanMeasurementsReady(
    Map<String, dynamic> measurements,
    String gender,
    double heightCm,
  ) async {
    final values = <String, double>{};
    measurements.forEach((key, value) {
      if (value is num) values[key] = value.toDouble();
    });
    if (!mounted) return;
    setState(() {
      _measurements = values;
      _scanOpen = false;
      _scanExpanded = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${values.length} measurements attached to your order'),
        backgroundColor: context.colors.statusSuccess,
      ),
    );
  }

  void _goToAddress() {
    if (_measurements == null || _scanOpen) return;
    setState(() => _step = 1);
  }

  Future<void> _goToReview() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;
    await ProfileAddressPrompt.askToSave(context, address);
    if (!mounted) return;
    setState(() => _step = 2);
  }

  Future<void> _placeOrder() async {
    if (_placing) return;
    final user = ref.read(currentUserProvider);
    final measurements = _measurements;
    final address = _addressController.text.trim();
    if (user == null || measurements == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Attach your measurements before paying'),
          backgroundColor: context.colors.statusError,
        ),
      );
      return;
    }
    if (address.isEmpty) {
      setState(() => _step = 1);
      return;
    }

    setState(() => _placing = true);
    final order = OrderEntity(
      id: OrderIds.newUuid()!,
      reference: OrderIds.purchaseReference(),
      requestingUserId: user.id,
      // The buyer is a browsing client: no record exists in `clients` yet and
      // `orders.client_id` is a foreign key to it — writing the auth uid here
      // failed every insert (23503). Client lists match on requesting_user_id.
      clientId: null,
      tailorId: widget.design.tailorId,
      clientName: user.name,
      status: OrderStatus.pending,
      totalAmount: _total,
      // Units ordered, on the column rather than only in metadata, so
      // fulfilment and reporting can query it.
      quantity: widget.quantity,
      dispatchFee: 0,
      createdAt: DateTime.now(),
      requiresDispatch: address.isNotEmpty,
      fabricType: widget.design.category,
      fabricColor: _colorHex,
      deliveryAddress: address,
      metadata: {
        'channel': 'shop',
        'quantity': widget.quantity,
        'size': widget.size ?? '',
        'color': _colorHex,
      },
      items: [
        OrderItem(
          id: OrderIds.newUuid()!,
          garmentType: widget.design.title,
          designId: widget.design.id,
          measurements: measurements,
          price: _total,
        ),
      ],
    );

    final result = await ref.read(createOrderUsecaseProvider)(order);
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() => _placing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'We could not start your payment: ${failure.message}. '
              'Nothing you entered was lost — try again.',
            ),
            backgroundColor: context.colors.statusError,
          ),
        );
      },
      (saved) {
        ref.invalidate(ordersProvider);
        ref.pushShell('/checkout', {
          'amount': _total,
          'orderId': saved.id,
          'orderIds': [saved.id],
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(context, title: 'Checkout'),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepRail(colors),
            Expanded(child: _buildStepContent(colors)),
            if (!_scanOpen) _buildBottomAction(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRail(DesbyThemeColors colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _stepLabels.length; i++) ...[
            _stepChip(i, colors),
            if (i < _stepLabels.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: i < _step ? AppColors.amber : colors.divider,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _stepChip(int index, DesbyThemeColors colors) {
    final done = index < _step;
    final active = index == _step;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done || active ? AppColors.amber : colors.divider,
          ),
          child: done
              ? Icon(Icons.check_rounded,
                  size: 14, color: AppColors.darkNavy)
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: active ? AppColors.darkNavy : colors.textMuted,
                  ),
                ),
        ),
        const SizedBox(width: 6),
        Text(
          _stepLabels[index],
          style: AppTypography.caption.copyWith(
            color: active || done ? colors.textPrimary : colors.textMuted,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent(DesbyThemeColors colors) {
    switch (_step) {
      case 0:
        return _buildMeasurementsStep(colors);
      case 1:
        return _buildAddressStep(colors);
      default:
        return _buildReviewStep(colors);
    }
  }

  Widget _buildMeasurementsStep(DesbyThemeColors colors) {
    if (_scanOpen) return _buildInFlowScan(colors);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your measurements',
                style: AppTypography.subtitle1
                    .copyWith(color: colors.textPrimary, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'The tailor needs your measurements to make this fit. Pick a '
                'saved scan or take a new one.',
                style: AppTypography.caption.copyWith(color: colors.textMuted),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        Expanded(
          child: BodyScanPickerWidget(
            onMeasurementsSelected: _selectMeasurements,
            onStartNewScan: () => setState(() {
              _scanOpen = true;
              _scanExpanded = true;
            }),
          ),
        ),
        if (_measurements != null)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.statusSuccess.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.statusSuccess),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 18, color: colors.statusSuccess),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_measurements!.length} measurements ready',
                    style: AppTypography.caption
                        .copyWith(color: colors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInFlowScan(DesbyThemeColors colors) {
    return Column(
      children: [
        if (!_scanExpanded)
          Container(
            color: colors.scaffoldBg,
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                Icon(Icons.accessibility_new,
                    size: 20, color: colors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New body scan',
                        style: AppTypography.subtitle1.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Two photos · about two minutes',
                        style: AppTypography.caption
                            .copyWith(color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Collapse',
                  icon: Icon(Icons.fullscreen_exit,
                      size: 20, color: colors.textSecondary),
                  onPressed: () => setState(() => _scanExpanded = false),
                ),
                IconButton(
                  tooltip: 'Close scan',
                  icon: Icon(Icons.close_rounded,
                      size: 20, color: colors.textSecondary),
                  onPressed: () => setState(() {
                    _scanOpen = false;
                    _scanExpanded = false;
                  }),
                ),
              ],
            ),
          ),
        Expanded(
          child: AiBodyScanPage(
            inFlow: true,
            expanded: _scanExpanded,
            onToggleExpanded: () =>
                setState(() => _scanExpanded = !_scanExpanded),
            onMeasurementsReady: _onScanMeasurementsReady,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressStep(DesbyThemeColors colors) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Where should it be delivered?',
          style: AppTypography.subtitle1
              .copyWith(color: colors.textPrimary, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'A rider drops your order at this address. Be as specific as you can.',
          style: AppTypography.caption.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: 16),
        if (_loadingProfile)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (_profileAddress != null) ...[
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() {
              _addressController.text = _profileAddress!;
            }),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.amber),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bookmark_added_outlined,
                      size: 20, color: AppColors.darkNavy),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'USE MY PROFILE ADDRESS',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.darkNavy,
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
                              .copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 20, color: colors.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Divider(color: colors.divider)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('OR A NEW ADDRESS',
                    style: AppTypography.caption
                        .copyWith(color: colors.textMuted)),
              ),
              Expanded(child: Divider(color: colors.divider)),
            ],
          ),
          const SizedBox(height: 14),
        ],
        TextField(
          controller: _addressController,
          maxLines: 3,
          minLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'e.g. 12 Allen Avenue, Ikeja, Lagos',
            filled: true,
            fillColor: colors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.amber),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Text(
          'Your address is never shared with anyone outside the delivery.',
          style: AppTypography.caption.copyWith(color: colors.textHint),
        ),
      ],
    );
  }

  Widget _buildReviewStep(DesbyThemeColors colors) {
    final image = widget.design.imageUrls.isNotEmpty
        ? widget.design.imageUrls.first
        : null;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.cardBorder),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AppNetworkImage(
                  url: image,
                  width: 72,
                  height: 90,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.design.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.subtitle1.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (widget.size != null && widget.size!.isNotEmpty)
                          'Size ${widget.size}',
                        'Qty ${widget.quantity}',
                      ].join(' · '),
                      style: AppTypography.caption
                          .copyWith(color: colors.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(widget.colorValue),
                            border: Border.all(color: colors.divider),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '₦${_formatted(_total)}',
                          style: AppTypography.subtitle1.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.cardBorder),
          ),
          child: Column(
            children: [
              _reviewRow(
                colors,
                icon: Icons.accessibility_new_rounded,
                label: 'Measurements',
                value: _measurements != null
                    ? '${_measurements!.length} measurements from your scan'
                    : 'Not set',
                actionLabel: 'Change',
                onAction: () => setState(() => _step = 0),
              ),
              Divider(height: 1, color: colors.divider, indent: 52),
              _reviewRow(
                colors,
                icon: Icons.location_on_outlined,
                label: 'Delivery address',
                value: _addressController.text.trim().isEmpty
                    ? 'Not set'
                    : _addressController.text.trim(),
                actionLabel: 'Change',
                onAction: () => setState(() => _step = 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Item total',
                      style: AppTypography.body2
                          .copyWith(color: colors.textSecondary)),
                  Text('₦${_formatted(_total)}',
                      style: AppTypography.body2
                          .copyWith(color: colors.textPrimary)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Delivery',
                      style: AppTypography.body2
                          .copyWith(color: colors.textSecondary)),
                  Text('Quoted on dispatch',
                      style: AppTypography.caption
                          .copyWith(color: colors.textMuted)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pay now',
                      style: AppTypography.subtitle1.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800)),
                  Text(
                    '₦${_formatted(_total)}',
                    style: AppTypography.subtitle1.copyWith(
                      color: AppColors.amber,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.statusSuccess.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.statusSuccess),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_rounded, size: 16, color: colors.statusSuccess),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Payment is secured by Flutterwave and split to the tailor '
                  'automatically once your order is confirmed.',
                  style: AppTypography.caption
                      .copyWith(color: colors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewRow(
    DesbyThemeColors colors, {
    required IconData icon,
    required String label,
    required String value,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.caption
                        .copyWith(color: colors.textMuted)),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body2
                      .copyWith(color: colors.textPrimary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel,
              style: AppTypography.caption.copyWith(
                color: AppColors.amber,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(DesbyThemeColors colors) {
    final labels = ['CONTINUE TO DELIVERY', 'CONTINUE TO REVIEW'];
    final enabled = _step == 0
        ? _measurements != null
        : _addressController.text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: _step < 2
            ? ElevatedButton(
                onPressed: enabled
                    ? () => _step == 0 ? _goToAddress() : _goToReview()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: AppColors.darkNavy,
                  disabledBackgroundColor: colors.divider,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  labels[_step],
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              )
            : ElevatedButton(
                onPressed: _placing ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: AppColors.darkNavy,
                  disabledBackgroundColor: AppColors.amber.withValues(alpha: 0.6),
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                child: _placing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.darkNavy,
                        ),
                      )
                    : Text(
                        'PAY ₦${_formatted(_total.toInt())}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1,
                        ),
                      ),
              ),
      ),
    );
  }
}
