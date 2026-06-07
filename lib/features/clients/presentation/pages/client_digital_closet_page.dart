import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../orders/presentation/providers/order_provider.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../theme/colors.dart';

/// Client Digital Closet (shell-safe)
///
/// Non-destructive contract: This widget is rendered inside `DesktopDashboardShell`
/// and MUST NOT push new routes.
class ClientDigitalClosetPage extends ConsumerWidget {
  const ClientDigitalClosetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider(null));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saved Garment Assets',
            style: TextStyle(
              color: AppColors.amber,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
Text(
            'Your saved garment assets and recent snapshots.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 28),
          ordersAsync.when(
            data: (orders) {
              final active = orders
                  .where((o) => o.materialAssetUrl != null && o.materialAssetUrl!.isNotEmpty)
                  .toList();

              if (active.isEmpty) {
                return const _EmptyState();
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: 0.95,
                ),
                itemCount: active.length,
                itemBuilder: (context, index) {
                  final order = active[index];
                  final garmentType = order.items.isNotEmpty ? order.items.first.garmentType : 'Garment';

                  return _ClosetAssetCard(
                    garmentType: garmentType,
                    status: order.status.displayName,
                    imageUrl: order.materialAssetUrl,
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
            error: (err, _) => const ErrorStateWidget(message: 'Failed to load closet assets.'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          'CLOSET EMPTY',
          style: TextStyle(color: Colors.white12, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2),
        ),
      ),
    );
  }
}

class _ClosetAssetCard extends StatelessWidget {
  final String garmentType;
  final String status;
  final String? imageUrl;

  const _ClosetAssetCard({
    required this.garmentType,
    required this.status,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.black26,
        image: imageUrl != null && imageUrl!.isNotEmpty
            ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              garmentType.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.2)),
              ),
              child: Text(
                status.toUpperCase(),
                style: const TextStyle(color: AppColors.amber, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

