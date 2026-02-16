import 'package:get/get.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class IProfileAnalyticsService {
  Future<Result<Map<String, dynamic>>> getProfileStats(String userId);
  Future<Result<void>> recordProfileView(String profileId, String viewerId);
  Future<Result<List<Map<String, dynamic>>>> getProfileViewers(String userId);
  Future<Result<Map<String, dynamic>>> getProfileEngagementStats(String userId);
}

class ProfileAnalyticsService implements IProfileAnalyticsService {
  late final UnifiedDatabaseService _databaseService;

  ProfileAnalyticsService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize ProfileAnalyticsService: $e');
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getProfileStats(String userId) async {
    try {
      final viewsResult = await _databaseService.readPath('profileViews/$userId');
      
      final stats = {
        'userId': userId,
        'totalViews': 0,
        'uniqueViewers': 0,
        'likes': 0,
        'matches': 0,
        'lastActiveAt': null,
      };

      if (viewsResult.isSuccess() && viewsResult.data is Map<String, dynamic>) {
        final views = viewsResult.data as Map<String, dynamic>;
        stats['totalViews'] = views.length;
        stats['uniqueViewers'] = views.keys.toSet().length;
      }

      return Result.success(stats);
    } catch (e) {
      return Result.failure(Exception('Failed to get profile stats: $e'));
    }
  }

  @override
  Future<Result<void>> recordProfileView(String profileId, String viewerId) async {
    try {
      final viewId = 'view_${DateTime.now().millisecondsSinceEpoch}';
      
      final viewData = {
        'viewId': viewId,
        'viewerId': viewerId,
        'viewedAt': DateTime.now().toIso8601String(),
      };

      final result = await _databaseService.createPath(
        'profileViews/$profileId/$viewId',
        viewData,
      );

      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to record profile view: $e'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getProfileViewers(String userId) async {
    try {
      final result = await _databaseService.readPath('profileViews/$userId');
      
      if (result.isSuccess() && result.data is Map<String, dynamic>) {
        final views = result.data as Map<String, dynamic>;
        final viewers = views.values
            .whereType<Map<String, dynamic>>()
            .toList();
        
        viewers.sort((a, b) {
          final aDate = DateTime.tryParse(a['viewedAt']?.toString() ?? '');
          final bDate = DateTime.tryParse(b['viewedAt']?.toString() ?? '');
          if (aDate == null || bDate == null) return 0;
          return bDate.compareTo(aDate);
        });

        return Result.success(viewers);
      }

      return Result.success([]);
    } catch (e) {
      return Result.failure(Exception('Failed to get profile viewers: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getProfileEngagementStats(String userId) async {
    try {
      final statsResult = await getProfileStats(userId);
      
      if (statsResult.isSuccess()) {
        final stats = statsResult.data!;
        return Result.success({
          'engagementScore': _calculateEngagementScore(stats),
          'stats': stats,
        });
      }

      return Result.failure(statsResult.exception ?? Exception('Failed to get engagement stats'));
    } catch (e) {
      return Result.failure(Exception('Failed to get engagement stats: $e'));
    }
  }

  double _calculateEngagementScore(Map<String, dynamic> stats) {
    double score = 0;
    score += (stats['totalViews'] as int? ?? 0) * 0.5;
    score += (stats['likes'] as int? ?? 0) * 1.0;
    score += (stats['matches'] as int? ?? 0) * 2.0;
    return score.clamp(0, 100);
  }
}
