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
import 'package:desby_app/features/profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../designs/domain/entities/design.dart';
import '../../../designs/presentation/providers/design_provider.dart';
import '../../../../core/widgets/app_network_image.dart';

/// TailorFinderDesktop - Uber-style Tailor Discovery Page
/// Responsive: adapts to 600px+ screens (mobile, tablet, desktop)
class TailorFinderDesktop extends ConsumerStatefulWidget {
  const TailorFinderDesktop({super.key});

  @override
  ConsumerState<TailorFinderDesktop> createState() =>
      _TailorFinderDesktopState();
}

class _TailorFinderDesktopState extends ConsumerState<TailorFinderDesktop> {
  bool _showTailorDetails = false;
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

  EdgeInsets get _padding => EdgeInsets.all(
    MediaQuery.of(context).size.width >= TailorFinderBreakpoints.desktop
        ? TailorFinderLayout.desktopPadding
        : TailorFinderLayout.mobilePadding,
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(tailorFinderProvider);
    final selectedTailor = state.selectedTailor;

    return Container(
      color: colors.scaffoldBg,
      child: Row(
        children: [
          Expanded(flex: 1, child: _buildMap(state, selectedTailor)),
          Expanded(flex: 1, child: _buildRightPanel(state)),
        ],
      ),
    );
  }

  Widget _buildRightPanel(TailorFinderState state) {
    if (state.isLoading) {
      return Container(
        padding: _padding,
        child: const TailorListShimmer(itemCount: 4),
      );
    }

    if (state.error != null) {
      return _buildErrorState(state.error!);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return _buildPanel(
          state,
          state.selectedTailor,
          state.selectedServiceTier,
          state.currentQuote,
          constraints,
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    final colors = context.colors;
    final bool isClockError = error.contains('issued at future');

    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isClockError ? Icons.access_time_rounded : Icons.error_outline,
            size: 64,
            color: AppColors.uberError,
          ),
          const SizedBox(height: 24),
          Text(
            isClockError ? 'SYSTEM CLOCK DESYNC' : 'SYNC FAILED',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isClockError
                ? 'Your Mac system clock is slightly in the past. Please Sync your Clock in System Settings to restore secure access.'
                : error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () =>
                ref.read(tailorFinderProvider.notifier).loadNearbyTailors(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'RETRY SYNC',
              style: TextStyle(
                color: colors.scaffoldBg,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(TailorFinderState state, UserProfile? selectedTailor) {
    return Semantics(
      label: TailorFinderSemantics.mapLabel,
      child: TailorMapView(
        tailors: state.markers,
        selectedTailor: selectedTailor != null
            ? TailorMarker.fromProfile(selectedTailor)
            : null,
        userLocation: state.userLocation,
        onTailorSelected: (marker) {
          ref.read(tailorFinderProvider.notifier).selectTailor(marker);
        },
        onMapTap: (location) {
          ref.read(tailorFinderProvider.notifier).setUserLocation(location);
        },
        onBack: () {
          if (ref.read(navigationProvider).route != '/main') {
            ref.setShell('/main');
          } else {
            Navigator.of(context).maybePop();
          }
        },
      ),
    );
  }

  Widget _buildPanel(
    TailorFinderState state,
    UserProfile? selectedTailor,
    ServiceTier? selectedTier,
    dynamic currentQuote,
    BoxConstraints constraints,
  ) {
    final padding = _padding;

    return Container(
      decoration: BoxDecoration(color: context.colors.scaffoldBg),
      child: Column(
        children: [
          if (!_showTailorDetails) _buildFilterButtonsRow(state),
          Expanded(
            child: _showTailorDetails && selectedTailor != null
                ? _buildTailorDetailsView(selectedTailor)
                : _buildTailorListForSelection(state, padding),
          ),
          _showTailorDetails
              ? _buildBackToListCTA(ref)
              : _buildUberActionButtons(context, selectedTailor),
        ],
      ),
    );
  }

  Widget _buildFilterButtonsRow(TailorFinderState state) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.only(top: 16, left: 36, right: 36),
      child: SingleChildScrollView(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _showMap ? AppColors.amber : AppColors.deepBlue,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _showMap ? AppColors.amber : colors.textMuted,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showMap ? Icons.map : Icons.list,
                      size: 16,
                      color: _showMap
                          ? colors.scaffoldBg
                          : colors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showMap ? 'MAP' : 'LIST',
                      style: TextStyle(
                        fontSize: 12,
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
            const SizedBox(width: 12),
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
                ref
                    .read(tailorFinderProvider.notifier)
                    .updateFilters(state.filters.copyWith(serviceTier: tier));
              },
              onClear: () {
                ref
                    .read(tailorFinderProvider.notifier)
                    .updateFilters(
                      state.filters.copyWith(clearServiceTier: true),
                    );
              },
            ),
            const SizedBox(width: 8),
            _buildDropdownFilter(
              context: context,
              label: state.filters.maxPrice != null
                  ? '\u20A6${state.filters.maxPrice!.toStringAsFixed(0)}'
                  : 'Price',
              icon: Icons.attach_money,
              isActive: state.filters.maxPrice != null,
              items: const [
                '\u20A610,000',
                '\u20A615,000',
                '\u20A620,000',
                '\u20A625,000',
                '\u20A630,000',
                '\u20A640,000',
                '\u20A650,000',
              ],
              onSelected: (value) {
                final price = double.tryParse(
                  value.replaceAll('\u20A6', '').replaceAll(',', ''),
                );
                if (price != null) {
                  ref
                      .read(tailorFinderProvider.notifier)
                      .updateFilters(state.filters.copyWith(maxPrice: price));
                }
              },
              onClear: () {
                ref
                    .read(tailorFinderProvider.notifier)
                    .updateFilters(state.filters.copyWith(clearMaxPrice: true));
              },
            ),
            const SizedBox(width: 8),
            _buildDropdownFilter(
              context: context,
              label: state.filters.minRating != null
                  ? '${state.filters.minRating}+ \u2605'
                  : 'Rating',
              icon: Icons.star,
              isActive: state.filters.minRating != null,
              items: const [
                '3.0+ \u2605',
                '3.5+ \u2605',
                '4.0+ \u2605',
                '4.5+ \u2605',
                '4.8+ \u2605',
              ],
              onSelected: (value) {
                final rating = double.tryParse(
                  value.replaceAll('+ \u2605', ''),
                );
                if (rating != null) {
                  ref
                      .read(tailorFinderProvider.notifier)
                      .updateFilters(state.filters.copyWith(minRating: rating));
                }
              },
              onClear: () {
                ref
                    .read(tailorFinderProvider.notifier)
                    .updateFilters(
                      state.filters.copyWith(clearMinRating: true),
                    );
              },
            ),
            const SizedBox(width: 8),
            AmberFilterChip(
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
            const SizedBox(width: 8),
            if (_hasActiveFilters(state.filters))
              GestureDetector(
                onTap: () {
                  ref
                      .read(tailorFinderProvider.notifier)
                      .updateFilters(const TailorFinderFilters());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.clear, size: 14, color: AppColors.error),
                      const SizedBox(width: 4),
                      Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
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
    return filters.serviceTier != null ||
        filters.maxPrice != null ||
        filters.minRating != null ||
        filters.onlyAvailable == true;
  }

  Widget _buildDropdownFilter({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isActive,
    required List<String> items,
    required Function(String) onSelected,
    required VoidCallback onClear,
  }) {
    final colors = context.colors;
    return PopupMenuButton<String>(
      color: colors.surface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              Icon(Icons.clear, size: 16, color: AppColors.error),
              const SizedBox(width: 8),
              Text(
                'Clear',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        ...items.map(
          (item) => PopupMenuItem(
            value: item,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                item,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.amber : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.amber : colors.borderSubtle,
          ),
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
            Icon(
              icon,
              size: 16,
              color: isActive ? colors.scaffoldBg : colors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? colors.scaffoldBg : colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: isActive ? colors.scaffoldBg : colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackToListCTA(WidgetRef ref) {
    final colors = context.colors;
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
                  color: colors.scaffoldBg,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: colors.textPrimary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'BACK TO TAILORS',
                        style: TextStyle(
                          color: colors.textPrimary,
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

  Widget _buildTailorDetailsView(UserProfile tailor) {
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
          _buildPortfolioSection(tailor),
          const SizedBox(height: 20),
          _buildDetailsBookingCTA(tailor),
        ],
      ),
    );
  }

  Widget _buildDetailsHeader(UserProfile tailor) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.scaffoldBg, colors.scaffoldBg.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.textPrimary.withValues(alpha: 0.1),
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
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (tailor is UserProfileDetails &&
                                  tailor.rating != null)
                              ? '${(tailor as UserProfileDetails).rating}'
                              : 'New',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (tailor.address != null)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: colors.textMuted,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              tailor.address!,
                              style: TextStyle(
                                color: colors.textMuted,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: AppColors.amber, size: 14),
                SizedBox(width: 6),
                Text(
                  'Available now',
                  style: TextStyle(
                    color: AppColors.amber,
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

  Widget _buildShortcutButton(IconData icon, String label, VoidCallback onTap) {
    final colors = context.colors;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: colors.textPrimary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Column(
            children: [
              Icon(icon, color: colors.scaffoldBg, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: colors.textSecondary,
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

  Widget _buildServicesSection(UserProfile tailor) {
    final colors = context.colors;
    final services = (tailor.services ?? [])
        .map(
          (s) => ServiceTier.values.firstWhere(
            (t) => t.displayName.toLowerCase() == s.toLowerCase(),
            orElse: () => ServiceTier.custom,
          ),
        )
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.textPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SERVICES',
            style: TextStyle(
              color: colors.scaffoldBg,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          if (services.isEmpty)
            Text(
              'Custom tailoring, alterations, and more',
              style: TextStyle(color: colors.textMuted, fontSize: 12),
            )
          else
            ...services.map(
              (service) => Padding(
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
                      child: const Icon(
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
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            service.description,
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
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

  Widget _buildPortfolioSection(UserProfile tailor) {
    final colors = context.colors;
    final designsAsync = ref.watch(tailorDesignsProvider(tailor.id));
    final previewDesigns = (designsAsync.valueOrNull ?? []).take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.textPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PORTFOLIO',
            style: TextStyle(
              color: colors.scaffoldBg,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          if (designsAsync.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (designsAsync.hasError || previewDesigns.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No public designs yet',
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < previewDesigns.length; i++) ...[
                  Expanded(child: _buildDesignCard(previewDesigns[i])),
                  if (i < previewDesigns.length - 1) const SizedBox(width: 12),
                ],
              ],
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () {
                ref.pushShell('/tailor-profile', {'tailorId': tailor.id});
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.amber.withValues(alpha: 0.4),
                  ),
                ),
                child: Center(
                  child: Text(
                    'VIEW FULL PROFILE',
                    style: TextStyle(
                      color: AppColors.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesignCard(Design design) {
    final colors = context.colors;
    final imageUrl = design.imageUrls.isNotEmpty
        ? design.imageUrls.first
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 110,
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: imageUrl != null
              ? AppNetworkImage(url: imageUrl, fit: BoxFit.cover)
              : Icon(
                  Icons.image_not_supported_outlined,
                  color: colors.textMuted,
                ),
        ),
        const SizedBox(height: 8),
        Text(
          design.title,
          style: TextStyle(
            color: colors.scaffoldBg,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '\u20A6${design.price.toStringAsFixed(0)}',
          style: TextStyle(
            color: AppColors.amber,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsBookingCTA(UserProfile tailor) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () {
        ref.pushShell('/booking-cart', {
          'id': tailor.id,
          'tailorId': tailor.id,
          'name': tailor.businessName?.isNotEmpty == true
              ? tailor.businessName!
              : tailor.name,
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.amber,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'BOOK APPOINTMENT',
            style: TextStyle(
              color: colors.scaffoldBg,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTailorListForSelection(
    TailorFinderState state,
    EdgeInsets padding,
  ) {
    final colors = context.colors;
    return Column(
      children: [
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
                const Icon(
                  Icons.info_outline,
                  color: AppColors.amber,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Select a service type above to see price quotes',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(padding.left),
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
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUberActionButtons(
    BuildContext context,
    UserProfile? selectedTailor,
  ) {
    return _buildBottomActionRow(context, selectedTailor);
  }

  Widget _buildBottomActionRow(
    BuildContext context,
    UserProfile? selectedTailor,
  ) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: GestureDetector(
          onTap: selectedTailor != null
              ? () {
                  ref.pushShell('/tailor-profile', {
                    'tailorId': selectedTailor.id,
                  });
                }
              : null,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: selectedTailor != null
                  ? colors.scaffoldBg
                  : colors.textMuted,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Center(
              child: Text(
                selectedTailor != null ? 'BOOK NOW' : 'SELECT A TAILOR',
                style: TextStyle(
                  color: selectedTailor != null
                      ? AppColors.amber
                      : colors.textSecondary,
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
}

/// AMBER filter chip widget
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
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.amber : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.amber : colors.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? colors.scaffoldBg : colors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? colors.scaffoldBg : colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: isActive ? colors.scaffoldBg : colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
