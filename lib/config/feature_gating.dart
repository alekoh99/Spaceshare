import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/subscription_management_service.dart';
import '../providers/auth_controller.dart';

/// Feature gating middleware for subscription-based access control
/// Prevents unauthorized feature access based on subscription tier
class FeatureGatingMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  /// Check if user has access to a feature
  /// Returns true if allowed, false otherwise
  static Future<bool> hasAccessToFeature(String featureKey) async {
    try {
      // Get userId from auth service
      final authController = Get.find<AuthController>();
      final userId = authController.currentUserId.value;
      
      if (userId == null) {
        // Unauthenticated users only have basic access
        return _isFreeFeature(featureKey);
      }
      
      // Get user's subscription tier
      final tier = await getUserSubscriptionTier();
      if (tier == null) return false;
      
      // Check if feature is available for this tier
      final tierFeatures = SubscriptionFeatures.getTierFeatures()[tier] ?? [];
      return tierFeatures.contains(featureKey);
    } catch (e) {
      debugPrint('[FeatureGating] Error checking feature access: $e');
      return _isFreeFeature(featureKey);
    }
  }

  /// Get current user's subscription tier
  static Future<SubscriptionTier?> getUserSubscriptionTier() async {
    try {
      // Get userId from auth service
      final authController = Get.find<AuthController>();
      final userId = authController.currentUserId.value;
      
      if (userId == null) {
        return SubscriptionTier.free;
      }
      
      // Get subscription from service
      final subscriptionService = Get.find<ISubscriptionManagementService>();
      final subscriptionResult = await subscriptionService.getUserSubscription(userId);
      
      // Map subscription status to tier
      if (subscriptionResult.isSuccess()) {
        final subscription = subscriptionResult.getOrNull() as Map<String, dynamic>?;
        if (subscription != null) {
          if (subscription["plan"] == "platinum") {
            return SubscriptionTier.platinum;
          } else if (subscription["plan"] == "premium") {
            return SubscriptionTier.premium;
          }
        }
      }
      
      return SubscriptionTier.free;
    } catch (e) {
      debugPrint('[FeatureGating] Error getting subscription tier: $e');
      return SubscriptionTier.free;
    }
  }

  /// Check if feature is available to free users
  static bool _isFreeFeature(String featureKey) {
    final freeFeatures = SubscriptionFeatures.getTierFeatures()[SubscriptionTier.free] ?? [];
    return freeFeatures.contains(featureKey);
  }

  /// Check multiple features at once
  static Future<Map<String, bool>> checkMultipleFeatures(
    List<String> featureKeys,
  ) async {
    final results = <String, bool>{};
    for (final feature in featureKeys) {
      results[feature] = await hasAccessToFeature(feature);
    }
    return results;
  }

  /// Enforce feature access - navigates to paywall if denied
  static Future<bool> enforceFeatureAccess(String featureKey) async {
    final hasAccess = await hasAccessToFeature(featureKey);
    if (!hasAccess) {
      Get.toNamed('/paywall', arguments: {'feature': featureKey});
      return false;
    }
    return true;
  }
}

/// Subscription tiers
enum SubscriptionTier { free, premium, platinum }

/// Subscription feature constants
class SubscriptionFeatures {
  // Basic features (free tier)
  static const String basicMessaging = 'basic_messaging';
  static const String basicMatching = 'basic_matching';
  static const String profileView = 'profile_view';

  // Premium features
  static const String unlimitedMatches = 'unlimited_matches';
  static const String unlimitedMessages = 'unlimited_messages';
  static const String advancedFilters = 'advanced_filters';
  static const String matchHistory = 'match_history';

  // Platinum features
  static const String prioritySupport = 'priority_support';
  static const String premiumBadges = 'premium_badges';
  static const String advancedAnalytics = 'advanced_analytics';
  static const String videoChat = 'video_chat';

  // Get all features by tier
  static Map<SubscriptionTier, List<String>> getTierFeatures() {
    return {
      SubscriptionTier.free: [
        basicMessaging,
        basicMatching,
        profileView,
      ],
      SubscriptionTier.premium: [
        basicMessaging,
        basicMatching,
        profileView,
        unlimitedMatches,
        unlimitedMessages,
        advancedFilters,
        matchHistory,
      ],
      SubscriptionTier.platinum: [
        basicMessaging,
        basicMatching,
        profileView,
        unlimitedMatches,
        unlimitedMessages,
        advancedFilters,
        matchHistory,
        prioritySupport,
        premiumBadges,
        advancedAnalytics,
        videoChat,
      ],
    };
  }
}
