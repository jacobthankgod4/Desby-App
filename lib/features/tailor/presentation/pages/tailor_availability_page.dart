import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';

class TailorAvailabilityPage extends ConsumerWidget {
  final Map<String, dynamic> tailor;

  const TailorAvailabilityPage({super.key, required this.tailor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Appointments',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: MediaQuery.of(context).size.width <= 1000,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => ref.popShell(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildAvailabilityCard(
            context: context,
            status: 'Offline',
            statusColor: colors.statusError,
            actionLabel: 'Get Directions',
            actionIcon: Icons.directions_rounded,
            onAction: () {},
          ),
          const SizedBox(height: 24),
          _buildAvailabilityCard(
            context: context,
            status: 'Online',
            statusColor: Colors.greenAccent,
            showSecondAction: true,
            actionLabel: 'Call',
            actionIcon: Icons.phone_rounded,
            secondActionLabel: 'Book Appointment',
            secondActionIcon: Icons.calendar_today_rounded,
            onAction: () {},
            onSecondAction: () => ref.pushShell('/booking-cart', tailor),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityCard({
    required BuildContext context,
    required String status,
    required Color statusColor,
    required String actionLabel,
    required IconData actionIcon,
    required VoidCallback onAction,
    bool showSecondAction = false,
    String? secondActionLabel,
    IconData? secondActionIcon,
    VoidCallback? onSecondAction,
  }) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.amber,
                child: Text(
                  (tailor['name'] ?? 'T')[0].toString().toUpperCase(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors.scaffoldBg,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tailor['name'] ?? 'Tailor Name',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      tailor['location'] ?? 'Shop Address',
                      style: TextStyle(color: colors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: colors.borderDefault),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.phone_outlined,
                color: AppColors.amber,
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                tailor['phone'] ?? '+234 800 000 0000',
                style: TextStyle(color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                color: AppColors.amber,
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                '09:00 AM - 06:00 PM',
                style: TextStyle(color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAction,
                  icon: Icon(actionIcon, size: 18),
                  label: Text(actionLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: showSecondAction
                        ? colors.surface
                        : AppColors.amber,
                    foregroundColor: showSecondAction
                        ? colors.textPrimary
                        : colors.scaffoldBg,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              if (showSecondAction) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onSecondAction,
                    icon: Icon(secondActionIcon!, size: 18),
                    label: Text(secondActionLabel!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: colors.scaffoldBg,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
