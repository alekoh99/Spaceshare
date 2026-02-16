import 'package:get/get.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class IUserBlockingService {
  Future<Result<void>> blockUser({required String userId, required String blockedUserId});
  Future<Result<void>> unblockUser({required String userId, required String blockedUserId});
  Future<Result<List<String>>> getBlockedUsers(String userId);
  Future<Result<bool>> isUserBlocked({required String userId, required String targetUserId});
}

class UserBlockingService implements IUserBlockingService {
  late final UnifiedDatabaseService _databaseService;

  UserBlockingService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize UserBlockingService: $e');
    }
  }

  @override
  Future<Result<void>> blockUser({
    required String userId,
    required String blockedUserId,
  }) async {
    try {
      final blockData = {
        'userId': userId,
        'blockedUserId': blockedUserId,
        'blockedAt': DateTime.now().toIso8601String(),
      };

      final result = await _databaseService.createPath(
        'user_blocks/$userId/$blockedUserId',
        blockData,
      );

      return result as Result<void>;
    } catch (e) {
      return Result<void>.failure(Exception('Error blocking user: $e'));
    }
  }

  @override
  Future<Result<void>> unblockUser({
    required String userId,
    required String blockedUserId,
  }) async {
    try {
      final result = await _databaseService.deletePath('user_blocks/$userId/$blockedUserId');
      return result;
    } catch (e) {
      return Result<void>.failure(Exception('Error unblocking user: $e'));
    }
  }

  @override
  Future<Result<List<String>>> getBlockedUsers(String userId) async {
    try {
      final result = await _databaseService.readPath('user_blocks/$userId');
      
      if (result.isSuccess()) {
        final blocks = (result.data as Map?)?.keys.toList().cast<String>() ?? [];
        return Result<List<String>>.success(blocks);
      } else {
        return Result<List<String>>.failure(
          result.exception ?? Exception('Failed to fetch blocked users'),
        );
      }
    } catch (e) {
      return Result<List<String>>.failure(Exception('Error fetching blocked users: $e'));
    }
  }

  @override
  Future<Result<bool>> isUserBlocked({
    required String userId,
    required String targetUserId,
  }) async {
    try {
      final result = await _databaseService.readPath('user_blocks/$userId/$targetUserId');
      return Result<bool>.success(result.isSuccess());
    } catch (e) {
      return Result<bool>.failure(Exception('Error checking block status: $e'));
    }
  }
}
