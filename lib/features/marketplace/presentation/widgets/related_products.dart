import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';
import '../../domain/entities/fabric.dart';

/// RelatedProducts - Shows similar fabrics based on category
class RelatedProducts extends StatelessWidget {
  final List<Fabric> relatedFabrics;
  final String currentFabricId;
  final Function(Fabric) onFabricTap;
  
  const RelatedProducts({
    super.key,
    required this.relatedFabrics,
    required this.currentFabricId,
    required this.onFabricTap,
  });

  @override
  Widget build(BuildContext context) {
    // Filter out current fabric
    final filteredFabrics = relatedFabrics
        .where((f) => f.id != currentFabricId)
        .take(4)
        .toList();
    
    if (filteredFabrics.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Text(
          'RELATED PRODUCTS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filteredFabrics.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final fabric = filteredFabrics[index];
              return _RelatedProductCard(
                fabric: fabric,
                onTap: () => onFabricTap(fabric),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RelatedProductCard extends StatelessWidget {
  final Fabric fabric;
  final VoidCallback onTap;
  
  const _RelatedProductCard({
    required this.fabric,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11),
                  ),
                ),
                child: fabric.imageUrls.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(11),
                        ),
                        child: Image.network(
                          fabric.imageUrls.first,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.texture_rounded,
                        color: Colors.grey,
                        size: 40,
                      ),
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fabric.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₦${fabric.pricePerYard.toStringAsFixed(0)}/yd',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.amber,
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
}
