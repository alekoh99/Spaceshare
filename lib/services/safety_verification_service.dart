import 'package:get/get.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class ISafetyVerificationService {
  Future<Result<Map<String, dynamic>>> verifySafety(String userId);
  Future<Result<void>> flagSuspiciousActivity(String userId, String reason);
  Future<Result<int>> getSafetyScore(String userId);
}

class SafetyVerificationService implements ISafetyVerificationService {
  late final UnifiedDatabaseService _databaseService;

  SafetyVerificationService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize SafetyVerificationService: $e');
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> verifySafety(String userId) async {
    try {
      final result = await _databaseService.readPath('safetyVerifications/$userId');
      
      if (result.isSuccess() && result.data is Map<String, dynamic>) {
        return Result.success(result.data as Map<String, dynamic>);
      }

      return Result.success({
        'userId': userId,
        'status': 'verified',
        'score': 100,
        'lastChecked': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return Result.failure(Exception('Failed to verify safety: $e'));
    }
  }

  @override
  Future<Result<void>> flagSuspiciousActivity(String userId, String reason) async {
    try {
      final flagId = 'safety_flag_${DateTime.now().millisecondsSinceEpoch}';
      
      final flagData = {
        'flagId': flagId,
        'userId': userId,
        'reason': reason,
        'flaggedAt': DateTime.now().toIso8601String(),
        'status': 'investigating',
      };

      final result = await _databaseService.createPath(
        'safetyFlags/$flagId',
        flagData,
      );

      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to flag suspicious activity: $e'));
    }
  }

  @override
  Future<Result<int>> getSafetyScore(String userId) async {
    try {
      final result = await _databaseService.readPath('userSafetyScores/$userId');
      
      if (result.isSuccess() && result.data is Map<String, dynamic>) {
        final data = result.data as Map<String, dynamic>;
        final score = (data['score'] as num?)?.toInt() ?? 100;
        return Result.success(score);
      }

      return Result.success(100);
    } catch (e) {
      return Result.failure(Exception('Failed to get safety score: $e'));
    }
  }
}
