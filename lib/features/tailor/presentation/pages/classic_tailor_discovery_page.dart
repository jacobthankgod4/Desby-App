import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/nigeria_lga_data.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/active_tailor_provider.dart';
import 'tailor_discovery_page.dart'; // For the provider

/// ClassicTailorDiscoveryPage - High-density grid discovery
/// Implements the standard 'Classic' list view with 2-column card grid.
class ClassicTailorDiscoveryPage extends ConsumerStatefulWidget {
  const ClassicTailorDiscoveryPage({super.key});

  @override
  ConsumerState<ClassicTailorDiscoveryPage> createState() => _ClassicTailorDiscoveryPageState();
}

class _ClassicTailorDiscoveryPageState extends ConsumerState<ClassicTailorDiscoveryPage> {
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
    final tailorsAsync = ref.watch(tailorsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        backgroundColor: AppColors.darkNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('DISCOVERY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 3)),
      ),
      body: CustomScrollView(
        slivers: [
          _buildFilterHero(),
          _buildSectionHeader('TOP ARCHITECTS'),
          
          tailorsAsync.when(
            data: (tailors) => _buildTechnicalGrid(tailors),
            loading: () => const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(80), child: CircularProgressIndicator(color: AppColors.amber)))),
            error: (error, _) => const SliverToBoxAdapter(child: Center(child: Text('SYNC ERROR', style: TextStyle(color: Colors.red)))),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildFilterHero() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('FIND YOUR ARCHITECT', style: TextStyle(color: AppColors.amber, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.0)),
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(child: _buildHeroDropdown('STATE', _selectedState, ['Nigeria', ...NigeriaLgaData.states], (v) {
                  setState(() {
                    _selectedState = v == 'Nigeria' ? null : v;
                    _selectedLga = null;
                    _availableLgas = (v != null && v != 'Nigeria') ? NigeriaLgaData.getLgasForState(v) : [];
                  });
                })),
                const SizedBox(width: 12),
                Expanded(child: _buildHeroDropdown('LGA', _selectedLga, _availableLgas, (v) => setState(() => _selectedLga = v), enabled: _selectedState != null)),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildFilterChips('SPECIALTY', _selectedService, 
              ['Custom', 'Ready-to-Wear', 'Bridal', 'Menswear', 'Womenswear'], 
              (v) => setState(() => _selectedService = v)),
            const SizedBox(height: 24),
            
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'SEARCH BY NAME OR SPECIALTY...',
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: AppColors.amber, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroDropdown(String hint, String? value, List<String> items, Function(String?) onChanged, {bool enabled = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: enabled ? Colors.white.withValues(alpha: 0.03) : Colors.transparent, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: value != null ? AppColors.amber.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05))
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Text(hint, style: TextStyle(color: enabled ? Colors.white38 : Colors.white10, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        dropdownColor: AppColors.darkNavy,
        isExpanded: true,
        underline: const SizedBox(),
        icon: Icon(Icons.expand_more_rounded, size: 18, color: enabled ? AppColors.amber : Colors.white10),
        items: items.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)))).toList(),
        onChanged: enabled ? onChanged : null,
      ),
    );
  }

  Widget _buildFilterChips(String label, String? selectedValue, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12, runSpacing: 12,
          children: [
            _buildFilterPill('ALL', selectedValue == null, () => onChanged(null)),
            ...items.map((item) => _buildFilterPill(item, selectedValue == item, () => onChanged(item))),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterPill(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.amber : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.amber : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(label.toUpperCase(), 
          style: TextStyle(color: isSelected ? AppColors.darkNavy : Colors.white60, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildTechnicalGrid(List<Map<String, dynamic>> tailors) {
    var filtered = tailors.where((t) {
      final name = (t['name'] ?? '').toString().toLowerCase();
      final specialty = (t['specialty'] ?? '').toString().toLowerCase();
      final services \u003d (t['services'] as List<dynamic>?)?.map((e) \u003d\u003e e.toString().toLowerCase()).toList() ?? [];
      
      final matchesSearch \u003d name.contains(_searchQuery) || specialty.contains(_searchQuery);
      final matchesService \u003d _selectedService \u003d\u003d null || 
        services.any((s) \u003d\u003e s.contains(_selectedService!.toLowerCase()));
      
      return matchesSearch \u0026\u0026 matchesService;
    }).toList();

    if (filtered.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(child: Padding(padding: EdgeInsets.all(80), child: Text(\u0027NO ARCHITECTS MATCHING CRITERIA\u0027, style: TextStyle(color: Colors.white12, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)))),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 24,
          crossAxisSpacing: 24,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) \u003d\u003e _buildCompactCard(filtered[index]),
          childCount: filtered.length,
        ),
      ),
    );
  }

  Widget _buildCompactCard(Map\u003cString, dynamic\u003e tailor) {
    final String name \u003d tailor[\u0027name\u0027] ?? \u0027Tailor\u0027;
    final double rating \u003d (tailor[\u0027rating\u0027] as num?)?.toDouble() ?? 4.9;
    final services \u003d (tailor[\u0027services\u0027] as List\u003cdynamic\u003e?)?.cast\u003cString\u003e() ?? [];
    final String specialty \u003d services.isNotEmpty ? services.first : \u0027Bespoke\u0027;

    return InkWell(
      onTap: () {
        ref.read(activeTailorProvider.notifier).state \u003d tailor;
        Navigator.pushNamed(context, \u0027/tailor-profile\u0027, arguments: tailor);
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Container(
                  color: Colors.black26,
                  child: tailor[\u0027profileImage\u0027] !\u003d null 
                      ? Image.network(tailor[\u0027profileImage\u0027], fit: BoxFit.cover, width: double.infinity)
                      : Center(child: Text(name[0], style: const TextStyle(color: AppColors.amber, fontSize: 40, fontWeight: FontWeight.w900))),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.toUpperCase(), 
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5), maxLines: 1),
                    const SizedBox(height: 4),
                    Text(specialty.toUpperCase(), 
                      style: const TextStyle(color: AppColors.amber, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [const Icon(Icons.star_rounded, color: AppColors.amber, size: 14), const SizedBox(width: 4), Text(\u0027$rating\u0027, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))]),
                        const Icon(Icons.verified_rounded, color: Colors.green, size: 14),
                      ],
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

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
        child: Row(
          children: [
            Text(title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(width: 16),
            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.05))),
          ],
        ),
      ),
    );
  }
}
