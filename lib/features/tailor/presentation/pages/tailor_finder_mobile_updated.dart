import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/service_tier.dart';
import '../providers/tailor_finder_provider.dart';
import '../widgets/tailor_map_view.dart';
import '../widgets/tailor_card.dart';
import '../widgets/service_tier_selector.dart';
import '../widgets/quote_estimation_card.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/tailor_finder_responsive.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

/// TailorFinderMobile - Uber-style Tailor Discovery for Mobile
/// Responsive: adapts to any mobile screen size (tablet-optimized)
/// Feature Parity: Full desktop feature set adapted for touch
class TailorFinderMobileUpdated extends ConsumerStatefulWidget {
  const TailorFinderMobileUpdated({super.key});

  @override
  ConsumerState<TailorFinderMobileUpdated> createState() => _TailorFinderMobileState();
}

class _TailorFinderMobileState extends ConsumerState<TailorFinderMobileUpdated> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  // Track if showing tailor details inline
  bool _showTailorDetails = false;

  // Track view mode: true = show map, false = hide map for more tailor options
  bool _showMap = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(tailorFinderProvider.notifier).loadNearbyTailors();
    });
    // Apply user's preferred finder style from onboarding
    _applyUserPreference();
  }

  /// Apply user's preferred finder style from their profile (FIX #4)
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

  /// Handle back navigation - INDUSTRY STANDARD: PopScope for back button handling (FIX #1)
  Future<bool> _onWillPop() async {
    // If showing details, go back to list first
    if (_showTailorDetails) {
      setState(() {
        _showTailorDetails = false;
      });
      return false;
    }
    // If there's a selected tailor, deselect first
    final state = ref.read(tailorFinderProvider);
    if (state.selectedTailor != null) {
      ref.read(tailorFinderProvider.notifier).clearSelection();
      // Collapse sheet
      await _sheetController.animateTo(
        0.25,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return false; // Don't pop, just deselect
    }
    // Otherwise check if we can pop
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return true;
    }
    // If no routes to pop, go to main dashboard
    if (ref.read(navigationProvider).route != '/main') {
      ref.read(navigationProvider.notifier).state = const NavigationState('/main');
    } else {
      Navigator.pushReplacementNamed(context, '/main');
    }
    return true;
  }

  // Adaptive sheet sizes based on aspect ratio
  double get _sheetInitialSize {
    final aspect = MediaQuery.of(context).size.aspectRatio;
    // On taller devices, open sheet more; on wider, open less
    return aspect < 0.5 ? 0.55 : 0.5;
  }

  // Loading sheet placeholder
  Widget _buildLoadingSheet() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: AppColors.figmaCardFill,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const TailorFinderShimmer(width: 100, height: 20),
            const SizedBox(height: 16),
            const TailorFinderShimmer(width: double.infinity, height: 48),
            const SizedBox(height: 16),
            const TailorListShimmer(itemCount: 2),
          ],
        ),
      ),
    );
  }

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
        body: Stack(
          children: [
            const MapShimmer(aspectRatio: 0.65),
            _buildLoadingSheet(),
          ],
        ),
      );
    }

    // Error state
    if (state.error != null) {
      return Scaffold(
        backgroundColor: AppColors.uberBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  label: 'Error loading tailors',
                  child: const Icon(Icons.error_outline,
                      size: 64, color: AppColors.uberError),
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load tailors',
                  style: TextStyle(
                    color: TailorFinderContrast.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TailorFinderContrast.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(tailorFinderProvider.notifier).loadNearbyTailors(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // FIX #1: Wrap with PopScope for back button handling
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Custom back handling
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.uberBg,
        body: LayoutBuilder(
          // FIX #12: Add responsive LayoutBuilder for tablet optimization
          builder: (context, constraints) {
            return Stack(
              children: [
                // MAP - adaptive height based on screen and toggle (FIX #11)
                if (_showMap)
                  Positioned.fill(
                    child: Semantics(
                      label: TailorFinderSemantics.mapLabel,
                      child: TailorMapView(
                        tailors: state.markers,
                        selectedTailor: selectedTailor != null ? TailorMarker.fromProfile(selectedTailor) : null,
                        userLocation: state.userLocation,
                        onTailorSelected: (marker) {
                          ref
                              .read(tailorFinderProvider.notifier)
                              .selectTailor(marker);
                          // Open bottom sheet when tailor selected
                          _sheetController.animateTo(
                            _sheetInitialSize,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        },
                        onMapTap: (location) {
                          ref
                              .read(tailorFinderProvider.notifier)
                              .setUserLocation(location);
                        },
                        onBack: () => _onWillPop(),
                      ),
                    ),
                  ),

                // BOTTOM SHEET
                DraggableScrollableSheet(
                  controller: _sheetController,
                  initialChildSize: _showMap ? 0.35 : 0.5,
                  minChildSize: TailorFinderLayout.sheetMin,
                  maxChildSize: TailorFinderLayout.sheetMax,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.figmaCardFill,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Sheet handle
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.borderLight,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          // Sheet content
                          Expanded(
                            child: NotificationListener<ScrollNotification>(
                              onNotification: (_) => true,
                              child: ListView(
                                controller: scrollController,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                children: [
                                  // FIX #10: Show details view OR list/grid
                                  if (_showTailorDetails && selectedTailor != null)
                                    _buildTailorDetailsView(selectedTailor)
                                  else ...[
                                    // Header
                                    _buildSheetHeader(selectedTailor),
                                    const SizedBox(height: 20),
                                    // Filter buttons row - in AMBER (now with map/list toggle)
                                    _buildFilterButtonsRow(state),
                                    const SizedBox(height: 16),
                                    // If no tailor selected, show grid of tailors
                                    if (selectedTailor == null &&
                                        state.tailors.isNotEmpty) ...[
                                      _buildTailorGrid(state),
                                      const SizedBox(height: 24),
                                    ] else ...[
                                      // Service tier chips
                                      ServiceTierSelector(
                                        selectedTier: selectedTier,
                                        onSelected: (tier) {
                                          ref
                                              .read(
                                                  tailorFinderProvider.notifier)
                                              .selectServiceTier(tier);
                                        },
                                        availableTiers: (selectedTailor?.services ?? [])
                                            .map((s) => ServiceTier.values.firstWhere(
                                              (t) => t.displayName.toLowerCase() == s.toLowerCase(),
                                              orElse: () => ServiceTier.custom,
                                            )).toList()
                                            .isEmpty ? ServiceTier.values : (selectedTailor?.services ?? [])
                                            .map((s) => ServiceTier.values.firstWhere(
                                              (t) => t.displayName.toLowerCase() == s.toLowerCase(),
                                              orElse: () => ServiceTier.custom,
                                            )).toList(),
                                      ),
                                      const SizedBox(height: 16),
                                      // Info block (FIX #7)
                                      _buildInfoBlock(selectedTailor, selectedTier),
                                      const SizedBox(height: 20),
                                    ],
                                    // Selected tailor info OR empty state
                                    if (selectedTailor != null) ...[
                                      _buildTailorInfoCard(selectedTailor),
                                      const SizedBox(height: 20),
                                      // Quote
                                      if (currentQuote != null)
                                        QuoteEstimationCard(
                                          quote: currentQuote,
                                          isExpanded: true,
                                        ),
                                      const SizedBox(height: 20),
                                      // Details link (FIX #2)
                                      if (!_showTailorDetails)
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _showTailorDetails = true;
                                            });
                                            _sheetController.animateTo(
                                               TailorFinderLayout.sheetMax,
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              curve: Curves.easeOut,
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                top: BorderSide(
                                                  color: AppColors.borderLight,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons
                                                      .arrow_forward_rounded,
                                                  size: 16,
                                                  color: AppColors.amber,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'VIEW FULL PROFILE',
                                                  style: TextStyle(
                                                    color: AppColors.amber,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ] else ...[
                                      _buildEmptyState(),
                                    ],
                                    const SizedBox(height: 100),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // FLOATING CTA BUTTON - now shows Book or Back depending on state
                if (selectedTailor != null && selectedTier != null &&
                    !_showTailorDetails)
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: MediaQuery.of(context).padding.bottom + 100,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/tailor-profile',
                          arguments: selectedTailor.id,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amber,
                        foregroundColor: AppColors.darkNavy,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 4,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'BOOK NOW',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),

                // Mobile nav bar placeholder
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _MobileNavBar(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSheetHeader(UserProfile? tailor) {
    return Row(
      children: [
        Flexible(
          child: Text(
            tailor != null ? 'SELECT SERVICE' : 'FIND A TAILOR',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.tune_rounded,
                color: AppColors.textMuted,
                size: 12,
              ),
              const SizedBox(width: 2),
              Text(
                'FILTER',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Compact tailor info card (shows at bottom of sheet before detail view)
  Widget _buildTailorInfoCard(UserProfile tailor) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showTailorDetails = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  tailor.name.isNotEmpty ? tailor.name[0].toUpperCase() : 'T',
                  style: const TextStyle(
                    color: AppColors.amber,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tailor.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.amber, size: 12),
                      const SizedBox(width: 2),
                      const Text(
                        '4.5',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '(12)',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  if (tailor.address != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.textMuted,
                          size: 10,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            tailor.address ?? '',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Availability (FIX #6)
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.uberLive,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Full detail view of tailor (FIX #2 \u0026 #3 \u0026 #5 \u0026 #8 \u0026 #9)
  Widget _buildTailorDetailsView(UserProfile tailor) {
    return Column(
      children: [
        // Back button (FIX #13)
        GestureDetector(
          onTap: () {
            setState(() {
              _showTailorDetails = false;
            });
          },
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.amber, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'BACK',
                    style: TextStyle(
                      color: AppColors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Detailed header (FIX #6)
        _buildDetailsHeader(tailor),
        const SizedBox(height: 20),
        // Action shortcuts (FIX #3)
        _buildActionShortcuts(tailor),
        const SizedBox(height: 20),
        // Services section (FIX #5)
        _buildServicesSection(tailor),
        const SizedBox(height: 20),
        // Portfolio preview (FIX #8)
        _buildPortfolioPreview(),
        const SizedBox(height: 20),
        // Booking CTA
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/tailor-profile',
              arguments: tailor,
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.amber,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'BOOK APPOINTMENT',
                style: TextStyle(
                  color: AppColors.darkNavy,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 100), // Bottom padding
      ],
    );
  }

  /// Detailed header with gradient background (FIX #6)
  Widget _buildDetailsHeader(UserProfile tailor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.darkNavy,
            AppColors.darkNavy.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Profile avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
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
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tailor.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(Icons.star_rounded,
                            color: AppColors.amber, size: 14),
                        SizedBox(width: 4),
                        Text(
                          '4.5 (12)',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    if (tailor.address != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.white54, size: 12),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              tailor.address!,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Availability badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.amber,
                  size: 12,
                ),
                SizedBox(width: 4),
                Text(
                  'Available now',
                  style: TextStyle(
                    color: AppColors.amber,
                    fontSize: 10,
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

  /// Action shortcuts (Call, Directions, Chat, Share) (FIX #3)
  Widget _buildActionShortcuts(UserProfile tailor) {
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

  Widget _buildShortcutButton(
      IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.darkNavy, size: 18),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Services section with descriptions (FIX #5)
  Widget _buildServicesSection(UserProfile tailor) {
    final services = (tailor.services ?? []).map((s) => ServiceTier.values.firstWhere(
      (t) => t.displayName.toLowerCase() == s.toLowerCase(),
      orElse: () => ServiceTier.custom,
    )).toList();

    return Container(
      padding: const EdgeInsets.all(14),
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
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          if (services.isEmpty)
            const Text(
              'Custom tailoring, alterations, and more',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            )
          else
            ...services.map((service) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.checkroom_rounded,
                      color: AppColors.amber,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.displayName.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          service.description,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 9,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  /// Portfolio preview area (FIX #8)
  Widget _buildPortfolioPreview() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_rounded,
            size: 28,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 8),
          Text(
            'Portfolio Preview',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Tap to view tailor\'s work',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  /// Info block showing service tier prompt (FIX #7)
  Widget _buildInfoBlock(UserProfile? tailor, ServiceTier? tier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Recommended label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Text(
              'RECOMMENDED',
              style: TextStyle(
                color: AppColors.amber,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const Spacer(),
          // Icon + availability
          const Icon(
            Icons.person_outline_rounded,
            color: AppColors.textMuted,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            tailor != null ? 'Available' : 'Select service',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
          const Spacer(),
          // Turnaround
          if (tier != null)
            Text(
              '${tier.defaultTurnaroundDays}d',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.touch_app_rounded,
            size: 48,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tap a tailor on the map',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'to see service options and quotes',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  /// Filter buttons row - now with map/list toggle (FIX #11)
  Widget _buildFilterButtonsRow(TailorFinderState state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
// MAP/LIST TOGGLE - new feature
          GestureDetector(
            onTap: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _showMap ? AppColors.amber : AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _showMap ? AppColors.amber : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showMap ? Icons.map : Icons.list,
                    size: 13,
                    color: _showMap
                        ? AppColors.darkNavy
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    _showMap ? 'MAP' : 'LIST',
                    style: TextStyle(
                      fontSize: 10,
                      color: _showMap
                          ? AppColors.darkNavy
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Service type filter
          _MobileFilterChip(
            label: state.filters.serviceTier?.displayName ?? 'Service',
            icon: Icons.content_cut,
            isActive: state.filters.serviceTier != null,
            onTap: () => _showServiceFilterMenu(state),
          ),
          const SizedBox(width: 8),
          // Price filter
          _MobileFilterChip(
            label: state.filters.maxPrice != null
                ? '₦${state.filters.maxPrice!.toStringAsFixed(0)}'
                : 'Price',
            icon: Icons.attach_money,
            isActive: state.filters.maxPrice != null,
            onTap: () => _showPriceFilterMenu(state),
          ),
          const SizedBox(width: 8),
          // Rating filter
          _MobileFilterChip(
            label: state.filters.minRating != null
                ? '${state.filters.minRating}+ ★'
                : 'Rating',
            icon: Icons.star,
            isActive: state.filters.minRating != null,
            onTap: () => _showRatingFilterMenu(state),
          ),
          const SizedBox(width: 8),
          // Availability toggle
          _MobileFilterChip(
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
          // Clear filters button
          if (_hasActiveFilters(state.filters)) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                ref.read(tailorFinderProvider.notifier).updateFilters(
                  const TailorFinderFilters(),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.clear, size: 12, color: Colors.red.shade700),
                    const SizedBox(width: 2),
                    Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _hasActiveFilters(TailorFinderFilters filters) {
    return filters.serviceTier != null ||
        filters.maxPrice != null ||
        filters.minRating != null ||
        filters.onlyAvailable != true;
  }

  void _showServiceFilterMenu(TailorFinderState state) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Service Type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('All Services'),
              onTap: () {
                ref.read(tailorFinderProvider.notifier).updateFilters(
                  state.filters.copyWith(clearServiceTier: true),
                );
                Navigator.pop(context);
              },
            ),
            ...ServiceTier.values.map((tier) => ListTile(
              title: Text(tier.displayName),
              trailing: tier == state.filters.serviceTier
                  ? const Icon(Icons.check, color: AppColors.amber)
                  : null,
              onTap: () {
                ref.read(tailorFinderProvider.notifier).updateFilters(
                  state.filters.copyWith(serviceTier: tier),
                );
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showPriceFilterMenu(TailorFinderState state) {
    final priceRanges = [10000.0, 15000.0, 20000.0, 25000.0, 30000.0, 40000.0, 50000.0];
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Max Price',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Any Price'),
              onTap: () {
                ref.read(tailorFinderProvider.notifier).updateFilters(
                  state.filters.copyWith(clearMaxPrice: true),
                );
                Navigator.pop(context);
              },
            ),
            ...priceRanges.map((price) => ListTile(
              title: Text('₦${price.toStringAsFixed(0)}'),
              trailing: state.filters.maxPrice == price
                  ? const Icon(Icons.check, color: AppColors.amber)
                  : null,
              onTap: () {
                ref.read(tailorFinderProvider.notifier).updateFilters(
                  state.filters.copyWith(maxPrice: price),
                );
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showRatingFilterMenu(TailorFinderState state) {
    final ratings = [3.0, 3.5, 4.0, 4.5, 4.8];
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Minimum Rating',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Any Rating'),
              onTap: () {
                ref.read(tailorFinderProvider.notifier).updateFilters(
                  state.filters.copyWith(clearMinRating: true),
                );
                Navigator.pop(context);
              },
            ),
            ...ratings.map((rating) => ListTile(
              title: Row(
                children: [
                  Text('${rating}+ '),
                  ...List.generate(5, (i) => Icon(
                    i < rating.floor() ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  )),
                ],
              ),
              trailing: state.filters.minRating == rating
                  ? const Icon(Icons.check, color: AppColors.amber)
                  : null,
              onTap: () {
                ref.read(tailorFinderProvider.notifier).updateFilters(
                  state.filters.copyWith(minRating: rating),
                );
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  /// Tailor grid for mobile - side by side cards
  Widget _buildTailorGrid(TailorFinderState state) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: state.markers.length,
      itemBuilder: (context, index) {
        final marker = state.markers[index];
        return TailorCard(
          tailor: marker,
          isSelected: state.selectedTailor?.id == marker.id,
          distanceMinutes: marker.distanceMinutes,
          onTap: () {
            ref.read(tailorFinderProvider.notifier).selectTailor(marker);
            _sheetController.animateTo(
              0.6,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          },
        );
      },
    );
  }
}

/// Mobile filter chip widget - AMBER styling (FIX #15: Standardize with desktop)
class _MobileFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isToggle;
  final VoidCallback onTap;

  const _MobileFilterChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.amber : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppColors.amber : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 12,
                color: isActive
                    ? AppColors.darkNavy
                    : AppColors.textSecondary),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color:
                    isActive ? AppColors.darkNavy : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!isToggle) ...[
              const SizedBox(width: 2),
              Icon(Icons.arrow_drop_down,
                  size: 12,
                  color: isActive
                      ? AppColors.darkNavy
                      : AppColors.textSecondary),
            ],
          ],
        ),
      ),
    );
  }
}

/// Mobile navigation bar
class _MobileNavBar extends StatelessWidget {
  const _MobileNavBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home_rounded, label: 'Home', isSelected: false, onTap: () {}),
          _NavItem(
              icon: Icons.search_rounded,
              label: 'Find',
              isSelected: true,
              onTap: () {}),
          _NavItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              isSelected: false,
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              }),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.amber : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.amber : AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
