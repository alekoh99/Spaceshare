import 'dart:math';
import 'package:get/get.dart';
import '../models/compatibility_model.dart';
import '../models/user_model.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

/// Interface for compatibility calculation service
abstract class ICompatibilityService {
  /// Calculate compatibility between two users
  Future<CompatibilityScore> calculateCompatibility(UserProfile user1, UserProfile user2);

  /// Get list of compatibility dimensions
  List<CompatibilityDimension> getCompatibilityDimensions();

  /// Get detailed compatibility factors between two users
  Future<Result<Map<String, dynamic>>> getDetailedCompatibility(String userId, String targetUserId);
}

/// Default compatibility dimensions
const List<String> DEFAULT_COMPATIBILITY_DIMENSIONS = [
  'location',
  'interests',
  'lifestyle',
  'values',
  'communication',
  'age_compatibility',
];

/// Implementation of compatibility service
class CompatibilityService extends GetxService implements ICompatibilityService {
  late final UnifiedDatabaseService _databaseService;
  final List<CompatibilityDimension> _dimensions = [];

  @override
  Future<void> onInit() async {
    super.onInit();
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
      _initializeDimensions();
    } catch (e) {
      throw ServiceException('Failed to initialize CompatibilityService: $e');
    }
  }

  void _initializeDimensions() {
    _dimensions.clear();
    _dimensions.addAll([
      CompatibilityDimension(
        id: 'location',
        name: 'Location Compatibility',
        weight: 0.15,
        score: 0,
        description: 'Living in the same area or proximity',
      ),
      CompatibilityDimension(
        id: 'interests',
        name: 'Shared Interests',
        weight: 0.2,
        score: 0,
        description: 'Common hobbies and interests',
      ),
      CompatibilityDimension(
        id: 'lifestyle',
        name: 'Lifestyle Compatibility',
        weight: 0.15,
        score: 0,
        description: 'Similar lifestyle choices and habits',
      ),
      CompatibilityDimension(
        id: 'values',
        name: 'Values Alignment',
        weight: 0.25,
        score: 0,
        description: 'Aligned values and goals',
      ),
      CompatibilityDimension(
        id: 'communication',
        name: 'Communication Style',
        weight: 0.15,
        score: 0,
        description: 'Compatible communication preferences',
      ),
      CompatibilityDimension(
        id: 'age_compatibility',
        name: 'Age Compatibility',
        weight: 0.1,
        score: 0,
        description: 'Similar age range',
      ),
    ]);
  }

  @override
  Future<CompatibilityScore> calculateCompatibility(UserProfile user1, UserProfile user2) async {
    try {
      final dimensions = <CompatibilityDimension>[];
      double totalScore = 0;

      // Location compatibility (within same city gets 100)
      final locationScore = user1.city == user2.city ? 100 : 50;
      dimensions.add(_dimensions[0].copyWith(score: locationScore.toInt()));
      totalScore += locationScore * _dimensions[0].weight;

      // Budget compatibility
      final budgetOverlap = _calculateBudgetOverlap(user1, user2);
      dimensions.add(_dimensions[1].copyWith(score: budgetOverlap.toInt()));
      totalScore += budgetOverlap * _dimensions[1].weight;

      // Lifestyle compatibility
      final lifestyleScore = _calculateLifestyleScore(user1, user2);
      dimensions.add(_dimensions[2].copyWith(score: lifestyleScore));
      totalScore += lifestyleScore * _dimensions[2].weight;

      // Values alignment (based on trust and verification)
      final valuesScore = _calculateValuesScore(user1, user2);
      dimensions.add(_dimensions[3].copyWith(score: valuesScore));
      totalScore += valuesScore * _dimensions[3].weight;

      // Communication style (simplified)
      final communicationScore = 75; // Default moderate compatibility
      dimensions.add(_dimensions[4].copyWith(score: communicationScore));
      totalScore += communicationScore * _dimensions[4].weight;

      // Age compatibility
      final ageDiff = (user1.age - user2.age).abs().toDouble();
      final ageScore = _calculateAgeScore(ageDiff).toInt();
      dimensions.add(_dimensions[5].copyWith(score: ageScore));
      totalScore += ageScore * _dimensions[5].weight;

      return CompatibilityScore(
        userId1: user1.userId,
        userId2: user2.userId,
        overallScore: totalScore.clamp(0, 100),
        dimensions: dimensions,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to calculate compatibility: $e');
    }
  }

  double _calculateBudgetOverlap(UserProfile user1, UserProfile user2) {
    final minBudget = max(user1.budgetMin, user2.budgetMin);
    final maxBudget = min(user1.budgetMax, user2.budgetMax);
    
    if (minBudget > maxBudget) {
      return 20; // No overlap
    }
    
    final overlapRange = maxBudget - minBudget;
    final avgRange = ((user1.budgetMax - user1.budgetMin) + (user2.budgetMax - user2.budgetMin)) / 2;
    
    return (overlapRange / avgRange * 100).clamp(20, 100).toDouble();
  }

  int _calculateLifestyleScore(UserProfile user1, UserProfile user2) {
    try {
      int score = 50;

      // Check sleep schedule compatibility
      if (user1.sleepSchedule == user2.sleepSchedule) {
        score += 15;
      }

      // Check social frequency compatibility
      final socialDiff = (user1.socialFrequency - user2.socialFrequency).abs();
      if (socialDiff <= 2) {
        score += 10;
      } else if (socialDiff <= 4) {
        score += 5;
      }

      // Check noise tolerance compatibility
      final noiseDiff = (user1.noiseTolerance - user2.noiseTolerance).abs();
      if (noiseDiff <= 2) {
        score += 10;
      }

      // Check cleanliness
      final cleanDiff = (user1.cleanliness - user2.cleanliness).abs();
      if (cleanDiff <= 2) {
        score += 10;
      }

      score = score.clamp(0, 100);
      return score;
    } catch (e) {
      return 50;
    }
  }

  int _calculateValuesScore(UserProfile user1, UserProfile user2) {
    try {
      int score = 50;

      // Check financial reliability compatibility
      final financialDiff = (user1.financialReliability - user2.financialReliability).abs();
      if (financialDiff <= 2) {
        score += 15;
      } else if (financialDiff <= 4) {
        score += 8;
      }

      // Check trust scores
      final trustDiff = (user1.trustScore - user2.trustScore).abs();
      if (trustDiff <= 10) {
        score += 10;
      }

      // Check verification status match
      if (user1.verified == user2.verified) {
        score += 5;
      }

      score = score.clamp(0, 100);
      return score;
    } catch (e) {
      return 50;
    }
  }

  double _calculateAgeScore(double ageDifference) {
    if (ageDifference <= 3) {
      return 100;
    } else if (ageDifference <= 7) {
      return 80;
    } else if (ageDifference <= 12) {
      return 60;
    } else if (ageDifference <= 20) {
      return 40;
    } else {
      return 20;
    }
  }

  @override
  List<CompatibilityDimension> getCompatibilityDimensions() {
    return _dimensions;
  }

  @override
  Future<Result<Map<String, dynamic>>> getDetailedCompatibility(String userId, String targetUserId) async {
    try {
      final userResult = await _databaseService.getProfile(userId);
      final targetResult = await _databaseService.getProfile(targetUserId);

      if (!userResult.isSuccess() || !targetResult.isSuccess()) {
        return Result.failure(Exception('Failed to fetch profiles for detailed compatibility'));
      }

      final user = userResult.data!;
      final target = targetResult.data!;

      final score = await calculateCompatibility(user, target);

      return Result.success({
        'score': score,
        'analysis': {
          'sharedInterests': _getSharedInterests(user, target),
          'mismatches': _identifyMismatches(user, target),
          'recommendations': _generateRecommendations(score),
        },
      });
    } catch (e) {
      return Result.failure(Exception('Error getting detailed compatibility: $e'));
    }
  }

  List<String> _getSharedInterests(UserProfile user1, UserProfile user2) {
    // Since interests are not tracked in current model, we return compatibility factors
    final factors = <String>[];
    
    if (user1.sleepSchedule == user2.sleepSchedule) {
      factors.add('Similar sleep schedules');
    }
    if ((user1.socialFrequency - user2.socialFrequency).abs() <= 2) {
      factors.add('Compatible social preferences');
    }
    if ((user1.cleanliness - user2.cleanliness).abs() <= 2) {
      factors.add('Similar cleanliness standards');
    }
    if ((user1.noiseTolerance - user2.noiseTolerance).abs() <= 2) {
      factors.add('Similar noise tolerance');
    }
    
    return factors.isNotEmpty ? factors : ['Potential for compatibility'];
  }

  List<String> _identifyMismatches(UserProfile user1, UserProfile user2) {
    final mismatches = <String>[];
    
    if (user1.city != user2.city) {
      mismatches.add('Different cities');
    }
    if ((user1.budgetMin > user2.budgetMax) || (user2.budgetMin > user1.budgetMax)) {
      mismatches.add('Incompatible budget ranges');
    }
    if ((user1.sleepSchedule != user2.sleepSchedule)) {
      mismatches.add('Different sleep schedules');
    }
    if ((user1.socialFrequency - user2.socialFrequency).abs() > 5) {
      mismatches.add('Very different social activity levels');
    }
    if ((user1.cleanliness - user2.cleanliness).abs() > 4) {
      mismatches.add('Significantly different cleanliness standards');
    }
    
    return mismatches;
  }

  List<String> _generateRecommendations(CompatibilityScore score) {
    if (score.overallScore >= 80) {
      return ['Great match! You have a lot in common'];
    } else if (score.overallScore >= 60) {
      return ['Good compatibility. Explore common interests'];
    } else if (score.overallScore >= 40) {
      return ['Moderate compatibility. Take time to know each other'];
    } else {
      return ['Limited compatibility. Different lifestyles'];
    }
  }
}

/// Extension to make copying CompatibilityDimension easier
extension CompatibilityDimensionX on CompatibilityDimension {
  CompatibilityDimension copyWith({
    String? id,
    String? name,
    double? weight,
    int? score,
    String? description,
  }) {
    return CompatibilityDimension(
      id: id ?? this.id,
      name: name ?? this.name,
      weight: weight ?? this.weight,
      score: score ?? this.score,
      description: description ?? this.description,
    );
  }
}
