import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../services/identity_verification_service.dart';
import '../models/identity_verification_model.dart';
import 'auth_controller.dart';

class IdentityVerificationController extends GetxController {
  late IIdentityVerificationService _verificationService;

  IIdentityVerificationService get verificationService => _verificationService;

  // State
  final currentVerificationSession = Rx<IdentityVerificationSession?>(null);
  final isProcessing = false.obs;
  final error = Rx<String?>(null);
  final verificationStatus = Rx<Map<String, dynamic>>({});
  final userTrustBadges = RxList<TrustBadge>([]);
  final verificationHistory = RxList<IdentityVerificationSession>([]);

  late AuthController authController;

  @override
  void onInit() {
    super.onInit();
    try {
      _verificationService = Get.find<IIdentityVerificationService>();
    } catch (e) {
      debugPrint('Failed to resolve IdentityVerificationController services: $e');
      rethrow;
    }
    authController = Get.find<AuthController>();
  }

  /// Start Stripe Identity verification
  Future<void> startStripeIdentityVerification() async {
    try {
      if (authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      isProcessing.value = true;
      final session =
          await _verificationService.createStripeIdentitySession(
        authController.currentUserId.value!,
      );

      currentVerificationSession.value = session;
      error.value = null;

      Get.snackbar(
        'Verification Started',
        'Please complete your identity verification',
      );
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', error.value ?? 'Failed to start verification');
    } finally {
      isProcessing.value = false;
    }
  }

  /// Complete Stripe Identity verification with result
  Future<void> completeStripeIdentityVerification(
    Map<String, dynamic> verificationResult,
  ) async {
    try {
      if (authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      isProcessing.value = true;

      // Extract session ID from result
      final sessionId = verificationResult['sessionId'] as String? ?? '';
      
      final result =
          await _verificationService.processStripeVerification(
        authController.currentUserId.value!,
        sessionId,
      );

      if (result.isSuccess()) {
        Get.snackbar(
          'Identity Verified',
          'Your identity has been verified successfully!',
        );
        await loadUserVerificationStatus();
      } else {
        Get.snackbar(
          'Verification Failed',
          'Please try again',
        );
      }

      error.value = null;
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', error.value ?? 'Failed to verify identity');
    } finally {
      isProcessing.value = false;
    }
  }

  /// Start background check
  Future<void> startBackgroundCheck({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    try {
      if (authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      isProcessing.value = true;

      final session = await _verificationService.initiateBackgroundCheck(
        authController.currentUserId.value!,
      );

      currentVerificationSession.value = session;

      Get.snackbar(
        'Background Check Initiated',
        'Results will be available within 24-48 hours',
      );

      error.value = null;
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', error.value ?? 'Failed to start background check');
    } finally {
      isProcessing.value = false;
    }
  }

  /// Complete background check with result
  Future<void> completeBackgroundCheck(
    Map<String, dynamic> checkResult,
  ) async {
    try {
      if (authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      isProcessing.value = true;

      // Extract check ID from result
      final checkId = checkResult['checkId'] as String? ?? '';

      final result =
          await _verificationService.processBackgroundCheckResult(
        authController.currentUserId.value!,
        checkId,
      );

      if (result.isSuccess()) {
        Get.snackbar(
          'Background Check Result Processed',
          'Your result has been processed successfully!',
        );
        await loadUserVerificationStatus();
      } else {
        Get.snackbar(
          'Background Check Result',
          'Your result requires review. Support will contact you soon.',
        );
      }

      error.value = null;
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', error.value ?? 'Failed to complete background check');
    } finally {
      isProcessing.value = false;
    }
  }

  /// Load user's verification status
  Future<void> loadUserVerificationStatus() async {
    try {
      if (authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      isProcessing.value = true;

      final statusResult =
          await _verificationService.getUserVerificationStatus(
        authController.currentUserId.value!,
      );

      if (statusResult.isSuccess()) {
        verificationStatus.value = statusResult.getOrNull() as Map<String, dynamic>? ?? {};
      }

      // Load trust badges
      final badgesResult =
          await _verificationService.getUserTrustBadges(
        authController.currentUserId.value!,
      );

      if (badgesResult.isSuccess()) {
        final badges = badgesResult.getOrNull();
        if (badges is List) {
          userTrustBadges.value = badges.cast<TrustBadge>();
        }
      }

      error.value = null;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isProcessing.value = false;
    }
  }

  /// Load verification history
  Future<void> loadVerificationHistory() async {
    try {
      if (authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      isProcessing.value = true;

      final historyResult =
          await _verificationService.getUserVerificationHistory(
        authController.currentUserId.value!,
      );

      if (historyResult.isSuccess()) {
        final history = historyResult.getOrNull();
        if (history is List) {
          verificationHistory.value = history.cast<IdentityVerificationSession>();
        }
      }
      
      error.value = null;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isProcessing.value = false;
    }
  }

  /// Load user's trust badges
  Future<void> loadUserTrustBadges() async {
    try {
      if (authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      final badgesResult =
          await _verificationService.getUserTrustBadges(
        authController.currentUserId.value!,
      );

      if (badgesResult.isSuccess()) {
        final badges = badgesResult.getOrNull();
        if (badges is List) {
          userTrustBadges.value = badges.cast<TrustBadge>();
        }
      }
      
      error.value = null;
    } catch (e) {
      error.value = e.toString();
    }
  }

  /// Get trust badge display info
  Map<String, String> getTrustBadgeInfo(String badgeType) {
    const badgeInfo = {
      'identity_verified': 'Identity Verified',
      'background_checked': 'Background Checked',
      'on_time_payments': 'On-Time Payer',
      'responsive_user': 'Responsive',
    };

    return {
      'type': badgeType,
      'label': badgeInfo[badgeType] ?? 'Verified',
      'icon': _getBadgeIcon(badgeType),
    };
  }

  String _getBadgeIcon(String badgeType) {
    const icons = {
      'identity_verified': '✓',
      'background_checked': '✓✓',
      'on_time_payments': '💳',
      'responsive_user': '💬',
    };
    return icons[badgeType] ?? '✓';
  }

  /// Get verification completion percentage
  double getVerificationCompletionPercentage() {
    double percentage = 0;

    if (verificationStatus.value['isIdentityVerified'] == true) {
      percentage += 40;
    }

    if (verificationStatus.value['backgroundCheckStatus'] == 'approved') {
      percentage += 40;
    }

    if (userTrustBadges.isNotEmpty) {
      percentage += 20;
    }

    return percentage;
  }

  /// Check if user has all verifications
  bool get isFullyVerified =>
      verificationStatus.value['isIdentityVerified'] == true &&
      verificationStatus.value['backgroundCheckStatus'] == 'approved';

  /// Get trust score display
  int get trustScore => verificationStatus.value['trustScore'] as int? ?? 50;
}
