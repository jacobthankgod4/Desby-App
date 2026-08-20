import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../widgets/market_header.dart';
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
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    final fabricsAsync = ref.watch(fabricCatalogProvider(_selectedCategory));

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.darkNavy,
      // Drawer works on both mobile and desktop - opens category filter
      drawer: Drawer(
        backgroundColor: AppColors.darkNavy, 
        child: _buildMobileSidebar()
      ),
      appBar: AppBar(
        backgroundColor: AppColors.darkNavy,
        elevation: 0,
        leading: isMobile 
          ? IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            )
          : (Navigator.canPop(context) 
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 18),
                  onPressed: () {
                    if (ref.canPopShell) {
                      ref.popShell();
                    } else {
                      ref.setShell('/main');
                    }
                  },
                )
              : null),
        title: const Text('MARKETPLACE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (!isMobile) const SizedBox(height: 0) else const MarketHeader(),
          if (!isMobile) const SizedBox.shrink() else const SearchHero(),
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
                          FabricCardGrid(isGridView: _isGridView, fabrics: fabrics),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
                    error: (e, _) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.storefront_outlined, color: Colors.white24, size: 64),
                          const SizedBox(height: 16),
                          const Text(
                            'MARKETPLACE UNAVAILABLE',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check your connection and try again.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 12),
                          ),
                          const SizedBox(height: 24),
                          TextButton.icon(
                            onPressed: () => ref.invalidate(fabricCatalogProvider(_selectedCategory)),
                            icon: const Icon(Icons.refresh, color: AppColors.amber, size: 16),
                            label: const Text('RETRY', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900, letterSpacing: 1)),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.white10))),
      child: _buildCategoryList(),
    );
  }

  Widget _buildMobileSidebar() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CATEGORIES', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 32),
          Expanded(child: _buildCategoryList()),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    final categories = ['All', 'Cotton', 'Silk', 'Linen', 'Wool', 'Lace', 'Velvet', 'Leather', 'Satin', 'Damask'];
    return ListView.separated(
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
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
              color: isSel ? AppColors.amber.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(cat.toUpperCase(), style: TextStyle(color: isSel ? AppColors.amber : Colors.white60, fontWeight: isSel ? FontWeight.w900 : FontWeight.w600, fontSize: 11, letterSpacing: 1)),
          ),
        );
      },
    );
  }

  Widget _buildMobileFilterButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: OutlinedButton.icon(
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        icon: const Icon(Icons.filter_list_rounded, color: AppColors.amber),
        label: const Text('EXPLORE CATEGORIES', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white10),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildContentHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PREMIUM INVENTORY', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
            Text('$count Masterpieces Found', style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900)),
          ],
        ),
        _buildViewToggle(),
      ],
    );
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          IconButton(icon: Icon(Icons.grid_view_rounded, color: _isGridView ? AppColors.amber : Colors.white24, size: 20), onPressed: () => setState(() => _isGridView = true)),
          Container(width: 1, height: 24, color: Colors.white10),
          IconButton(icon: Icon(Icons.list_rounded, color: !_isGridView ? AppColors.amber : Colors.white24, size: 20), onPressed: () => setState(() => _isGridView = false)),
        ],
      ),
    );
  }
}
