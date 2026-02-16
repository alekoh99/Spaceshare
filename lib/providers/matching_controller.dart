import 'package:get/get.dart';
import 'dart:async';
import '../models/user_model.dart';
import '../models/match_model.dart';
import '../models/compatibility_model.dart';
import '../services/matching_service.dart';
import '../services/compatibility_service.dart';
import '../services/ai_recommendation_engine.dart';
import '../services/ai_preference_learning.dart';
import '../services/user_data_sync_service.dart';
import '../utils/logger.dart';
import 'auth_controller.dart';

class MatchingController extends GetxController {
  late IMatchingService _matchingService;
  late ICompatibilityService _compatibilityService;
  late AIRecommendationEngine _recommendationEngine;
  late AIPreferenceLearningService _preferenceLearning;

  IMatchingService get matchingService => _matchingService;
  ICompatibilityService get compatibilityService => _compatibilityService;
  AIRecommendationEngine get recommendationEngine => _recommendationEngine;
  AIPreferenceLearningService get preferenceLearning => _preferenceLearning;

  @override
  void onInit() {
    super.onInit();
    try {
      _matchingService = Get.find<IMatchingService>();
      _compatibilityService = Get.find<ICompatibilityService>();
      _recommendationEngine = Get.find<AIRecommendationEngine>();
      _preferenceLearning = Get.find<AIPreferenceLearningService>();
      authController = Get.find<AuthController>();
    } catch (e) {
      AppLogger.error('MatchingController', 'Failed to resolve services', e);
      rethrow;
    }
  }

  // State
  final swipeFeed = RxList<UserProfile>([]);
  final activeMatches = RxList<Match>([]);
  final isLoadingFeed = false.obs;
  final isLoadingMatches = false.obs;
  final isSwipingRight = false.obs; // Prevent double-tap
  final isSwipingLeft = false.obs; // Prevent double-tap
  final isLoadingMoreFeed = false.obs; // Track lazy loading
  final currentFeedIndex = 0.obs;
  final hasMoreFeed = true.obs;
  final feedOffset = 0.obs; // Track pagination offset
  final error = Rx<String?>(null);
  final currentCity = Rx<String?>(null);
  final minScore = 65.0.obs;
  final matchHistory = RxList<Match>([]);
  // AI-powered states
  final aiRecommendations = RxList<Map<String, dynamic>>([]);
  final isLoadingAIRecommendations = false.obs;
  final userPreferenceInsight = Rx<AIPreferenceInsight?>(null);
  
  // Stats state
  final totalMatches = 0.obs;
  final acceptedMatches = 0.obs;
  final activeConversations = 0.obs;
  final profileCompletion = 0.0.obs;
  final isLoadingStats = false.obs;
  final currentCompatibilityScore = 0.0.obs;

  late AuthController authController;

  // authController initialized in first onInit above

  Future<void> loadSwipeFeed({int limit = 10}) async {
    try {
      if (authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      isLoadingFeed.value = true;
      
      // Ensure user data is synced before loading matches (with timeout)
      try {
        final syncService = UserDataSyncService();
        await syncService.syncUserData(authController.currentUserId.value!).timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            throw TimeoutException('User data sync timeout');
          },
        );
      } catch (e) {
        AppLogger.warning('MatchingController', 'User data sync failed: $e');
        // Continue anyway - sync failure shouldn't block feed loading
      }

      // Use intelligent AI-powered feed with reasonable timeout
      final result = await _matchingService.getIntelligentSwipeFeed(
        authController.currentUserId.value!,
        limit: limit,
      ).timeout(
        const Duration(seconds: 30), // Total timeout for feed loading (increased from 15s)
        onTimeout: () {
          throw TimeoutException('Feed loading took too long');
        },
      );

      if (result.isSuccess()) {
        final profiles = result.getOrNull() ?? [];
        swipeFeed.value = List<UserProfile>.from(profiles);
        currentFeedIndex.value = 0;
        error.value = null;
        
        AppLogger.success('MatchingController', 'Loaded ${profiles.length} AI-ranked profiles');
      } else {
        throw result.getExceptionOrNull() ?? Exception('Failed to load feed');
      }
    } catch (e) {
      AppLogger.error('MatchingController', 'Error loading swipe feed', e);
      error.value = e.toString();
    } finally {
      isLoadingFeed.value = false;
    }
  }

  Future<void> loadMoreFeed() async {
    try {
      if (!hasMoreFeed.value || isLoadingMoreFeed.value || authController.currentUserId.value == null) return;

      isLoadingMoreFeed.value = true;
      final newOffset = feedOffset.value + 10;
      
      final profiles = await _matchingService.getSwipeFeed(
        authController.currentUserId.value!,
        offset: newOffset,
        minScore: minScore.value,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Failed to load more profiles'),
      );

      if (profiles.isEmpty) {
        hasMoreFeed.value = false;
      } else {
        swipeFeed.addAll(profiles);
        feedOffset.value = newOffset;
      }
    } catch (e) {
      AppLogger.error('MatchingController', 'Error loading more feed', e);
      error.value = e.toString();
    } finally {
      isLoadingMoreFeed.value = false;
    }
  }

  Future<void> swipeRight(String targetUserId) async {
    try {
      if (isSwipingRight.value) return; // Prevent double-tap
      if (authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }
      
      // Validate target user ID
      if (targetUserId.isEmpty || targetUserId == 'unknown') {
        error.value = 'Invalid profile: cannot create match with invalid user ID';
        Get.snackbar('Error', 'Invalid profile selected');
        AppLogger.warning('MatchingController', 'Attempted to create match with invalid user ID: $targetUserId');
        return;
      }

      isSwipingRight.value = true;
      
      // Run match creation without blocking UI
      await _matchingService.createMatch(
        authController.currentUserId.value!,
        targetUserId,
      );

      // Remove from swipe feed immediately for smooth UX
      swipeFeed.removeWhere((p) => p.userId == targetUserId);

      // Trigger preference learning in background (non-blocking)
      _preferenceLearning.analyzeUserPreferences(authController.currentUserId.value!).then(
        (insight) {
          userPreferenceInsight.value = insight;
          AppLogger.info('MatchingController', 'Preference insights updated');
        },
      ).catchError((e) {
        AppLogger.warning('MatchingController', 'Failed to update preferences: $e');
      });

      // Auto-load more profiles if running low
      if (swipeFeed.length < 5 && hasMoreFeed.value) {
        loadMoreFeed();
      }

      Get.snackbar(
        'Like Sent!',
        'If they like you back, it\'s a match!',
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', error.value ?? 'Unknown error');
    } finally {
      isSwipingRight.value = false;
    }
  }

  Future<void> swipeLeft(String targetUserId) async {
    try {
      if (isSwipingLeft.value) return; // Prevent double-tap
      
      isSwipingLeft.value = true;
      // Just remove from feed - optional: log the skip
      swipeFeed.removeWhere((p) => p.userId == targetUserId);

      // Auto-load more profiles if running low
      if (swipeFeed.length < 5 && hasMoreFeed.value) {
        loadMoreFeed();
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isSwipingLeft.value = false;
    }
  }

  Future<void> loadActiveMatches({int limit = 20}) async {
    try {
      if (authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      isLoadingMatches.value = true;
      final matches = await _matchingService.getActiveMatches(
        authController.currentUserId.value!,
        limit: limit,
      );
      activeMatches.value = matches;
      error.value = null;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingMatches.value = false;
    }
  }

  Future<void> loadMatchHistory() async {
    try {
      if (authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      isLoadingMatches.value = true;
      final matches = await _matchingService.getMatchHistory(
        authController.currentUserId.value!,
      );
      matchHistory.value = matches;
      error.value = null;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingMatches.value = false;
    }
  }

  Future<void> acceptMatch(String matchId) async {
    try {
      final match = await _matchingService.acceptMatch(matchId);
      activeMatches.removeWhere((m) => m.matchId == matchId);
      activeMatches.insert(0, match);

      Get.snackbar(
        'Match Accepted!',
        'Start chatting now',
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', error.value ?? 'Failed to accept match');
    }
  }

  /// Get AI-powered personalized recommendations
  Future<void> loadAIRecommendations() async {
    try {
      if (authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      isLoadingAIRecommendations.value = true;
      
      final result = await _recommendationEngine.getPersonalizedRecommendations(
        authController.currentUserId.value!,
        limit: 10,
      );

      if (result.isSuccess()) {
        aiRecommendations.value = result.getOrNull() ?? [];
        AppLogger.success(
          'MatchingController',
          'Loaded ${aiRecommendations.length} AI recommendations',
        );
      } else {
        throw result.getExceptionOrNull() ?? Exception('Failed to load recommendations');
      }
    } catch (e) {
      AppLogger.error('MatchingController', 'Error loading AI recommendations', e);
      error.value = e.toString();
    } finally {
      isLoadingAIRecommendations.value = false;
    }
  }

  /// Load user's preference insights from AI learning
  Future<void> loadPreferenceInsights() async {
    try {
      if (authController.currentUserId.value == null) return;

      final insight = await _preferenceLearning.getUserPreferenceInsight(
        authController.currentUserId.value!,
      );

      if (insight != null) {
        userPreferenceInsight.value = insight;
        AppLogger.info('MatchingController', 'Loaded preference insights');
      }
    } catch (e) {
      AppLogger.warning('MatchingController', 'Failed to load preference insights: $e');
    }
  }

  /// Record match outcome for ML training
  Future<void> recordMatchOutcome({
    required String matchId,
    required String outcome,
    required int durationDays,
    double? satisfactionScore,
    List<String> failureReasons = const [],
  }) async {
    try {
      final result = await _recommendationEngine.recordMatchOutcome(
        matchId: matchId,
        outcome: outcome,
        durationDays: durationDays,
        satisfactionScore: satisfactionScore,
        failureReasons: failureReasons,
      );

      if (result.isSuccess()) {
        AppLogger.success('MatchingController', 'Match outcome recorded: $matchId');
      }
    } catch (e) {
      AppLogger.error('MatchingController', 'Failed to record match outcome', e);
    }
  }

  Future<void> rejectMatch(String matchId) async {
    try {
      await _matchingService.rejectMatch(matchId);
      activeMatches.removeWhere((m) => m.matchId == matchId);

      Get.snackbar(
        'Match Rejected',
        'This match has been removed',
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', error.value ?? 'Failed to reject match');
    }
  }

  Future<void> archiveMatch(String matchId) async {
    try {
      await _matchingService.archiveMatch(matchId);
      activeMatches.removeWhere((m) => m.matchId == matchId);
    } catch (e) {
      error.value = e.toString();
    }
  }

  void nextProfile() {
    if (currentFeedIndex.value < swipeFeed.length - 1) {
      currentFeedIndex.value++;
    }
  }

  void previousProfile() {
    if (currentFeedIndex.value > 0) {
      currentFeedIndex.value--;
    }
  }

  void updateFilters(String? city, double minScoreValue) {
    currentCity.value = city;
    minScore.value = minScoreValue;
    loadSwipeFeed();
  }

  /// Calculate detailed compatibility with current profile
  Future<void> getCompatibilityDetails(UserProfile targetUser) async {
    try {
      if (authController.currentUser.value == null) {
        error.value = 'Current user not loaded';
        return;
      }

      final score = await _compatibilityService.calculateCompatibility(
        authController.currentUser.value!,
        targetUser,
      );

      currentCompatibilityScore.value = score.overallScore;
    } catch (e) {
      error.value = 'Failed to calculate compatibility: $e';
    }
  }

  /// Get list of compatibility dimensions for display
  List<CompatibilityDimension> getCompatibilityDimensions() {
    return _compatibilityService.getCompatibilityDimensions();
  }

  /// Load user statistics for dashboard
  Future<void> loadUserStats() async {
    try {
      if (authController.currentUserId.value == null) return;

      isLoadingStats.value = true;
      // userId loaded but only needed to verify it's not null (already done above)

      // Load accepted matches count
      final accepted = activeMatches.where((m) => m.status == 'matched').length;
      acceptedMatches.value = accepted;

      // Load total matches
      totalMatches.value = activeMatches.length;

      // Load profile completion
      final currentUser = authController.currentUser.value;
      if (currentUser != null) {
        profileCompletion.value = _calculateProfileCompletion(currentUser);
      }

      // Load active conversations (simplified - based on matches with messages)
      final conversations = activeMatches
          .where((m) => m.messageCount > 0)
          .length;
      activeConversations.value = conversations;

      AppLogger.success('MatchingController', 'Loaded user stats');
    } catch (e) {
      AppLogger.error('MatchingController', 'Error loading stats', e);
    } finally {
      isLoadingStats.value = false;
    }
  }

  /// Calculate profile completion percentage
  double _calculateProfileCompletion(UserProfile profile) {
    int completedFields = 0;
    int totalFields = 0;

    // Basic info
    totalFields += 5;
    if (profile.name.isNotEmpty) completedFields++;
    if (profile.age > 0) completedFields++;
    if (profile.city.isNotEmpty) completedFields++;
    if (profile.avatar != null && profile.avatar!.isNotEmpty) completedFields++;
    if (profile.bio.isNotEmpty) completedFields++;

    // Location preferences
    totalFields += 2;
    if (profile.neighborhoods.isNotEmpty) completedFields++;
    if (profile.budgetMin > 0 && profile.budgetMax > 0) completedFields++;

    // Compatibility info
    totalFields += 5;
    if (profile.cleanliness > 0) completedFields++;
    if (profile.sleepSchedule.isNotEmpty) completedFields++;
    if (profile.socialFrequency > 0) completedFields++;
    if (profile.noiseTolerance > 0) completedFields++;
    if (profile.financialReliability > 0) completedFields++;

    // Verification
    totalFields += 2;
    if (profile.verified) completedFields++;
    if (profile.backgroundCheckStatus == 'approved') completedFields++;

    return (completedFields / totalFields) * 100;
  }

  @override
  void onClose() {
    AppLogger.info('MatchingController', 'Disposing controller resources');
    swipeFeed.clear();
    activeMatches.clear();
    matchHistory.clear();
    aiRecommendations.clear();
    super.onClose();
  }
}

