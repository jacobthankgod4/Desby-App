import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import '../../domain/entities/notification.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/shell_app_bar.dart';

class NotificationCenterPage extends ConsumerWidget {
  const NotificationCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(
        context,
        title: 'Notifications',
        actions: [
          TextButton(
            onPressed: () async {
              final user = ref.read(currentUserProvider);
              if (user != null) {
                await ref.read(markAllAsReadProvider(user.id).future);
                ref.invalidate(notificationsProvider);
              }
            },
            child: const Text(
              'Mark all read',
              style: TextStyle(color: AppColors.amber, fontSize: 12),
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) => notifications.isEmpty
            ? _buildEmptyState(context)
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _NotificationCard(notification: notification);
                },
              ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
        error: (error, _) => _buildErrorState(context, ref),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_outlined,
              size: 48,
              color: AppColors.amber.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 18,
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No notifications yet',
            style: TextStyle(fontSize: 13, color: colors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_rounded,
              size: 48,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'NOTIFICATIONS UNAVAILABLE',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notifications will appear here once set up',
            style: TextStyle(fontSize: 13, color: colors.textMuted),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(notificationsProvider),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text(
              'RETRY',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: AppColors.darkNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: notification.isRead
            ? colors.surface
            : AppColors.amber.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead
              ? colors.borderDefault
              : AppColors.amber.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getIconColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_getIcon(), color: _getIconColor(), size: 20),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w900,
            fontSize: 13,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              '${notification.timestamp.hour}:${notification.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 11, color: colors.textMuted),
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.amber,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.orderUpdate:
        return Icons.shopping_bag_outlined;
      case NotificationType.newMessage:
        return Icons.chat_bubble_outline;
      case NotificationType.apprenticeTask:
        return Icons.school_outlined;
      case NotificationType.paymentReceived:
        return Icons.payments_outlined;
      case NotificationType.clientInvite:
        return Icons.person_add_outlined;
      case NotificationType.system:
        return Icons.settings_outlined;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case NotificationType.orderUpdate:
        return Colors.blueAccent;
      case NotificationType.newMessage:
        return AppColors.successGreen;
      case NotificationType.apprenticeTask:
        return AppColors.amber;
      case NotificationType.paymentReceived:
        return Colors.purpleAccent;
      case NotificationType.clientInvite:
        return AppColors.amber;
      case NotificationType.system:
        return AppColors.textMuted;
    }
  }
}
