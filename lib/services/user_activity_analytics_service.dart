import 'package:get/get.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class IUserActivityAnalyticsService {
  Future<Result<void>> recordUserActivity(String userId, String activityType, Map<String, dynamic> data);
  Future<Result<Map<String, dynamic>>> getActivityStats(String userId);
  Future<Result<List<Map<String, dynamic>>>> getUserActivityHistory(String userId, {int limit = 50});
}

class UserActivityAnalyticsService implements IUserActivityAnalyticsService {
  late final UnifiedDatabaseService _databaseService;

  UserActivityAnalyticsService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize UserActivityAnalyticsService: $e');
    }
  }

  @override
  Future<Result<void>> recordUserActivity(String userId, String activityType, Map<String, dynamic> data) async {
    try {
      final activityId = 'activity_${DateTime.now().millisecondsSinceEpoch}';
      
      final activityData = {
        'activityId': activityId,
        'userId': userId,
        'type': activityType,
        ...data,
        'recordedAt': DateTime.now().toIso8601String(),
      };

      final result = await _databaseService.createPath(
        'userActivities/$userId/$activityId',
        activityData,
      );

      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to record activity: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getActivityStats(String userId) async {
    try {
      final result = await _databaseService.readPath('userActivities/$userId');
      
      if (result.isSuccess() && result.data is Map<String, dynamic>) {
        final data = result.data as Map<String, dynamic>;
        final activities = data.values.whereType<Map<String, dynamic>>().toList();

        final stats = <String, int>{};
        for (var activity in activities) {
          final type = activity['type'] as String?;
          if (type != null) {
            stats[type] = (stats[type] ?? 0) + 1;
          }
        }

        return Result.success({
          'totalActivities': activities.length,
          'types': stats,
        });
      }

      return Result.success({'totalActivities': 0, 'types': {}});
    } catch (e) {
      return Result.failure(Exception('Failed to get activity stats: $e'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getUserActivityHistory(String userId, {int limit = 50}) async {
    try {
      final result = await _databaseService.readPath('userActivities/$userId');
      
      if (result.isSuccess() && result.data is Map<String, dynamic>) {
        final data = result.data as Map<String, dynamic>;
        final activities = data.values
            .whereType<Map<String, dynamic>>()
            .toList();

        // Sort by recordedAt descending
        activities.sort((a, b) {
          final aDate = DateTime.tryParse(a['recordedAt']?.toString() ?? '');
          final bDate = DateTime.tryParse(b['recordedAt']?.toString() ?? '');
          if (aDate == null || bDate == null) return 0;
          return bDate.compareTo(aDate);
        });

        return Result.success(activities.take(limit).toList());
      }

      return Result.success([]);
    } catch (e) {
      return Result.failure(Exception('Failed to get activity history: $e'));
    }
  }
}
