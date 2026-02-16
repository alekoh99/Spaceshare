
import 'package:get/get.dart';
import 'dart:async';
import '../utils/logger.dart';
import 'firebase_realtime_database_service.dart';
import 'mongodb_database_service.dart';

/// Health check service for database connectivity
/// Monitors and reports on database availability
class DatabaseHealthService extends GetxService {
  FirebaseRealtimeDatabaseService? _rtdbService;
  MongoDBDatabaseService? _mongoDbService;
  
  // Health status indicators
  final RxBool isRtdbHealthy = false.obs;
  final RxBool isMongoHealthy = false.obs;
  final RxString lastHealthCheckTime = ''.obs;
  final RxString rtdbHealthIssue = ''.obs;
  final RxString mongoHealthIssue = ''.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    try {
      _rtdbService = Get.find<FirebaseRealtimeDatabaseService>();
      AppLogger.debug('DatabaseHealth', 'RTDB service initialized');
    } catch (e) {
      AppLogger.warning('DatabaseHealth', 'RTDB service not initialized: $e');
      _rtdbService = null;
    }
    try {
      _mongoDbService = Get.find<MongoDBDatabaseService>();
      AppLogger.debug('DatabaseHealth', 'MongoDB service initialized');
    } catch (e) {
      AppLogger.warning('DatabaseHealth', 'MongoDB service not initialized: $e');
      _mongoDbService = null;
    }
  }

  /// Perform comprehensive health check on all databases
  Future<void> performHealthCheck() async {
    try {
      AppLogger.info('DatabaseHealth', 'Starting health check...');
      lastHealthCheckTime.value = DateTime.now().toIso8601String();

      // Check Firebase Realtime Database
      await _checkRtdbHealth();

      // Check MongoDB
      await _checkMongoHealth();

      AppLogger.info('DatabaseHealth',
        'Health check complete: RTDB=${isRtdbHealthy.value}, MongoDB=${isMongoHealthy.value}');
    } catch (e) {
      AppLogger.error('DatabaseHealth', 'Health check failed', e);
    }
  }

  /// Check Firebase Realtime Database connectivity and responsiveness
  Future<void> _checkRtdbHealth() async {
    try {
      if (_rtdbService == null) {
        // Try to find it again
        try {
          _rtdbService = Get.find<FirebaseRealtimeDatabaseService>();
        } catch (e) {
          isRtdbHealthy.value = false;
          rtdbHealthIssue.value = 'Service not initialized';
          AppLogger.warning('DatabaseHealth', 'RTDB service unavailable: $e');
          return;
        }
      }

      final startTime = DateTime.now();
      
      // Simple connection check with timeout
      final isConnected = await _rtdbService!.isConnected()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException('RTDB health check timeout', const Duration(seconds: 5)),
          );

      final duration = DateTime.now().difference(startTime);
      isRtdbHealthy.value = isConnected;
      rtdbHealthIssue.value = '';
      
      AppLogger.success('DatabaseHealth',
        '✅ SUCCESS: Firebase RTDB healthy (response time: ${duration.inMilliseconds}ms)');
    } catch (e) {
      isRtdbHealthy.value = false;
      rtdbHealthIssue.value = e.toString();
      AppLogger.warning('DatabaseHealth', '⚠️ WARNING: Firebase RTDB unhealthy: $e');
    }
  }

  /// Check MongoDB connectivity
  Future<void> _checkMongoHealth() async {
    try {
      if (_mongoDbService == null) {
        // Try to find it again
        try {
          _mongoDbService = Get.find<MongoDBDatabaseService>();
        } catch (e) {
          isMongoHealthy.value = false;
          mongoHealthIssue.value = 'Service not initialized';
          AppLogger.warning('DatabaseHealth', '⚠️ WARNING: MongoDB service unavailable: $e');
          return;
        }
      }

      final startTime = DateTime.now();
      
      final isConnected = await _mongoDbService!.isConnected();
      final duration = DateTime.now().difference(startTime);
      
      isMongoHealthy.value = isConnected;
      if (isConnected) {
        mongoHealthIssue.value = '';
        AppLogger.success('DatabaseHealth',
          '✅ SUCCESS: MongoDB healthy (response time: ${duration.inMilliseconds}ms)');
      } else {
        mongoHealthIssue.value = 'Connection failed';
        AppLogger.warning('DatabaseHealth', '⚠️ WARNING: MongoDB unhealthy: Connection failed');
      }
    } catch (e) {
      isMongoHealthy.value = false;
      mongoHealthIssue.value = e.toString();
      AppLogger.warning('DatabaseHealth', '⚠️ WARNING: MongoDB health check error: $e');
    }
  }

  /// Check if at least one database is available
  bool isAnyDatabaseAvailable() {
    return isRtdbHealthy.value || isMongoHealthy.value;
  }

  /// Check if all databases are available
  bool areAllDatabasesAvailable() {
    return isRtdbHealthy.value && isMongoHealthy.value;
  }

  /// Get health status summary
  Map<String, dynamic> getHealthSummary() {
    return {
      'rtdb': {
        'healthy': isRtdbHealthy.value,
        'issue': rtdbHealthIssue.value,
      },
      'mongodb': {
        'healthy': isMongoHealthy.value,
        'issue': mongoHealthIssue.value,
      },
      'lastCheck': lastHealthCheckTime.value,
      'anyAvailable': isAnyDatabaseAvailable(),
      'allAvailable': areAllDatabasesAvailable(),
    };
  }
}
