import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/providers/style_preferences_provider.dart';
import '../../../checkout/presentation/providers/checkout_draft_provider.dart';
import '../../../checkout/presentation/providers/request_journey_feature.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/shell_scope.dart';
import '../widgets/material_upload_station.dart';
import '../widgets/dispatch_logistics_module.dart';

class BookingCartPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> tailor;

  const BookingCartPage({super.key, required this.tailor});

  @override
  ConsumerState<BookingCartPage> createState() => _BookingCartPageState();
}

class _BookingCartPageState extends ConsumerState<BookingCartPage> {
  String _orderName = 'Suit';
  String _fabricType = 'Cotton';
  String _fabricColor = 'Black';
  int _quantity = 1;
  final String _selectedGender = 'Male';
  XFile? _pickedMaterialXFile;
  String? _uploadedMaterialUrl;

  @override
  void initState() {
    super.initState();
    _bootstrapWithoutArgs();
    // Carry the design selection through from the design detail page so it
    // survives the hop into the cart (the old hardcoded defaults lost it).
    // When NO product was preselected, start empty so Step 1 forces the
    // client to state what they actually want made.
    final args = widget.tailor;
    if (args.isNotEmpty) {
      _orderName = (args['designTitle'] as String?) ?? '';
      _fabricType = (args['fabricType'] as String?) ?? '';
      _fabricColor = (args['fabricColor'] as String?) ?? '';
      final qty = (args['quantity'] as num?)?.toInt() ?? 1;
      if (qty > 0) _quantity = qty;
    }
  }

  final GlobalKey _step1Key = GlobalKey();
  final GlobalKey _materialKey = GlobalKey();
  final GlobalKey _measurementsKey = GlobalKey();
  final GlobalKey _priceKey = GlobalKey();

  final List<Map<String, String>> _fabricOptions = [
    {'name': 'Cotton', 'desc': 'Lightweight for casual wear', 'price': '45000'},
    {'name': 'Linen', 'desc': 'Breathable for hot weather', 'price': '65000'},
    {
      'name': 'Wool',
      'desc': 'Premium wool for formal suits',
      'price': '120000',
    },
    {'name': 'Silk', 'desc': 'Luxury for special occasions', 'price': '180000'},
  ];

  final List<Map<String, dynamic>> _colorOptions = [
    {'name': 'Black', 'color': Colors.black},
    {'name': 'Navy', 'color': const Color(0xFF000080)},
    {'name': 'Brown', 'color': const Color(0xFF8B4513)},
    {'name': 'White', 'color': Colors.white},
    {'name': 'Burgundy', 'color': const Color(0xFF800020)},
    {'name': 'Gold', 'color': const Color(0xFFD4AF37)},
    {'name': 'Silver', 'color': const Color(0xFFC0C0C0)},
    {'name': 'Multi', 'color': null},
  ];

  static const List<String> _maleGarments = [
    'Suit',
    'Agbada',
    'Kaftan',
    'Senator',
    'Shirt',
    'Jacket',
    'Trousers',
  ];
  static const List<String> _femaleGarments = [
    'Dress',
    'Ankara',
    'Gown',
    'Blazer',
    'Trousers',
    'Skirt',
    'Jumpsuit',
  ];

  bool get _isStep1Done =>
      _orderName.isNotEmpty &&
      _fabricType.isNotEmpty &&
      _fabricColor.isNotEmpty;
  bool get _isStep2Done => _pickedMaterialXFile != null;
  bool get _isStylePrefsDone => ref.read(stylePreferencesProvider) != null;

  double get _estimatedPrice {
    final designPrice = (widget.tailor['designPrice'] as num?)?.toDouble();
    final fabricEntry = _fabricOptions.firstWhere(
      (f) => f['name'] == _fabricType,
      orElse: () => _fabricOptions.first,
    );
    final fabricBase =
        double.tryParse(fabricEntry['price'] ?? '45000') ?? 45000;
    if (designPrice != null) {
      final originalFabric = widget.tailor['fabricType'] ?? 'Cotton';
      if (_fabricType == originalFabric) return designPrice * _quantity;
    }
    return fabricBase * _quantity;
  }

  void _validateAndConfirm() {
    if (!_isStep1Done) {
      _scrollTo(_step1Key);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _orderName.isEmpty
                ? 'Step 1: Tell us what you want made.'
                : 'Step 1: Complete fabric and colour.',
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }
    if (!_isStep2Done) {
      _scrollTo(_materialKey);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Step 2: Upload a material photo.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }
    if (!_isStylePrefsDone) {
      _scrollTo(_measurementsKey);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Step 4: Complete style preferences.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }
    ref.pushShell('/price-estimation', {
      ...widget.tailor,
      'garmentType': _orderName,
      'fabricType': _fabricType,
      'fabricColor': _fabricColor,
      'materialUrl': _uploadedMaterialUrl,
      'estimatedPrice': _estimatedPrice,
    });
  }

  void _scrollTo(GlobalKey key) {
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _uploadMaterialPhoto() async {
    if (_pickedMaterialXFile == null) return;
    try {
      final bytes = await _pickedMaterialXFile!.readAsBytes();
      final ext = _pickedMaterialXFile!.name.split('.').last;
      final fileName = 'material_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final path = 'orders/materials/$fileName';

      await Supabase.instance.client.storage
          .from('images')
          .uploadBinary(path, bytes);
      final url = Supabase.instance.client.storage
          .from('images')
          .getPublicUrl(path);
      if (mounted) setState(() => _uploadedMaterialUrl = url);
    } catch (e) {
      debugPrint('[BOOKING] Material upload failed: $e');
    }
  }

  @override
  /// `/booking-cart` with no arguments. Rather than making the client read an
  /// error, put them back where they were: on their unfinished request if one
  /// exists, otherwise on the dashboard.
  Future<void> _bootstrapWithoutArgs() async {
    if (widget.tailor.isNotEmpty) return;
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    try {
      final recent = await ref.read(recentDraftProvider.future);
      if (!mounted) return;
      if (recent != null && recent.tailor != null) {
        ref.pushShell(
          requestJourneyRoute,
          tailorProfileJourneyArgs(
            tailorId: recent.tailor!.id,
            tailorName: recent.tailor!.name,
            tailorAvatarUrl: recent.tailor!.avatarUrl,
          ),
        );
        return;
      }
    } catch (e) {
      debugPrint('[BOOKING_CART] draft resume failed: $e');
    }
    if (!mounted) return;
    ref.setShell('/main');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isCartValid = widget.tailor.isNotEmpty;
    if (!isCartValid) return _buildSessionExpiredState(context);

    final stylePrefs = ref.watch(stylePreferencesProvider);

    return PopScope(
      canPop: _pickedMaterialXFile == null && stylePrefs == null,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard Booking?'),
            content: const Text(
              'Your selected materials and design details will be lost.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('KEEP EDITING'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'DISCARD',
                  style: TextStyle(color: colors.statusError),
                ),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          final nav = ref.read(navigationStackProvider.notifier);
          if (nav.canPop) {
            nav.pop();
          } else {
            nav.set('/main');
          }
        }
      },
      child: Scaffold(
        backgroundColor: colors.scaffoldBg,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: colors.scaffoldBg,
              elevation: 0,
              toolbarHeight: 60,
              // Dual-hosted: rendered inside the shell (where the shell header
              // already owns back) and as a standalone named route (where this
              // bar must own it). Unconditional leading put two arrows on screen.
              leading: ShellScope.isInside(context)
                  ? null
                  : IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.amber,
                        size: 20,
                      ),
                      onPressed: () => ref.popShell(),
                    ),
              title: Text(
                'CHECKOUT',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.8,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(10),
                child: Container(height: 10, color: AppColors.amber),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: _buildMTNStatusCard(
                  'RESERVING WITH',
                  (widget.tailor['name'] ?? 'Your tailor'),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildOrderPromoCard()),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    MaterialUploadStation(
                      key: _materialKey,
                      isCompleted: _isStep2Done,
                      onImagePicked: (xFile) async {
                        if (mounted)
                          setState(() => _pickedMaterialXFile = xFile);
                        await _uploadMaterialPhoto();
                      },
                    ),
                    const SizedBox(height: 16),
                    // Tailor-side dispatch summary. This page has no customer
                    // delivery address yet, so it falls back to Lagos; the
                    // checkout surface passes the real state instead.
                    const DispatchLogisticsModule(),
                    const SizedBox(height: 32),
                    _buildMTNGlassAction(
                      key: _measurementsKey,
                      title: 'STEP 4: STYLE PREFERENCES',
                      subtitle: stylePrefs != null
                          ? '${stylePrefs.occasion} • ${stylePrefs.fabric} • Budget ₦${stylePrefs.budgetMin.toInt()}'
                          : 'Set your design preferences',
                      isCompleted: stylePrefs != null,
                      onTap: () => ref.pushShell('/measurements-input'),
                    ),
                    const SizedBox(height: 12),
                    _buildMTNGlassAction(
                      title: 'PRICE ESTIMATION',
                      subtitle: 'Cost breakdown',
                      isCompleted: false,
                      onTap: _validateAndConfirm,
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomSheet: _buildBottomAction(context),
      ),
    );
  }

  // Reached when the cart is opened without a tailor session (browser
  // refresh, direct link or restored tab) — the nav arguments are in-memory
  // only. Give the client a designed recovery path instead of a dead end.
  /// Reached when `/booking-cart` is entered without arguments — a bare deep
  /// link or a restored tab from before the draft table existed.
  ///
  /// This used to be a wall: the only way out was a button. Now it restores
  /// itself to somewhere useful, so nobody is ever stranded on a dead end. Any
  /// saved draft is offered first, because the client may well have been
  /// mid-request when the tab reloaded.
  Widget _buildSessionExpiredState(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.amber.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: AppColors.amber,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'CART STARTED ELSEWHERE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This booking session does not carry over when you refresh '
                    'or open a link directly. Pick a tailor to start a fresh '
                    'request — it only takes a moment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => ref.setShell('/tailor-discovery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amber,
                        foregroundColor: colors.textOnAmber,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: const Text(
                        'BROWSE TAILORS',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => ref.setShell('/main'),
                    child: Text(
                      'Back to home',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMTNStatusCard(String label, String value) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.amber.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_rounded,
            color: AppColors.amber,
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderPromoCard() {
    final colors = context.colors;
    final awaitingRequest = _orderName.isEmpty;
    return Container(
      key: _step1Key,
      height: 240,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: colors.surface,
        border: Border.all(
          color: _isStep1Done
              ? AppColors.amber.withValues(alpha: 0.6)
              : colors.borderSubtle,
          width: 2.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: SizedBox(
                height: double.infinity,
                child: Image.asset(
                  'assets/images/tailor.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: colors.overlayLight,
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: colors.borderSubtle,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _isStep1Done
                            ? AppColors.amber.withValues(alpha: 0.1)
                            : colors.borderSubtle,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'STEP 1',
                            style: TextStyle(
                              color: _isStep1Done
                                  ? AppColors.amber
                                  : colors.textMuted,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          if (_isStep1Done) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified_rounded,
                              color: AppColors.amber,
                              size: 10,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      awaitingRequest
                          ? 'WHAT DO YOU WANT MADE?'
                          : _orderName.toUpperCase(),
                      style: TextStyle(
                        color: awaitingRequest
                            ? colors.textMuted
                            : colors.textPrimary,
                        fontSize: awaitingRequest ? 16 : 22,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        letterSpacing: awaitingRequest ? 0 : -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      awaitingRequest
                          ? 'TELL US THE OUTFIT, FABRIC AND COLOUR'
                          : '$_fabricType • $_fabricColor'.toUpperCase(),
                      style: TextStyle(
                        color: awaitingRequest
                            ? AppColors.amber
                            : colors.textMuted,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'ESTIMATE',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
Text(
                      awaitingRequest ? '—' : '₦${_estimatedPrice.toInt()}',
                      style: const TextStyle(
                        color: AppColors.amber,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _showEditDetailsDialog(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amber,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_rounded,
                              color: colors.textOnAmber,
                              size: 12,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              awaitingRequest ? 'START' : 'EDIT',
                              style: TextStyle(
                                color: colors.textOnAmber,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMTNGlassAction({
    Key? key,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return InkWell(
      key: key,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surfaceHover,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted
                ? AppColors.amber.withValues(alpha: 0.6)
                : colors.borderSubtle,
            width: 2.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (isCompleted) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.verified_rounded,
                        color: AppColors.amber,
                        size: 12,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.amber,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDetailsDialog(BuildContext context) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bottomSheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final types = _selectedGender == 'Male'
              ? _maleGarments
              : _femaleGarments;
          return Padding(
            padding: EdgeInsets.only(
              left: 32,
              right: 32,
              top: 32,
              bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EDIT DETAILS',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.8,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'GARMENT TYPE',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: types.map((type) {
                      final isSelected = _orderName == type;
                      return ChoiceChip(
                        label: Text(
                          type.toUpperCase(),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.black
                                : colors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (s) {
                          if (s) setState(() => _orderName = type);
                          setModalState(() {});
                        },
                        selectedColor: AppColors.amber,
                        backgroundColor: colors.borderSubtle,
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.amber
                              : colors.borderSubtle,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'COLOR PALETTE',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _colorOptions.length,
                      itemBuilder: (context, index) {
                        final colorOpt = _colorOptions[index];
                        final isSelected = _fabricColor == colorOpt['name'];
                        return GestureDetector(
                          onTap: () {
                            setState(() => _fabricColor = colorOpt['name']);
                            setModalState(() {});
                          },
                          child: Container(
                            width: 50,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: colorOpt['color'] ?? Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.amber
                                    : colors.borderSubtle,
                                width: isSelected ? 3 : 1,
                              ),
                              gradient: colorOpt['name'] == 'Multi'
                                  ? const SweepGradient(
                                      colors: [
                                        Colors.red,
                                        Colors.yellow,
                                        Colors.green,
                                        Colors.blue,
                                        Colors.red,
                                      ],
                                    )
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: AppColors.amber,
                                    size: 20,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'FABRIC SELECTION',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._fabricOptions.map(
                    (f) => ListTile(
                      onTap: () {
                        setState(() => _fabricType = f['name']!);
                        setModalState(() {});
                      },
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        f['name']!.toUpperCase(),
                        style: TextStyle(
                          color: _fabricType == f['name']
                              ? AppColors.amber
                              : colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      subtitle: Text(
                        f['desc']!,
                        style: TextStyle(color: colors.textMuted, fontSize: 11),
                      ),
                      trailing: Text(
                        '₦${f['price']}',
                        style: TextStyle(
                          color: AppColors.amber,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'SAVE MODIFICATIONS',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(24),
      color: colors.scaffoldBg,
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: _validateAndConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: AppColors.darkNavy,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'PLACE ORDER',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 2.0,
                  ),
                ),
                SizedBox(width: 12),
                Icon(Icons.check_circle_rounded, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
