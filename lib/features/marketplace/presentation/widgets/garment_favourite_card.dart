import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/app_network_image.dart';

/// Garment Favourite Card Widget
/// Displays a saved Ready-to-Wear garment card in favorites grid
class GarmentFavouriteCard extends StatelessWidget {
  final Map<String, dynamic> garment;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const GarmentFavouriteCard({
    super.key,
    required this.garment,
    this.onTap,
    this.onRemove,
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
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child:
                        garment['imageUrl'] != null &&
                            garment['imageUrl'].toString().isNotEmpty
                        ? AppNetworkImage(
                            url: garment['imageUrl'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : Container(
                            color: colors.surfaceHover,
                            child: Center(
                              child: Icon(
                                Icons.checkroom_rounded,
                                color: colors.textMuted,
                                size: 32,
                              ),
                            ),
                          ),
                  ),
                  // Remove button
                  if (onRemove != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colors.scaffoldBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  // Availability badge
                  if (garment['isAvailable'] == false)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'SOLD',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info section
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Garment type
                  Text(
                    (garment['garmentType'] ?? 'Style')
                        .toString()
                        .toUpperCase(),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Tailor name
                  Text(
                    garment['tailorName'] ?? 'Tailor',
                    style: TextStyle(color: colors.textMuted, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Price
                  Text(
                    _formatPrice(garment['price']),
                    style: const TextStyle(
                      color: AppColors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '\u20A60';
    double parsed;
    if (price is double) {
      parsed = price;
    } else {
      parsed = double.tryParse(price.toString()) ?? 0.0;
    }
    // Use intl NumberFormat for proper currency formatting
    final formatter = NumberFormat.currency(
      locale: 'en_NG',
      symbol: '\u20A6',
      decimalDigits: 0,
    );
    return formatter.format(parsed);
  }
}

/// Garment Favourite Card - Grid Variant (Horizontal layout for lists)
class GarmentFavouriteListCard extends StatelessWidget {
  final Map<String, dynamic> garment;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const GarmentFavouriteListCard({
    super.key,
    required this.garment,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            // Image thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 70,
                height: 70,
                child:
                    garment['imageUrl'] != null &&
                        garment['imageUrl'].toString().isNotEmpty
                    ? AppNetworkImage(
                        url: garment['imageUrl'],
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: colors.surfaceHover,
                        child: Icon(
                          Icons.checkroom_rounded,
                          color: colors.textMuted,
                          size: 24,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (garment['garmentType'] ?? 'Style')
                        .toString()
                        .toUpperCase(),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        color: colors.textMuted,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          garment['tailorName'] ?? 'Tailor',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatPrice(garment['price']),
                    style: const TextStyle(
                      color: AppColors.amber,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            // Remove button
            if (onRemove != null)
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.favorite, color: Colors.red, size: 20),
              )
            else
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.amber,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '\u20A60';
    double parsed;
    if (price is double) {
      parsed = price;
    } else {
      parsed = double.tryParse(price.toString()) ?? 0.0;
    }
    // Use intl NumberFormat for proper currency formatting
    final formatter = NumberFormat.currency(
      locale: 'en_NG',
      symbol: '\u20A6',
      decimalDigits: 0,
    );
    return formatter.format(parsed);
  }
}
