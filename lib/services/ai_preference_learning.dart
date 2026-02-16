import 'package:get/get.dart';
import '../utils/logger.dart';
import '../utils/result.dart';
import 'unified_database_service.dart';

class AIPreferenceInsight {
  final String userId;
  final Map<String, int> dimensionPreferences; // preference scores for each dimension
  final Map<String, dynamic> matchingPatterns;
  final List<String> successFactors;
  final List<String> riskFactors;
  final DateTime lastUpdated;

  AIPreferenceInsight({
    required this.userId,
    required this.dimensionPreferences,
    required this.matchingPatterns,
    required this.successFactors,
    this.riskFactors = const [],
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'dimensionPreferences': dimensionPreferences,
    'matchingPatterns': matchingPatterns,
    'successFactors': successFactors,
    'riskFactors': riskFactors,
    'lastUpdated': lastUpdated.toIso8601String(),
  };
}

/// Learns from user behavior to improve matching
class AIPreferenceLearningService extends GetxService {
  late final UnifiedDatabaseService _databaseService;

  static AIPreferenceLearningService get to => Get.find();

  @override
  void onInit() {
    super.onInit();
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      AppLogger.warning('AIPreferenceLearning', 'UnifiedDatabaseService not initialized: $e');
    }
  }

  /// Analyze user's swipe patterns to extract preferences
  Future<AIPreferenceInsight> analyzeUserPreferences(String userId) async {
    try {
      // Backend service handles preference analysis
      AppLogger.info('AIPreferenceLearning', 'Analyzing preferences for user: $userId');
      
      // Return placeholder until backend integration
      return AIPreferenceInsight(
        userId: userId,
        dimensionPreferences: {
          'cleanliness': 7,
          'noiseTolerance': 6,
          'socialFrequency': 5,
        },
        matchingPatterns: {},
        successFactors: [],
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      AppLogger.error('AIPreferenceLearning', 'Failed to analyze preferences', e);
      rethrow;
    }
  }

  /// Get cached preferences or analyze if not cached
  Future<AIPreferenceInsight?> getUserPreferenceInsight(String userId) async {
    try {
      // For now,just analyze
      return await analyzeUserPreferences(userId);
    } catch (e) {
      AppLogger.error('AIPreferenceLearning', 'Failed to get preference insight', e);
      return null;
    }
  }

  // Private helpers

  Map<String, int> _extractDimensionPreferences(
    List<Map<String, dynamic>> acceptedMatches,
  ) {
    if (acceptedMatches.isEmpty) {
      return {
        'cleanliness': 50,
        'noiseTourance': 50,
        'socialFrequency': 50,
        'financialReliability': 50,
      };
    }

    int cleanlinessSum = 0;
    int noiseSum = 0;
    int socialSum = 0;
    int financialSum = 0;

    for (final match in acceptedMatches) {
      cleanlinessSum += (match['cleanlinessScore'] as int? ?? 50);
      noiseSum += (match['noiseToleranceScore'] as int? ?? 50);
      socialSum += (match['socialFrequencyScore'] as int? ?? 50);
      financialSum += (match['financialReliabilityScore'] as int? ?? 50);
    }

    return {
      'cleanliness': (cleanlinessSum / acceptedMatches.length).toInt(),
      'noiseTolerance': (noiseSum / acceptedMatches.length).toInt(),
      'socialFrequency': (socialSum / acceptedMatches.length).toInt(),
      'financialReliability': (financialSum / acceptedMatches.length).toInt(),
    };
  }

  Map<String, dynamic> _extractMatchingPatterns(
    List<Map<String, dynamic>> acceptedMatches,
    List<Map<String, dynamic>> rejectedMatches,
  ) {
    final total = acceptedMatches.length + rejectedMatches.length;

    return {
      'acceptanceRate': total > 0 ? acceptedMatches.length / total : 0.0,
      'averageCompatibilityScore': total > 0
          ? acceptedMatches.fold<double>(
              0,
              (sum, m) => sum + ((m['compatibilityScore'] as num?) ?? 0).toDouble(),
            ) / acceptedMatches.length
          : 0.0,
      'matchCount': total,
      'acceptedCount': acceptedMatches.length,
      'rejectedCount': rejectedMatches.length,
    };
  }

  List<String> _identifySuccessFactors(List<Map<String, dynamic>> acceptedMatches) {
    if (acceptedMatches.isEmpty) return [];

    final factors = <String>[];

    // Calculate average scores across accepted matches
    double avgCleanliness = 0;
    double avgNoise = 0;
    double avgSocial = 0;
    double avgFinancial = 0;

    for (final match in acceptedMatches) {
      avgCleanliness += (match['cleanlinessScore'] as int? ?? 50);
      avgNoise += (match['noiseToleranceScore'] as int? ?? 50);
      avgSocial += (match['socialFrequencyScore'] as int? ?? 50);
      avgFinancial += (match['financialReliabilityScore'] as int? ?? 50);
    }

    avgCleanliness /= acceptedMatches.length;
    avgNoise /= acceptedMatches.length;
    avgSocial /= acceptedMatches.length;
    avgFinancial /= acceptedMatches.length;

    if (avgCleanliness > 75) factors.add('Cleanliness compatibility');
    if (avgNoise > 75) factors.add('Noise tolerance alignment');
    if (avgSocial > 75) factors.add('Social habits match');
    if (avgFinancial > 75) factors.add('Financial reliability');

    return factors.isEmpty ? ['General compatibility'] : factors;
  }

  List<String> _identifyRiskFactors(List<Map<String, dynamic>> rejectedMatches) {
    if (rejectedMatches.isEmpty) return [];

    final riskFactors = <String>[];

    // Calculate average scores for rejected matches
    double avgCleanliness = 0;
    double avgNoise = 0;
    double avgSocial = 0;
    double avgFinancial = 0;

    for (final match in rejectedMatches) {
      avgCleanliness += (match['cleanlinessScore'] as int? ?? 50);
      avgNoise += (match['noiseToleranceScore'] as int? ?? 50);
      avgSocial += (match['socialFrequencyScore'] as int? ?? 50);
      avgFinancial += (match['financialReliabilityScore'] as int? ?? 50);
    }

    avgCleanliness /= rejectedMatches.length;
    avgNoise /= rejectedMatches.length;
    avgSocial /= rejectedMatches.length;
    avgFinancial /= rejectedMatches.length;

    // Identify low-scoring factors
    if (avgCleanliness < 40) riskFactors.add('Poor cleanliness habits');
    if (avgNoise < 40) riskFactors.add('Noise tolerance mismatch');
    if (avgSocial < 40) riskFactors.add('Social habits incompatibility');
    if (avgFinancial < 40) riskFactors.add('Financial reliability concerns');

    return riskFactors;
  }

  Future<void> _savePreferenceInsight(AIPreferenceInsight insight) async {
    try {
      await _databaseService.createPath(
        'user_preference_insights/${insight.userId}',
        insight.toJson(),
      );
    } catch (e) {
      AppLogger.error('AIPreferenceLearning', 'Failed to save preference insight', e);
    }
  }
}
