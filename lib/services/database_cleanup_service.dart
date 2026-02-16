import 'package:get/get.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class IDatabaseCleanupService {
  Future<Result<Map<String, dynamic>>> cleanupOldData();
  Future<Result<void>> deleteInactiveUsers(int inactiveDaysThreshold);
  Future<Result<void>> deleteExpiredSessions();
  Future<Result<void>> archiveOldMessages(int archiveDaysThreshold);
}

class DatabaseCleanupService implements IDatabaseCleanupService {
  late final UnifiedDatabaseService _databaseService;

  DatabaseCleanupService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize DatabaseCleanupService: $e');
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> cleanupOldData() async {
    try {
      final stats = {
        'deletedUsers': 0,
        'deletedSessions': 0,
        'archivedMessages': 0,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Run cleanup tasks
      await deleteInactiveUsers(90);
      await deleteExpiredSessions();
      await archiveOldMessages(30);

      // Log cleanup operation
      await _databaseService.createPath(
        'cleanupLogs/${DateTime.now().millisecondsSinceEpoch}',
        stats,
      );

      return Result.success(stats);
    } catch (e) {
      return Result.failure(Exception('Failed to cleanup old data: $e'));
    }
  }

  @override
  Future<Result<void>> deleteInactiveUsers(int inactiveDaysThreshold) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: inactiveDaysThreshold));
      
      final result = await _databaseService.readPath('profiles');
      
      if (result.isSuccess() && result.data is Map<String, dynamic>) {
        final data = result.data as Map<String, dynamic>;
        
        for (var entry in data.entries) {
          final userProfile = entry.value as Map<String, dynamic>?;
          if (userProfile != null) {
            final lastActive = userProfile['lastActiveAt'];
            if (lastActive != null) {
              final lastActiveDate = DateTime.parse(lastActive.toString());
              if (lastActiveDate.isBefore(cutoffDate)) {
                await _databaseService.deletePath('profiles/${entry.key}');
              }
            }
          }
        }
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('Failed to delete inactive users: $e'));
    }
  }

  @override
  Future<Result<void>> deleteExpiredSessions() async {
    try {
      final result = await _databaseService.readPath('sessions');
      
      if (result.isSuccess() && result.data is Map<String, dynamic>) {
        final data = result.data as Map<String, dynamic>;
        
        for (var entry in data.entries) {
          final session = entry.value as Map<String, dynamic>?;
          if (session != null) {
            final expiresAt = session['expiresAt'];
            if (expiresAt != null) {
              final expiryDate = DateTime.parse(expiresAt.toString());
              if (expiryDate.isBefore(DateTime.now())) {
                await _databaseService.deletePath('sessions/${entry.key}');
              }
            }
          }
        }
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('Failed to delete expired sessions: $e'));
    }
  }

  @override
  Future<Result<void>> archiveOldMessages(int archiveDaysThreshold) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: archiveDaysThreshold));
      
      final result = await _databaseService.readPath('conversations');
      
      if (result.isSuccess() && result.data is Map<String, dynamic>) {
        final data = result.data as Map<String, dynamic>;
        
        for (var conversationEntry in data.entries) {
          final conversation = conversationEntry.value as Map<String, dynamic>?;
          if (conversation != null) {
            final messages = conversation['messages'] as Map<String, dynamic>?;
            if (messages != null) {
              for (var messageEntry in messages.entries) {
                final message = messageEntry.value as Map<String, dynamic>?;
                if (message != null) {
                  final createdAt = message['createdAt'];
                  if (createdAt != null) {
                    final createdDate = DateTime.parse(createdAt.toString());
                    if (createdDate.isBefore(cutoffDate)) {
                      await _databaseService.updatePath(
                        'messageArchive/${conversationEntry.key}/${messageEntry.key}',
                        message,
                      );
                    }
                  }
                }
              }
            }
          }
        }
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('Failed to archive old messages: $e'));
    }
  }
}
