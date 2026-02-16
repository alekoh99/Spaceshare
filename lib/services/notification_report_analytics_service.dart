import 'package:get/get.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class INotificationReportAnalyticsService {
  Future<Result<void>> recordNotificationSent(String userId, String type, String contentId);
  Future<Result<void>> recordNotificationOpened(String notificationId);
  Future<Result<Map<String, dynamic>>> getNotificationStats(String userId);
  Future<Result<List<Map<String, dynamic>>>> getNotificationHistory(String userId);
}

class NotificationReportAnalyticsService implements INotificationReportAnalyticsService {
  late final UnifiedDatabaseService _databaseService;

  NotificationReportAnalyticsService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize NotificationReportAnalyticsService: $e');
    }
  }

  @override
  Future<Result<void>> recordNotificationSent(String userId, String type, String contentId) async {
    try {
      final notificationId = 'notif_${DateTime.now().millisecondsSinceEpoch}';
      
      final notificationData = {
        'notificationId': notificationId,
        'userId': userId,
        'type': type,
        'contentId': contentId,
        'sentAt': DateTime.now().toIso8601String(),
        'openedAt': null,
        'isRead': false,
      };

      final result = await _databaseService.createPath(
        'notifications/$notificationId',
        notificationData,
      );

      if (result.isSuccess()) {
        await _databaseService.updatePath(
          'userNotifications/$userId',
          {notificationId: notificationData},
        );
      }

      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to record notification: $e'));
    }
  }

  @override
  Future<Result<void>> recordNotificationOpened(String notificationId) async {
    try {
      final result = await _databaseService.updatePath(
        'notifications/$notificationId',
        {
          'isRead': true,
          'openedAt': DateTime.now().toIso8601String(),
        },
      );

      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to record notification opened: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getNotificationStats(String userId) async {
    try {
      final result = await _databaseService.readPath('userNotifications/$userId');
      
      if (result.isSuccess() && result.data is Map<String, dynamic>) {
        final data = result.data as Map<String, dynamic>;
        final notifications = data.values.whereType<Map<String, dynamic>>().toList();
        
        final stats = {
          'total': notifications.length,
          'read': notifications.where((n) => n['isRead'] == true).length,
          'unread': notifications.where((n) => n['isRead'] != true).length,
          'types': <String, int>{},
        };

        for (var notif in notifications) {
          final type = notif['type'] as String?;
          if (type != null) {
            stats['types'] = {
              ...stats['types'] as Map<String, int>,
              type: ((stats['types'] as Map?)?[type] as int? ?? 0) + 1,
            };
          }
        }

        return Result.success(stats);
      }

      return Result.success({'total': 0, 'read': 0, 'unread': 0, 'types': {}});
    } catch (e) {
      return Result.failure(Exception('Failed to get notification stats: $e'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getNotificationHistory(String userId) async {
    try {
      final result = await _databaseService.readPath('userNotifications/$userId');
      
      if (result.isSuccess() && result.data is Map<String, dynamic>) {
        final data = result.data as Map<String, dynamic>;
        final notifications = data.values
            .whereType<Map<String, dynamic>>()
            .toList();
        
        // Sort by sentAt descending
        notifications.sort((a, b) {
          final aDate = DateTime.tryParse(a['sentAt']?.toString() ?? '');
          final bDate = DateTime.tryParse(b['sentAt']?.toString() ?? '');
          if (aDate == null || bDate == null) return 0;
          return bDate.compareTo(aDate);
        });

        return Result.success(notifications);
      }

      return Result.success([]);
    } catch (e) {
      return Result.failure(Exception('Failed to get notification history: $e'));
    }
  }
}
