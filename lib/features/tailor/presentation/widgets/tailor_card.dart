import 'package:flutter/material.dart';
import '../providers/tailor_finder_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/app_network_image.dart';

/// Tailor card widget - modern, beautifully designed
/// Amber highlight when selected with premium styling
class TailorCard extends StatelessWidget {
  final TailorMarker tailor;
  final bool isSelected;
  final VoidCallback onTap;
  final int? distanceMinutes;

  const TailorCard({
    super.key,
    required this.tailor,
    required this.isSelected,
    required this.onTap,
    this.distanceMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.amber : colors.borderSubtle,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.amber.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Full background image
              Container(
                color: AppColors.deepBlue,
                child: tailor.profileImage != null
                    ? AppNetworkImage(
                        url: tailor.profileImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : _buildPlaceholder(),
              ),
              // Gradient overlay for text readability
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, context.colors.scaffoldBg],
                    ),
                  ),
                ),
              ),
              // Text content at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tailor.name.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          color: context.colors.textPrimary,
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
                            '₦${_formatPrice(tailor.startingPrice)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppColors.amber,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (distanceMinutes != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: context.colors.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.near_me_rounded,
                                    size: 9,
                                    color: AppColors.amber,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${distanceMinutes}min',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Premium badge - only when selected
              if (isSelected)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 12,
                          color: colors.textOnAmber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'SELECTED',
                          style: TextStyle(
                            color: colors.textOnAmber,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.deepBlue,
      child: Center(
        child: Icon(Icons.content_cut, size: 40, color: AppColors.textMuted),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      final formatted = price.toStringAsFixed(0);
      final result = StringBuffer();
      for (int i = 0; i < formatted.length; i++) {
        if (i > 0 && (formatted.length - i) % 3 == 0) {
          result.write(',');
        }
        result.write(formatted[i]);
      }
      return result.toString();
    }
    return price.toStringAsFixed(0);
  }
}
