import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';
import '../../domain/entities/fabric.dart';
import '../../../../core/widgets/app_network_image.dart';

/// Fabric Card Widget
///
/// Displays a fabric item with image, name, price, and stock information.
class FabricCard extends StatelessWidget {
  final Fabric fabric;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;

  const FabricCard({
    super.key,
    required this.fabric,
    this.onTap,
    this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: fabric.imageUrls.isNotEmpty
                        ? AppNetworkImage(
                            url: fabric.imageUrls.first,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                        : _buildPlaceholder(context),
                  ),
                  if (onFavorite != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onFavorite,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: context.colors.scaffoldBg.withValues(
                              alpha: 0.7,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.favorite_border,
                            color: colors.textPrimary,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  if (fabric.stockQuantity < 10)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.statusError,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Only a few left',
                          style: TextStyle(
                            color: colors.textPrimary,
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
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fabric.name.toUpperCase(),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\u20A6${fabric.pricePerYard.toStringAsFixed(0)}/yd',
                        style: const TextStyle(
                          color: AppColors.amber,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${fabric.stockQuantity.toInt()} yds',
                        style: TextStyle(
                          color: fabric.stockQuantity < 5
                              ? colors.statusError
                              : colors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
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

  Widget _buildPlaceholder(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: colors.borderSubtle,
      child: Icon(Icons.texture_rounded, color: colors.textMuted, size: 48),
    );
  }
}
