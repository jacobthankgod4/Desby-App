import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/fabric.dart';
import '../providers/fabric_provider.dart';
import '../../../../core/widgets/app_network_image.dart';

class SellerInventoryPage extends ConsumerWidget {
  const SellerInventoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: Text('User not found'));

    final inventoryAsync = ref.watch(sellerInventoryProvider(user.id));

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: inventoryAsync.when(
        data: (fabrics) => fabrics.isEmpty
            ? _buildEmptyState(context)
            : _buildInventoryList(context, fabrics, ref),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: colors.textMuted,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'INVENTORY UNAVAILABLE',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check your connection and try again.',
                style: TextStyle(color: colors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.pushShell('/fabric-upload'),
        backgroundColor: AppColors.amber,
        child: Icon(Icons.add_rounded, color: context.colors.textOnAmber),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: colors.textMuted),
          const SizedBox(height: 24),
          Text(
            'NO FABRIC UPLOADED',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your digital shelf is empty.',
            style: TextStyle(color: colors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryList(
    BuildContext context,
    List<Fabric> fabrics,
    WidgetRef ref,
  ) {
    final colors = context.colors;
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: fabrics.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final fabric = fabrics[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: fabric.imageUrls.isNotEmpty
                    ? AppNetworkImage(
                        url: fabric.imageUrls.first,
                        fit: BoxFit.cover,
                        width: 80,
                        height: 80,
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: colors.borderSubtle,
                        child: Icon(
                          Icons.texture_rounded,
                          color: colors.textMuted,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fabric.name.toUpperCase(),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${fabric.stockQuantity} yds remaining',
                      style: TextStyle(
                        color: fabric.stockQuantity < 5
                            ? colors.statusError
                            : colors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\u20A6${fabric.pricePerYard.toStringAsFixed(0)}/yd',
                      style: TextStyle(
                        color: AppColors.amber,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: colors.textMuted,
                      size: 20,
                    ),
                    onPressed: () {
                      ref.pushShell('/fabric-upload', {'fabric': fabric});
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    onPressed: () => _confirmDelete(context, ref, fabric.id),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String fabricId,
  ) async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.dialogBg,
        title: Text(
          'DELETE FABRIC?',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          'This action cannot be undone and will remove the material from the marketplace.',
          style: TextStyle(color: colors.textMuted, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'DELETE',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await ref
          .read(fabricRepositoryProvider)
          .deleteFabric(fabricId);
      if (!context.mounted) return;
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete fabric. Please try again.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        },
        (_) {
          ref.invalidate(
            sellerInventoryProvider(ref.read(currentUserProvider)?.id ?? ''),
          );
          ref.invalidate(fabricCatalogProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fabric deleted'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        },
      );
    }
  }
}
