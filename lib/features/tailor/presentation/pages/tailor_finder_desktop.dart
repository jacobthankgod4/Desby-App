import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/service_tier.dart';
import '../providers/tailor_finder_provider.dart';
import '../widgets/tailor_map_view.dart';
import '../widgets/tailor_card.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/tailor_finder_responsive.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

/// TailorFinderDesktop - Uber-style Tailor Discovery Page
/// Responsive: adapts to 600px+ screens (mobile, tablet, desktop)
class TailorFinderDesktop extends ConsumerStatefulWidget {
  const TailorFinderDesktop({super.key});

  @override
  ConsumerState<TailorFinderDesktop> createState() => _TailorFinderDesktopState();
}

class _TailorFinderDesktopState extends ConsumerState<TailorFinderDesktop> {
  // Track if showing tailor details inline
  bool _showTailorDetails = false;
  // Track view mode: true = show map+grid (Uber), false = list only (Classic)
  // Default to true (Uber style), will be updated based on user preference
  bool _showMap = true;
  
  @override
  void initState() {
    super.initState();
    // Load nearby tailors on init
    Future.microtask(() {
      ref.read(tailorFinderProvider.notifier).loadNearbyTailors();
    });
// Apply user's preferred finder style from onboarding
    _applyUserPreference();
  }

  /// Apply user's preferred finder style from their profile
  void _applyUserPreference() {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      final profileAsync = ref.read(userProfileProvider(currentUser.id));
      // Handle the async profile data
      profileAsync.when(
        data: (profile) {
          if (profile?.preferredFinderStyle != null) {
            // If user chose 'classic' during onboarding, hide map by default
            final useClassic = profile!.preferredFinderStyle == 'classic';
            if (mounted) {
              setState(() {
                _showMap = !useClassic;
              });
            }
          }
        },
        loading: () {},
        error: (_, __) {},
      );
    }
  }

  EdgeInsets get _padding => EdgeInsets.all(
    MediaQuery.of(context).size.width >= TailorFinderBreakpoints.desktop
        ? TailorFinderLayout.desktopPadding
        : TailorFinderLayout.mobilePadding,
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tailorFinderProvider);
    final selectedTailor = state.selectedTailor;
    final selectedTier = state.selectedServiceTier;
    final currentQuote = state.currentQuote;

    // Loading state with shimmer
    if (state.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.uberBg,
        body: Row(
          children: [
            const Expanded(child: MapShimmer()),
            Expanded(
              child: Container(
                padding: _padding,
                child: const TailorListShimmer(itemCount: 4),
              ),
            ),
          ],
        ),
      );
    }

    // Error state
    if (state.error != null) {
      return Scaffold(
        backgroundColor: AppColors.uberBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.uberError),
              const SizedBox(height: 16),
              Text(
                'Failed to load tailors',
                style: TextStyle(color: AppColors.uberTextPrimary, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                style: TextStyle(color: AppColors.uberTextMuted, fontSize: 12),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.read(tailorFinderProvider.notifier).loadNearbyTailors(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

return Scaffold(
      backgroundColor: AppColors.uberBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= TailorFinderBreakpoints.tablet;
          
          // Calculate bottom safe area padding for mobile (navigation bar + floating elements)
          final bottomPadding = MediaQuery.of(context).padding.bottom;
          final bottomNavHeight = isWide ? 0.0 : 80.0 + bottomPadding;
          
// Adaptive: switch between side-by-side and stacked on narrow screens
          if (isWide) {
            // EQUAL 50/50 SPLIT - Map and Tailor Grid side by side
            return Row(
              children: [
                // LEFT: Map - 50% width (conditionally shown based on toggle)
                if (_showMap)
                  Expanded(
                    flex: 1,
                    child: _buildMap(state, selectedTailor),
                  ),
                // RIGHT: Tailor Grid Panel - 50% width (or 100% when map hidden)
                Expanded(
                  flex: _showMap ? 1 : 2,
                  child: _buildPanel(state, selectedTailor, selectedTier, currentQuote, constraints),
                ),
              ],
            );
          } else {
// Mobile/tablet stacked: map on top, panel below
// FIX: Adjust flex to account for bottom nav bar (80px) + CTA (56px) to prevent overflow
            return Column(
              children: [
                Expanded(
                  flex: 55, // Reduced from 65 to give more room to panel
                  child: _buildMap(state, selectedTailor),
                ),
                Expanded(
                  flex: 45, // Increased from 35 to accommodate content
                  child: Padding(
                    // Add bottom padding to prevent overflow into nav bar area
                    padding: EdgeInsets.only(bottom: bottomNavHeight.clamp(0, 80)),
                    child: _buildPanel(state, selectedTailor, selectedTier, currentQuote, constraints),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildMap(TailorFinderState state, dynamic selectedTailor) {
    return Semantics(
      label: TailorFinderSemantics.mapLabel,
      child: TailorMapView(
        tailors: state.tailors,
        selectedTailor: selectedTailor,
        userLocation: state.userLocation,
        onTailorSelected: (tailor) {
          ref.read(tailorFinderProvider.notifier).selectTailor(tailor);
        },
        onMapTap: (location) {
          ref.read(tailorFinderProvider.notifier).setUserLocation(location);
        },
      ),
    );
  }

Widget _buildPanel(TailorFinderState state, dynamic selectedTailor, ServiceTier? selectedTier, dynamic currentQuote, BoxConstraints constraints) {
    final padding = _padding;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= TailorFinderBreakpoints.tablet;
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.figmaCardFill,
        borderRadius: BorderRadius.horizontal(
          left: const Radius.circular(28),
          right: Radius.circular(isWide ? 28 : 0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 60,
            offset: const Offset(-20, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Filter buttons row - with dropdown menus only (hide when showing details)
          if (!_showTailorDetails) _buildFilterButtonsRow(state),
          
          // Content area - switch between tailor list and inline details
          Expanded(
            child: _showTailorDetails && selectedTailor != null
                ? _buildTailorDetailsView(selectedTailor)
                : _buildTailorListForSelection(state, padding),
          ),
          
          // Action Buttons row - switch between grid CTA and details back CTA
          _showTailorDetails
              ? _buildBackToListCTA()
              : _buildUberActionButtons(context, selectedTailor),
        ],
      ),
    );
  }

/// Filter buttons row - with dropdown menus (not bottom sheets)
  Widget _buildFilterButtonsRow(TailorFinderState state) {
    return Container(
      padding: const EdgeInsets.only(top: 16, left: 36, right: 36),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
// MAP/LIST TOGGLE - new feature
            GestureDetector(
              onTap: () {
                setState(() {
                  _showMap = !_showMap;
                });
                // FIX: Force reload when toggling view to ensure tailors load properly
                ref.read(tailorFinderProvider.notifier).loadNearbyTailors();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _showMap ? AppColors.amber : AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _showMap ? AppColors.amber : Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showMap ? Icons.map : Icons.list,
                      size: 16,
                      color: _showMap ? AppColors.darkNavy : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showMap ? 'MAP' : 'LIST',
                      style: TextStyle(
                        fontSize: 12,
                        color: _showMap ? AppColors.darkNavy : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Service type filter - dropdown
            _buildDropdownFilter(
              context: context,
              label: state.filters.serviceTier?.displayName ?? 'Service',
              icon: Icons.content_cut,
              isActive: state.filters.serviceTier != null,
              items: ServiceTier.values.map((t) => t.displayName).toList(),
              onSelected: (value) {
                final tier = ServiceTier.values.firstWhere(
                  (t) => t.displayName == value,
                  orElse: () => ServiceTier.custom,
                );
                ref.read(tailorFinderProvider.notifier).updateFilters(
                  state.filters.copyWith(serviceTier: tier),
                );
              },
              onClear: () {
                ref.read(tailorFinderProvider.notifier).updateFilters(
                  state.filters.copyWith(clearServiceTier: true),
                );
              },
            ),
            const SizedBox(width: 8),
            // Price filter - dropdown
            _buildDropdownFilter(
              context: context,
              label: state.filters.maxPrice != null 
                  ? '₦${state.filters.maxPrice!.toStringAsFixed(0)}'
                  : 'Price',
              icon: Icons.attach_money,
              isActive: state.filters.maxPrice != null,
              items: ['₦10,000', '₦15,000', '₦20,000', '₦25,000', '₦30,000', '₦40,000', '₦50,000'],
              onSelected: (value) {
                final price = double.tryParse(value.replaceAll('₦', '').replaceAll(',', ''));
                if (price != null) {
                  ref.read(tailorFinderProvider.notifier).updateFilters(
                    state.filters.copyWith(maxPrice: price),
                  );
                }
              },
              onClear: () {
                ref.read(tailorFinderProvider.notifier).updateFilters(
                  state.filters.copyWith(clearMaxPrice: true),
                );
              },
            ),
            const SizedBox(width: 8),
            // Rating filter - dropdown
            _buildDropdownFilter(
              context: context,
              label: state.filters.minRating != null
                  ? '${state.filters.minRating}+ ★'
                  : 'Rating',
              icon: Icons.star,
              isActive: state.filters.minRating != null,
              items: ['3.0+ ★', '3.5+ ★', '4.0+ ★', '4.5+ ★', '4.8+ ★'],
              onSelected: (value) {
                final rating = double.tryParse(value.replaceAll('+ ★', ''));
                if (rating != null) {
                  ref.read(tailorFinderProvider.notifier).updateFilters(
                    state.filters.copyWith(minRating: rating),
                  );
                }
              },
              onClear: () {
                ref.read(tailorFinderProvider.notifier).updateFilters(
                  state.filters.copyWith(clearMinRating: true),
                );
              },
            ),
            const SizedBox(width: 8),
            // Availability toggle - AMBER when active
AmberFilterChip(
              label: 'Available',
              icon: Icons.check_circle,
              isActive: state.filters.onlyAvailable,
              isToggle: true,
              onTap: () {
                ref.read(tailorFinderProvider.notifier).updateFilters(
                  state.filters.copyWith(onlyAvailable: !state.filters.onlyAvailable),
                );
              },
            ),
            const SizedBox(width: 8),
            // Clear all filters
            if (_hasActiveFilters(state.filters))
              GestureDetector(
                onTap: () {
                  ref.read(tailorFinderProvider.notifier).updateFilters(
                    const TailorFinderFilters(),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.clear, size: 14, color: Colors.red.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
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

  bool _hasActiveFilters(TailorFinderFilters filters) {
    // Check if any filter has been modified from default values
    return filters.serviceTier != null ||
        filters.maxPrice != null ||
        filters.minRating != null ||
        filters.onlyAvailable == false;
  }

  /// Build dropdown filter menu
  Widget _buildDropdownFilter({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isActive,
    required List<String> items,
    required Function(String) onSelected,
    required VoidCallback onClear,
  }) {
    return PopupMenuButton<String>(
      // Ultra-modern white dropdown with custom styling
      color: Colors.white,  // White dropdown background
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (value) {
        if (value == '__CLEAR__') {
          onClear();
        } else {
          onSelected(value);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: '__CLEAR__',
          child: Row(
            children: [
              Icon(Icons.clear, size: 16, color: Colors.red.shade400),
              const SizedBox(width: 8),
              Text('Clear', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        ...items.map((item) => PopupMenuItem(
          value: item,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              item,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        )),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.amber : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppColors.amber : Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? AppColors.darkNavy : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? AppColors.darkNavy : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: isActive ? AppColors.darkNavy : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  /// Uber-style Book CTA button widget
  Widget _buildUberBookButton({
    required dynamic selectedTailor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: selectedTailor != null ? AppColors.amber : Colors.grey.shade400,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Center(
          child: Text(
            selectedTailor != null ? 'SELECT TAILOR' : 'SELECT A TAILOR',
            style: TextStyle(
              color: selectedTailor != null ? AppColors.darkNavy : Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  /// Info block showing service tier prompt
  Widget _buildInfoBlock() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Select a service type above to see price quotes',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Price block display with large font (Uber-style)
  Widget _buildPriceBlock(dynamic quote) {
    if (quote == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Price
          Text(
            quote.formattedPrice,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 48,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 12),
          // Turnaround time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                quote.formattedTurnaround,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Portfolio preview image area
  Widget _buildPortfolioPreview() {
    return Container(
      height: 188,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.photo_library_rounded,
            size: 32,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 8),
          Text(
            'Portfolio Preview',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to view tailor\'s work',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

/// Bottom action buttons row - ONLY Book Now CTA (no Money/Clock)
  Widget _buildBottomActionRow(BuildContext context, dynamic selectedTailor) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
child: GestureDetector(
          onTap: selectedTailor != null
              ? () {
                  // Navigate to tailor profile page with all Firebase details
                  Navigator.pushNamed(
                    context,
                    '/tailor-profile',
                    arguments: {
                      'id': selectedTailor.id,
                      'name': selectedTailor.name,
                      'profileImage': selectedTailor.profileImage,
                      'rating': selectedTailor.rating,
                      'reviewCount': selectedTailor.reviewCount,
                      'startingPrice': selectedTailor.startingPrice,
                      'shopAddress': selectedTailor.shopAddress,
                      'phoneNumber': selectedTailor.phoneNumber,
                      'email': selectedTailor.email,
                      'bio': selectedTailor.bio,
                      'isAvailable': selectedTailor.isAvailable,
                      'availableServices': selectedTailor.availableServices.map((s) => s.displayName).toList(),
                      'latitude': selectedTailor.location.latitude,
                      'longitude': selectedTailor.location.longitude,
                    },
                  );
                }
              : null,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: selectedTailor != null ? AppColors.darkNavy : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Center(
              child: Text(
                selectedTailor != null ? 'BOOK NOW' : 'SELECT A TAILOR',
                style: TextStyle(
                  color: selectedTailor != null ? AppColors.amber : Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Action button widget (Money/Clock buttons)
  Widget _ActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(46),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

/// Tailor list for initial selection (before service tier picked)
  Widget _buildTailorListForSelection(TailorFinderState state, EdgeInsets padding) {
    return Column(
      children: [
        // Info prompt
        Padding(
          padding: EdgeInsets.all(padding.left),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.amber, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Select a service type above to see price quotes',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Tailor grid - scrollable
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(padding.left),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: state.tailors.length,
            itemBuilder: (context, index) {
              final tailor = state.tailors[index];
              return TailorCard(
                tailor: tailor,
                isSelected: state.selectedTailor?.id == tailor.id,
                distanceMinutes: tailor.distanceMinutes,
                onTap: () {
                  ref.read(tailorFinderProvider.notifier).selectTailor(tailor);
                },
              );
            },
          ),
        ),
      ],
    );
  }

/// CTA Button Row - Now shows full Uber-style action buttons
Widget _buildUberActionButtons(BuildContext context, dynamic selectedTailor) {
    return _buildBottomActionRow(context, selectedTailor);
  }

  /// Back to list CTA button - appears when viewing tailor details
  Widget _buildBackToListCTA() {
    return Container(
      padding: const EdgeInsets.only(left: 36, right: 36, bottom: 24, top: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showTailorDetails = false;
                });
              },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.darkNavy,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'BACK TO TAILORS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Inline tailor details view - shows full details in right panel
  Widget _buildTailorDetailsView(dynamic tailor) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_padding.left),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailsHeader(tailor),
          const SizedBox(height: 20),
          _buildActionShortcuts(tailor),
          const SizedBox(height: 20),
          _buildServicesSection(tailor),
          const SizedBox(height: 20),
          _buildDetailsBookingCTA(tailor),
        ],
      ),
    );
  }

  Widget _buildDetailsHeader(dynamic tailor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.darkNavy,
            AppColors.darkNavy.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Profile avatar
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.amber.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    tailor.name.isNotEmpty ? tailor.name[0].toUpperCase() : 'T',
                    style: const TextStyle(
                      color: AppColors.amber,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tailor.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, color: AppColors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${tailor.rating.toStringAsFixed(1)} (${tailor.reviewCount} reviews)',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (tailor.shopAddress != null)
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.white54, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              tailor.shopAddress!,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Availability badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: tailor.isAvailable 
                  ? AppColors.amber.withValues(alpha: 0.2)
                  : Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tailor.isAvailable ? Icons.check_circle : Icons.cancel,
                  color: tailor.isAvailable ? AppColors.amber : Colors.red,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  tailor.isAvailable ? 'Available now' : 'Busy',
                  style: TextStyle(
                    color: tailor.isAvailable ? AppColors.amber : Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionShortcuts(dynamic tailor) {
    return Row(
      children: [
        _buildShortcutButton(Icons.phone_rounded, 'Call', () {}),
        const SizedBox(width: 8),
        _buildShortcutButton(Icons.near_me_rounded, 'Directions', () {}),
        const SizedBox(width: 8),
        _buildShortcutButton(Icons.chat_bubble_rounded, 'Chat', () {}),
        const SizedBox(width: 8),
        _buildShortcutButton(Icons.ios_share_rounded, 'Share', () {}),
      ],
    );
  }

  Widget _buildShortcutButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.darkNavy, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesSection(dynamic tailor) {
    final services = tailor.availableServices as List<ServiceTier>? ?? [];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SERVICES',
            style: TextStyle(
              color: AppColors.darkNavy,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          if (services.isEmpty)
            const Text(
              'Custom tailoring, alterations, and more',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            )
          else
            ...services.map((service) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.checkroom_rounded,
                      color: AppColors.amber,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.displayName.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          service.description,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

Widget _buildDetailsBookingCTA(dynamic tailor) {
    return GestureDetector(
      onTap: () {
        // Navigate to booking with tailor details
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.amber,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'BOOK APPOINTMENT',
            style: TextStyle(
              color: AppColors.darkNavy,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Uber-style Book CTA button widget (defined at file level)
class UberBookButton extends StatelessWidget {
  final dynamic selectedTailor;
  final VoidCallback onTap;

  const UberBookButton({
    super.key,
    required this.selectedTailor,
    required this.onTap,
  });

@override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: selectedTailor != null ? AppColors.darkNavy : Colors.grey.shade400,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Center(
          child: Text(
            selectedTailor != null ? 'SELECT TAILOR' : 'SELECT A TAILOR',
            style: TextStyle(
              color: selectedTailor != null ? AppColors.amber : Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// Internal method wrapper for UberBookButton
Widget _buildUberBookButton({
  required dynamic selectedTailor,
  required VoidCallback onTap,
}) {
  return UberBookButton(
    selectedTailor: selectedTailor,
    onTap: onTap,
  );
}

/// AMBER filter chip widget - all filter buttons use amber styling (defined at file level)
class AmberFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isToggle;
  final VoidCallback onTap;

  const AmberFilterChip({
    super.key,
    required this.label,
    required this.icon,
    required this.isActive,
    this.isToggle = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.amber : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.amber : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? AppColors.darkNavy : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? AppColors.darkNavy : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: isActive ? AppColors.darkNavy : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}


