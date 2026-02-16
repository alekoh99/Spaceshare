import 'package:get/get.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class INotificationPreferencesService {
  Future<Result<void>> setPreferences(String userId, Map<String, bool> preferences);
  Future<Result<Map<String, bool>>> getPreferences(String userId);
  Future<Result<void>> updatePreference(String userId, String preferenceKey, bool value);
  Future<Result<void>> updatePreferences(Map<String, dynamic> preferences);
  Future<Result<void>> setQuietHours(String userId, String startTime, String endTime);
  Future<Result<void>> clearQuietHours(String userId);
}

class NotificationPreferencesService implements INotificationPreferencesService {
  late final UnifiedDatabaseService _databaseService;

  NotificationPreferencesService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize NotificationPreferencesService: $e');
    }
  }

  @override
  Future<Result<void>> setPreferences(String userId, Map<String, bool> preferences) async {
    try {
      final result = await _databaseService.createPath(
        'notificationPreferences/$userId',
        {
          ...preferences,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to set preferences: $e'));
    }
  }

  @override
  Future<Result<Map<String, bool>>> getPreferences(String userId) async {
    try {
      final result = await _databaseService.readPath('notificationPreferences/$userId');
      
      if (result.isSuccess() && result.getOrNull() is Map<String, dynamic>) {
        final data = result.getOrNull() as Map<String, dynamic>;
        final preferences = <String, bool>{};
        
        data.forEach((key, value) {
          if (key != 'updatedAt' && value is bool) {
            preferences[key] = value;
          }
        });

        return Result.success(preferences);
      }

      // Return default preferences
      return Result.success({
        'messages': true,
        'matches': true,
        'payments': true,
        'system': true,
        'marketing': false,
      });
    } catch (e) {
      return Result.failure(Exception('Failed to get preferences: $e'));
    }
  }

  @override
  Future<Result<void>> updatePreference(String userId, String preferenceKey, bool value) async {
    try {
      final result = await _databaseService.updatePath(
        'notificationPreferences/$userId',
        {
          preferenceKey: value,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to update preference: $e'));
    }
  }

  @override
  Future<Result<void>> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      // Assuming preferences contains userId
      final userId = preferences['userId'] ?? '';
      if (userId.isEmpty) {
        return Result.failure(Exception('userId required in preferences'));
      }

      final prefs = Map<String, dynamic>.from(preferences)..remove('userId');
      prefs['updatedAt'] = DateTime.now().toIso8601String();

      final result = await _databaseService.updatePath(
        'notificationPreferences/$userId',
        prefs,
      );
      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to update preferences: $e'));
    }
  }

  @override
  Future<Result<void>> setQuietHours(String userId, String startTime, String endTime) async {
    try {
      final result = await _databaseService.updatePath(
        'notificationPreferences/$userId',
        {
          'quietHoursStart': startTime,
          'quietHoursEnd': endTime,
          'quietHoursEnabled': true,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to set quiet hours: $e'));
    }
  }

  @override
  Future<Result<void>> clearQuietHours(String userId) async {
    try {
      final result = await _databaseService.updatePath(
        'notificationPreferences/$userId',
        {
          'quietHoursEnabled': false,
          'quietHoursStart': null,
          'quietHoursEnd': null,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to clear quiet hours: $e'));
    }
  }
}
