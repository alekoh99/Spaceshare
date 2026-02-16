import 'package:get/get.dart';
import '../services/user_blocking_service.dart';
import '../services/user_reputation_service.dart';
import '../utils/logger.dart';
import 'auth_controller.dart';

class UserManagementController extends GetxController {
  late IUserBlockingService _blockingService;
  late IUserReputationService _reputationService;
  late AuthController _authController;

  final blockedUsers = RxList<String>([]);
  final isLoadingBlocked = false.obs;
  final userReputation = 0.obs;
  final reputationDetails = Rx<Map<String, dynamic>>({});
  final isLoadingReputation = false.obs;
  final error = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    try {
      _blockingService = Get.find<IUserBlockingService>();
      _reputationService = Get.find<IUserReputationService>();
      _authController = Get.find<AuthController>();
    } catch (e) {
      AppLogger.error('UserManagementController', 'Failed to resolve services', e);
      rethrow;
    }
  }

  Future<void> blockUser(String targetUserId) async {
    try {
      if (_authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      final result = await _blockingService.blockUser(
        userId: _authController.currentUserId.value!,
        blockedUserId: targetUserId,
      );

      if (result.isSuccess()) {
        await loadBlockedUsers();
        AppLogger.info('UserManagement', 'Successfully blocked user: $targetUserId');
      } else {
        error.value = 'Failed to block user';
      }
    } catch (e) {
      AppLogger.error('UserManagementController', 'Error blocking user', e);
      error.value = e.toString();
    }
  }

  Future<void> unblockUser(String targetUserId) async {
    try {
      if (_authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      final result = await _blockingService.unblockUser(
        userId: _authController.currentUserId.value!,
        blockedUserId: targetUserId,
      );

      if (result.isSuccess()) {
        await loadBlockedUsers();
        AppLogger.info('UserManagement', 'Successfully unblocked user: $targetUserId');
      } else {
        error.value = 'Failed to unblock user';
      }
    } catch (e) {
      AppLogger.error('UserManagementController', 'Error unblocking user', e);
      error.value = e.toString();
    }
  }

  Future<void> loadBlockedUsers() async {
    try {
      if (_authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      isLoadingBlocked.value = true;
      final result = await _blockingService.getBlockedUsers(_authController.currentUserId.value!);

      if (result.isSuccess()) {
        final blocked = result.getOrNull() ?? [];
        blockedUsers.assignAll(blocked);
        error.value = null;
      } else {
        error.value = 'Failed to load blocked users';
        blockedUsers.clear();
      }
    } catch (e) {
      AppLogger.error('UserManagementController', 'Error loading blocked users', e);
      error.value = e.toString();
      blockedUsers.clear();
    } finally {
      isLoadingBlocked.value = false;
    }
  }

  Future<bool> isUserBlocked(String targetUserId) async {
    try {
      if (_authController.currentUserId.value == null) {
        return false;
      }

      final result = await _blockingService.isUserBlocked(
        userId: _authController.currentUserId.value!,
        targetUserId: targetUserId,
      );

      return result.isSuccess() && (result.getOrNull() ?? false);
    } catch (e) {
      AppLogger.error('UserManagementController', 'Error checking block status', e);
      return false;
    }
  }

  Future<void> loadUserReputation(String userId) async {
    try {
      isLoadingReputation.value = true;
      final result = await _reputationService.getUserReputation(userId);

      if (result.isSuccess()) {
        userReputation.value = result.getOrNull() ?? 0;
        
        final detailsResult = await _reputationService.getReputationDetails(userId);
        if (detailsResult.isSuccess()) {
          reputationDetails.value = detailsResult.getOrNull() ?? {};
        }
        error.value = null;
      } else {
        error.value = 'Failed to load reputation';
      }
    } catch (e) {
      AppLogger.error('UserManagementController', 'Error loading reputation', e);
      error.value = e.toString();
    } finally {
      isLoadingReputation.value = false;
    }
  }

  Future<void> addReputation(String userId, int points, String reason) async {
    try {
      final result = await _reputationService.addReputation(userId, points, reason);
      
      if (result.isSuccess()) {
        await loadUserReputation(userId);
        AppLogger.info('UserManagement', 'Added $points reputation points to $userId');
      } else {
        error.value = 'Failed to add reputation';
      }
    } catch (e) {
      AppLogger.error('UserManagementController', 'Error adding reputation', e);
      error.value = e.toString();
    }
  }

  Future<void> subtractReputation(String userId, int points, String reason) async {
    try {
      final result = await _reputationService.subtractReputation(userId, points, reason);
      
      if (result.isSuccess()) {
        await loadUserReputation(userId);
        AppLogger.info('UserManagement', 'Subtracted $points reputation points from $userId');
      } else {
        error.value = 'Failed to subtract reputation';
      }
    } catch (e) {
      AppLogger.error('UserManagementController', 'Error subtracting reputation', e);
      error.value = e.toString();
    }
  }
}
