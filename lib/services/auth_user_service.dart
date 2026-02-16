import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../utils/result.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';
import 'database_service.dart';
import 'sync_manager.dart';

/// Interface for user authentication and management
abstract class IUserService {
  Future<Result<UserProfile>> getUserProfile(String userId);
  Future<Result<void>> updateUserProfile(String userId, UserProfile profile);
  Future<Result<void>> deleteUserProfile(String userId);
  Future<Result<List<UserProfile>>> searchUsers(Map<String, dynamic> filters);
  Future<String> uploadAvatar(String userId, String filePath);
  Future<Result<Map<String, dynamic>>> getUserStats(String userId);
}

/// Implementation using Firebase Realtime Database
class UserService implements IUserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late IDatabaseService _databaseService;

  UserService() {
    _initializeDatabaseService();
  }

  void _initializeDatabaseService() {
    try {
      _databaseService = Get.find<IDatabaseService>();
    } catch (e) {
      AppLogger.warning(
        'UserService',
        'Database service not found in GetIt, will try to find it later: $e',
      );
    }
  }

  /// Get or initialize database service
  IDatabaseService _getDatabaseService() {
    try {
      return Get.find<IDatabaseService>();
    } catch (e) {
      throw Exception('Database service not available: $e');
    }
  }

  @override
  Future<Result<UserProfile>> getUserProfile(String userId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Result.failure(Exception('User not authenticated'));
      }

      // Get profile from database service (unified)
      // This would be injected in real implementation
      return Result.success(UserProfile.empty());
    } catch (e) {
      return Result.failure(Exception('Failed to get user profile: $e'));
    }
  }

  @override
  Future<Result<void>> updateUserProfile(String userId, UserProfile profile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Result.failure(Exception('User not authenticated'));
      }

      AppLogger.info('UserService', 'Updating profile for user: $userId');

      // Get database service instance
      final dbService = _getDatabaseService();

      // Convert UserProfile to Map for database update
      final profileData = profile.toJson();

      // Update through unified database service (local)
      final result = await dbService.updateProfile(userId, profileData);

      if (result.isSuccess()) {
        AppLogger.success('UserService', 'Profile updated in local database: $userId');
        
        // Also sync to backend API asynchronously
        try {
          final syncManager = Get.find<SyncManager>();
          // Schedule background sync to backend with correct endpoint including userId
          syncManager.queueOperation(
            type: 'profile',
            entity: 'profile',
            entityId: userId,
            endpoint: '/profiles/$userId',
          );
          syncManager.syncProfile(profile).catchError((e) {
            AppLogger.warning(
              'UserService',
              'Failed to sync profile to backend (will retry): $e',
            );
            // Don't fail the update if backend sync fails - data is local safe
          });
        } catch (e) {
          AppLogger.warning(
            'UserService',
            'SyncManager not available, queuing for later: $e',
          );
        }
        
        return Result.success(null);
      } else {
        AppLogger.error(
          'UserService',
          'Profile update failed',
          result.getExceptionOrNull(),
        );
        return result;
      }
    } catch (e) {
      AppLogger.error('UserService', 'Error updating user profile', e);
      return Result.failure(Exception('Failed to update user profile: $e'));
    }
  }

  @override
  Future<Result<void>> deleteUserProfile(String userId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Result.failure(Exception('User not authenticated'));
      }

      // Delete would go through unified database service
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('Failed to delete user profile: $e'));
    }
  }

  @override
  Future<Result<List<UserProfile>>> searchUsers(Map<String, dynamic> filters) async {
    try {
      // Search would go through unified database service
      return Result.success([]);
    } catch (e) {
      return Result.failure(Exception('Failed to search users: $e'));
    }
  }

  @override
  Future<String> uploadAvatar(String userId, String filePath) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      // Avatar upload would be handled by backend service
      // For now, return a placeholder URL
      return 'https://placeholder.com/avatar/$userId';
    } catch (e) {
      throw Exception('Failed to upload avatar: $e');
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getUserStats(String userId) async {
    try {
      final stats = {
        'userId': userId,
        'matchesCount': 0,
        'messagesCount': 0,
        'reviewsCount': 0,
        'averageRating': 0.0,
        'joinDate': DateTime.now().toIso8601String(),
      };
      return Result.success(stats);
    } catch (e) {
      return Result.failure(Exception('Failed to get user stats: $e'));
    }
  }
}

/// Authentication service interface
abstract class IAuthService {
  Future<Result<UserCredential>> signUp(String email, String password);
  Future<Result<UserCredential>> signIn(String email, String password);
  Future<Result<void>> signOut();
  Future<Result<void>> resetPassword(String email);
  User? getCurrentUser();
}

/// Implementation using Firebase Authentication
class AuthService implements IAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<Result<UserCredential>> signUp(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Result.success(credential);
    } catch (e) {
      return Result.failure(Exception('Sign up failed: $e'));
    }
  }

  @override
  Future<Result<UserCredential>> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Result.success(credential);
    } catch (e) {
      return Result.failure(Exception('Sign in failed: $e'));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _auth.signOut();
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('Sign out failed: $e'));
    }
  }

  @override
  Future<Result<void>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('Password reset failed: $e'));
    }
  }

  @override
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
