import 'package:get/get.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class IMatchFilterService {
  Future<Result<void>> setUserFilters(String userId, Map<String, dynamic> filters);
  Future<Result<Map<String, dynamic>>> getUserFilters(String userId);
  Future<Result<void>> applyFilter(String userId, String filterKey, dynamic value);
  Future<Result<List<Map<String, dynamic>>>> getFilteredMatches(String userId);
}

class MatchFilterService implements IMatchFilterService {
  late final UnifiedDatabaseService _databaseService;

  MatchFilterService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize MatchFilterService: $e');
    }
  }

  @override
  Future<Result<void>> setUserFilters(String userId, Map<String, dynamic> filters) async {
    try {
      final result = await _databaseService.createPath(
        'userMatchFilters/$userId',
        {
          ...filters,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to set user filters: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getUserFilters(String userId) async {
    try {
      final result = await _databaseService.readPath('userMatchFilters/$userId');
      
      if (result.isSuccess() && result.data is Map<String, dynamic>) {
        return Result.success(result.data as Map<String, dynamic>);
      }

      // Return default filters if not found
      return Result.success({
        'minAge': 18,
        'maxAge': 65,
        'budgetMin': 0,
        'budgetMax': 100000,
        'locations': [],
      });
    } catch (e) {
      return Result.failure(Exception('Failed to get user filters: $e'));
    }
  }

  @override
  Future<Result<void>> applyFilter(String userId, String filterKey, dynamic value) async {
    try {
      final result = await _databaseService.updatePath(
        'userMatchFilters/$userId',
        {
          filterKey: value,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to apply filter: $e'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getFilteredMatches(String userId) async {
    try {
      // This would typically retrieve matches and apply filters
      final filtersResult = await getUserFilters(userId);
      
      if (filtersResult.isSuccess()) {
        // Apply filters to matches
        return Result.success([]);
      }

      return Result.failure(filtersResult.exception ?? Exception('Failed to get user filters'));
    } catch (e) {
      return Result.failure(Exception('Failed to get filtered matches: $e'));
    }
  }
}
