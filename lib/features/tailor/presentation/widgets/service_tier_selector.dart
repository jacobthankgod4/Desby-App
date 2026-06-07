import 'package:flutter/material.dart';
import '../../domain/entities/service_tier.dart';
import '../../../../theme/colors.dart';

/// Service Tier Selector Widget
/// Adapted from Uber ride type chips (UberX, Select, Black, UberBAG)
/// Dimensions: 126w × 54h × 27r, Gap: 26px
class ServiceTierSelector extends StatelessWidget {
  final ServiceTier? selectedTier;
  final Function(ServiceTier) onSelected;
  final List<ServiceTier> availableTiers;

  const ServiceTierSelector({
    super.key,
    required this.selectedTier,
    required this.onSelected,
    this.availableTiers = ServiceTier.values,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 36),
        itemCount: availableTiers.length,
        separatorBuilder: (_, _) => const SizedBox(width: 26),
        itemBuilder: (context, index) {
          final tier = availableTiers[index];
          final isSelected = tier == selectedTier;
          return _ServiceTierChip(
            tier: tier,
            isSelected: isSelected,
            onTap: () => onSelected(tier),
          );
        },
      ),
    );
  }
}

/// Individual Service Tier Chip
class _ServiceTierChip extends StatelessWidget {
  final ServiceTier tier;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceTierChip({
    required this.tier,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 126,
        height: 54,
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(27),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon for tier
            Icon(
              _getTierIcon(tier),
              size: 18,
              color: isSelected ? Colors.white : Colors.black,
            ),
            const SizedBox(height: 2),
            // Tier name
            Text(
              tier.displayName,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTierIcon(ServiceTier tier) {
    switch (tier) {
      case ServiceTier.custom:
        return Icons.checkroom_rounded;
      case ServiceTier.readyToWear:
        return Icons.content_cut_rounded;
      case ServiceTier.bridal:
        return Icons.celebration_rounded;
      case ServiceTier.menswear:
        return Icons.face_rounded;
      case ServiceTier.womenswear:
        return Icons.face_2_rounded;
    }
  }
}

/// Service tier info tile (shown in panel)
class ServiceTierInfoTile extends StatelessWidget {
  final ServiceTier tier;
  final double startingPrice;
  final bool isSelected;
  final VoidCallback onTap;

  const ServiceTierInfoTile({
    super.key,
    required this.tier,
    required this.startingPrice,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.amber.withValues(alpha: 0.1) : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.amber : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.amber : Colors.white12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getTierIcon(tier),
                color: isSelected ? AppColors.darkNavy : AppColors.textMuted,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Name and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tier.displayName,
                    style: TextStyle(
                      color: isSelected ? AppColors.amber : AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tier.description,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₦${startingPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: isSelected ? AppColors.amber : AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '~${tier.defaultTurnaroundDays} days',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTierIcon(ServiceTier tier) {
    switch (tier) {
      case ServiceTier.custom:
        return Icons.checkroom_rounded;
      case ServiceTier.readyToWear:
        return Icons.content_cut_rounded;
      case ServiceTier.bridal:
        return Icons.celebration_rounded;
      case ServiceTier.menswear:
        return Icons.face_rounded;
      case ServiceTier.womenswear:
        return Icons.face_2_rounded;
    }
  }
}
