import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../../../../core/providers/layout_provider.dart';
import '../../../../core/widgets/shell_app_bar.dart';
import '../../domain/constants/fabric_constants.dart';
import '../widgets/search_hero.dart';
import '../widgets/fabric_card_grid.dart';
import '../widgets/shortcut_cards.dart';
import '../providers/fabric_provider.dart';

class FabricCatalogPage extends ConsumerStatefulWidget {
  const FabricCatalogPage({super.key});

  @override
  ConsumerState<FabricCatalogPage> createState() => _FabricCatalogPageState();
}

class _FabricCatalogPageState extends ConsumerState<FabricCatalogPage> {
  bool _isGridView = true;
  String _selectedCategory = 'All';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool isMobile = !ref.watch(isDesktopProvider);
    final fabricsAsync = ref.watch(fabricCatalogProvider(_selectedCategory));

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: colors.scaffoldBg,
      // Drawer works on both mobile and desktop - opens category filter
      drawer: Drawer(
        backgroundColor: colors.scaffoldBg,
        child: _buildMobileSidebar(),
      ),
      appBar: shellAppBar(context, title: 'Fabric Marketplace'),
      body: Column(
        children: [
          const SearchHero(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMobile)
                  SizedBox(width: 260, child: _buildDesktopSidebar()),
                Expanded(
                  child: fabricsAsync.when(
                    data: (fabrics) => SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isMobile) _buildMobileFilterButton(),
                          if (!isMobile) const ShortcutCards(),
                          if (!isMobile) const SizedBox(height: 32),
                          _buildContentHeader(fabrics.length),
                          const SizedBox(height: 16),
                          FabricCardGrid(
                            isGridView: _isGridView,
                            fabrics: fabrics,
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.amber),
                    ),
                    error: (e, _) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            color: colors.textMuted,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'MARKETPLACE UNAVAILABLE',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check your connection and try again.',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextButton.icon(
                            onPressed: () => ref.invalidate(
                              fabricCatalogProvider(_selectedCategory),
                            ),
                            icon: const Icon(
                              Icons.refresh,
                              color: AppColors.amber,
                              size: 16,
                            ),
                            label: const Text(
                              'RETRY',
                              style: TextStyle(
                                color: AppColors.amber,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: colors.borderSubtle)),
      ),
      child: _buildCategoryList(),
    );
  }

  Widget _buildMobileSidebar() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CATEGORIES',
            style: TextStyle(
              color: AppColors.amber,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(child: _buildCategoryList()),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    final colors = context.colors;
    final categories = kFabricCategories;
    return ListView.separated(
      itemCount: categories.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final cat = categories[index];
        final isSel = _selectedCategory == cat;
        return InkWell(
          onTap: () {
            setState(() => _selectedCategory = cat);
            if (MediaQuery.of(context).size.width < 900) Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSel
                  ? AppColors.amber.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              cat.toUpperCase(),
              style: TextStyle(
                color: isSel ? AppColors.amber : colors.textSecondary,
                fontWeight: isSel ? FontWeight.w900 : FontWeight.w600,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileFilterButton() {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: OutlinedButton.icon(
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        icon: const Icon(Icons.filter_list_rounded, color: AppColors.amber),
        label: const Text(
          'EXPLORE CATEGORIES',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colors.borderSubtle),
          foregroundColor: colors.textPrimary,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildContentHeader(int count) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PREMIUM INVENTORY',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count Masterpieces Found',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        _buildViewToggle(),
      ],
    );
  }

  Widget _buildViewToggle() {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.grid_view_rounded,
              color: _isGridView ? AppColors.amber : colors.textMuted,
              size: 20,
            ),
            onPressed: () => setState(() => _isGridView = true),
          ),
          Container(width: 1, height: 24, color: colors.borderSubtle),
          IconButton(
            icon: Icon(
              Icons.list_rounded,
              color: !_isGridView ? AppColors.amber : colors.textMuted,
              size: 20,
            ),
            onPressed: () => setState(() => _isGridView = false),
          ),
        ],
      ),
    );
  }
}
