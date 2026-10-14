import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../theme/colors.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/providers/layout_provider.dart';
import '../../domain/entities/design.dart';
import '../../presentation/providers/design_provider.dart';
import '../../../../core/widgets/shell_scope.dart';
import '../../../../core/widgets/app_network_image.dart';

class SavedDesignsPage extends ConsumerWidget {
  const SavedDesignsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final savedAsync = ref.watch(savedDesignsProvider);
    final isDesktop = ref.watch(isDesktopProvider);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          if (!ShellScope.isInside(context))
            SliverAppBar(
              pinned: true,
              backgroundColor: colors.scaffoldBg,
              elevation: 0,
              toolbarHeight: 60,
              leading: isDesktop
                  ? const SizedBox.shrink()
                  : IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.amber,
                        size: 20,
                      ),
                      onPressed: () => ref.popShell(),
                    ),
              title: Text(
                'SAVED DESIGNS',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.8,
                ),
              ),
            ),
          savedAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.amber),
              ),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(
                child: Text(
                  'Could not load saved designs',
                  style: TextStyle(color: colors.textMuted),
                ),
              ),
            ),
            data: (designs) {
              if (designs.isEmpty) {
                return SliverFillRemaining(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border_rounded,
                        color: colors.textMuted,
                        size: 56,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'NOTHING SAVED YET',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the heart on any design to save it here',
                        style: TextStyle(color: colors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }
              return SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 48 : 20,
                  vertical: 16,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 260,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _SavedCard(design: designs[index]),
                    childCount: designs.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SavedCard extends ConsumerWidget {
  final Design design;
  const _SavedCard({required this.design});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final price = NumberFormat('#,##0').format(design.price.toInt());
    final image = design.imageUrls.isNotEmpty ? design.imageUrls.first : null;

    return GestureDetector(
      onTap: () => ref.pushShell('/design-details', {'design': design}),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(17),
                      ),
                    ),
                    child: image != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(17),
                            ),
                            child: AppNetworkImage(
                              url: image,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.checkroom_rounded,
                              color: colors.divider,
                              size: 40,
                            ),
                          ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colors.overlayMedium,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: AppColors.amber,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    design.title.toUpperCase(),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          design.tailorName.toUpperCase(),
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '\u20A6$price',
                        style: TextStyle(
                          color: AppColors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
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
}
