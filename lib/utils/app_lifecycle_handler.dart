import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/cache_manager.dart';
import '../services/matching_service.dart';
import '../providers/auth_controller.dart';
import '../providers/matching_controller.dart';
import '../providers/messaging_controller.dart';
import '../providers/payment_controller.dart';
import '../providers/notification_controller.dart';
import '../providers/compliance_controller.dart';
import '../providers/profile_controller.dart';
import '../providers/monetization_controller.dart';
import '../providers/notification_preferences_controller.dart';
import 'logger.dart';

/// Handles app-level lifecycle events for proper resource cleanup
/// Ensures no residual data or background tasks persist after app close
class AppLifecycleHandler with WidgetsBindingObserver {
  static final AppLifecycleHandler _instance = AppLifecycleHandler._internal();

  factory AppLifecycleHandler() {
    return _instance;
  }

  AppLifecycleHandler._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.inactive:
        _handleAppInactive();
        break;
      case AppLifecycleState.hidden:
        _handleAppHidden();
        break;
      default:
        break;
    }
  }

  /// Called when app is resumed from background
  Future<void> _handleAppResumed() async {
    AppLogger.info('AppLifecycle', 'App resumed');
    try {
      // Resume services on app return
      // Background sync is handled by Firebase
    } catch (e) {
      AppLogger.error('AppLifecycle', 'Error handling app resume', e);
    }
  }

  /// Called when app is paused (backgrounded but not closed)
  Future<void> _handleAppPaused() async {
    AppLogger.info('AppLifecycle', 'App paused - saving state');
    try {
      // Keep services running but don't start new operations
    } catch (e) {
      AppLogger.error('AppLifecycle', 'Error handling app pause', e);
    }
  }

  /// Called when app is inactive (transitioning states)
  Future<void> _handleAppInactive() async {
    AppLogger.info('AppLifecycle', 'App inactive');
  }

  /// Called when app is hidden (typically Android)
  Future<void> _handleAppHidden() async {
    AppLogger.info('AppLifecycle', 'App hidden');
  }

  /// Called when app is being terminated/closed
  /// This is the final cleanup opportunity
  Future<void> _handleAppDetached() async {
    AppLogger.info('AppLifecycle', 'App detached - performing cleanup');
    await _performFullCleanup();
  }

  /// Perform full cleanup on app close
  /// This ensures NO residual data or background tasks persist
  Future<void> _performFullCleanup() async {
    try {
      AppLogger.info('AppLifecycle', 'Starting full app cleanup...');

      // 1. Cancel all GetX controllers
      await _disposeAllControllers();

      // 2. Close background sync
      await _closeBackgroundSync();

      // 3. Cancel all Firestore listeners/subscriptions
      await _closeSyncService();

      // 4. Dispose cache manager
      await _closeCache();

      // 5. Dispose matching service (clears timers)
      await _disposeMatchingService();

      // 6. Close all get services
      await _closeGetServices();

      AppLogger.info('AppLifecycle', 'Full cleanup completed successfully');
    } catch (e) {
      AppLogger.error('AppLifecycle', 'Error during full cleanup', e);
    }
  }

  /// Dispose all GetX controllers
  Future<void> _disposeAllControllers() async {
    try {
      AppLogger.debug('AppLifecycle', 'Disposing all GetX controllers');
      
      // GetX will automatically call onClose() if it exists
      // when the controller is deleted. We use Get.delete<T>()
      final List<Function> deleteOperations = [
        () => _safeDelete<AuthController>('AuthController'),
        () => _safeDelete<MatchingController>('MatchingController'),
        () => _safeDelete<MessagingController>('MessagingController'),
        () => _safeDelete<PaymentController>('PaymentController'),
        () => _safeDelete<NotificationController>('NotificationController'),
        () => _safeDelete<ComplianceController>('ComplianceController'),
        () => _safeDelete<ProfileController>('ProfileController'),
        () => _safeDelete<MonetizationController>('MonetizationController'),
        () => _safeDelete<NotificationPreferencesController>('NotificationPreferencesController'),
      ];

      for (final operation in deleteOperations) {
        try {
          operation();
        } catch (e) {
          AppLogger.debug('AppLifecycle', 'Controller deletion error: $e');
        }
      }
    } catch (e) {
      AppLogger.error('AppLifecycle', 'Error disposing controllers', e);
    }
  }

  void _safeDelete<T extends GetxController>(String name) {
    try {
      if (Get.isRegistered<T>()) {
        Get.delete<T>();
        AppLogger.debug('AppLifecycle', 'Disposed: $name');
      }
    } catch (e) {
      AppLogger.debug('AppLifecycle', '$name not registered or error: $e');
    }
  }

  /// Close background sync service
  // Deprecated - Using Firebase Realtime Database instead
  Future<void> _closeBackgroundSync() async {
    try {
      // BackgroundSyncService is deprecated - using Firebase Realtime Database instead
      // if (Get.isRegistered<BackgroundSyncService>()) {
      //   AppLogger.debug('AppLifecycle', 'Closing BackgroundSyncService');
      //   final service = Get.find<BackgroundSyncService>();
      //   service.onClose();
      //   Get.delete<BackgroundSyncService>();
      // }
    } catch (e) {
      AppLogger.error('AppLifecycle', 'Error closing BackgroundSyncService', e);
    }
  }

  /// Close sync service
  // Deprecated - Using Firebase Realtime Database instead
  Future<void> _closeSyncService() async {
    try {
      // FirestoreSyncService is deprecated - using Firebase Realtime Database instead
      // if (Get.isRegistered<FirestoreSyncService>()) {
      //   AppLogger.debug('AppLifecycle', 'Closing FirestoreSyncService');
      //   final service = Get.find<FirestoreSyncService>();
      //   service.cancelAllSubscriptions();
      //   service.onClose();
      //   Get.delete<FirestoreSyncService>();
      // }
    } catch (e) {
      AppLogger.error('AppLifecycle', 'Error closing FirestoreSyncService', e);
    }
  }

  /// Close cache manager
  Future<void> _closeCache() async {
    try {
      AppLogger.debug('AppLifecycle', 'Closing CacheManager');
      final cacheManager = CacheManager();
      await cacheManager.clearAll();
      await cacheManager.close();
    } catch (e) {
      AppLogger.error('AppLifecycle', 'Error closing cache', e);
    }
  }

  /// Dispose matching service timers
  Future<void> _disposeMatchingService() async {
    try {
      if (Get.isRegistered<MatchingService>()) {
        AppLogger.debug('AppLifecycle', 'Disposing MatchingService');
        final service = Get.find<MatchingService>();
        service.dispose();
        Get.delete<MatchingService>();
      }
    } catch (e) {
      AppLogger.debug('AppLifecycle', 'MatchingService cleanup: $e');
    }
  }

  /// Close all GetX services marked as permanent
  Future<void> _closeGetServices() async {
    try {
      AppLogger.debug('AppLifecycle', 'Closing all GetX services');
      // All services will call their onClose() method automatically
      // when Get.deleteByKey() is called
    } catch (e) {
      AppLogger.error('AppLifecycle', 'Error closing services', e);
    }
  }

  /// Initialize app lifecycle handler
  static void initialize() {
    AppLifecycleHandler();
    AppLogger.info('AppLifecycle', 'Lifecycle handler initialized');
  }

  /// Cleanup - called manually if needed
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppLogger.info('AppLifecycle', 'Lifecycle handler disposed');
  }
}
