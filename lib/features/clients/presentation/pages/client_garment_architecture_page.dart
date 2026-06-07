import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../orders/presentation/providers/order_provider.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../theme/colors.dart';

/// Client Garment Architecture (shell-safe)
///
/// Non-destructive contract: This widget is rendered inside `DesktopDashboardShell`
/// and MUST NOT push new routes.
class ClientGarmentArchitecturePage extends ConsumerWidget {
  const ClientGarmentArchitecturePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider(null));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Design & Fit Plan',
            style: TextStyle(
              color: AppColors.amber,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'A quick view of your active design and fitting plans.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 28),
          ordersAsync.when(
            data: (orders) {
              final active = orders
                  .where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled)
                  .toList();

              if (active.isEmpty) {
                return const _EmptyState();
              }

              // Reuse order item fields to show a lightweight architecture card.
              return Wrap(
                spacing: 18,
                runSpacing: 18,
                children: active.map((order) {
                  final item = order.items.isNotEmpty ? order.items.first : null;
                  final garmentType = item?.garmentType ?? 'Garment';
                  final imageUrl = order.materialAssetUrl;

                  return _ArchitectureCard(
                    garmentType: garmentType,
                    established: order.createdAt.toLocal().toString().split(' ').first.toUpperCase(),
                    status: order.status.displayName,
                    imageUrl: imageUrl,
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
            error: (err, _) => const ErrorStateWidget(message: 'Failed to sync architecture. '),
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
          'NO ACTIVE ARCHITECTURE FOUND',
          style: TextStyle(color: Colors.white12, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2),
        ),
      ),
    );
  }
}

class _ArchitectureCard extends StatelessWidget {
  final String garmentType;
  final String established;
  final String status;
  final String? imageUrl;

  const _ArchitectureCard({
    required this.garmentType,
    required this.established,
    required this.status,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.black26,
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
          ),
        ),
        alignment: Alignment.bottomLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${garmentType.toUpperCase()} ARCHITECTURE',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            Text(
              'ESTABLISHED: $established',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

