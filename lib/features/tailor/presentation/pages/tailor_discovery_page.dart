import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/tailor_finder_responsive.dart';
import '../../../../theme/colors.dart';
import 'tailor_finder_desktop.dart';
import 'tailor_finder_mobile.dart';
import 'classic_tailor_discovery_page.dart';

final discoveryViewModeProvider = StateProvider<String>((ref) => 'uber');

/// TailorDiscoveryPage - Unified responsive entry point for discovery
/// Allows switching between UBER (Map) and GALLERY (Classic) modes
class TailorDiscoveryPage extends ConsumerWidget {
  const TailorDiscoveryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(discoveryViewModeProvider);

    final bool isDesktop = MediaQuery.of(context).size.width > 1000;

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: Column(
        children: [
          _buildDiscoverySubHeader(context, ref, viewMode),
          Expanded(
            child: viewMode == 'uber'
                ? TailorFinderResponsive(
                    mobile: const TailorFinderMobile(),
                    desktop: const TailorFinderDesktop(),
                    forceDesktop: isDesktop,
                  )
                : const ClassicTailorDiscoveryPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverySubHeader(BuildContext context, WidgetRef ref, String currentMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkNavy,
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          _buildViewToggle(ref, 'uber', Icons.map_outlined, 'UBER MODE', currentMode == 'uber'),
          const SizedBox(width: 12),
          _buildViewToggle(ref, 'gallery', Icons.grid_view_rounded, 'GALLERY MODE', currentMode == 'gallery'),
          const Spacer(),
          Text(
            currentMode == 'uber' ? 'SPLIT RADAR ACTIVE' : 'GRID ARCHITECTURE',
            style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(WidgetRef ref, String mode, IconData icon, String label, bool isActive) {
    return InkWell(
      onTap: () => ref.read(discoveryViewModeProvider.notifier).state = mode,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.amber.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? AppColors.amber : Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isActive ? AppColors.amber : Colors.white24),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.white24, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}
