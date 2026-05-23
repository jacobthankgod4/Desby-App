import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/colors.dart';
import '../widgets/material_upload_station.dart';
import '../widgets/dispatch_logistics_module.dart';

class BookingCartPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> tailor;

  const BookingCartPage({super.key, required this.tailor});

  @override
  ConsumerState<BookingCartPage> createState() => _BookingCartPageState();
}

class _BookingCartPageState extends ConsumerState<BookingCartPage> {
  // --- FUNCTIONAL STATE ---
  String _orderName = 'Suit';
  String _fabricType = 'Cotton';
  String _fabricColor = 'Black';
  final String _selectedGender = 'MALE';
  XFile? _pickedMaterialXFile; 
  bool _measurementsCompleted = false; 
  
  // SCROLL KEYS FOR AUTO-ATTENTION
  final GlobalKey _materialKey = GlobalKey();
  final GlobalKey _measurementsKey = GlobalKey();

  final List<Map<String, String>> _fabricOptions = [
    {'name': 'Cotton', 'desc': 'Lightweight for casual wear', 'price': '₦45,000'},
    {'name': 'Linen', 'desc': 'Breathable for hot weather', 'price': '₦65,000'},
    {'name': 'Wool', 'desc': 'Premium wool for formal suits', 'price': '₦120,000'},
    {'name': 'Silk', 'desc': 'Luxury for special occasions', 'price': '₦180,000'},
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
  
  static const List<String> _maleGarments = ['Suit', 'Agbada', 'Kaftan', 'Senator', 'Shirt', 'Jacket', 'Trousers'];
  static const List<String> _femaleGarments = ['Dress', 'Ankara', 'Gown', 'Blazer', 'Trousers', 'Skirt', 'Jumpsuit'];

  // --- MILESTONE CHECKS ---
  bool get _isStep1Done => _orderName.isNotEmpty && _fabricType.isNotEmpty && _fabricColor.isNotEmpty;
  bool get _isStep2Done => _pickedMaterialXFile != null;
  bool get _isStep4Done => _measurementsCompleted;

  void _validateAndConfirm() {
    if (!_isStep2Done) {
      _scrollTo(_materialKey);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Step 2: Material Asset required.'), backgroundColor: Colors.orangeAccent));
      return;
    }
    if (!_isStep4Done) {
      _scrollTo(_measurementsKey);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Step 4: Verify Precision Measurements.'), backgroundColor: Colors.orangeAccent));
      return;
    }
    Navigator.pushNamed(context, '/price-estimation', arguments: widget.tailor);
  }

  void _scrollTo(GlobalKey key) {
    if (key.currentContext != null) {
      Scrollable.ensureVisible(key.currentContext!, duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    // WEB STABILITY: Focus Check
    final isCartValid = widget.tailor.isNotEmpty;
    if (!isCartValid) return const Scaffold(body: Center(child: Text('CART ARCHITECTURE ERROR')));

    return PopScope(
      canPop: _pickedMaterialXFile == null && !_measurementsCompleted,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard Booking?'),
            content: const Text('Your selected materials and architecture details will be lost.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('KEEP EDITING')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('DISCARD', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        );

        if (confirmed == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.darkNavy,
        body: CustomScrollView(
          slivers: [
            // 1. HEADER
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.darkNavy,
              elevation: 0,
              toolbarHeight: 60,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('CHECKOUT',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.8)),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(10),
                child: Container(height: 10, color: AppColors.amber),
              ),
            ),
  
            // 2. CONTEXT STATUS (VCARD)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: _buildMTNStatusCard('RESERVING WITH', (widget.tailor['name'] ?? 'MASTER TAILOR').toUpperCase()),
              ),
            ),
  
            // 3. STEP 1: ARCHITECTURE
            SliverToBoxAdapter(
              child: _buildOrderPromoCard(),
            ),
  
            // 4. FUNCTIONAL FLOW
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    MaterialUploadStation(
                      key: _materialKey,
                      isCompleted: _isStep2Done,
                      onImagePicked: (xFile) => setState(() => _pickedMaterialXFile = xFile),
                    ),
                    const SizedBox(height: 16),
                    const DispatchLogisticsModule(),
                    const SizedBox(height: 32),
                    _buildMTNGlassAction(
                      key: _measurementsKey,
                      title: 'STEP 4: PRECISION MEASUREMENTS', 
                      subtitle: 'Verify digital profile alignment', 
                      isCompleted: _isStep4Done,
                      onTap: () {
                        Navigator.pushNamed(context, '/measurements-input').then((_) {
                          setState(() => _measurementsCompleted = true);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMTNGlassAction(
                      title: 'PRICE ESTIMATION', 
                      subtitle: 'Architecture & Cost breakdown', 
                      isCompleted: false,
                      onTap: () => Navigator.pushNamed(context, '/price-estimation', arguments: widget.tailor),
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

  Widget _buildMTNStatusCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: AppColors.amber, size: 18),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5))),
        ],
      ),
    );
  }

  Widget _buildOrderPromoCard() {
    return Container(
      height: 240,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF141414),
        border: Border.all(
          color: _isStep1Done ? AppColors.amber.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.05),
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
                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.black12, child: const Icon(Icons.shopping_bag_outlined, color: Colors.white12, size: 40)),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isStep1Done ? AppColors.amber.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('STEP 1', style: TextStyle(color: _isStep1Done ? AppColors.amber : Colors.white24, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          if (_isStep1Done) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded, color: AppColors.amber, size: 10),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(_orderName.toUpperCase(), 
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.0, letterSpacing: -1)),
                    const SizedBox(height: 4),
                    Text('$_fabricType • $_fabricColor'.toUpperCase(), 
                      style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    const Spacer(),
                    const Text('ESTIMATE', style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    const Text('₦85,000', style: TextStyle(color: AppColors.amber, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -1)),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _showEditDetailsDialog(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.amber, borderRadius: BorderRadius.circular(10)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_rounded, color: AppColors.darkNavy, size: 12),
                            SizedBox(width: 6),
                            Text('EDIT', style: TextStyle(color: AppColors.darkNavy, fontSize: 9, fontWeight: FontWeight.w900)),
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

  Widget _buildMTNGlassAction({Key? key, required String title, required String subtitle, required bool isCompleted, required VoidCallback onTap}) {
    return InkWell(
      key: key,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted ? AppColors.amber.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.05),
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
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    if (isCompleted) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.verified_rounded, color: AppColors.amber, size: 12),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.amber, size: 16),
          ],
        ),
      ),
    );
  }

  void _showEditDetailsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final types = _selectedGender == 'MALE' ? _maleGarments : _femaleGarments;
          return Padding(
            padding: EdgeInsets.only(left: 32, right: 32, top: 32, bottom: MediaQuery.of(context).viewInsets.bottom + 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('EDIT ARCHITECTURE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.8)),
                  const SizedBox(height: 24),
                  
                  const Text('GARMENT TYPE', style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: types.map((type) {
                      final isSelected = _orderName == type;
                      return ChoiceChip(
                        label: Text(type.toUpperCase(), style: TextStyle(color: isSelected ? Colors.black : Colors.white60, fontSize: 10, fontWeight: FontWeight.w900)),
                        selected: isSelected,
                        onSelected: (s) { if (s) setState(() => _orderName = type); setModalState(() {}); },
                        selectedColor: AppColors.amber,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        side: BorderSide(color: isSelected ? AppColors.amber : Colors.white10),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  const Text('COLOR PALETTE', style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
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
                          onTap: () { setState(() => _fabricColor = colorOpt['name']); setModalState(() {}); },
                          child: Container(
                            width: 50,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: colorOpt['color'] ?? Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(color: isSelected ? AppColors.amber : Colors.white10, width: isSelected ? 3 : 1),
                              gradient: colorOpt['name'] == 'Multi' 
                                ? const SweepGradient(colors: [Colors.red, Colors.yellow, Colors.green, Colors.blue, Colors.red])
                                : null,
                            ),
                            child: isSelected ? const Icon(Icons.check, color: AppColors.amber, size: 20) : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text('FABRIC SELECTION', style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  ..._fabricOptions.map((f) => ListTile(
                    onTap: () { setState(() => _fabricType = f['name']!); setModalState(() {}); },
                    contentPadding: EdgeInsets.zero,
                    title: Text(f['name']!.toUpperCase(), style: TextStyle(color: _fabricType == f['name'] ? AppColors.amber : Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                    subtitle: Text(f['desc']!, style: const TextStyle(color: Colors.white24, fontSize: 11)),
                    trailing: Text(f['price']!, style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900, fontSize: 12)),
                  )),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity, height: 60,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: const Text('SAVE MODIFICATIONS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
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
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.darkNavy,
      child: SafeArea(
        child: SizedBox(
          width: double.infinity, height: 64,
          child: ElevatedButton(
            onPressed: _validateAndConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber, 
              foregroundColor: AppColors.darkNavy, 
              elevation: 0, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('PLACE ORDER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2.0)),
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
