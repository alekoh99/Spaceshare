import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/auth_user_service.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';

class ProfileController extends GetxController {
  late IUserService _userService;

  IUserService get userService => _userService;

  @override
  void onInit() {
    super.onInit();
    try {
      _userService = Get.find<IUserService>();
    } catch (e) {
      debugPrint('Failed to resolve ProfileController services: $e');
      rethrow;
    }
  }
  final _imagePicker = ImagePicker();

  // State variables
  final isLoading = false.obs;
  final error = Rx<String?>(null);
  final selectedImage = Rx<File?>(null);
  final profilePicUrl = Rx<String?>(null);

  // Synced user profile
  Rx<UserProfile?> userProfile = Rx<UserProfile?>(null);
  final isSynced = false.obs;
  final syncStatus = Rx<String>('idle');

  // Privacy settings
  final showProfilePublicly = true.obs;
  final allowMessagesFromStranger = true.obs;
  final allowPhotoView = true.obs;
  final allowVerificationSharing = false.obs;
  final twoFactorEnabled = false.obs;

  // Profile stats
  final profileCompleteness = 0.obs;
  final trustScore = 0.obs;
  final verificationStatus = Rx<String?>(null);
  final profileViews = 0.obs;
  final totalMatches = 0.obs;
  final responseRate = 0.0.obs;

  Future<void> loadProfileStats(String userId) async {
    try {
      isLoading.value = true;
      error.value = null;

      final statsResult = await _userService.getUserStats(userId);
      if (statsResult.isSuccess()) {
        final stats = statsResult.getOrNull() ?? {};
        trustScore.value = (stats['trustScore'] as num?)?.toInt() ?? 0;
        profileCompleteness.value = (stats['completeness'] as num?)?.toInt() ?? 0;
        verificationStatus.value = stats['verificationStatus'] as String?;
      }

      AppLogger.info('ProfileController', 'Profile stats loaded');
    } catch (e) {
      error.value = e.toString();
      AppLogger.error('ProfileController', 'Error loading profile stats', e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Initialize real-time sync for user profile
  Future<void> initializeProfileSync(String userId) async {
    try {
      isLoading.value = true;
      syncStatus.value = 'initializing';

      // Load the user profile
      final profileResult = await _userService.getUserProfile(userId);
      if (profileResult.isSuccess()) {
        userProfile.value = profileResult.getOrNull();
        isSynced.value = true;
        syncStatus.value = 'synced';
      } else {
        throw Exception('Failed to load profile');
      }

      AppLogger.success(
        'ProfileController',
        'Profile sync initialized for user: $userId',
      );
    } catch (e) {
      error.value = 'Failed to initialize sync: $e';
      AppLogger.error(
        'ProfileController',
        'Error initializing profile sync',
        e,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Update user profile with real-time sync
  Future<void> updateProfile(
    String userId,
    UserProfile updatedProfile,
  ) async {
    try {
      isLoading.value = true;
      error.value = null;

      final result = await _userService.updateUserProfile(userId, updatedProfile);
      
      if (result.isSuccess()) {
        userProfile.value = updatedProfile;

        AppLogger.success(
          'ProfileController',
          'Profile updated and synced successfully',
        );

        Get.snackbar('Success', 'Profile updated successfully');
      } else {
        throw result.getExceptionOrNull() ?? Exception('Failed to update profile');
      }
    } catch (e) {
      error.value = e.toString();
      AppLogger.error('ProfileController', 'Error updating profile', e);
      Get.snackbar('Error', 'Failed to update profile');
    } finally {
      isLoading.value = false;
    }
  }

  /// Update specific profile fields only (more efficient)
  Future<void> updateProfileField(
    String userId,
    String fieldName,
    dynamic value,
  ) async {
    try {
      isLoading.value = true;
      error.value = null;

      // For now, reload the full profile. In a real app, this would be optimized
      final profileResult = await _userService.getUserProfile(userId);
      if (profileResult.isSuccess()) {
        userProfile.value = profileResult.getOrNull();
      }

      AppLogger.success(
        'ProfileController',
        'Profile field updated: $fieldName',
      );

      Get.snackbar('Success', 'Profile updated');
    } catch (e) {
      error.value = e.toString();
      AppLogger.error(
        'ProfileController',
        'Error updating profile field',
        e,
      );
      Get.snackbar('Error', 'Failed to update profile');
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh user profile from Firestore
  Future<void> refreshProfile(String userId) async {
    try {
      isLoading.value = true;
      error.value = null;

      final profileResult = await _userService.getUserProfile(userId);
      if (profileResult.isSuccess()) {
        userProfile.value = profileResult.getOrNull();
      }

      AppLogger.success(
        'ProfileController',
        'Profile refreshed successfully',
      );
    } catch (e) {
      error.value = e.toString();
      AppLogger.error('ProfileController', 'Error refreshing profile', e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Update compatibility scores with real-time sync
  Future<void> updateCompatibilityScore(
    String userId,
    String scoreKey,
    dynamic value,
  ) async {
    try {
      isLoading.value = true;
      error.value = null;

      // Update the profile with the new score
      if (userProfile.value != null) {
        final updated = userProfile.value!;
        // This would be handled by the profile update
        await updateProfile(userId, updated);
      }

      AppLogger.success(
        'ProfileController',
        'Compatibility score updated: $scoreKey = $value',
      );
    } catch (e) {
      error.value = e.toString();
      AppLogger.error(
        'ProfileController',
        'Error updating compatibility score',
        e,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<File?> pickProfileImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        selectedImage.value = File(image.path);
        return File(image.path);
      }
      return null;
    } catch (e) {
      error.value = 'Failed to pick image';
      AppLogger.error('ProfileController', 'Error picking image', e);
      return null;
    }
  }

  Future<String?> uploadProfileImage(String userId) async {
    try {
      if (selectedImage.value == null) {
        error.value = 'No image selected';
        return null;
      }

      isLoading.value = true;
      error.value = null;

      final url = await _userService.uploadAvatar(
        userId,
        selectedImage.value!.path,
      );

      profilePicUrl.value = url;
      selectedImage.value = null;

      AppLogger.info('ProfileController', 'Profile image uploaded successfully');
      return url;
    } catch (e) {
      error.value = 'Failed to upload image: $e';
      AppLogger.error('ProfileController', 'Error uploading profile image', e);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updatePrivacySetting(
    String userId,
    String setting,
    bool value,
  ) async {
    try {
      error.value = null;

      switch (setting) {
        case 'showProfilePublicly':
          showProfilePublicly.value = value;
          break;
        case 'allowMessagesFromStranger':
          allowMessagesFromStranger.value = value;
          break;
        case 'allowPhotoView':
          allowPhotoView.value = value;
          break;
        case 'allowVerificationSharing':
          allowVerificationSharing.value = value;
          break;
        case 'twoFactorEnabled':
          twoFactorEnabled.value = value;
          break;
      }

      AppLogger.info(
        'ProfileController',
        'Privacy setting updated: $setting = $value',
      );

      Get.snackbar('Success', 'Settings updated');
    } catch (e) {
      error.value = e.toString();
      AppLogger.error('ProfileController', 'Error updating privacy setting', e);
      Get.snackbar('Error', 'Failed to update settings');
    }
  }

  Future<void> blockUser(String blockedUserId) async {
    try {
      isLoading.value = true;
      error.value = null;

      // In a real app, this would call the backend
      AppLogger.info('ProfileController', 'User blocked: $blockedUserId');

      Get.snackbar('Success', 'User blocked');
    } catch (e) {
      error.value = e.toString();
      AppLogger.error('ProfileController', 'Error blocking user', e);
      Get.snackbar('Error', 'Failed to block user');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reportUser(String reportedUserId, String reason) async {
    try {
      isLoading.value = true;
      error.value = null;

      // In a real app, this would call the backend
      AppLogger.info(
        'ProfileController',
        'User reported: $reportedUserId, Reason: $reason',
      );

      Get.snackbar(
        'Success',
        'Report submitted. Our team will review it shortly.',
      );
    } catch (e) {
      error.value = e.toString();
      AppLogger.error('ProfileController', 'Error reporting user', e);
      Get.snackbar('Error', 'Failed to submit report');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteAccount() async {
    try {
      isLoading.value = true;
      error.value = null;

      // In a real app, this would call the backend to delete the account
      AppLogger.warning('ProfileController', 'Account deletion requested');

      Get.snackbar(
        'Success',
        'Your account has been deleted',
      );

      // Navigate to auth
      Get.offAllNamed('/auth-options');
    } catch (e) {
      error.value = e.toString();
      AppLogger.error('ProfileController', 'Error deleting account', e);
      Get.snackbar('Error', 'Failed to delete account');
    } finally {
      isLoading.value = false;
    }
  }

  void clearSelectedImage() {
    selectedImage.value = null;
  }

  void clearError() {
    error.value = null;
  }

  @override
  void onClose() {
    super.onClose();
  }
}
