import 'package:get/get.dart';
import '../utils/logger.dart';
import 'api_client.dart';
import 'sync_manager.dart';

/// Service initialization coordinator for frontend-backend sync
/// Initializes all required services in the correct order
class ServiceInitializer extends GetxService {
  static const String tag = 'ServiceInitializer';

  @override
  void onInit() {
    super.onInit();
    AppLogger.info(tag, 'Starting service initialization...');
  }

  /// Initialize all services required for sync
  Future<void> initializeAll() async {
    try {
      // 1. Initialize API Client first
      await _initializeApiClient();

      // 2. Initialize Sync Manager
      await _initializeSyncManager();

      AppLogger.success(tag, 'All services initialized successfully');
    } catch (e) {
      AppLogger.error(tag, 'Service initialization failed: $e');
      rethrow;
    }
  }

  /// Initialize API Client service
  Future<void> _initializeApiClient() async {
    try {
      // Check if already initialized
      try {
        Get.find<ApiClient>();
        AppLogger.debug(tag, 'ApiClient already initialized');
        return;
      } catch (e) {
        // Not initialized yet
      }

      AppLogger.info(tag, 'Initializing ApiClient...');
      Get.put<ApiClient>(ApiClient());
      
      // Verify API connectivity
      final apiClient = Get.find<ApiClient>();
      final isHealthy = await apiClient.isHealthy();
      
      if (isHealthy) {
        AppLogger.success(tag, 'ApiClient initialized and API is healthy');
      } else {
        AppLogger.warning(tag, 'ApiClient initialized but API health check failed');
      }
    } catch (e) {
      AppLogger.error(tag, 'Failed to initialize ApiClient: $e');
      rethrow;
    }
  }

  /// Initialize Sync Manager service
  Future<void> _initializeSyncManager() async {
    try {
      // Check if already initialized
      try {
        Get.find<SyncManager>();
        AppLogger.debug(tag, 'SyncManager already initialized');
        return;
      } catch (e) {
        // Not initialized yet
      }

      AppLogger.info(tag, 'Initializing SyncManager...');
      Get.put<SyncManager>(SyncManager());
      
      final syncManager = Get.find<SyncManager>();
      AppLogger.success(tag, 'SyncManager initialized');
      
      // Log sync stats periodically
      _startStatsLogging(syncManager);
    } catch (e) {
      AppLogger.error(tag, 'Failed to initialize SyncManager: $e');
      rethrow;
    }
  }

  /// Start periodic logging of sync statistics
  void _startStatsLogging(SyncManager syncManager) {
    Future.delayed(const Duration(seconds: 5), () {
      final stats = syncManager.getStats();
      AppLogger.debug(tag, 'Sync Stats: $stats');
    });
  }

  /// Initialize all app services with proper dependency injection
  /// Call this static method during app startup
  static Future<void> initializeAppServices() async {
    // Create service initializer
    final initializer = Get.put<ServiceInitializer>(ServiceInitializer());
    
    // Initialize all services
    await initializer.initializeAll();
  }
}
