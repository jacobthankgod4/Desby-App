import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../features/designs/domain/entities/design.dart';
import '../../theme/colors.dart';
import 'app_network_image.dart';

class DesignCardPublic extends StatelessWidget {
  final Design design;
  final VoidCallback onTap;

  const DesignCardPublic({
    super.key,
    required this.design,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.containerFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.shimmerBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (design.imageUrls.isNotEmpty)
                    AppNetworkImage(
                      url: design.imageUrls.first,
                      fit: BoxFit.cover,
                      placeholderIcon: Icons.checkroom_rounded,
                    )
                  else
                    _buildPlaceholder(colors),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        design.category.toUpperCase(),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          design.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₦${_formatPrice(design.price)}',
                        style: const TextStyle(
                          color: AppColors.amber,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 9,
                        backgroundColor: AppColors.amber.withValues(alpha: 0.2),
                        backgroundImage: design.tailorAvatarUrl != null
                            ? NetworkImage(design.tailorAvatarUrl!)
                            : null,
                        child: design.tailorAvatarUrl == null
                            ? Text(
                                design.tailorName.isNotEmpty
                                    ? design.tailorName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppColors.amber,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          design.tailorName,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.favorite_border_rounded,
                        color: Colors.redAccent.withValues(alpha: 0.7),
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${design.likesCount}',
                        style: TextStyle(color: colors.textMuted, fontSize: 10),
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

  Widget _buildPlaceholder(DesbyThemeColors colors) {
    return Container(
      color: colors.containerFill,
      child: Center(
        child: Icon(Icons.checkroom_rounded, color: colors.iconMuted, size: 48),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return NumberFormat('#,##0').format(price.toInt());
    }
    return price.toInt().toString();
  }
}
