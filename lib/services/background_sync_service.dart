import 'package:get/get.dart';
import 'dart:async';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class IBackgroundSyncService {
  Future<Result<void>> syncUserData(String userId);
  Future<Result<void>> syncPendingChanges(String userId);
  Future<void> startPeriodicSync();
  Future<void> stopPeriodicSync();
}

class BackgroundSyncService extends GetxController implements IBackgroundSyncService {
  late final UnifiedDatabaseService _databaseService;
  Timer? _syncTimer;
  final Duration _syncInterval = const Duration(minutes: 5);

  @override
  void onInit() {
    super.onInit();
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize BackgroundSyncService: $e');
    }
  }

  @override
  Future<Result<void>> syncUserData(String userId) async {
    try {
      // Sync profile
      final profileResult = await _databaseService.getProfile(userId);
      if (profileResult.isSuccess()) {
        await _databaseService.updatePath(
          'userSyncLog/$userId',
          {
            'lastProfileSync': DateTime.now().toIso8601String(),
            'status': 'synced',
          },
        );
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('Failed to sync user data: $e'));
    }
  }

  @override
  Future<Result<void>> syncPendingChanges(String userId) async {
    try {
      final pendingResult = await _databaseService.readPath('pendingChanges/$userId');
      
      if (pendingResult.isSuccess() && pendingResult.data is Map<String, dynamic>) {
        final pendingData = pendingResult.data as Map<String, dynamic>;
        
        for (var entry in pendingData.entries) {
          try {
            // Process each pending change
            await _databaseService.updatePath(
              'profiles/$userId/${entry.key}',
              entry.value,
            );
            
            // Remove from pending after successful sync
            await _databaseService.deletePath('pendingChanges/$userId/${entry.key}');
          } catch (e) {
            // Log individual change failure but continue with others
            continue;
          }
        }
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('Failed to sync pending changes: $e'));
    }
  }

  @override
  Future<void> startPeriodicSync() async {
    _syncTimer = Timer.periodic(_syncInterval, (timer) {
      // This would sync for current user if authenticated
    });
  }

  @override
  Future<void> stopPeriodicSync() async {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  @override
  void onClose() {
    stopPeriodicSync();
    super.onClose();
  }
}
