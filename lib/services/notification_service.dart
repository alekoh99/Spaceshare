import 'package:get/get.dart';
import '../models/supporting_models.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class INotificationService {
  Future<Result> sendNotification(Notification notification);
  Stream<List<Notification>>? getNotificationStream(String userId);
  Future<Result> markAsRead(String notificationId);
  Future<Result> deleteNotification(String notificationId);
  Future<Result> getNotifications(String userId, {int limit = 50});
  Future<Result> getUnreadCount(String userId);
  Future<Result> markAllAsRead(String userId);
  Future<Result> subscribeToTopic(String topic);
  Future<Result> unsubscribeFromTopic(String topic);
}

class NotificationService implements INotificationService {
  late final UnifiedDatabaseService _databaseService;

  NotificationService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize NotificationService: $e');
    }
  }

  @override
  Future<Result> sendNotification(Notification notification) async {
    try {
      final result = await _databaseService.createPath(
        'notifications/${notification.userId}/${notification.notificationId}',
        notification.toJson(),
      );

      if (result.isSuccess()) {
        return Result.success(notification.notificationId);
      } else {
        return Result.failure(result.exception ?? Exception('Failed to send notification'));
      }
    } catch (e) {
      return Result.failure(Exception('Error sending notification: $e'));
    }
  }

  @override
  Stream<List<Notification>>? getNotificationStream(String userId) {
    try {
      // This would return a real-time stream in a full implementation
      return Stream.value([]);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Result> markAsRead(String notificationId) async {
    try {
      // In a real implementation, this would update all matching notifications
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('Error marking notification as read: $e'));
    }
  }

  @override
  Future<Result> deleteNotification(String notificationId) async {
    try {
      // In a real implementation, would delete from database
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('Error deleting notification: $e'));
    }
  }

  @override
  Future<Result> getNotifications(String userId, {int limit = 50}) async {
    try {
      final result = await _databaseService.readPath('notifications/$userId');

      if (result.isSuccess() && result.data != null) {
        final notificationsData = Map<String, dynamic>.from(result.data!);
        final notifications = <Notification>[];

        notificationsData.forEach((key, value) {
          try {
            final notifData = Map<String, dynamic>.from(value as Map);
            final createdAtStr = notifData['createdAt'] as dynamic;
            final readAtStr = notifData['readAt'] as dynamic?;

            final notification = Notification(
              notificationId: notifData['notificationId'] ?? key,
              userId: notifData['userId'] ?? userId,
              type: notifData['type'] ?? 'system',
              title: notifData['title'] ?? '',
              body: notifData['body'] ?? '',
              actionUrl: notifData['actionUrl'] as String?,
              createdAt: _parseDateTime(createdAtStr),
              isRead: notifData['isRead'] ?? false,
              readAt: readAtStr != null ? _parseDateTime(readAtStr) : null,
            );
            notifications.add(notification);
          } catch (e) {
            // Skip notifications that can't be parsed
          }
        });

        // Sort by creation date, most recent first
        notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Limit results
        return Result.success(notifications.take(limit).toList());
      }

      return Result.success([]);
    } catch (e) {
      return Result.failure(Exception('Error fetching notifications: $e'));
    }
  }

  @override
  Future<Result> getUnreadCount(String userId) async {
    try {
      final result = await getNotifications(userId);
      if (result is Success<List<Notification>>) {
        final notifications = result.getOrNull() as List<dynamic>? ?? [];
        final unreadCount = notifications.whereType<Notification>().where((n) => !n.isRead).length;
        return Result.success(unreadCount);
      }
      return Result.success(0);
    } catch (e) {
      return Result.failure(Exception('Error getting unread count: $e'));
    }
  }

  @override
  Future<Result> markAllAsRead(String userId) async {
    try {
      final result = await getNotifications(userId);
      if (result is Success<List<Notification>>) {
        final notifications = result.getOrNull() as List<dynamic>? ?? [];
        for (final notif in notifications) {
          if (notif is Notification && !notif.isRead) {
            await _databaseService.updatePath(
              'notifications/$userId/${notif.notificationId}',
              {'isRead': true, 'readAt': DateTime.now().toIso8601String()},
            );
          }
        }
        return Result.success(null);
      }
      return Result.failure(Exception('Failed to mark all as read'));
    } catch (e) {
      return Result.failure(Exception('Error marking all as read: $e'));
    }
  }

  @override
  Future<Result> subscribeToTopic(String topic) async {
    try {
      // Implementation for topic subscription
      // In a real implementation, this would subscribe to FCM topic or similar
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('Error subscribing to topic: $e'));
    }
  }

  @override
  Future<Result> unsubscribeFromTopic(String topic) async {
    try {
      // Implementation for topic unsubscription
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('Error unsubscribing from topic: $e'));
    }
  }

  DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }
}
