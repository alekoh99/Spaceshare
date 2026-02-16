import 'package:get/get.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class IUserReputationService {
  Future<Result<int>> getUserReputation(String userId);
  Future<Result<void>> addReputation(String userId, int points, String reason);
  Future<Result<void>> subtractReputation(String userId, int points, String reason);
  Future<Result<Map<String, dynamic>>> getReputationDetails(String userId);
}

class UserReputationService implements IUserReputationService {
  late final UnifiedDatabaseService _databaseService;

  UserReputationService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize UserReputationService: $e');
    }
  }

  @override
  Future<Result<int>> getUserReputation(String userId) async {
    try {
      final result = await _databaseService.readPath('userReputation/$userId/score');
      
      if (result.isSuccess() && result.data is num) {
        return Result.success((result.data as num).toInt());
      }

      return Result.success(0);
    } catch (e) {
      return Result.failure(Exception('Failed to get user reputation: $e'));
    }
  }

  @override
  Future<Result<void>> addReputation(String userId, int points, String reason) async {
    try {
      final recordId = 'rep_${DateTime.now().millisecondsSinceEpoch}';
      
      final result = await _databaseService.createPath(
        'reputationRecords/$userId/$recordId',
        {
          'points': points,
          'reason': reason,
          'type': 'addition',
          'recordedAt': DateTime.now().toIso8601String(),
        },
      );

      if (result.isSuccess()) {
        // Update total score
        final currentResult = await getUserReputation(userId);
        final newScore = (currentResult.data ?? 0) + points;
        await _databaseService.updatePath(
          'userReputation/$userId',
          {'score': newScore},
        );
      }

      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to add reputation: $e'));
    }
  }

  @override
  Future<Result<void>> subtractReputation(String userId, int points, String reason) async {
    try {
      final recordId = 'rep_${DateTime.now().millisecondsSinceEpoch}';
      
      final result = await _databaseService.createPath(
        'reputationRecords/$userId/$recordId',
        {
          'points': -points,
          'reason': reason,
          'type': 'subtraction',
          'recordedAt': DateTime.now().toIso8601String(),
        },
      );

      if (result.isSuccess()) {
        // Update total score
        final currentResult = await getUserReputation(userId);
        final newScore = (currentResult.data ?? 0) - points;
        await _databaseService.updatePath(
          'userReputation/$userId',
          {'score': newScore.clamp(0, 999999)},
        );
      }

      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to subtract reputation: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getReputationDetails(String userId) async {
    try {
      final scoreResult = await getUserReputation(userId);
      
      final recordsResult = await _databaseService.readPath('reputationRecords/$userId');
      
      if (scoreResult.isSuccess()) {
        final records = <Map<String, dynamic>>[];
        if (recordsResult.isSuccess() && recordsResult.data is Map<String, dynamic>) {
          final data = recordsResult.data as Map<String, dynamic>;
          records.addAll(data.values.whereType<Map<String, dynamic>>());
        }

        return Result.success({
          'score': scoreResult.data,
          'records': records,
          'level': _getReputationLevel(scoreResult.data ?? 0),
        });
      }

      return Result.failure(scoreResult.exception ?? Exception('Failed to get reputation score'));
    } catch (e) {
      return Result.failure(Exception('Failed to get reputation details: $e'));
    }
  }

  String _getReputationLevel(int score) {
    if (score >= 1000) return 'trusted';
    if (score >= 500) return 'good';
    if (score >= 100) return 'neutral';
    return 'new';
  }
}
