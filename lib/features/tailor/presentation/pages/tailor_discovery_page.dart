import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/tailor_finder_responsive.dart';
import '../../../../core/providers/layout_provider.dart';
import '../../../../theme/colors.dart';
import 'tailor_finder_desktop.dart';
import 'tailor_finder_mobile.dart';
import 'classic_tailor_discovery_page.dart';

/// Defaults to gallery mode on mobile, where the map-style split view crowds
/// the viewport and shows very little of each tailor at a time. Desktop keeps
/// the uber view, which suits its wider layout.
///
/// Either mode stays user-selectable via the toggle in the sub-header.
final discoveryViewModeProvider = StateProvider<String>((ref) {
  final isDesktop = ref.watch(isDesktopProvider);
  return isDesktop ? 'uber' : 'gallery';
});

class TailorDiscoveryPage extends ConsumerWidget {
  const TailorDiscoveryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final viewMode = ref.watch(discoveryViewModeProvider);

    final bool isDesktop = ref.watch(isDesktopProvider);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
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

  Widget _buildDiscoverySubHeader(
    BuildContext context,
    WidgetRef ref,
    String currentMode,
  ) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: colors.scaffoldBg,
        border: Border(bottom: BorderSide(color: colors.borderSubtle)),
      ),
      child: Row(
        children: [
          _buildViewToggle(
            context,
            ref,
            'uber',
            Icons.map_outlined,
            'UBER MODE',
            currentMode == 'uber',
          ),
          const SizedBox(width: 12),
          _buildViewToggle(
            context,
            ref,
            'gallery',
            Icons.grid_view_rounded,
            'GALLERY MODE',
            currentMode == 'gallery',
          ),
          const Spacer(),
          Text(
            currentMode == 'uber' ? 'SPLIT RADAR ACTIVE' : 'GRID ARCHITECTURE',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(
    BuildContext context,
    WidgetRef ref,
    String mode,
    IconData icon,
    String label,
    bool isActive,
  ) {
    final colors = context.colors;
    return InkWell(
      onTap: () => ref.read(discoveryViewModeProvider.notifier).state = mode,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.amber.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? AppColors.amber : colors.borderDefault,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? AppColors.amber : colors.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? colors.textPrimary : colors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
