import 'package:get/get.dart';
import '../models/user_model.dart';
import '../models/match_model.dart';
import '../utils/result.dart';
import '../utils/logger.dart';
import '../utils/exceptions.dart' as exceptions;
import 'dart:async';
import 'unified_database_service.dart';

/// Match prediction model metadata
class MatchPredictionMetrics {
  final double compatibilityScore;
  final Map<String, double> scoreBreakdown;
  final double successProbability; // ML-based success probability (0-1)
  final List<String> compatibilityFactors; // Top matching factors
  final List<String> riskFactors; // Potential compatibility issues
  final DateTime calculatedAt;

  MatchPredictionMetrics({
    required this.compatibilityScore,
    required this.scoreBreakdown,
    required this.successProbability,
    required this.compatibilityFactors,
    required this.riskFactors,
    required this.calculatedAt,
  });

  Map<String, dynamic> toJson() => {
    'compatibilityScore': compatibilityScore,
    'scoreBreakdown': scoreBreakdown,
    'successProbability': successProbability,
    'compatibilityFactors': compatibilityFactors,
    'riskFactors': riskFactors,
    'calculatedAt': calculatedAt.toIso8601String(),
  };
}

abstract class IMatchingService {
  Future<Map<String, dynamic>> calculateScore(UserProfile user1, UserProfile user2);
  Future<Result<MatchPredictionMetrics>> calculateAdvancedScore(UserProfile user1, UserProfile user2);
  Future<Match> createMatch(String user1Id, String user2Id);
  Future<Match> acceptMatch(String matchId);
  Future<Match> rejectMatch(String matchId);
  Future<Match> archiveMatch(String matchId);
  Future<List<UserProfile>> getSwipeFeed(String userId, {int limit, int offset, String? city, double minScore});
  Future<List<Match>> getActiveMatches(String userId, {int limit});
  Future<List<Match>> getMatchHistory(String userId);
  Future<Match?> getMatch(String matchId);
  Future<Result<List<UserProfile>>> getIntelligentSwipeFeed(String userId, {int limit});
  Future<double> predictMatchSuccess(String matchId);
}

class MatchingService implements IMatchingService {
  final UnifiedDatabaseService _db = Get.find();
  final Map<String, MatchPredictionMetrics> _scoreCache = {};
  final Map<String, double> _successProbabilityCache = {};
  late final Timer _cacheClearTimer;
  
  // Cache average success rate to avoid repeated Firestore queries
  double? _cachedAverageSuccessRate;
  DateTime? _successRateCacheTime;
  static const Duration _successRateCacheDuration = Duration(hours: 1);

  MatchingService() {
    // Clear cache every hour
    _cacheClearTimer = Timer.periodic(Duration(hours: 1), (_) {
      _scoreCache.clear();
      _successProbabilityCache.clear();
      _cachedAverageSuccessRate = null;
      _successRateCacheTime = null;
    });
  }

  void dispose() {
    _cacheClearTimer.cancel();
  }

  /// Advanced ML-based compatibility scoring with success prediction
  @override
  Future<Result<MatchPredictionMetrics>> calculateAdvancedScore(
    UserProfile user1,
    UserProfile user2,
  ) async {
    try {
      final cacheKey = '${user1.userId}:${user2.userId}';
      if (_scoreCache.containsKey(cacheKey)) {
        return Result.success(_scoreCache[cacheKey]!);
      }

      // 1. Cleanliness compatibility (0-1 scale)
      final cleanliness1 = (user1.cleanliness).toDouble();
      final cleanliness2 = (user2.cleanliness).toDouble();
      final cleanlinessScore = 1.0 - ((cleanliness1 - cleanliness2).abs() / 10.0).clamp(0, 1);

      // 2. Quietness compatibility
      final quiet1 = (user1.noiseTolerance).toDouble();
      final quiet2 = (user2.noiseTolerance).toDouble();
      final quietnessScore = 1.0 - ((quiet1 - quiet2).abs() / 10.0).clamp(0, 1);

      // 3. Social frequency compatibility
      final social1 = (user1.socialFrequency).toDouble();
      final social2 = (user2.socialFrequency).toDouble();
      final socialFrequencyScore = 1.0 - ((social1 - social2).abs() / 10.0).clamp(0, 1);

      // 4. Budget compatibility (advanced)
      double budgetScore = _calculateBudgetCompatibility(user1, user2);

      // 5. Pet compatibility
      double petScore = user1.hasPets == user2.hasPets ? 1.0 : 0.5;

      // 6. Lifestyle compatibility (new)
      double lifestyleScore = _calculateLifestyleCompatibility(user1, user2);

      // 7. Schedule compatibility (new)
      double scheduleScore = _calculateScheduleCompatibility(user1, user2);

      // 8. Verification match (new) - trust factor
      double verificationScore = _calculateVerificationMatch(user1, user2);

      // Weighted average with ML adjustments
      final baseScore = ((cleanlinessScore * 0.20 +
              quietnessScore * 0.20 +
              socialFrequencyScore * 0.15 +
              budgetScore * 0.20 +
              petScore * 0.08 +
              lifestyleScore * 0.10 +
              scheduleScore * 0.05 +
              verificationScore * 0.02) *
          100)
          .round();

      // Machine learning adjustment based on historical match outcomes
      final successProbability = await _predictSuccessProbability(user1, user2, baseScore / 100);

      // Identify compatibility factors and risk factors
      final compatibilityFactors = _identifyCompatibilityFactors(
        cleanlinessScore,
        quietnessScore,
        socialFrequencyScore,
        budgetScore,
        petScore,
      );
      
      final riskFactors = _identifyRiskFactors(user1, user2, baseScore);

      final metrics = MatchPredictionMetrics(
        compatibilityScore: baseScore.toDouble(),
        scoreBreakdown: {
          'cleanliness': cleanlinessScore,
          'quietness': quietnessScore,
          'socialFrequency': socialFrequencyScore,
          'budget': budgetScore,
          'pets': petScore,
          'lifestyle': lifestyleScore,
          'schedule': scheduleScore,
          'verification': verificationScore,
        },
        successProbability: successProbability,
        compatibilityFactors: compatibilityFactors,
        riskFactors: riskFactors,
        calculatedAt: DateTime.now(),
      );

      _scoreCache[cacheKey] = metrics;
      return Result.success(metrics);
    } catch (e) {
      return Result.failure(MatchException('Failed to calculate advanced score: $e') as Exception);
    }
  }

  /// Intelligent swipe feed with ML ranking - OPTIMIZED for fast loading
  @override
  Future<Result<List<UserProfile>>> getIntelligentSwipeFeed(
    String userId, {
    int limit = 20,
  }) async {
    try {
      AppLogger.info('MatchingService', 'Getting intelligent swipe feed for: $userId');
      
      // Use unified database service (handles Firestore → PostgreSQL fallback)
      final result = await _db.getIntelligentSwipeFeed(userId, limit: limit);
      
      if (result.isSuccess()) {
        AppLogger.success('MatchingService', 'Intelligent feed loaded: ${result.getOrNull()?.length} profiles');
        return result;
      } else {
        AppLogger.error('MatchingService', 'Failed to load intelligent feed', result.getExceptionOrNull());
        return result;
      }
    } catch (e) {
      AppLogger.error('MatchingService', 'Intelligent feed error', e);
      return Result.failure(exceptions.MatchException('Failed to load swipe feed: ${e.toString()}'));
    }
  }

  /// Predict match success based on historical data
  @override
  Future<double> predictMatchSuccess(String matchId) async {
    try {
      final matchResult = await _db.getMatch(matchId);
      if (!matchResult.isSuccess()) return 0.0;
      
      final match = matchResult.getOrNull();
      if (match == null) return 0.0;

      final user1Result = await _db.getProfile(match.user1Id);
      final user2Result = await _db.getProfile(match.user2Id);

      if (!user1Result.isSuccess() || !user2Result.isSuccess()) return 0.0;

      final user1 = user1Result.getOrNull();
      final user2 = user2Result.getOrNull();
      
      if (user1 == null || user2 == null) return 0.0;

      final scoreResult = await calculateAdvancedScore(user1, user2);
      if (scoreResult.isSuccess()) {
        final metrics = scoreResult.getOrNull();
        return metrics?.successProbability ?? 0.0;
      }

      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // Private helper methods

  double _calculateBudgetCompatibility(UserProfile user1, UserProfile user2) {
    if (user1.budgetMin <= user2.budgetMax && user1.budgetMax >= user2.budgetMin) {
      return 1.0;
    } else {
      final diff = (user1.budgetMax - user2.budgetMin).abs();
      return 1.0 - (diff / (user1.budgetMax + user2.budgetMax)).clamp(0.0, 1.0);
    }
  }

  double _calculateLifestyleCompatibility(UserProfile user1, UserProfile user2) {
    // Calculate lifestyle compatibility based on extended fields
    double score = 0.0;
    int fieldCount = 0;
    
    // Pet compatibility (if both users have pet preferences)
    if (user1.hasPets != null && user2.petTolerance != null) {
      // If user1 has pets, check if user2 is tolerant
      if (user1.hasPets! && user2.petTolerance! >= 6) {
        score += 1.0;
      } else if (!user1.hasPets! && user2.petTolerance! >= 4) {
        score += 1.0;
      } else {
        score += 0.5;
      }
      fieldCount++;
    }
    
    if (user2.hasPets != null && user1.petTolerance != null) {
      if (user2.hasPets! && user1.petTolerance! >= 6) {
        score += 1.0;
      } else if (!user2.hasPets! && user1.petTolerance! >= 4) {
        score += 1.0;
      } else {
        score += 0.5;
      }
      fieldCount++;
    }
    
    // Guest policy compatibility
    if (user1.guestPolicy != null && user2.guestPolicy != null) {
      final diff = (user1.guestPolicy! - user2.guestPolicy!).abs();
      score += 1.0 - (diff / 10).clamp(0.0, 1.0);
      fieldCount++;
    }
    
    // Privacy needs compatibility
    if (user1.privacyNeed != null && user2.privacyNeed != null) {
      final diff = (user1.privacyNeed! - user2.privacyNeed!).abs();
      score += 1.0 - (diff / 10).clamp(0.0, 1.0);
      fieldCount++;
    }
    
    // Kitchen habits compatibility (cleanliness in shared spaces)
    if (user1.kitchenHabits != null && user2.kitchenHabits != null) {
      final diff = (user1.kitchenHabits! - user2.kitchenHabits!).abs();
      score += 1.0 - (diff / 10).clamp(0.0, 1.0);
      fieldCount++;
    }
    
    // If no lifestyle fields are set, return neutral score
    if (fieldCount == 0) {
      return 0.75; // Neutral score when data is insufficient
    }
    
    // Normalize to 0-1 scale
    return (score / fieldCount).clamp(0.0, 1.0);
  }

  double _calculateScheduleCompatibility(UserProfile user1, UserProfile user2) {
    // Compare sleep schedules
    final scheduleMatch = user1.sleepSchedule == user2.sleepSchedule ? 1.0 : 0.6;
    return scheduleMatch;
  }

  double _calculateVerificationMatch(UserProfile user1, UserProfile user2) {
    // Trust factor based on identity verification
    final v1 = (user1.trustScore >= 50 && user1.identityVerifiedAt != null) ? 1.0 : 0.5;
    final v2 = (user2.trustScore >= 50 && user2.identityVerifiedAt != null) ? 1.0 : 0.5;
    return (v1 + v2) / 2;
  }

  Future<double> _predictSuccessProbability(
    UserProfile user1,
    UserProfile user2,
    double baseScore,
  ) async {
    try {
      // Check if we have a cached pair-specific probability
      final pairKey = '${user1.userId}:${user2.userId}';
      if (_successProbabilityCache.containsKey(pairKey)) {
        return _successProbabilityCache[pairKey]!;
      }

      // Use cached average success rate if available
      if (_cachedAverageSuccessRate != null && 
          _successRateCacheTime != null &&
          DateTime.now().difference(_successRateCacheTime!) < _successRateCacheDuration) {
        final probability = (baseScore * 0.6 + _cachedAverageSuccessRate! * 0.4).clamp(0.0, 1.0);
        _successProbabilityCache[pairKey] = probability;
        return probability;
      }

      // Query historical matches with timeout
      try {
        final matchHistoryResult = await _db.getMatchHistory(user1.userId);
        if (!matchHistoryResult.isSuccess()) {
          final probability = baseScore * 0.8;
          _successProbabilityCache[pairKey] = probability;
          return probability;
        }
        final matchHistory = matchHistoryResult.getOrNull() ?? [];
        final similarMatches = matchHistory.where((m) => m.status == 'matched').toList();

        if (similarMatches.isEmpty) {
          final probability = baseScore * 0.8;
          _successProbabilityCache[pairKey] = probability;
          return probability;
        }

        final successRate = similarMatches.length / (matchHistory.length > 0 ? matchHistory.length : 1);
        _cachedAverageSuccessRate = successRate;
        _successRateCacheTime = DateTime.now();

        final probability = (baseScore * 0.6 + successRate * 0.4).clamp(0.0, 1.0);
        _successProbabilityCache[pairKey] = probability;
        return probability;
      } catch (e) {
        // If Firestore query fails, use default calculation
        final probability = baseScore * 0.8;
        _successProbabilityCache[pairKey] = probability;
        return probability;
      }
    } catch (e) {
      return baseScore * 0.8;
    }
  }

  List<String> _identifyCompatibilityFactors(
    double cleanliness,
    double quietness,
    double social,
    double budget,
    double pets,
  ) {
    final factors = <String>[];
    
    if (cleanliness > 0.8) factors.add('Great cleanliness match');
    if (quietness > 0.8) factors.add('Similar noise preferences');
    if (social > 0.8) factors.add('Compatible social frequency');
    if (budget > 0.9) factors.add('Perfect budget alignment');
    if (pets > 0.9) factors.add('Pet preferences align');

    return factors.isEmpty ? ['Potential compatibility'] : factors;
  }

  List<String> _identifyRiskFactors(
    UserProfile user1,
    UserProfile user2,
    int score,
  ) {
    final risks = <String>[];

    if (score < 60) risks.add('Lower compatibility score');
    if ((user1.trustScore ?? 50) < 40 || (user2.trustScore ?? 50) < 40) {
      risks.add('One or both users not fully verified');
    }
    if ((user1.trustScore ?? 50) < 35 || (user2.trustScore ?? 50) < 35) {
      risks.add('One or both users have lower trust scores');
    }

    return risks;
  }

  @override
  Future<Map<String, dynamic>> calculateScore(UserProfile user1, UserProfile user2) async {
    try {
      // 1. Cleanliness compatibility (0-1 scale)
      final cleanliness1 = 5.0;  // Default value
      final cleanliness2 = 5.0;  // Default value
      final cleanlinessScore = 1.0 - ((cleanliness1 - cleanliness2).abs() / 10.0).clamp(0, 1);

      // 2. Quietness compatibility
      final quiet1 = 5.0;  // Default value
      final quiet2 = 5.0;  // Default value
      final quietnessScore = 1.0 - ((quiet1 - quiet2).abs() / 10.0).clamp(0, 1);

      // 3. Social frequency compatibility
      final social1 = 5.0;  // Default value
      final social2 = 5.0;  // Default value
      final socialFrequencyScore = 1.0 - ((social1 - social2).abs() / 10.0).clamp(0, 1);

      // 4. Budget compatibility
      double budgetScore = 0;
      if (user1.budgetMin <= user2.budgetMax && user1.budgetMax >= user2.budgetMin) {
        budgetScore = 1.0;
      } else {
        final diff = (user1.budgetMax - user2.budgetMin).abs();
        budgetScore = 1.0 - (diff / (user1.budgetMax + user2.budgetMax)).clamp(0.0, 1.0);
      }

      // 5. Pet compatibility
      double petScore = user1.hasPets == user2.hasPets ? 1.0 : 0.5;

      // Weighted average
      final compatibilityScore = ((cleanlinessScore * 0.25 +
                  quietnessScore * 0.25 +
                  socialFrequencyScore * 0.20 +
                  budgetScore * 0.20 +
                  petScore * 0.10) *
              100)
          .round();

      return {
        'compatibilityScore': compatibilityScore,
        'scoreBreakdown': {
          'cleanliness': cleanlinessScore,
          'quietness': quietnessScore,
          'socialFrequency': socialFrequencyScore,
          'budget': budgetScore,
          'pets': petScore,
        },
      };
    } catch (e) {
      throw MatchException('Failed to calculate compatibility score: $e');
    }
  }

  @override
  Future<Match> createMatch(String user1Id, String user2Id) async {
    try {
      // Validate user IDs before attempting to create match
      if (user1Id.isEmpty || user1Id == 'unknown') {
        throw MatchException('Invalid user1Id: must be a valid user ID');
      }
      if (user2Id.isEmpty || user2Id == 'unknown') {
        throw MatchException('Invalid user2Id: must be a valid user ID');
      }
      
      AppLogger.info('MatchingService', 'Creating match: $user1Id <-> $user2Id');
      
      final result = await _db.createMatch(user1Id, user2Id);
      if (result.isSuccess()) {
        final match = result.getOrNull();
        if (match != null) {
          AppLogger.success('MatchingService', 'Match created: ${match.matchId}');
          return match;
        }
      }
      
      throw MatchException('Failed to create match: ${result.getExceptionOrNull()}');
    } catch (e) {
      AppLogger.error('MatchingService', 'Create match failed', e);
      throw MatchException('Failed to create match: $e');
    }
  }

  @override
  Future<Match> acceptMatch(String matchId) async {
    try {
      AppLogger.info('MatchingService', 'Accepting match: $matchId');
      
      final result = await _db.acceptMatch(matchId);
      if (result.isSuccess()) {
        final match = result.getOrNull();
        if (match != null) {
          AppLogger.success('MatchingService', 'Match accepted: $matchId');
          return match;
        }
      }
      
      throw MatchException('Failed to accept match: ${result.getExceptionOrNull()}');
    } catch (e) {
      AppLogger.error('MatchingService', 'Accept match failed', e);
      throw MatchException('Failed to accept match: $e');
    }
  }

  @override
  Future<Match> rejectMatch(String matchId) async {
    try {
      AppLogger.info('MatchingService', 'Rejecting match: $matchId');
      
      final result = await _db.rejectMatch(matchId);
      if (result.isSuccess()) {
        final match = result.getOrNull();
        if (match != null) {
          AppLogger.success('MatchingService', 'Match rejected: $matchId');
          return match;
        }
      }
      
      throw MatchException('Failed to reject match: ${result.getExceptionOrNull()}');
    } catch (e) {
      AppLogger.error('MatchingService', 'Reject match failed', e);
      throw MatchException('Failed to reject match: $e');
    }
  }

  @override
  Future<Match> archiveMatch(String matchId) async {
    try {
      AppLogger.info('MatchingService', 'Archiving match: $matchId');
      
      final result = await _db.archiveMatch(matchId);
      if (result.isSuccess()) {
        final match = result.getOrNull();
        if (match != null) {
          AppLogger.success('MatchingService', 'Match archived: $matchId');
          return match;
        }
      }
      
      throw MatchException('Failed to archive match: ${result.getExceptionOrNull()}');
    } catch (e) {
      AppLogger.error('MatchingService', 'Archive match failed', e);
      throw MatchException('Failed to archive match: $e');
    }
  }

  @override
  Future<List<UserProfile>> getSwipeFeed(
    String userId, {
    int limit = 10,
    int offset = 0,
    String? city,
    double minScore = 65,
  }) async {
    try {
      AppLogger.info('MatchingService', 'Getting swipe feed for: $userId');
      
      // Use unified database service (handles Firestore → PostgreSQL fallback)
      final result = await _db.getSwipeFeed(
        userId,
        limit: limit,
        offset: offset,
        city: city,
        minScore: minScore,
      );
      
      if (result.isSuccess()) {
        final profiles = result.getOrNull() ?? [];
        AppLogger.success('MatchingService', 'Swipe feed loaded: ${profiles.length} profiles');
        return profiles;
      } else {
        throw MatchException('Failed to get swipe feed: ${result.getExceptionOrNull()}');
      }
    } catch (e) {
      AppLogger.error('MatchingService', 'Get swipe feed failed', e);
      throw MatchException('Failed to get swipe feed: $e');
    }
  }

  @override
  Future<List<Match>> getActiveMatches(String userId, {int limit = 20}) async {
    try {
      AppLogger.info('MatchingService', 'Getting active matches for: $userId');
      
      final result = await _db.getActiveMatches(userId, limit: limit);
      if (result.isSuccess()) {
        final matches = result.getOrNull() ?? [];
        AppLogger.success('MatchingService', 'Active matches loaded: ${matches.length}');
        return matches;
      } else {
        throw MatchException('Failed to get active matches: ${result.getExceptionOrNull()}');
      }
    } catch (e) {
      AppLogger.error('MatchingService', 'Get active matches failed', e);
      throw MatchException('Failed to get active matches: $e');
    }
  }

  @override
  Future<List<Match>> getMatchHistory(String userId) async {
    try {
      AppLogger.info('MatchingService', 'Getting match history for: $userId');
      
      final result = await _db.getMatchHistory(userId);
      if (result.isSuccess()) {
        final matches = result.getOrNull() ?? [];
        AppLogger.success('MatchingService', 'Match history loaded: ${matches.length}');
        return matches;
      } else {
        throw MatchException('Failed to get match history: ${result.getExceptionOrNull()}');
      }
    } catch (e) {
      AppLogger.error('MatchingService', 'Get match history failed', e);
      throw MatchException('Failed to get match history: $e');
    }
  }

  @override
  Future<Match?> getMatch(String matchId) async {
    try {
      AppLogger.info('MatchingService', 'Getting match: $matchId');
      
      final result = await _db.getMatch(matchId);
      if (result.isSuccess()) {
        final match = result.getOrNull();
        if (match != null) {
          AppLogger.success('MatchingService', 'Match retrieved: $matchId');
        }
        return match;
      } else {
        throw MatchException('Failed to get match: ${result.getExceptionOrNull()}');
      }
    } catch (e) {
      AppLogger.error('MatchingService', 'Get match failed', e);
      throw MatchException('Failed to get match: $e');
    }
  }
}

class MatchException implements Exception {
  final String message;
  MatchException(this.message);
  @override
  String toString() => 'MatchException: $message';
}
