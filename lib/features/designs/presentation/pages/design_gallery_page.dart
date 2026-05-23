import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';

// Design Gallery Page - Threadly Feature
// Browse trending designs and garment styles
class DesignGalleryPage extends ConsumerStatefulWidget {
  const DesignGalleryPage({super.key});

  @override
  ConsumerState<DesignGalleryPage> createState() => _DesignGalleryPageState();
}

class _DesignGalleryPageState extends ConsumerState<DesignGalleryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  // Threadly style categories + trending designs
  static const List<String> categories = [
    'All', 'Dress', 'Gown', 'Ankara', 'Aso Ebi', 
    'Suits', 'Agbada', 'Kaftan', 'Senator', 'Jean'
  ];

  // Sample design data - should come from Firebase in production
  final List<Map<String, dynamic>> _designs = [
    {'id': '1', 'name': 'Emerald Silk Gown', 'category': 'Gown', 'image': 'assets/images/logo.png', 'tailor': 'Ada Fashion'},
    {'id': '2', 'name': 'Ankara Maxi', 'category': 'Ankara', 'image': 'assets/images/logo.png', 'tailor': 'Nigerian Couture'},
    {'id': '3', 'name': 'Classic Suit', 'category': 'Suits', 'image': 'assets/images/logo.png', 'tailor': 'Bespoke Tailors'},
    {'id': '4', 'name': 'Agbada Elite', 'category': 'Agbada', 'image': 'assets/images/logo.png', 'tailor': 'Royal Threads'},
    {'id': '5', 'name': 'Kaftan Modern', 'category': 'Kaftan', 'image': 'assets/images/logo.png', 'tailor': 'Elite Dressmakers'},
    {'id': '6', 'name': 'Senator Gold', 'category': 'Senator', 'image': 'assets/images/logo.png', 'tailor': 'Ada Fashion'},
    {'id': '7', 'name': 'Aso Ebi Style', 'category': 'Aso Ebi', 'image': 'assets/images/logo.png', 'tailor': 'Nigerian Couture'},
    {'id': '8', 'name': 'Denim Jacket', 'category': 'Jean', 'image': 'assets/images/logo.png', 'tailor': 'Bespoke Tailors'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredDesigns = _getFilteredDesigns();

    return Scaffold(
      backgroundColor: const Color(0xFF0A1921),
      appBar: AppBar(
        title: const Text('DESIGN PORTFOLIO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
        backgroundColor: Colors.transparent, elevation: 0,
leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 18), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryTabs(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDesignGrid(filteredDesigns),
                _buildDesignGrid(filteredDesigns),
                _buildDesignGrid(_designs.where((d) => d['category'] == 'Dress').toList()),
                _buildDesignGrid(_designs.where((d) => d['category'] == 'Gown').toList()),
                _buildDesignGrid(_designs.where((d) => d['category'] == 'Ankara').toList()),
                _buildDesignGrid(_designs.where((d) => d['category'] == 'Aso Ebi').toList()),
                _buildDesignGrid(_designs.where((d) => d['category'] == 'Suits').toList()),
                _buildDesignGrid(_designs.where((d) => d['category'] == 'Agbada').toList()),
                _buildDesignGrid(_designs.where((d) => d['category'] == 'Kaftan').toList()),
                _buildDesignGrid(_designs.where((d) => d['category'] == 'Senator').toList()),
                _buildDesignGrid(_designs.where((d) => d['category'] == 'Jean').toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search designs, fabrics, styles...',
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: const Icon(Icons.search, color: AppColors.amber),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppColors.amber,
        labelColor: AppColors.amber,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
        tabs: categories.map((cat) => Tab(text: cat.toUpperCase())).toList(),
      ),
    );
  }

List<Map<String, dynamic>> _getFilteredDesigns() {
    if (_searchQuery.isEmpty) return _designs;
    return _designs.where((d) {
      final name = d['name'].toString().toLowerCase();
      final category = d['category'].toString().toLowerCase();
      final tailor = d['tailor'].toString().toLowerCase();
      return name.contains(_searchQuery) || category.contains(_searchQuery) || tailor.contains(_searchQuery);
    }).cast<Map<String, dynamic>>().toList();
  }

  Widget _buildDesignGrid(List<Map<String, dynamic>> designs) {
    if (designs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text('No designs found', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: designs.length,
      itemBuilder: (context, index) {
        final design = designs[index];
        return _DesignCard(
          design: design,
          onTap: () => _viewDesignDetail(design),
        );
      },
    );
  }

  void _viewDesignDetail(Map<String, dynamic> design) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1921),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.amber,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.checkroom, size: 40, color: AppColors.darkNavy),
            ),
            const SizedBox(height: 16),
            Text(
              design['name'],
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              '${design['category']} • ${design['tailor']}',
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to booking with this design
                  _bookThisDesign(design);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: AppColors.darkNavy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('ORDER THIS DESIGN', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _bookThisDesign(Map<String, dynamic> design) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking ${design['name']} - Coming soon!'),
        backgroundColor: AppColors.amber,
      ),
    );
  }
}

// Design Card Widget
class _DesignCard extends StatelessWidget {
  final Map<String, dynamic> design;
  final VoidCallback onTap;

  const _DesignCard({required this.design, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: const Center(
                  child: Icon(Icons.checkroom, size: 48, color: Colors.white24),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    design['name'],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    design['tailor'],
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
