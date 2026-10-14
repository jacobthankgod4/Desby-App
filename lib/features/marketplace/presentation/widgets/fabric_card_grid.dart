import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../../../../core/constants/fabric_images.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../domain/entities/fabric.dart';
import '../../../../core/widgets/app_network_image.dart';

class FabricCardGrid extends ConsumerWidget {
  final bool isGridView;
  final List<Fabric> fabrics;
  const FabricCardGrid({
    super.key,
    required this.isGridView,
    required this.fabrics,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    if (fabrics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.storefront_outlined,
                  color: AppColors.amber.withValues(alpha: 0.5),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No fabrics found',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Try a different category or check back later.',
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (isGridView) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.65,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: fabrics.length,
        itemBuilder: (context, index) =>
            _FabricTallCard(fabric: fabrics[index]),
      );
    } else {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: fabrics.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) =>
            _FabricListTile(fabric: fabrics[index]),
      );
    }
  }
}

class _FabricTallCard extends ConsumerWidget {
  final Fabric fabric;
  const _FabricTallCard({required this.fabric});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return InkWell(
      onTap: () {
        ref.pushShell('/fabric-details', {'fabricId': fabric.id});
      },
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colors.overlayLight,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: fabric.imageUrls.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            child: AppNetworkImage(
                              url: fabric.imageUrls.first,
                              fit: BoxFit.cover,
                            ),
                          )
                        : _buildFallbackImage(fabric.category),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.scaffoldBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        fabric.category.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.amber,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\u20A6${fabric.pricePerYard.toStringAsFixed(0)} / yd',
                    style: const TextStyle(
                      color: AppColors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    fabric.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: colors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fabric.composition ?? 'Premium Material',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 10,
                        color: AppColors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${fabric.origin ?? 'GLOBAL'} \u2022 ${fabric.stockQuantity.toInt()}yd left',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (fabric.origin != null || fabric.composition != null)
                    Text(
                      [
                        fabric.origin,
                        fabric.composition,
                      ].where((e) => e != null).join(' \u2022 '),
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackImage(String category) {
    final asset = FabricImages.getAsset(category);
    if (asset != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Image.asset(asset, fit: BoxFit.cover, width: double.infinity),
      );
    }
    return Container(
      color: AppColors.amber.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          FabricImages.getIcon(category),
          color: AppColors.amber,
          size: 48,
        ),
      ),
    );
  }
}

class _FabricListTile extends ConsumerWidget {
  final Fabric fabric;
  const _FabricListTile({required this.fabric});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return InkWell(
      onTap: () {
        ref.pushShell('/fabric-details', {'fabricId': fabric.id});
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.overlayLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: fabric.imageUrls.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AppNetworkImage(
                        url: fabric.imageUrls.first,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Builder(
                      builder: (context) {
                        final asset = FabricImages.getAsset(fabric.category);
                        return asset != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(asset, fit: BoxFit.cover),
                              )
                            : Icon(
                                FabricImages.getIcon(fabric.category),
                                color: AppColors.amber,
                              );
                      },
                    ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fabric.name.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: colors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    [
                      fabric.origin,
                      fabric.composition,
                    ].whereType<String>().join(' \u2022 '),
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\u20A6${fabric.pricePerYard.toInt()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.amber,
                    fontSize: 20,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'PER YARD',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: colors.textMuted,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
