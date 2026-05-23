import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/nigeria_lga_data.dart';
import '../../../../theme/colors.dart';
import '../../../auth/data/repositories/firebase_auth_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final tailorsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final localDatasource = ref.read(authLocalDatasourceProvider);
  final repo = FirebaseAuthRepository(localDatasource: localDatasource);
  return repo.getTailors();
});

class TailorDiscoveryPage extends ConsumerStatefulWidget {
  const TailorDiscoveryPage({super.key});

  @override
  ConsumerState<TailorDiscoveryPage> createState() => _TailorDiscoveryPageState();
}

class _TailorDiscoveryPageState extends ConsumerState<TailorDiscoveryPage> {
  String _searchQuery = '';
  String? _selectedState;
  String? _selectedLga;
  List<String> _availableLgas = [];
  final _searchController = TextEditingController();
  
  String? _selectedService;
  String? _selectedFabric;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tailorsAsync = ref.watch(tailorsProvider);
    const int cartCount = 0; 

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        backgroundColor: AppColors.darkNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('DISCOVERY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.8)),
      ),
      body: CustomScrollView(
        slivers: [
          _buildMTNHeader(cartCount),
          _buildFilterHero(),
          _buildFunctionalShortcuts(),
          _buildSectionHeader('TOP TAILORS'),
          
          tailorsAsync.when(
            data: (tailors) => _buildFilteredProductGrid(tailors),
            loading: () => const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator(color: AppColors.amber)))),
            error: (error, _) => SliverToBoxAdapter(child: Center(child: Text('Access Failed', style: TextStyle(color: AppColors.amber)))),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 60)),
        ],
      ),
    );
  }

  Widget _buildMTNHeader(int cartCount) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.darkNavy,
      elevation: 0,
      toolbarHeight: 50,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          _buildNavItem('Tailors', true),
          const SizedBox(width: 12),
          _buildNavItem('Fabrics', false),
          const SizedBox(width: 12),
          _buildNavItem('History', false),
        ],
      ),
      actions: [
        const Icon(Icons.search, color: AppColors.amber, size: 20),
        const SizedBox(width: 16),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.amber, size: 24),
              onPressed: () => Navigator.pushNamed(context, '/booking-cart', arguments: {}),
            ),
            if (cartCount > 0)
              Positioned(
                right: 8, top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                  child: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(10),
        child: Container(height: 10, color: AppColors.amber),
      ),
    );
  }

  Widget _buildNavItem(String label, bool isSelected) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: isSelected ? AppColors.amber : Colors.white.withValues(alpha: 0.5),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.8,
      ),
    );
  }

  Widget _buildFilterHero() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: 0.03),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text('FIND A TAILOR OR FASHION DESIGNER', style: TextStyle(color: AppColors.amber, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.0, height: 1.1)),
                const SizedBox(height: 24),
                
                _buildHeroDropdown('SELECT STATE', _selectedState, ['Nigeria', ...NigeriaLgaData.states], (v) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (!mounted) return;
                    setState(() {
                      _selectedState = v == 'Nigeria' ? null : v;
                      _selectedLga = null;
                      _availableLgas = (v != null && v != 'Nigeria') ? NigeriaLgaData.getLgasForState(v) : [];
                    });
                  });
                }),
                const SizedBox(height: 12),
                _buildHeroDropdown('SELECT LGA', _selectedLga, _availableLgas, (v) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (!mounted) return;
                    setState(() => _selectedLga = v);
                  });
                }, enabled: _selectedState != null),
                const SizedBox(height: 12),
                
                _buildFilterChips('SPECIALTY', _selectedService, 
                  ['Custom', 'Ready-to-Wear', 'Bridal', 'Menswear', 'Womenswear'], 
                  (v) => setState(() => _selectedService = v)),
                const SizedBox(height: 12),
                
                _buildFilterChips('FABRICS', _selectedFabric, 
                  ['Cotton', 'Silk', 'Wool', 'Linen', 'Leather'], 
                  (v) => setState(() => _selectedFabric = v)),
                const SizedBox(height: 24),
                
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'SEARCH BY NAME...',
                      hintStyle: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: AppColors.amber, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroDropdown(String hint, String? value, List<String> items, Function(String?) onChanged, {bool enabled = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: enabled ? Colors.white.withValues(alpha: 0.05) : Colors.transparent, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: value != null ? AppColors.amber : Colors.white24)
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Text(hint, style: TextStyle(color: enabled ? Colors.white70 : Colors.white10, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        dropdownColor: AppColors.darkNavy,
        isExpanded: true,
        underline: const SizedBox(),
        icon: Icon(Icons.expand_more_rounded, size: 16, color: enabled ? AppColors.amber : Colors.white10),
        items: items.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)))).toList(),
        onChanged: enabled ? onChanged : null,
      ),
    );
  }

  Widget _buildFilterChips(String label, String? selectedValue, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            InkWell(
              onTap: () => onChanged(null),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selectedValue == null ? AppColors.amber : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selectedValue == null ? AppColors.amber : Colors.white24),
                ),
                child: Text('ALL', style: TextStyle(
                  color: selectedValue == null ? AppColors.darkNavy : Colors.white70,
                  fontSize: 10, fontWeight: FontWeight.bold,
                )),
              ),
            ),
            ...items.map((item) => InkWell(
              onTap: () => onChanged(item),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selectedValue == item ? AppColors.amber : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selectedValue == item ? AppColors.amber : Colors.white24),
                ),
                child: Text(item.toUpperCase(), style: TextStyle(
                  color: selectedValue == item ? AppColors.darkNavy : Colors.white70,
                  fontSize: 10, fontWeight: FontWeight.bold,
                )),
              ),
            )).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildFunctionalShortcuts() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLargeSquareShortcut(Icons.straighten_rounded, 'MEASURE', () => Navigator.pushNamed(context, '/measurements-input')),
            _buildLargeSquareShortcut(Icons.shopping_bag_rounded, 'FABRICS', () => Navigator.pushNamed(context, '/marketplace')),
            _buildLargeSquareShortcut(Icons.history_rounded, 'ORDERS', () => Navigator.pushNamed(context, '/orders')),
            _buildLargeSquareShortcut(Icons.person_search_rounded, 'DASHBOARD', () => Navigator.pushNamed(context, '/main')),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeSquareShortcut(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.amber,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.darkNavy, size: 24),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: AppColors.darkNavy, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Text(title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildFilteredProductGrid(List<Map<String, dynamic>> tailors) {
    var filtered = tailors.where((t) {
      final name = (t['name'] ?? '').toString().toLowerCase();
      final specialty = (t['specialty'] ?? '').toString().toLowerCase();
      final services = (t['services'] as List<dynamic>?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
      final fabrics = (t['availableFabrics'] as List<dynamic>?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
      
      final matchesSearch = name.contains(_searchQuery) || specialty.contains(_searchQuery);
      final matchesService = _selectedService == null || 
        services.any((s) => s.contains(_selectedService!.toLowerCase()));
      final matchesFabric = _selectedFabric == null || 
        fabrics.any((f) => f.contains(_selectedFabric!.toLowerCase()));
      
      return matchesSearch && matchesService && matchesFabric;
    }).toList();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildCompactCard(context, filtered[index]),
          childCount: filtered.length,
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context, Map<String, dynamic> tailor) {
    final services = (tailor['services'] as List<dynamic>?)?.cast<String>() ?? [];
    final fabrics = (tailor['availableFabrics'] as List<dynamic>?)?.cast<String>() ?? [];
    final displayServices = services.take(2).join(', ');
    final displayFabrics = fabrics.take(2).join(', ');

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/tailor-profile', arguments: tailor),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: AppColors.amber, width: 2.5),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Container(
                  width: double.infinity,
                  color: Colors.black26,
                  child: tailor['profileImage'] != null 
                    ? Image.network(tailor['profileImage'], fit: BoxFit.cover)
                    : Center(child: Text((tailor['name'] ?? 'T')[0].toUpperCase(), style: const TextStyle(color: AppColors.amber, fontSize: 32, fontWeight: FontWeight.w900))),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((tailor['name'] ?? 'TAILOR').toString().toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5), maxLines: 1),
                  const SizedBox(height: 4),
                  if (displayServices.isNotEmpty)
                    Text(displayServices.toUpperCase(), style: const TextStyle(color: AppColors.amber, fontSize: 7, fontWeight: FontWeight.w800), maxLines: 1),
                  if (displayFabrics.isNotEmpty)
                    Text(displayFabrics.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 7, fontWeight: FontWeight.w700), maxLines: 1),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [const Icon(Icons.star, color: AppColors.amber, size: 10), const SizedBox(width: 4), Text(tailor['rating'] ?? '4.9', style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold))]),
                      const Icon(Icons.verified_rounded, color: AppColors.amber, size: 12),
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
}
