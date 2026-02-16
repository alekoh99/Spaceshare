import 'package:get/get.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class IUserPreferenceLearningService {
  Future<Result<void>> recordUserPreference(String userId, String preferenceKey, dynamic preferenceValue);
  Future<Result<Map<String, dynamic>>> getPredictedPreferences(String userId);
  Future<Result<void>> updatePreferenceWeights(String userId, Map<String, double> weights);
}

class UserPreferenceLearningService implements IUserPreferenceLearningService {
  late final UnifiedDatabaseService _databaseService;

  UserPreferenceLearningService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize UserPreferenceLearningService: $e');
    }
  }

  @override
  Future<Result<void>> recordUserPreference(String userId, String preferenceKey, dynamic preferenceValue) async {
    try {
      final recordId = 'pref_${DateTime.now().millisecondsSinceEpoch}';
      
      final result = await _databaseService.createPath(
        'preferenceRecords/$userId/$recordId',
        {
          'preference': preferenceKey,
          'value': preferenceValue.toString(),
          'recordedAt': DateTime.now().toIso8601String(),
        },
      );

      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to record preference: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getPredictedPreferences(String userId) async {
    try {
      final result = await _databaseService.readPath('userPreferences/$userId');
      
      if (result.isSuccess() && result.data is Map<String, dynamic>) {
        return Result.success(result.data as Map<String, dynamic>);
      }

      return Result.success({});
    } catch (e) {
      return Result.failure(Exception('Failed to get predicted preferences: $e'));
    }
  }

  @override
  Future<Result<void>> updatePreferenceWeights(String userId, Map<String, double> weights) async {
    try {
      final result = await _databaseService.updatePath(
        'preferenceLearning/$userId',
        {
          'weights': weights,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to update preference weights: $e'));
    }
  }
}
