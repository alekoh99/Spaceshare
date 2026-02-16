import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/app_colors.dart';
import '../../providers/notification_controller.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final notificationController = Get.find<NotificationController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notificationController.loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Obx(() {
        if (notificationController.isLoadingNotifications.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
            ),
          );
        }

        if (notificationController.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                const Text(
                  'No notifications',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => notificationController.loadNotifications(),
          backgroundColor: AppColors.cyan,
          color: AppColors.darkBg,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notificationController.notifications.length,
            itemBuilder: (context, index) {
              final notif = notificationController.notifications[index];
              return Dismissible(
                key: Key(notif.id ?? index.toString()),
                onDismissed: (_) {
                  notificationController.deleteNotification(notif.id ?? '');
                },
                child: ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.darkBg2,
                      border: Border.all(color: AppColors.cyan, width: 1),
                    ),
                    child: Icon(
                      _getIconForType(notif.type ?? ''),
                      color: AppColors.cyan,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    notif.title ?? 'Notification',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    notif.body ?? '',
                    style: const TextStyle(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(notif.createdAt),
                        style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                      if (notif.isRead == false)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.cyan,
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    notificationController.markAsRead(notif.id ?? '');
                  },
                ),
              );
            },
          ),
        );
      }),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'match':
        return Icons.favorite;
      case 'message':
        return Icons.message;
      case 'payment':
        return Icons.check_circle;
      case 'verification':
        return Icons.verified;
      case 'dispute':
        return Icons.warning;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) return 'now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    
    return '${timestamp.month}/${timestamp.day}';
  }
}
