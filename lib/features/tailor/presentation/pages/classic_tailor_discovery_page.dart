import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/nigeria_lga_data.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../providers/active_tailor_provider.dart';
import '../providers/tailor_finder_provider.dart';

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
    final tailorsAsync = ref.watch(tailorsProvider(_searchQuery));

    return Container(
      color: AppColors.darkNavy,
      child: CustomScrollView(
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

  Widget _buildTechnicalGrid(List<UserProfile> tailors) {
    var filtered = tailors.where((t) {
      final name = t.name.toLowerCase();
      final specialty = (t.businessName ?? '').toLowerCase();
      final services = t.services?.map((e) => e.toLowerCase()).toList() ?? [];
      
      final matchesSearch = name.contains(_searchQuery) || specialty.contains(_searchQuery);
      final matchesService = _selectedService == null || 
        services.any((s) => s.contains(_selectedService!.toLowerCase()));
      
      return matchesSearch && matchesService;
    }).toList();

    if (filtered.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(child: Padding(padding: EdgeInsets.all(80), child: Text('NO ARCHITECTS MATCHING CRITERIA', style: TextStyle(color: Colors.white12, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)))),
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
          (context, index) => _buildCompactCard(filtered[index]),
          childCount: filtered.length,
        ),
      ),
    );
  }

  Widget _buildCompactCard(UserProfile tailor) {
    final String name = tailor.name;
    final double rating = 4.9; // Rating not yet in core UserProfile, using default
    final services = tailor.services ?? [];
    final String specialty = services.isNotEmpty ? services.first : 'Bespoke';

    return InkWell(
      onTap: () {
        ref.read(activeTailorProvider.notifier).state = tailor.toJson();
        ref.pushShell('/tailor-profile', {'tailorId': tailor.id});
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
                  child: tailor.profileImage != null 
                      ? Image.network(tailor.profileImage!, fit: BoxFit.cover, width: double.infinity)
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
                        Row(children: [const Icon(Icons.star_rounded, color: AppColors.amber, size: 14), const SizedBox(width: 4), Text('$rating', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))]),
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
