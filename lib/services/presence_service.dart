import 'package:get/get.dart';
import '../utils/result.dart';
import 'unified_database_service.dart';

abstract class IPresenceService {
  Future<Result> setPresence(String userId, String status);
  Future<Result> getPresence(String userId);
  Future<Result> getMultiplePresence(List<String> userIds);
}

class PresenceService extends GetxService implements IPresenceService {
  late final UnifiedDatabaseService _databaseService;

  @override
  Future<void> onInit() async {
    super.onInit();
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw Exception('Failed to initialize PresenceService: $e');
    }
  }

  @override
  Future<Result> setPresence(String userId, String status) async {
    try {
      // status: 'online', 'away', 'offline'
      await _databaseService.updatePath(
        'presence/$userId',
        {
          'status': status,
          'lastSeen': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('Error setting presence: $e'));
    }
  }

  @override
  Future<Result> getPresence(String userId) async {
    try {
      final result = await _databaseService.readPath('presence/$userId');
      
      if (result.isSuccess() && result.data != null) {
        final presenceData = Map<String, dynamic>.from(result.data!);
        return Result.success(presenceData);
      }
      
      // Return default offline status
      return Result.success({
        'status': 'offline',
        'lastSeen': null,
      });
    } catch (e) {
      return Result.failure(Exception('Error getting presence: $e'));
    }
  }

  @override
  Future<Result> getMultiplePresence(List<String> userIds) async {
    try {
      final presenceMap = <String, dynamic>{};
      
      for (final userId in userIds) {
        final result = await getPresence(userId);
        if (result.isSuccess()) {
          presenceMap[userId] = result.getOrNull();
        }
      }
      
      return Result.success(presenceMap);
    } catch (e) {
      return Result.failure(Exception('Error getting multiple presence: $e'));
    }
  }
}
