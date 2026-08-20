import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import '../../domain/entities/notification.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/providers/navigation_provider.dart';

class NotificationCenterPage extends ConsumerWidget {
  const NotificationCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 18),
          onPressed: () => ref.popShell(),
        ),
        backgroundColor: AppColors.darkNavy,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () async {
              final user = ref.read(currentUserProvider);
              if (user != null) {
                await ref.read(markAllAsReadProvider(user.id));
                ref.invalidate(notificationsProvider);
              }
            },
            child: const Text('Mark all read', style: TextStyle(color: AppColors.amber, fontSize: 12)),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) => notifications.isEmpty
            ? _buildEmptyState()
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _NotificationCard(notification: notification);
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
        error: (error, _) => _buildErrorState(ref),
      ),
    );
  }

  Widget _buildEmptyState() {
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
            child: Icon(Icons.notifications_none_outlined, size: 48, color: AppColors.amber.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 20),
          const Text('All caught up!', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('No notifications yet', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.4))),
        ],
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref) {
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
            child: const Icon(Icons.notifications_off_rounded, size: 48, color: Colors.redAccent),
          ),
          const SizedBox(height: 20),
          const Text('NOTIFICATIONS UNAVAILABLE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text('Notifications will appear here once set up', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.4))),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(notificationsProvider),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('RETRY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: AppColors.darkNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    return Container(
      decoration: BoxDecoration(
        color: notification.isRead
            ? Colors.white.withValues(alpha: 0.03)
            : AppColors.amber.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead
              ? Colors.white.withValues(alpha: 0.06)
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
            color: Colors.white,
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
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              '${notification.timestamp.hour}:${notification.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3)),
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
      case NotificationType.system:
        return Icons.settings_outlined;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case NotificationType.orderUpdate:
        return Colors.blueAccent;
      case NotificationType.newMessage:
        return const Color(0xFF00FF7F);
      case NotificationType.apprenticeTask:
        return AppColors.amber;
      case NotificationType.paymentReceived:
        return Colors.purpleAccent;
      case NotificationType.system:
        return Colors.white54;
    }
  }
}
