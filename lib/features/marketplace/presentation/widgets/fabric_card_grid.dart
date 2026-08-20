import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../domain/entities/fabric.dart';

class FabricCardGrid extends ConsumerWidget {
  final bool isGridView;
  final List<Fabric> fabrics;
  const FabricCardGrid({super.key, required this.isGridView, required this.fabrics});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (fabrics.isEmpty) {
      return const Center(child: Text('EMPTY CATALOG', style: TextStyle(color: Colors.white12, fontWeight: FontWeight.w900, fontSize: 32)));
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
        itemBuilder: (context, index) => _FabricTallCard(fabric: fabrics[index]),
      );
    } else {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: fabrics.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) => _FabricListTile(fabric: fabrics[index]),
      );
    }
  }
}

class _FabricTallCard extends ConsumerWidget {
  final Fabric fabric;
  const _FabricTallCard({required this.fabric});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        ref.pushShell(
          '/fabric-details',
          {'fabricId': fabric.id},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
          ],
          border: Border.all(color: Colors.white10),
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
                      color: Colors.black26,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: fabric.imageUrls.isNotEmpty 
                      ? ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), child: Image.network(fabric.imageUrls.first, fit: BoxFit.cover))
                      : const Center(child: Icon(Icons.texture_rounded, color: AppColors.amber, size: 60)),
                  ),
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.darkNavy, borderRadius: BorderRadius.circular(8)),
                      child: Text(fabric.category.toUpperCase(), style: const TextStyle(color: AppColors.amber, fontSize: 8, fontWeight: FontWeight.w900)),
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
                  Text('₦${fabric.pricePerYard.toStringAsFixed(0)} / yd', style: const TextStyle(color: AppColors.amber, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  Text(fabric.name.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(fabric.composition ?? 'Premium Material', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 10, color: AppColors.amber),
                      const SizedBox(width: 4),
                      Text('${fabric.origin ?? 'GLOBAL'} • ${fabric.stockQuantity.toInt()}yd left', style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: const Text('VERIFIED MERCHANT', style: TextStyle(color: Color(0xFF00FF7F), fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 1)),
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

class _FabricListTile extends ConsumerWidget {
  final Fabric fabric;
  const _FabricListTile({required this.fabric});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        ref.pushShell(
          '/fabric-details',
          {'fabricId': fabric.id},
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(16)),
              child: fabric.imageUrls.isNotEmpty 
                ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(fabric.imageUrls.first, fit: BoxFit.cover))
                : const Icon(Icons.texture_rounded, color: AppColors.amber),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fabric.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13)),
                  Text('${fabric.origin} • ${fabric.composition}', style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₦${fabric.pricePerYard.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.amber, fontSize: 20, letterSpacing: -0.5)),
                const Text('PER YARD', style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(width: 16),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white12, size: 14),
          ],
        ),
      ),
    );
  }
}
