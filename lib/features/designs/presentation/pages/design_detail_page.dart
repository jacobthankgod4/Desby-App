import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../theme/colors.dart';
import 'virtual_tryon_page.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/providers/layout_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/entities/design.dart';
import '../providers/design_provider.dart';
import '../../../../core/widgets/shell_app_bar.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../checkout/presentation/providers/request_journey_feature.dart';

class DesignDetailPage extends ConsumerStatefulWidget {
  final Design design;

  /// `'shop'` when opened from the Shop tab: the primary action becomes
  /// BUY NOW into the streamlined three-step shop checkout instead of the
  /// made-to-order journey.
  final String? origin;

  const DesignDetailPage({super.key, required this.design, this.origin});

  @override
  ConsumerState<DesignDetailPage> createState() => _DesignDetailPageState();
}

class _DesignDetailPageState extends ConsumerState<DesignDetailPage> {
  int _selectedImage = 0;
  int _selectedColor = 1;
  int _quantity = 1;
  int _selectedFitSize = 0;
  late final PageController _pageController;
  Timer? _carouselTimer;

  static const List<Color> _colors = [
    Color(0xFFD9C3B8), // beige
    Color(0xFF0A3D2E), // dark green
    Color(0xFF1A1A2E), // navy black
    Color(0xFF8B4513), // brown
  ];

  static const List<String> _fitSizes = ['52', '54', '56', '58', '60'];

  String get _formattedPrice =>
      NumberFormat('#,##0').format(widget.design.price.toInt());
  String get _formattedTotal =>
      NumberFormat('#,##0').format((widget.design.price * _quantity).toInt());

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoPlay();
    _trackRecentlyViewed();
  }

  Future<void> _trackRecentlyViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList('recently_viewed') ?? [];
      ids.remove(widget.design.id);
      ids.insert(0, widget.design.id);
      if (ids.length > 20) ids.removeRange(20, ids.length);
      await prefs.setStringList('recently_viewed', ids);
    } catch (e) {
      debugPrint('[ERROR] _trackRecentlyViewed: $e');
    }
  }

  void _startAutoPlay() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final images = widget.design.imageUrls;
      if (images.length <= 1) return;
      final next = (_selectedImage + 1) % images.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// Scenario B: a design is already chosen, so checkout opens on the journey
  /// with the design as context and only asks how they want it made.
  ///
  /// The size and colour selected on this page are carried through. The legacy
  /// path accepted `size` and `colorIndex` and then discarded both, so a client
  /// picked a size and it never reached the order.
  void _startRequest(Design design) {
    if (!RequestJourneyFeature.enabled) {
      // Legacy chain, unchanged.
      ref.pushShell('/booking-cart', {
        'id': design.tailorId,
        'tailorId': design.tailorId,
        'name': design.tailorName,
        'designId': design.id,
        'designTitle': design.title,
        'designPrice': design.price,
        'quantity': _quantity,
        'size': _fitSizes[_selectedFitSize],
        'colorIndex': _selectedColor,
      });
      return;
    }
    ref.pushShell(requestJourneyRoute, designJourneyArgs(
      designId: design.id,
      tailorId: design.tailorId,
      tailorName: design.tailorName,
      title: design.title,
      category: design.category,
      imageUrls: design.imageUrls,
      price: design.price,
      selectedSize: _fitSizes[_selectedFitSize],
      selectedColour: design.category != null ? design.category : null,
      quantity: _quantity,
    ));
  }

  /// Shop-tab buy path: ready-to-wear, three steps (measurements → address →
  /// pay) — no journey, no quoting round-trip.
  void _startShopCheckout(Design design) {
    ref.pushShell('/shop-checkout', {
      'design': design,
      'quantity': _quantity,
      'size': _fitSizes[_selectedFitSize],
      'colorValue': _colors[_selectedColor].toARGB32(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDesktop = ref.watch(isDesktopProvider);
    final design = widget.design;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(
        context,
        titleWidget: _buildBreadcrumb(),
        actions: [
          IconButton(
            icon: Icon(
              Icons.search_rounded,
              color: colors.textSecondary,
              size: 22,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 48 : 20,
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isDesktop
                ? _buildDesktopLayout(design)
                : _buildMobileLayout(design),
            const SizedBox(height: 40),
            isDesktop
                ? _buildBottomSectionsDesktop(design)
                : _buildBottomSectionsMobile(design),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // BREADCRUMB
  // ------------------------------------------------------------------

  Widget _buildBreadcrumb() {
    final colors = context.colors;
    final design = widget.design;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _crumb('Shop'),
        _chevron(),
        _crumb(design.category.toUpperCase()),
        _chevron(),
        Flexible(
          child: Text(
            design.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _crumb(String label) {
    final colors = context.colors;
    return Text(
      label,
      style: TextStyle(
        color: colors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _chevron() {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Icon(
        Icons.chevron_right_rounded,
        size: 14,
        color: colors.textMuted,
      ),
    );
  }

  // ------------------------------------------------------------------
  // TOP LAYOUT — GALLERY + BUY PANEL
  // ------------------------------------------------------------------

  Widget _buildDesktopLayout(Design design) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 50, child: _buildGallery(design)),
        const SizedBox(width: 40),
        Expanded(flex: 50, child: _buildBuyPanel(design)),
      ],
    );
  }

  Widget _buildMobileLayout(Design design) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGallery(design),
        const SizedBox(height: 24),
        _buildBuyPanel(design),
      ],
    );
  }

  // ------------------------------------------------------------------
  // IMAGE GALLERY — main image + thumbnails
  // ------------------------------------------------------------------

  Widget _buildGallery(Design design) {
    final colors = context.colors;
    final images = design.imageUrls;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1000;
    final galleryHeight = isDesktop
        ? 480.0
        : (screenWidth * 0.7).clamp(300.0, 420.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.borderDefault),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: galleryHeight,
                child: images.isNotEmpty
                    ? PageView.builder(
                        controller: _pageController,
                        itemCount: images.length,
                        onPageChanged: (i) =>
                            setState(() => _selectedImage = i),
                        itemBuilder: (_, i) => AppNetworkImage(
                          url: images[i],
                          fit: BoxFit.contain,
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.checkroom_rounded,
                          color: colors.divider,
                          size: 72,
                        ),
                      ),
              ),
              // Gradient overlay at bottom for indicators
              if (images.length > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 60,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x990A1921)],
                      ),
                    ),
                  ),
                ),
              // Page indicators
              if (images.length > 1)
                Positioned(
                  left: 16,
                  bottom: 14,
                  child: Row(
                    children: List.generate(
                      images.length,
                      (i) => GestureDetector(
                        onTap: () => _pageController.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: _selectedImage == i ? 28 : 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _selectedImage == i
                                ? AppColors.amber
                                : colors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Zoom button
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () => _openImageViewer(images),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: colors.overlayHeavy,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.zoom_in_rounded,
                      color: colors.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ),
              // Category badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.overlayMedium,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    design.category.toUpperCase(),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Thumbnail strip
        if (images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final selected = _selectedImage == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedImage = index);
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOutCubic,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? AppColors.amber
                              : colors.borderDefault,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: AppNetworkImage(
                          url: images[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  void _openImageViewer(List<String> images) {
    final colors = context.colors;
    showDialog(
      context: context,
      barrierColor: colors.barrierColor,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          children: [
            InteractiveViewer(
              maxScale: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AppNetworkImage(
                  url: images[_selectedImage.clamp(0, images.length - 1)],
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: colors.textPrimary,
                  size: 28,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTryOn() {
    final design = widget.design;
    if (design.imageUrls.isEmpty) return;
    ref
        .read(virtualTryOnProvider.notifier)
        .startTryOn(
          garmentUrl: design.imageUrls.first,
          designTitle: design.title,
          designId: design.id,
          tailorId: design.tailorId,
          tailorName: design.tailorName,
        );
    ref.pushShell('/virtual-tryon', {'fromDesignId': design.id});
  }

  // ------------------------------------------------------------------
  // BUY PANEL — title, rating, colors, sizes, price, qty, CTAs
  // ------------------------------------------------------------------

  Widget _buildBuyPanel(Design design) {
    final colors = context.colors;
    final isShop = widget.origin == 'shop';
    final profileAsync = ref.watch(userProfileProvider(design.tailorId));
    final profile = profileAsync.valueOrNull;

    // Use the design's stored tailorName as the source of truth
    final tailorName = design.tailorName.toUpperCase();
    final tailorAvatar = profile?.profileImage ?? design.tailorAvatarUrl;
    // Location priority: live profile (address/state/lga) → stored design fields
    final locationStr =
        (profile?.address?.isNotEmpty == true
                ? profile!.address!
                : profile?.state?.isNotEmpty == true
                ? profile!.state!
                : design.tailorLocation?.isNotEmpty == true
                ? design.tailorLocation!
                : design.tailorState ?? 'Nigeria')
            .toString();
    final lgaStr = profile?.lga ?? design.tailorLga;
    final rating = design.tailorRating > 0 ? design.tailorRating : 4.7;
    final reviewCount = design.tailorReviewCount > 0
        ? design.tailorReviewCount
        : 1;
    final orderCount = design.tailorOrderCount > 0
        ? design.tailorOrderCount
        : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                design.title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _saveButton(design),
          ],
        ),
        const SizedBox(height: 10),

        // Rating + likes
        Row(
          children: [
            ...List.generate(5, (i) {
              if (i < rating.floor()) {
                return const Icon(
                  Icons.star_rounded,
                  color: AppColors.amber,
                  size: 18,
                );
              } else if (i == rating.floor() && rating % 1 > 0) {
                return Icon(
                  Icons.star_half_rounded,
                  color: AppColors.amber,
                  size: 18,
                );
              }
              return Icon(Icons.star_rounded, color: colors.divider, size: 18);
            }),
            const SizedBox(width: 8),
            Text(
              '($rating · $reviewCount reviews)',
              style: TextStyle(color: colors.textMuted, fontSize: 12),
            ),
            const SizedBox(width: 8),
            Text(
              '${design.likesCount} likes',
              style: TextStyle(color: colors.textMuted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Tailor info card
        GestureDetector(
          onTap: () =>
              ref.pushShell('/tailor-profile', {'tailorId': design.tailorId}),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.borderDefault),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.amber.withValues(alpha: 0.15),
                  backgroundImage:
                      tailorAvatar != null && tailorAvatar.isNotEmpty
                      ? NetworkImage(tailorAvatar)
                      : null,
                  child: tailorAvatar == null || tailorAvatar.isEmpty
                      ? Text(
                          tailorName.isNotEmpty
                              ? tailorName[0].toUpperCase()
                              : 'T',
                          style: TextStyle(
                            color: AppColors.amber,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tailorName,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: colors.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              '$locationStr${lgaStr != null && lgaStr.isNotEmpty ? ' · $lgaStr' : ''}',
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceHover,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$orderCount+ orders',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Divider(height: 28, color: colors.divider),

        // Select Color
        Text(
          'Select Color',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(_colors.length, (i) {
            final selected = _selectedColor == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = i),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _colors[i],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.amber : colors.borderDefault,
                    width: selected ? 3 : 1,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),

        // Price + Quantity
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Price',
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\u20A6$_formattedTotal',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (_quantity > 1) ...[
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '(\u20A6$_formattedPrice x $_quantity)',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quantity',
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.divider),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      _qtyButton(Icons.remove_rounded, () {
                        if (_quantity > 1) setState(() => _quantity--);
                      }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          '$_quantity',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _qtyButton(
                        Icons.add_rounded,
                        () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // "Try this on" button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _openTryOn,
            icon: const Icon(Icons.checkroom_rounded, size: 18),
            label: const Text(
              'TRY THIS ON',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.surfaceHover,
              foregroundColor: colors.textPrimary,
              elevation: 0,
              side: BorderSide(color: colors.divider),
              shape: const StadiumBorder(),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // CTAs
        Row(
          children: [
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (isShop) {
                      _startShopCheckout(design);
                    } else {
                      _startRequest(design);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: AppColors.darkNavy,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    isShop ? 'BUY NOW' : 'GET THIS MADE',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    _startRequest(design);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.surfaceHover,
                    foregroundColor: colors.textPrimary,
                    elevation: 0,
                    side: BorderSide(color: colors.divider),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    isShop ? 'GET THIS MADE' : 'ADD TO CART',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _saveButton(Design design) {
    final colors = context.colors;
    final likedAsync = ref.watch(likedDesignIdsProvider);
    final isLiked = likedAsync.valueOrNull?.contains(design.id) ?? false;

    return GestureDetector(
      onTap: () async {
        final user = ref.read(currentUserProvider);
        if (user == null) return;
        await ref.read(designRepositoryProvider).toggleLike(design.id, user.id);
        ref.invalidate(likedDesignIdsProvider);
        ref.invalidate(savedDesignsProvider);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: isLiked
              ? AppColors.amber.withValues(alpha: 0.15)
              : colors.surfaceHover,
          shape: BoxShape.circle,
          border: Border.all(color: isLiked ? AppColors.amber : colors.divider),
        ),
        child: Icon(
          isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: isLiked ? AppColors.amber : colors.textSecondary,
          size: 20,
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: 16, color: colors.textSecondary),
      ),
    );
  }

  // ------------------------------------------------------------------
  // BOTTOM SECTIONS — Product Details | Size & Fit
  // ------------------------------------------------------------------

  Widget _buildBottomSectionsDesktop(Design design) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _productDetailsSection(design)),
        const SizedBox(width: 48),
        Expanded(child: _sizeFitSection()),
      ],
    );
  }

  Widget _buildBottomSectionsMobile(Design design) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _productDetailsSection(design),
        const SizedBox(height: 36),
        _sizeFitSection(),
      ],
    );
  }

  Widget _productDetailsSection(Design design) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Details',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          design.description?.isNotEmpty == true
              ? design.description!
              : 'Introducing our sophisticated bespoke ${design.category.toLowerCase()}, designed to seamlessly blend style, comfort, and intricate craftsmanship. '
                    'Made from premium fabrics and tailored precisely to your measurements by ${design.tailorName}. '
                    'Each piece is finished with reinforced stitching for a world-class bespoke result.',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13.5,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 16),
        _bulletPoint(
          'Front Open Style',
          'A modern and versatile design that exudes effortless elegance and practicality.',
        ),
        _bulletPoint(
          'Premium Fabric',
          'Luxuriously soft, lightweight, and breathable material for all-day comfort.',
        ),
        _bulletPoint(
          'Tailored Fit',
          'Crafted to your exact measurements with one free fitting adjustment.',
        ),
      ],
    );
  }

  Widget _bulletPoint(String title, String body) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: CircleAvatar(
              radius: 2.5,
              backgroundColor: AppColors.amber.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  height: 1.6,
                ),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                    ),
                  ),
                  TextSpan(text: body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sizeFitSection() {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Size & Fit',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(_fitSizes.length, (i) {
            final selected = _selectedFitSize == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedFitSize = i),
              child: Container(
                width: 56,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.amber : colors.surfaceHover,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.amber : colors.divider,
                  ),
                ),
                child: Text(
                  _fitSizes[i],
                  style: TextStyle(
                    color: selected ? AppColors.darkNavy : colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 18),
        _fitRow('Shoulder', '20 inch / 50.8cm'),
        _fitRow('Length', '48 inch / 122cm'),
        _fitRow('Sleeve length', '25 inch / 63.5cm'),
        _fitRow('Waist', '34 inch / 86.4cm'),
      ],
    );
  }

  Widget _fitRow(String label, String value) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
            ),
          ),
          Text(':', style: TextStyle(color: colors.textMuted, fontSize: 12.5)),
          const SizedBox(width: 14),
          Text(
            value,
            style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
