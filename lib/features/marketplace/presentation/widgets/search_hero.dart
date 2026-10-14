import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../../domain/entities/marketplace_filter.dart';
import '../providers/marketplace_filter_provider.dart';

class SearchHero extends ConsumerStatefulWidget {
  const SearchHero({super.key});

  @override
  ConsumerState<SearchHero> createState() => _SearchHeroState();
}

class _SearchHeroState extends ConsumerState<SearchHero> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(marketplaceFilterProvider);
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: colors.scaffoldBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildLocationSelector(filter),
              Container(width: 1, height: 32, color: colors.divider),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (val) {
                    ref
                        .read(marketplaceFilterProvider.notifier)
                        .setSearchQueryImmediate(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search premium silk, cotton, wool...',
                    hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(marketplaceFilterProvider.notifier)
                                  .clearSearch();
                            },
                          )
                        : null,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: colors.scaffoldBg,
                  child: IconButton(
                    icon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.amber,
                      size: 20,
                    ),
                    onPressed: () {
                      ref
                          .read(marketplaceFilterProvider.notifier)
                          .setSearchQueryImmediate(_searchController.text);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSelector(MarketplaceFilter filter) {
    final colors = context.colors;
    return InkWell(
      onTap: () => _showStateLgaPicker(filter),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: AppColors.amber,
              size: 20,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'LOCATION',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: colors.textMuted,
                  ),
                ),
                Text(
                  filter.selectedState ?? 'All States',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: colors.iconMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showStateLgaPicker(MarketplaceFilter filter) {
    final colors = context.colors;
    final states = [
      'All States',
      'Abia',
      'Adamawa',
      'Akwa Ibom',
      'Anambra',
      'Bauchi',
      'Bayelsa',
      'Benue',
      'Borno',
      'Cross River',
      'Delta',
      'Ebonyi',
      'Edo',
      'Ekiti',
      'Enugu',
      'FCT',
      'Gombe',
      'Imo',
      'Jigawa',
      'Kaduna',
      'Kano',
      'Katsina',
      'Kebbi',
      'Kogi',
      'Kwara',
      'Lagos',
      'Nasarawa',
      'Niger',
      'Ogun',
      'Ondo',
      'Osun',
      'Oyo',
      'Plateau',
      'Rivers',
      'Sokoto',
      'Taraba',
      'Yobe',
      'Zamfara',
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: colors.bottomSheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.85,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SELECT STATE',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap a state to filter the fabric market',
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: states.length,
                  itemBuilder: (ctx, index) {
                    final state = states[index];
                    final isSelected =
                        state == (filter.selectedState ?? 'All States');
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.location_on_outlined,
                        color: isSelected ? AppColors.amber : colors.iconMuted,
                        size: 20,
                      ),
                      title: Text(
                        state,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.amber
                              : colors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: AppColors.amber)
                          : null,
                      onTap: () {
                        ref
                            .read(marketplaceFilterProvider.notifier)
                            .setSelectedState(
                              state == 'All States' ? null : state,
                            );
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
