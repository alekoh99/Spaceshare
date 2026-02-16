import 'package:get/get.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class IRecommendedMatchesService {
  Future<Result<List<Map<String, dynamic>>>> getRecommendedMatches(String userId);
  Future<Result<void>> updateMatchRecommendations(String userId);
}

class RecommendedMatchesService implements IRecommendedMatchesService {
  late final UnifiedDatabaseService _databaseService;

  RecommendedMatchesService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize RecommendedMatchesService: $e');
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getRecommendedMatches(String userId) async {
    try {
      final result = await _databaseService.readPath('recommendedMatches/$userId');
      
      if (result.isSuccess() && result.data is Map<String, dynamic>) {
        final data = result.data as Map<String, dynamic>;
        final matches = data.values
            .whereType<Map<String, dynamic>>()
            .toList();
        return Result.success(matches);
      }

      return Result.success([]);
    } catch (e) {
      return Result.failure(Exception('Failed to get recommended matches: $e'));
    }
  }

  @override
  Future<Result<void>> updateMatchRecommendations(String userId) async {
    try {
      // Recalculate and update recommendations
      final result = await _databaseService.updatePath(
        'recommendedMatches/$userId',
        {'updatedAt': DateTime.now().toIso8601String()},
      );
      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to update recommendations: $e'));
    }
  }
}
