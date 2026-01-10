import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/notification.dart';
import '../../providers/collaboration_providers.dart';
import '../../providers/auth_providers.dart';

/// Icon button with badge for notifications
class NotificationIconButton extends ConsumerWidget {
  const NotificationIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCountAsync = ref.watch(unreadNotificationsCountProvider);

    return unreadCountAsync.when(
      data: (count) => IconButton(
        icon: Badge(
          isLabelVisible: count > 0,
          label: Text(count > 99 ? '99+' : '$count'),
          child: const Icon(Icons.notifications_outlined),
        ),
        onPressed: () => _showNotificationsPanel(context),
        tooltip: 'Notifications',
      ),
      loading: () => IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () => _showNotificationsPanel(context),
        tooltip: 'Notifications',
      ),
      error: (_, __) => IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () => _showNotificationsPanel(context),
        tooltip: 'Notifications',
      ),
    );
  }

  void _showNotificationsPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => NotificationsPanel(
          scrollController: scrollController,
        ),
      ),
    );
  }
}

/// Panel showing all notifications
class NotificationsPanel extends ConsumerWidget {
  final ScrollController scrollController;

  const NotificationsPanel({
    super.key,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _markAllAsRead(ref),
                  child: const Text('Mark all as read'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Notifications list
          Expanded(
            child: notificationsAsync.when(
              data: (notifications) {
                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "You're all caught up!",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  controller: scrollController,
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _NotificationTile(
                      notification: notification,
                      onTap: () => _handleNotificationTap(context, ref, notification),
                      onDismiss: () => _deleteNotification(ref, notification),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAllAsRead(WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await ref.read(notificationRepositoryProvider).markAllAsRead(user.uid);
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    // Mark as read
    if (!notification.isRead) {
      await ref.read(notificationRepositoryProvider).markAsRead(notification.id);
    }

    // Navigate to relevant page
    if (notification.projectId != null && context.mounted) {
      Navigator.pop(context); // Close panel
      context.go('/project/${notification.projectId}/analysis');
    }
  }

  Future<void> _deleteNotification(WidgetRef ref, AppNotification notification) async {
    await ref.read(notificationRepositoryProvider).deleteNotification(notification.id);
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        onTap: onTap,
        tileColor: notification.isRead ? null : Colors.blue.shade50,
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(notification.type).withValues(alpha: 0.2),
          child: Icon(
            _getTypeIcon(notification.type),
            color: _getTypeColor(notification.type),
            size: 20,
          ),
        ),
        title: Text(
          notification.message,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Row(
          children: [
            if (notification.triggeredByUserName != null) ...[
              Text(
                notification.triggeredByUserName!,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              Text(' - ', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
            Text(
              notification.timeAgo,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.statusChange:
        return Icons.swap_horiz;
      case NotificationType.comment:
        return Icons.chat_bubble_outline;
      case NotificationType.mention:
        return Icons.alternate_email;
      case NotificationType.approvalRequest:
        return Icons.pending_actions;
      case NotificationType.approvalReminder:
        return Icons.alarm;
      case NotificationType.projectAssigned:
        return Icons.assignment_ind;
      case NotificationType.documentUploaded:
        return Icons.attach_file;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.statusChange:
        return Colors.purple;
      case NotificationType.comment:
        return Colors.blue;
      case NotificationType.mention:
        return Colors.teal;
      case NotificationType.approvalRequest:
        return Colors.orange;
      case NotificationType.approvalReminder:
        return Colors.red;
      case NotificationType.projectAssigned:
        return Colors.green;
      case NotificationType.documentUploaded:
        return Colors.indigo;
    }
  }
}
