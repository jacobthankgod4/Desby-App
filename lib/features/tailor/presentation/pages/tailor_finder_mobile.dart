import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/service_tier.dart';
import '../providers/tailor_finder_provider.dart';
import '../widgets/tailor_map_view.dart';
import '../widgets/tailor_card.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/tailor_finder_responsive.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class TailorFinderMobile extends ConsumerStatefulWidget {
  const TailorFinderMobile({super.key});

  @override
  ConsumerState<TailorFinderMobile> createState() => _TailorFinderMobileState();
}

class _TailorFinderMobileState extends ConsumerState<TailorFinderMobile> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  bool _showMap = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(tailorFinderProvider.notifier).loadNearbyTailors();
    });
    _applyUserPreference();
  }

  void _applyUserPreference() {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      final profileAsync = ref.read(userProfileProvider(currentUser.id));
      profileAsync.when(
        data: (profile) {
          if (profile?.preferredFinderStyle != null) {
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

  Future<bool> _onWillPop() async {
    // No selection state to unwind any more — a tailor tap navigates away, so
    // backing out of this screen always means leaving it.
    final state = ref.read(tailorFinderProvider);
    if (state.selectedTailor != null) {
      ref.read(tailorFinderProvider.notifier).clearSelection();
    }
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return true;
    }
    if (ref.read(navigationProvider).route != '/main') {
      ref.setShell('/main');
    } else {
      Navigator.pushReplacementNamed(context, '/main');
    }
    return true;
  }

  /// Open a tailor's profile. The single entry point for "I want this tailor".
  void _openProfile(String tailorId) {
    ref.pushShell('/tailor-profile', {'tailorId': tailorId});
  }

  /// Shown when filters or the search term leave nothing to show. Previously
  /// the browse grid simply disappeared, so a search that matched no tailors
  /// looked like a loading failure.
  Widget _buildNoResults() {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 8),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 40,
            color: colors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'No tailors match those filters',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try widening the distance or clearing a filter.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

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
                  color: context.colors.borderDefault,
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
    final colors = context.colors;
    final state = ref.watch(tailorFinderProvider);
    // A tailor is no longer "selected" into an intermediate preview: tapping
    // one navigates straight to their profile.
    final selectedTailor = state.selectedTailor;

    if (state.isLoading) {
      return Container(
        color: colors.scaffoldBg,
        child: Stack(
          children: [const MapShimmer(aspectRatio: 0.65), _buildLoadingSheet()],
        ),
      );
    }

    if (state.error != null) {
      return Container(
        color: colors.scaffoldBg,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.uberError,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load tailors',
                  style: TextStyle(
                    color: colors.cardBg,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textMuted, fontSize: 10),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref
                      .read(tailorFinderProvider.notifier)
                      .loadNearbyTailors(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).maybePop();
        }
      },
      child: Container(
        color: colors.scaffoldBg,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                if (_showMap)
                  Positioned.fill(
                    child: Semantics(
                      label: TailorFinderSemantics.mapLabel,
                      child: TailorMapView(
                        tailors: state.markers,
                        selectedTailor: selectedTailor != null
                            ? TailorMarker.fromProfile(selectedTailor)
                            : null,
                        userLocation: state.userLocation,
                        onTailorSelected: (marker) {
                          // Straight to the profile, matching desktop.
                          //
                          // This used to only select the tailor and slide the
                          // sheet up to a preview containing "VIEW FULL PROFILE"
                          // and a "BOOK NOW" button, and only then open the real
                          // profile — which has its own BOOK APPOINTMENT button.
                          // Two screens and two identical-looking CTAs to reach
                          // one destination, with the preview's own text
                          // rendering near-invisible in light mode.
                          _openProfile(marker.id);
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

                DraggableScrollableSheet(
                  controller: _sheetController,
                  initialChildSize: _showMap ? 0.35 : 0.5,
                  minChildSize: TailorFinderLayout.sheetMin,
                  maxChildSize: TailorFinderLayout.sheetMax,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: context.colors.bottomSheetBg,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 20,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colors.textMuted,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Expanded(
                            child: NotificationListener<ScrollNotification>(
                              onNotification: (_) => true,
                              child: ListView(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                children: [
                                  _buildSheetHeader(state),
                                  const SizedBox(height: 20),
                                  _buildFilterButtonsRow(state),
                                  const SizedBox(height: 16),
                                  if (state.markers.isNotEmpty) ...[
                                    _buildTailorGrid(state),
                                    // Clears the bottom nav bar and the home
                                    // indicator so the final row is reachable.
                                    const SizedBox(height: 120),
                                  ] else
                                    _buildNoResults(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              ],
            );
          },
        ),
      ),
    );
  }

  /// Title row for the browse sheet.
  ///
  /// It previously switched between "FIND A TAILOR" and "SELECT SERVICE"
  /// depending on whether a tailor was picked. With the preview gone there is
  /// only ever one state, so it just reports the result count — which is more
  /// useful than a title that never changes.
  Widget _buildSheetHeader(TailorFinderState state) {
    final colors = context.colors;
    final count = state.markers.length;
    return Row(
      children: [
        Expanded(
          child: Text(
            'FIND A TAILOR',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
        Text(
          count == 1 ? '1 result' : '$count results',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButtonsRow(TailorFinderState state) {
    final colors = context.colors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _showMap = !_showMap;
              });
              ref.read(tailorFinderProvider.notifier).loadNearbyTailors();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _showMap ? AppColors.amber : AppColors.deepBlue,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _showMap ? AppColors.amber : colors.borderSubtle,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showMap ? Icons.map : Icons.list,
                    size: 13,
                    color: _showMap ? colors.scaffoldBg : colors.textSecondary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    _showMap ? 'MAP' : 'LIST',
                    style: TextStyle(
                      fontSize: 10,
                      color: _showMap
                          ? colors.scaffoldBg
                          : colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _MobileFilterChip(
            label: state.filters.serviceTier?.displayName ?? 'Service',
            icon: Icons.content_cut,
            isActive: state.filters.serviceTier != null,
            onTap: () => _showServiceFilterMenu(state),
          ),
          const SizedBox(width: 8),
          _MobileFilterChip(
            label: state.filters.maxPrice != null
                ? '\u20A6${state.filters.maxPrice!.toStringAsFixed(0)}'
                : 'Price',
            icon: Icons.attach_money,
            isActive: state.filters.maxPrice != null,
            onTap: () => _showPriceFilterMenu(state),
          ),
          const SizedBox(width: 8),
          _MobileFilterChip(
            label: state.filters.minRating != null
                ? '${state.filters.minRating}+ \u2605'
                : 'Rating',
            icon: Icons.star,
            isActive: state.filters.minRating != null,
            onTap: () => _showRatingFilterMenu(state),
          ),
          const SizedBox(width: 8),
          _MobileFilterChip(
            label: 'Available',
            icon: Icons.check_circle,
            isActive: state.filters.onlyAvailable,
            isToggle: true,
            onTap: () {
              ref
                  .read(tailorFinderProvider.notifier)
                  .updateFilters(
                    state.filters.copyWith(
                      onlyAvailable: !state.filters.onlyAvailable,
                    ),
                  );
            },
          ),
          if (_hasActiveFilters(state.filters)) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                ref
                    .read(tailorFinderProvider.notifier)
                    .updateFilters(const TailorFinderFilters());
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.clear, size: 12, color: AppColors.error),
                    const SizedBox(width: 2),
                    Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.error,
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
        filters.onlyAvailable == true;
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
            const Text(
              'Select Service Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('All Services'),
              onTap: () {
                ref
                    .read(tailorFinderProvider.notifier)
                    .updateFilters(
                      state.filters.copyWith(clearServiceTier: true),
                    );
                Navigator.pop(context);
              },
            ),
            ...ServiceTier.values.map(
              (tier) => ListTile(
                title: Text(tier.displayName),
                trailing: tier == state.filters.serviceTier
                    ? const Icon(Icons.check, color: AppColors.amber)
                    : null,
                onTap: () {
                  ref
                      .read(tailorFinderProvider.notifier)
                      .updateFilters(state.filters.copyWith(serviceTier: tier));
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPriceFilterMenu(TailorFinderState state) {
    final priceRanges = [
      10000.0,
      15000.0,
      20000.0,
      25000.0,
      30000.0,
      40000.0,
      50000.0,
    ];
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Max Price',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Any Price'),
              onTap: () {
                ref
                    .read(tailorFinderProvider.notifier)
                    .updateFilters(state.filters.copyWith(clearMaxPrice: true));
                Navigator.pop(context);
              },
            ),
            ...priceRanges.map(
              (price) => ListTile(
                title: Text('\u20A6${price.toStringAsFixed(0)}'),
                trailing: state.filters.maxPrice == price
                    ? const Icon(Icons.check, color: AppColors.amber)
                    : null,
                onTap: () {
                  ref
                      .read(tailorFinderProvider.notifier)
                      .updateFilters(state.filters.copyWith(maxPrice: price));
                  Navigator.pop(context);
                },
              ),
            ),
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
            const Text(
              'Minimum Rating',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Any Rating'),
              onTap: () {
                ref
                    .read(tailorFinderProvider.notifier)
                    .updateFilters(
                      state.filters.copyWith(clearMinRating: true),
                    );
                Navigator.pop(context);
              },
            ),
            ...ratings.map(
              (rating) => ListTile(
                title: Row(
                  children: [
                    Text('${rating}+ '),
                    ...List.generate(
                      5,
                      (i) => Icon(
                        i < rating.floor() ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                trailing: state.filters.minRating == rating
                    ? const Icon(Icons.check, color: AppColors.amber)
                    : null,
                onTap: () {
                  ref
                      .read(tailorFinderProvider.notifier)
                      .updateFilters(state.filters.copyWith(minRating: rating));
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          onTap: () => _openProfile(marker.id),
        );
      },
    );
  }
}

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
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.amber : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppColors.amber : colors.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isActive ? colors.scaffoldBg : colors.textSecondary,
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? colors.scaffoldBg : colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!isToggle) ...[
              const SizedBox(width: 2),
              Icon(
                Icons.arrow_drop_down,
                size: 12,
                color: isActive ? colors.scaffoldBg : colors.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
