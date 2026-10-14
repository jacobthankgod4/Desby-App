import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/nigeria_lga_data.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../providers/active_tailor_provider.dart';
import '../providers/tailor_finder_provider.dart';
import '../../../../core/widgets/app_network_image.dart';

/// ClassicTailorDiscoveryPage - High-density grid discovery
/// Implements the standard 'Classic' list view with 2-column card grid.
class ClassicTailorDiscoveryPage extends ConsumerStatefulWidget {
  const ClassicTailorDiscoveryPage({super.key});

  @override
  ConsumerState<ClassicTailorDiscoveryPage> createState() =>
      _ClassicTailorDiscoveryPageState();
}

class _ClassicTailorDiscoveryPageState
    extends ConsumerState<ClassicTailorDiscoveryPage> {
  String _searchQuery = '';
  String? _selectedState;
  String? _selectedLga;
  List<String> _availableLgas = [];
  final _searchController = TextEditingController();

  String? _selectedService;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tailorsAsync = ref.watch(tailorsProvider(_searchQuery));

    return Container(
      color: context.colors.scaffoldBg,
      child: CustomScrollView(
        slivers: [
          _buildFilterHero(),
          _buildSectionHeader('TOP TAILORS'),

          tailorsAsync.when(
            data: (tailors) => _buildTechnicalGrid(tailors),
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(80),
                  child: CircularProgressIndicator(color: AppColors.amber),
                ),
              ),
            ),
            error: (error, _) => SliverToBoxAdapter(
              child: Center(
                child: Text(
                  'SYNC ERROR',
                  style: TextStyle(color: context.colors.statusError),
                ),
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildFilterHero() {
    final colors = context.colors;
    // Sticky so filters stay reachable while scrolling cards, without ever
    // consuming the viewport above the grid the way the old hero block did.
    return SliverPersistentHeader(
      pinned: true,
      delegate: _FilterHeaderDelegate(
        background: colors.scaffoldBg,
        border: colors.borderSubtle,
        child: Container(
          color: colors.scaffoldBg,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search sits first: it is the primary action and needs no
              // disclosure.
              Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: colors.borderSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.borderDefault),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.toLowerCase()),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                  ),
                  cursorColor: colors.textSecondary,
                  decoration: InputDecoration(
                    hintText: 'SEARCH BY NAME OR SPECIALTY...',
                    hintStyle: TextStyle(
                      color: colors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                    border: InputBorder.none,
                    icon: const Icon(Icons.search, color: AppColors.amber, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Filters collapse to a single row so tailor cards start near the
              // top of the viewport rather than below a tall hero block.
              Row(
                children: [
                  Expanded(
                    child: _buildHeroDropdown(
                      'STATE',
                      _selectedState,
                      ['Nigeria', ...NigeriaLgaData.states],
                      (v) {
                        setState(() {
                          _selectedState = v == 'Nigeria' ? null : v;
                          _selectedLga = null;
                          _availableLgas = (v != null && v != 'Nigeria')
                              ? NigeriaLgaData.getLgasForState(v)
                              : [];
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildHeroDropdown(
                      'LGA',
                      _selectedLga,
                      _availableLgas,
                      (v) => setState(() => _selectedLga = v),
                      enabled: _selectedState != null,
                    ),
                  ),
                ],
              ),

              // Specialty is a single horizontal scroller instead of a wrapped
              // two-line block, which is what pushed the grid down.
              const SizedBox(height: 10),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildCompactChip(
                      'All',
                      _selectedService == null,
                      () => setState(() => _selectedService = null),
                    ),
                    ...['Custom', 'Ready-to-Wear', 'Bridal', 'Menswear',
                        'Womenswear'].map(
                      (s) => _buildCompactChip(
                        s,
                        _selectedService == s,
                        () => setState(
                          () => _selectedService =
                              _selectedService == s ? null : s,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactChip(String label, bool active, VoidCallback onTap) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: active ? AppColors.amber : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? AppColors.amber : colors.borderDefault,
            ),
          ),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: active ? Colors.black : colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroDropdown(
    String hint,
    String? value,
    List<String> items,
    Function(String?) onChanged, {
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: enabled ? context.colors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value != null
              ? AppColors.amber.withValues(alpha: 0.5)
              : context.colors.borderSubtle,
        ),
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Text(
          hint,
          style: TextStyle(
            color: enabled
                ? context.colors.textMuted
                : context.colors.textMuted.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        dropdownColor: context.colors.scaffoldBg,
        isExpanded: true,
        underline: const SizedBox(),
        icon: Icon(
          Icons.expand_more_rounded,
          size: 18,
          color: enabled
              ? AppColors.amber
              : context.colors.textMuted.withValues(alpha: 0.5),
        ),
        items: items
            .map(
              (s) => DropdownMenuItem(
                value: s,
                child: Text(
                  s.toUpperCase(),
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: enabled ? onChanged : null,
      ),
    );
  }

  Widget _buildTechnicalGrid(List<UserProfile> tailors) {
    var filtered = tailors.where((t) {
      final name = t.name.toLowerCase();
      final specialty = (t.businessName ?? '').toLowerCase();
      final services = t.services?.map((e) => e.toLowerCase()).toList() ?? [];

      final matchesSearch =
          name.contains(_searchQuery) || specialty.contains(_searchQuery);
      final matchesService =
          _selectedService == null ||
          services.any((s) => s.contains(_selectedService!.toLowerCase()));

      return matchesSearch && matchesService;
    }).toList();

    if (filtered.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(80),
            child: Text(
              'NO TAILORS MATCHING CRITERIA',
              style: TextStyle(
                color: context.colors.divider,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200
        ? 5
        : screenWidth > 900
        ? 4
        : screenWidth > 600
        ? 3
        : 2;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildCompactCard(filtered[index]),
          childCount: filtered.length,
        ),
      ),
    );
  }

  Widget _buildCompactCard(UserProfile tailor) {
    final String name = tailor.name;
    final double rating = 4.9;
    final services = tailor.services ?? [];
    final String specialty = services.isNotEmpty ? services.first : 'Bespoke';
    final colors = context.colors;

    return InkWell(
      onTap: () {
        ref.read(activeTailorProvider.notifier).state = tailor.toJson();
        ref.pushShell('/tailor-profile', {'tailorId': tailor.id});
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: tailor.profileImage != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child: AppNetworkImage(
                              url: tailor.profileImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : Center(
                            child: Text(
                              name[0],
                              style: TextStyle(
                                color: AppColors.amber,
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.scaffoldBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.amber,
                            size: 12,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$rating',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.toUpperCase(),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        specialty.toUpperCase(),
                        style: TextStyle(
                          color: AppColors.amber,
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
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
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
        child: Row(
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Divider(color: context.colors.borderSubtle)),
          ],
        ),
      ),
    );
  }
}

/// Keeps the compact search + filter block pinned while the tailor grid scrolls.
///
/// Height is fixed and small by design: the previous hero block consumed roughly
/// 400px before the first card was visible on a phone, which pushed the grid
/// almost entirely below the fold.
class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  _FilterHeaderDelegate({
    required this.child,
    required this.background,
    required this.border,
  });

  final Widget child;
  final Color background;
  final Color border;

  static const double _height = 156;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_FilterHeaderDelegate oldDelegate) =>
      oldDelegate.child != child ||
      oldDelegate.background != background ||
      oldDelegate.border != border;
}
