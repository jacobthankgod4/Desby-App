import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/constants/nigeria_lga_data.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_ids.dart';
import '../providers/order_provider.dart';
import '../providers/logistics_provider.dart';
import '../widgets/body_scan_picker_widget.dart';
import '../../../../core/providers/style_preferences_provider.dart';
import '../../../../core/widgets/shell_app_bar.dart';

class PriceEstimationPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> tailor;

  const PriceEstimationPage({super.key, required this.tailor});

  @override
  ConsumerState<PriceEstimationPage> createState() =>
      _PriceEstimationPageState();
}

class _PriceEstimationPageState extends ConsumerState<PriceEstimationPage> {
  bool _isCreating = false;
  Map<String, double>? _measurements;
  String _deliveryAddress = '';
  DateTime? _deliveryDate;
  final _addressController = TextEditingController();
  double _dispatchFee = 0.0;
  bool _isLoadingDispatchFee = false;
  String? _dispatchFeeError;
  bool _prefilledAddress = false;
  String? _profileState;
  int _dispatchFeeRequest = 0;

  String get _garmentType => widget.tailor['garmentType'] ?? 'Suit';
  String get _fabricType => widget.tailor['fabricType'] ?? 'Cotton';
  String get _fabricColor => widget.tailor['fabricColor'] ?? 'Black';
  String? get _materialUrl => widget.tailor['materialUrl'];
  double get _basePrice =>
      (widget.tailor['estimatedPrice'] as num?)?.toDouble() ?? 45000;
  bool get _requiresDispatch => _deliveryAddress.trim().isNotEmpty;
  double get _dispatchFeeAmount => _requiresDispatch ? _dispatchFee : 0.0;
  double get _totalPrice => _basePrice + _dispatchFeeAmount;

  @override
  void initState() {
    super.initState();
    _prefillAddressFromProfile();
  }

  Future<void> _prefillAddressFromProfile() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final profile = await ref.read(userProfileProvider(user.id).future);
      if (!mounted) return;
      final address = profile?.address?.trim() ?? '';
      final profileState = profile?.state?.trim() ?? '';
      if (address.isEmpty && profileState.isEmpty) return;
      setState(() {
        if (address.isNotEmpty) {
          _addressController.text = address;
          _deliveryAddress = address;
          _prefilledAddress = true;
        }
        if (profileState.isNotEmpty) {
          _profileState = profileState;
        }
      });
      if (_requiresDispatch) _fetchDispatchFee();
    } catch (e) {
      debugPrint('Profile address prefill failed: $e');
    }
  }

  /// Derive the Nigerian state from the free-text address so the dispatch
  /// estimate is computed against a state name, not a full street address.
  String _deriveStateName(String address) {
    final normalized = address.toLowerCase().trim();
    final states = [...NigeriaLgaData.states]
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final state in states) {
      if (normalized.contains(state.toLowerCase())) return state;
    }
    if (normalized.contains('abuja')) return 'FCT';

    final profileState = _profileState?.trim().toLowerCase() ?? '';
    for (final state in states) {
      if (state.toLowerCase() == profileState) return state;
    }
    if (profileState == 'abuja' || profileState == 'fct') return 'FCT';
    return 'Lagos';
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _fetchDispatchFee() async {
    final requestId = ++_dispatchFeeRequest;
    if (!mounted) return;
    if (!_requiresDispatch) {
      setState(() {
        _dispatchFee = 0;
        _dispatchFeeError = null;
        _isLoadingDispatchFee = false;
      });
      return;
    }
    setState(() {
      _isLoadingDispatchFee = true;
      _dispatchFeeError = null;
    });

    try {
      final repo = ref.read(logisticsRepositoryProvider);
      final stateName = _deriveStateName(_deliveryAddress);
      final result = await repo.estimateCost(stateName);
      if (!mounted || requestId != _dispatchFeeRequest) return;
      result.fold(
        (failure) {
          if (!mounted || requestId != _dispatchFeeRequest) return;
          setState(() {
            _dispatchFeeError = failure.message;
            _isLoadingDispatchFee = false;
          });
        },
        (cost) {
          if (!mounted || requestId != _dispatchFeeRequest) return;
          setState(() {
            _dispatchFee = cost;
            _isLoadingDispatchFee = false;
          });
        },
      );
    } catch (e) {
      if (!mounted || requestId != _dispatchFeeRequest) return;
      setState(() {
        _dispatchFeeError = 'Failed to fetch delivery estimate: $e';
        _isLoadingDispatchFee = false;
      });
    }
  }

  /// `widget.tailor['id']` was read first, but callers pass the tailor id under
  /// BOTH 'id' and 'tailorId' — and design/product callers sometimes put a
  /// product id in 'id'. Prefer the explicitly named tailor keys.
  String? get _resolvedTailorId {
    for (final key in const ['tailorId', 'tailor_id', 'id']) {
      final value = widget.tailor[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  Future<void> _confirmBooking() async {
    if (_requiresDispatch &&
        (_isLoadingDispatchFee || _dispatchFeeError != null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for the delivery fee estimate'),
        ),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      // The uuid PK and the readable reference are the repository's job now
      // (OrderIds). Previously this page passed 'ORD_<millis>' as the primary
      // key, which Postgres rejected (22P02) and put user.id into client_id,
      // which references clients(id) and failed the FK (23503). Both made every
      // booking fail. `requestingUserId` is the correct home for the buyer's id;
      // clientId stays null until the tailor creates a customer record.
      final order = OrderEntity(
        id: OrderIds.newUuid()!,
        reference: OrderIds.newReference(),
        requestingUserId: user.id,
        clientId: null,
        tailorId: _resolvedTailorId,
        clientName: user.name,
        status: OrderStatus.pending,
        totalAmount: _totalPrice,
        dispatchFee: _dispatchFeeAmount,
        dueDate: _deliveryDate,
        createdAt: DateTime.now(),
        fabricType: _fabricType,
        fabricColor: _fabricColor,
        materialAssetUrl: _materialUrl,
        deliveryAddress: _deliveryAddress.isNotEmpty ? _deliveryAddress : null,
        requiresDispatch: _requiresDispatch,
        items: [
          OrderItem(
            id: 'item_1',
            garmentType: _garmentType,
            designId: widget.tailor['designId'] as String?,
            price: _basePrice,
            measurements: _measurements,
          ),
        ],
      );

      final result = await ref.read(createOrderUsecaseProvider)(order);

      result.fold(
        (failure) {
          // The repository now surfaces the real Postgres reason; showing it is
          // the difference between a reportable bug and a ghost.
          debugPrint('[ORDER_CREATE_FAILED] ${failure.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: context.colors.statusError,
            ),
          );
        },
        (saved) {
          // Use the id the database actually assigned, not a locally invented
          // one — the payment step updates the order by id, so a mismatch here
          // would mark nothing as paid.
          final savedId = saved.id;
          ref.invalidate(ordersProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('BOOKING CONFIRMED!'),
              backgroundColor: Colors.greenAccent,
            ),
          );
          ref.read(stylePreferencesProvider.notifier).state = null;
          // Navigate to payment checkout
          ref.pushShell('/checkout', {
            'amount': _totalPrice,
            'orderId': savedId,
            'orderIds': [savedId],
            'reference': saved.displayReference,
          });
        },
      );
    } catch (e) {
      debugPrint('Booking Error: $e');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(context, title: 'Price Estimate'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPriceCard(),
            const SizedBox(height: 24),
            _buildOrderSummary(),
            const SizedBox(height: 24),
            _buildMeasurementsSection(),
            const SizedBox(height: 24),
            _buildDeliverySection(),
            const SizedBox(height: 32),
            _buildCostBreakdown(),
            const SizedBox(height: 32),
            _buildConfirmButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard() {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.calculate_rounded, color: AppColors.amber, size: 44),
          const SizedBox(height: 20),
          Text(
            'ESTIMATED TOTAL',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '₦${_totalPrice.toInt().toString()}',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'with ${widget.tailor['name'] ?? 'Your tailor'}',
            style: TextStyle(
              color: AppColors.amber,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ORDER DETAILS',
            style: TextStyle(
              color: AppColors.amber,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _detailRow('Garment', _garmentType),
          _detailRow('Fabric', _fabricType),
          _detailRow('Color', _fabricColor),
          if (_materialUrl != null) _detailRow('Material', 'Uploaded'),
          Builder(
            builder: (context) {
              final prefs = ref.read(stylePreferencesProvider);
              if (prefs == null) return const SizedBox.shrink();
              return Column(
                children: [
                  _detailRow('Occasion', prefs.occasion),
                  _detailRow(
                    'Budget Range',
                    '₦${prefs.budgetMin.toInt()} — ₦${prefs.budgetMax.toInt()}',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementsSection() {
    return BodyScanPickerWidget(
      onMeasurementsSelected: (measurements) {
        setState(() => _measurements = measurements);
      },
      onStartNewScan: () {
        ref.pushShell('/ai-body-scan', null);
      },
    );
  }

  Widget _buildDeliverySection() {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.local_shipping_rounded,
                color: AppColors.amber,
                size: 18,
              ),
              SizedBox(width: 10),
              Text(
                'Delivery Details',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            style: TextStyle(color: colors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Delivery address (optional)',
              hintStyle: TextStyle(color: colors.textMuted),
              filled: true,
              fillColor: colors.surfaceHover,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.amber,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: (v) {
              final requiresDispatch = v.trim().isNotEmpty;
              setState(() {
                _deliveryAddress = v;
                if (!requiresDispatch) {
                  _dispatchFeeRequest++;
                  _dispatchFee = 0;
                  _dispatchFeeError = null;
                  _isLoadingDispatchFee = false;
                }
              });
              if (requiresDispatch) _fetchDispatchFee();
            },
          ),
          if (_prefilledAddress) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: colors.textMuted, size: 12),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'We prefilled your address from your profile — tap to edit.',
                    style: TextStyle(color: colors.textMuted, fontSize: 10),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 14)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (date != null) setState(() => _deliveryDate = date);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: colors.surfaceHover,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: _deliveryDate != null
                        ? AppColors.amber
                        : colors.textMuted,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _deliveryDate != null
                        ? '${_deliveryDate!.day}/${_deliveryDate!.month}/${_deliveryDate!.year}'
                        : 'Preferred delivery date (optional)',
                    style: TextStyle(
                      color: _deliveryDate != null
                          ? colors.textPrimary
                          : colors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostBreakdown() {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'COST BREAKDOWN',
          style: TextStyle(
            color: AppColors.amber,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        _buildCostLine(
          'Base Stitching ($_garmentType)',
          '₦${_basePrice.toInt().toString()}',
        ),
        if (_requiresDispatch && _isLoadingDispatchFee)
          _buildCostLine('Dispatch Fee', 'Calculating...')
        else if (_requiresDispatch && _dispatchFeeError != null)
          _buildCostLine('Dispatch Fee', _dispatchFeeError!)
        else
          _buildCostLine(
            'Dispatch Fee',
            _requiresDispatch
                ? '₦${_dispatchFee.toInt().toString()}'
                : 'Not requested',
          ),
        Divider(color: colors.divider, height: 32),
        _buildCostLine(
          'Total Amount',
          '₦${_totalPrice.toInt().toString()}',
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildCostLine(String label, String value, {bool isTotal = false}) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? colors.textPrimary : colors.textSecondary,
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? AppColors.amber : colors.textPrimary,
              fontSize: isTotal ? 20 : 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    final canConfirm =
        !_isCreating &&
        (!_requiresDispatch ||
            (!_isLoadingDispatchFee && _dispatchFeeError == null));
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: canConfirm ? _confirmBooking : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.darkNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: _isCreating
            ? CircularProgressIndicator(color: context.colors.textOnAmber)
            : const Text(
                'Confirm Booking',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
      ),
    );
  }
}
