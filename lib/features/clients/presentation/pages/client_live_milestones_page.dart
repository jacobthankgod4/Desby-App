import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../orders/presentation/providers/order_provider.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../theme/colors.dart';

/// Client Live Milestones (shell-safe)
///
/// NOTE:
/// Desktop shell (`DesktopDashboardShell`) renders this widget via index selection.
/// This page MUST NOT push new routes.
class ClientLiveMilestonesPage extends ConsumerWidget {
  const ClientLiveMilestonesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    // ordersProvider(null) is used elsewhere in ClientDashboard.
    final ordersAsync = ref.watch(ordersProvider(null));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Updates',
            style: TextStyle(
              color: AppColors.amber,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your active projects and the latest status updates.',
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

              return Column(
                children: active.map((order) {
                  final garmentType = order.items.isNotEmpty ? order.items.first.garmentType : 'Garment';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _MilestoneCard(
                      title: garmentType.toUpperCase(),
                      subtitle: 'ESTABLISHED: ${order.createdAt.toLocal().toString().split(' ').first.toUpperCase()}',
                      status: order.status.displayName,
                      // If more milestone details exist, extend here.
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
            error: (err, _) => const ErrorStateWidget(message: 'Failed to sync live milestones.'),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          'NO ACTIVE MILESTONES',
          style: TextStyle(color: Colors.white12, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2),
        ),
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;

  const _MilestoneCard({required this.title, required this.subtitle, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.checkroom_rounded, color: AppColors.amber, size: 24),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
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
    );
  }
}

