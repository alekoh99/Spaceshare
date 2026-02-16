import 'package:get/get.dart';
import '../utils/logger.dart';
import '../utils/result.dart';
import 'firebase_realtime_database_service.dart';

class UserDataSyncService {
  late final FirebaseRealtimeDatabaseService _databaseService;

  UserDataSyncService() {
    try {
      _databaseService = Get.find<FirebaseRealtimeDatabaseService>();
    } catch (e) {
      AppLogger.warning('SYNC', 'Database service not initialized: $e');
    }
  }

  /// Ensure user profile has all required fields for matching
  Future<void> syncUserData(String userId) async {
    try {
      final result = await _databaseService.readPath('users/$userId');
      
      if (!result.isSuccess() || result.data == null) {
        AppLogger.warning('SYNC', 'User not found: $userId');
        return;
      }

      final userData = Map<String, dynamic>.from(result.data as Map);
      final updates = <String, dynamic>{};
      bool needsUpdate = false;

      // Check and add missing critical fields
      if (userData['isActive'] == null) {
        updates['isActive'] = true;
        needsUpdate = true;
      }

      if (userData['isSuspended'] == null) {
        updates['isSuspended'] = false;
        needsUpdate = true;
      }

      if (userData['city'] == null || ((userData['city'] as String?)?.isEmpty ?? false)) {
        updates['city'] = 'Unknown';
        needsUpdate = true;
      }

      if (userData['state'] == null) {
        updates['state'] = '';
        needsUpdate = true;
      }

      if (userData['name'] == null) {
        updates['name'] = userData['displayName'] ?? '';
        needsUpdate = true;
      }

      if (userData['bio'] == null) {
        updates['bio'] = '';
        needsUpdate = true;
      }

      if (userData['phone'] == null) {
        updates['phone'] = '';
        needsUpdate = true;
      }

      if (userData['phoneVerified'] == null) {
        updates['phoneVerified'] = false;
        needsUpdate = true;
      }

      if (userData['email'] == null && userData['email'] != null) {
        updates['email'] = userData['email'];
        needsUpdate = true;
      }

      if (userData['emailVerified'] == null) {
        updates['emailVerified'] = false;
        needsUpdate = true;
      }

      if (userData['age'] == null) {
        updates['age'] = 0;
        needsUpdate = true;
      }

      if (userData['budgetMin'] == null) {
        updates['budgetMin'] = 0.0;
        needsUpdate = true;
      }

      if (userData['budgetMax'] == null) {
        updates['budgetMax'] = 0.0;
        needsUpdate = true;
      }

      if (userData['cleanliness'] == null) {
        updates['cleanliness'] = 5;
        needsUpdate = true;
      }

      if (userData['sleepSchedule'] == null) {
        updates['sleepSchedule'] = 'normal';
        needsUpdate = true;
      }

      if (userData['socialFrequency'] == null) {
        updates['socialFrequency'] = 5;
        needsUpdate = true;
      }

      if (userData['noiseTolerance'] == null) {
        updates['noiseTolerance'] = 5;
        needsUpdate = true;
      }

      if (userData['financialReliability'] == null) {
        updates['financialReliability'] = 5;
        needsUpdate = true;
      }

      if (userData['trustScore'] == null) {
        updates['trustScore'] = 50;
        needsUpdate = true;
      }

      if (userData['lastActiveAt'] == null) {
        updates['lastActiveAt'] = DateTime.now().toIso8601String();
        needsUpdate = true;
      }

      if (userData['authMethod'] == null) {
        // Try to infer auth method
        String authMethod = 'unknown';
        if (userData['phone'] != null && (userData['phone'] as String).isNotEmpty) {
          authMethod = 'phone';
        } else if (userData['email'] != null && (userData['email'] as String).isNotEmpty) {
          authMethod = 'email';
        }
        updates['authMethod'] = authMethod;
        needsUpdate = true;
      }

      if (needsUpdate) {
        await _databaseService.updatePath('users/$userId', updates);
        AppLogger.info('SYNC', 'User data synced successfully for: $userId');
      }
    } catch (e) {
      AppLogger.error('SYNC', 'Failed to sync user data for $userId', e);
    }
  }

  /// Batch migrate all users without proper matching fields
  Future<void> migrateAllUsers({int batchSize = 100}) async {
    try {
      AppLogger.info('SYNC', 'Starting user data migration');
      
      int totalProcessed = 0;
      final result = await _databaseService.readPath('users');
      
      if (result.isSuccess() && result.data is Map) {
        final usersData = Map<String, dynamic>.from(result.data as Map);
        
        for (final userId in usersData.keys) {
          try {
            final userData = usersData[userId];
            if (userData is Map) {
              await syncUserData(userId);
              totalProcessed++;
            }
          } catch (e) {
            AppLogger.debug('SYNC', 'Failed to migrate user $userId: $e');
          }
        }
      }

      AppLogger.success('SYNC', 'User migration completed. Total: $totalProcessed');
    } catch (e) {
      AppLogger.error('SYNC', 'User migration failed', e);
    }
  }
}
