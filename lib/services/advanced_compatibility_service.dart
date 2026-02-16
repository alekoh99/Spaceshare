import 'package:get/get.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class IAdvancedCompatibilityService {
  Future<Result<List<Map<String, dynamic>>>> calculateCompatibility(String userId, String targetUserId);
  Future<Result<Map<String, dynamic>>> getDetailedCompatibility(String userId, String targetUserId);
  Future<Result<List<String>>> getCompatibilityFactors(String userId, String targetUserId);
}

class AdvancedCompatibilityService implements IAdvancedCompatibilityService {
  late final UnifiedDatabaseService _databaseService;

  AdvancedCompatibilityService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize AdvancedCompatibilityService: $e');
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> calculateCompatibility(String userId, String targetUserId) async {
    try {
      final userResult = await _databaseService.getProfile(userId);
      final targetResult = await _databaseService.getProfile(targetUserId);

      if (!userResult.isSuccess() || !targetResult.isSuccess()) {
        return Result.failure(Exception('Failed to fetch profiles for compatibility'));
      }

      final user = userResult.data!;
      final target = targetResult.data!;

      final factors = <Map<String, dynamic>>[];

      // Age compatibility
      final ageDiff = (user.age - target.age).abs().toDouble();
      factors.add({
        'factor': 'age',
        'score': _calculateAgeScore(ageDiff),
        'details': 'Age difference: ${ageDiff.toInt()} years',
      });

      // Location compatibility
      factors.add({
        'factor': 'location',
        'score': user.city == target.city ? 100 : 50,
        'details': 'Same city: ${user.city == target.city}',
      });

      // Budget compatibility
      final budgetOverlap = _calculateBudgetOverlap(
        user.budgetMin, user.budgetMax,
        target.budgetMin, target.budgetMax,
      );
      factors.add({
        'factor': 'budget',
        'score': budgetOverlap,
        'details': 'Budget overlap: ${budgetOverlap.toStringAsFixed(0)}%',
      });

      return Result.success(factors);
    } catch (e) {
      return Result.failure(Exception('Failed to calculate compatibility: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getDetailedCompatibility(String userId, String targetUserId) async {
    try {
      final factorsResult = await calculateCompatibility(userId, targetUserId);

      if (!factorsResult.isSuccess()) {
        return Result.failure(factorsResult.exception ?? Exception('Failed to calculate compatibility'));
      }

      final factors = factorsResult.data!;
      final scores = factors.map((f) => (f['score'] as num).toDouble()).toList();
      final averageScore = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;

      return Result.success({
        'userId': userId,
        'targetUserId': targetUserId,
        'overallScore': averageScore,
        'factors': factors,
        'recommendation': averageScore > 70 ? 'highly_compatible' : averageScore > 50 ? 'compatible' : 'low_compatibility',
        'calculatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return Result.failure(Exception('Failed to get detailed compatibility: $e'));
    }
  }

  @override
  Future<Result<List<String>>> getCompatibilityFactors(String userId, String targetUserId) async {
    try {
      final result = await calculateCompatibility(userId, targetUserId);

      if (result.isSuccess()) {
        final factors = (result.data ?? [])
            .map((f) => '${f['factor']}: ${f['score']}%')
            .toList();
        return Result.success(factors);
      }

      return Result.failure(result.exception ?? Exception('Failed to calculate compatibility'));
    } catch (e) {
      return Result.failure(Exception('Failed to get compatibility factors: $e'));
    }
  }

  int _calculateAgeScore(double ageDiff) {
    if (ageDiff == 0) return 100;
    if (ageDiff <= 2) return 95;
    if (ageDiff <= 5) return 80;
    if (ageDiff <= 10) return 60;
    return 30;
  }

  double _calculateBudgetOverlap(double userMin, double userMax, double targetMin, double targetMax) {
    final overlapStart = [userMin, targetMin].reduce((a, b) => a > b ? a : b);
    final overlapEnd = [userMax, targetMax].reduce((a, b) => a < b ? a : b);

    if (overlapStart > overlapEnd) return 0;

    final overlapRange = overlapEnd - overlapStart;
    final userRange = userMax - userMin;
    return (overlapRange / userRange) * 100;
  }
}
