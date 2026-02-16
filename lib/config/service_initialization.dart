import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/matching_service.dart';
import '../services/ai_recommendation_engine.dart';
import '../services/ai_preference_learning.dart';
import '../services/listing_service.dart';
import '../services/review_service.dart';
import '../services/unified_database_service.dart';
import '../services/api_client.dart';
import '../services/sync_manager.dart';
import '../services/auth_user_service.dart';
import '../services/compatibility_service.dart';
import '../services/database_service.dart';
import '../services/firebase_realtime_database_service.dart';
import '../services/database_health_service.dart';
import '../services/mongodb_database_service.dart';
import '../services/messaging_service.dart';
import '../services/payment_service.dart';
import '../services/stripe_connect_service.dart';
import '../services/user_blocking_service.dart';
import '../services/user_reputation_service.dart';
import '../services/notification_service.dart';
import '../services/notification_preferences_service.dart';
import '../services/compliance_service.dart';
import '../services/moderation_workflow_service.dart';
import '../services/dispute_resolution_service.dart';
import '../services/identity_verification_service.dart';

/// Initializes core services required for SpaceShare platform
/// Called once during app startup to configure dependency injection
class ServiceInitialization {
  static Future<void> initialize() async {
    try {
      // FIRESTORE OPTIMIZATION SERVICE (initialize first for performance)
      // Deprecated - Using Firebase Realtime Database instead
      // try {
      //   await Get.putAsync<FirestoreOptimizationService>(
      //     () async => FirestoreOptimizationService(),
      //     permanent: true,
      //   );
      // } catch (e) {
      //   debugPrint('[ServiceInitialization] Error initializing FirestoreOptimizationService: $e');
      // }

      // BACKGROUND SYNC SERVICE (for intelligent sync)
      // Deprecated - Using Firebase Realtime Database instead
      // try {
      //   await Get.putAsync<BackgroundSyncService>(
      //     () async => BackgroundSyncService(),
      //     permanent: true,
      //   );
      // } catch (e) {
      //   debugPrint('[ServiceInitialization] Error initializing BackgroundSyncService: $e');
      // }

      // Firestore Connectivity Service (MUST be early for retry logic)
      // Deprecated - Using Firebase Realtime Database instead
      // try {
      //   await Get.putAsync<FirestoreConnectivityService>(
      //     () async => FirestoreConnectivityService(),
      //     permanent: true,
      //   );
      // } catch (e) {
      //   debugPrint('[ServiceInitialization] Error initializing FirestoreConnectivityService: $e');
      // }

      // Firestore Diagnostics Service
      // Deprecated - Using Firebase Realtime Database instead
      // try {
      //   await Get.putAsync<FirestoreDiagnosticsService>(
      //     () async => FirestoreDiagnosticsService(),
      //     permanent: true,
      //   );
      // } catch (e) {
      //   debugPrint('[ServiceInitialization] Error initializing FirestoreDiagnosticsService: $e');
      // }

      // Firebase Realtime Database Service (core database layer)
      try {
        await Get.putAsync<FirebaseRealtimeDatabaseService>(
          () async => FirebaseRealtimeDatabaseService(),
          permanent: true,
        );
        debugPrint('[ServiceInitialization] FirebaseRealtimeDatabaseService initialized');
        
        // Also register as IDatabaseService interface for dependency injection
        final firebaseService = Get.find<FirebaseRealtimeDatabaseService>();
        Get.put<IDatabaseService>(firebaseService, permanent: true);
        debugPrint('[ServiceInitialization] IDatabaseService registered as Firebase implementation');
      } catch (e) {
        debugPrint('[ServiceInitialization] Error initializing FirebaseRealtimeDatabaseService: $e');
      }

      // MongoDB Database Service (NoSQL database)
      try {
        await Get.putAsync<MongoDBDatabaseService>(
          () async => MongoDBDatabaseService(),
          permanent: true,
        );
        debugPrint('[ServiceInitialization] MongoDBDatabaseService initialized');
      } catch (e) {
        debugPrint('[ServiceInitialization] Error initializing MongoDBDatabaseService: $e');
      }

      // Unified Database Service (Firebase Realtime Database + PostgreSQL fallback)
      try {
        await Get.putAsync<UnifiedDatabaseService>(
          () async => UnifiedDatabaseService(),
          permanent: true,
        );
      } catch (e) {
        debugPrint('[ServiceInitialization] Error initializing UnifiedDatabaseService: $e');
      }

      // Database Health Service (health monitoring)
      try {
        Get.put<DatabaseHealthService>(
          DatabaseHealthService(),
          permanent: true,
        );
        debugPrint('[ServiceInitialization] DatabaseHealthService initialized');
      } catch (e) {
        debugPrint('[ServiceInitialization] Error initializing DatabaseHealthService: $e');
      }

      // API Client Service (for backend communication)
      try {
        Get.put<ApiClient>(ApiClient(), permanent: true);
        debugPrint('[ServiceInitialization] ApiClient initialized');
      } catch (e) {
        debugPrint('[ServiceInitialization] Error initializing ApiClient: $e');
      }

      // Sync Manager Service (for frontend-backend data sync)
      try {
        Get.put<SyncManager>(SyncManager(), permanent: true);
        debugPrint('[ServiceInitialization] SyncManager initialized');
      } catch (e) {
        debugPrint('[ServiceInitialization] Error initializing SyncManager: $e');
      }

      // User Service (for user authentication and management)
      try {
        Get.put<IUserService>(UserService(), permanent: true);
        debugPrint('[ServiceInitialization] UserService initialized');
      } catch (e) {
        debugPrint('[ServiceInitialization] Error initializing UserService: $e');
      }

      // Compatibility Service (for matching compatibility calculations)
      try {
        await Get.putAsync<ICompatibilityService>(
          () async => CompatibilityService(),
          permanent: true,
        );
        debugPrint('[ServiceInitialization] CompatibilityService initialized');
      } catch (e) {
        debugPrint('[ServiceInitialization] Error initializing CompatibilityService: $e');
      }

      // Messaging Service (for user conversations)
      try {
        await Get.putAsync<IMessagingService>(
          () async => MessagingService(),
          permanent: true,
        );
        debugPrint('[ServiceInitialization] MessagingService initialized');
      } catch (e) {
        debugPrint('[ServiceInitialization] Error initializing MessagingService: $e');
      }

      // Core Services
      try {
        Get.put<IMatchingService>(MatchingService(), permanent: true);
      } catch (e) {
        debugPrint('[ServiceInitialization] Error initializing MatchingService: $e');
      }

      // AI & ML Services

      try {
        await Get.putAsync<AIRecommendationEngine>(
          () async => AIRecommendationEngine(),
          permanent: true,
        );
      } catch (e) {
        debugPrint('[ServiceInitialization] Error initializing AIRecommendationEngine: $e');
      }

      try {
        await Get.putAsync<AIPreferenceLearningService>(
          () async => AIPreferenceLearningService(),
          permanent: true,
        );
      } catch (e) {
        debugPrint('[ServiceInitialization] Error initializing AIPreferenceLearningService: $e');
      }

      // Listings & Reviews Services (NEW)
      try {
        Get.put<ListingService>(ListingService(), permanent: true);
      } catch (e) {
        debugPrint('[ServiceInitialization] Error initializing ListingService: $e');
      }

      try {
        Get.put<ReviewService>(ReviewService(), permanent: true);
      } catch (e) {
        debugPrint('[ServiceInitialization] Error initializing ReviewService: $e');
      }

      // Payment Services (for payment and Stripe Connect functionality)
      try {
        Get.put<IPaymentService>(PaymentService(), permanent: true);
        debugPrint('[ServiceInitialization] PaymentService initialized');
      } catch (e) {
        debugPrint('[ServiceInitialization] Error initializing PaymentService: $e');
      }

      try {
        Get.put<IStripeConnectService>(StripeConnectService(), permanent: true);
        debugPrint('[ServiceInitialization] StripeConnectService initialized');
      } catch (e) {
        debugPrint('[ServiceInitialization] Error initializing StripeConnectService: $e');
      }

      // USER MANAGEMENT SERVICES
      try {
        Get.put<IUserBlockingService>(UserBlockingService(), permanent: true);
        debugPrint('[ServiceInitialization] UserBlockingService initialized');
      } catch (e) {
        debugPrint('[ServiceInitialization] Error initializing UserBlockingService: $e');
      }

      try {
        Get.put<IUserReputationService>(UserReputationService(), permanent: true);
        debugPrint('[ServiceInitialization] UserReputationService initialized');
      } catch (e) {
        debugPrint('[ServiceInitialization] Error initializing UserReputationService: $e');
      }

      // NOTIFICATION SERVICES
      try {
        final notificationService = NotificationService();
        Get.put<INotificationService>(notificationService, permanent: true);
        Get.put<NotificationService>(notificationService, permanent: true);
        debugPrint('[ServiceInitialization] NotificationService initialized');
      } catch (e) {
        debugPrint('[ServiceInitialization] Error initializing NotificationService: $e');
      }

      try {
        Get.put<INotificationPreferencesService>(NotificationPreferencesService(), permanent: true);
        debugPrint('[ServiceInitialization] NotificationPreferencesService initialized');
      } catch (e) {
        debugPrint('[ServiceInitialization] Error initializing NotificationPreferencesService: $e');
      }

      // COMPLIANCE & MODERATION SERVICES
      try {
        Get.put<IComplianceService>(ComplianceService(), permanent: true);
        debugPrint('[ServiceInitialization] ComplianceService initialized');
      } catch (e) {
        debugPrint('[ServiceInitialization] Error initializing ComplianceService: $e');
      }

      try {
        Get.put<IModerationWorkflowService>(ModerationWorkflowService(), permanent: true);
        debugPrint('[ServiceInitialization] ModerationWorkflowService initialized');
      } catch (e) {
        debugPrint('[ServiceInitialization] Error initializing ModerationWorkflowService: $e');
      }

      // DISPUTE & VERIFICATION SERVICES
      try {
        Get.put<IDisputeResolutionService>(DisputeResolutionService(), permanent: true);
        debugPrint('[ServiceInitialization] DisputeResolutionService initialized');
      } catch (e) {
        debugPrint('[ServiceInitialization] Error initializing DisputeResolutionService: $e');
      }

      try {
        Get.put<IIdentityVerificationService>(IdentityVerificationService(), permanent: true);
        debugPrint('[ServiceInitialization] IdentityVerificationService initialized');
      } catch (e) {
        debugPrint('[ServiceInitialization] Error initializing IdentityVerificationService: $e');
      }

      debugPrint('[ServiceInitialization] All core services initialized');
    } catch (e, stackTrace) {
      debugPrint('[ServiceInitialization] Fatal error initializing services: $e');
      debugPrint('[ServiceInitialization] Stack trace: $stackTrace');
    }
  }

  /// Get service instance by type
  static T getService<T>() {
    if (Get.isRegistered<T>()) {
      return Get.find<T>();
    }
    throw Exception('Service of type $T not registered');
  }

  /// Check if core services are initialized
  static bool isFullyInitialized() {
    return Get.isRegistered<UnifiedDatabaseService>() &&
        Get.isRegistered<ApiClient>() &&
        Get.isRegistered<SyncManager>() &&
        Get.isRegistered<IMatchingService>();
  }
}
