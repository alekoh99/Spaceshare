import 'package:get/get.dart';
import 'logger.dart';

class NavigationHelper {
  static const Duration _defaultNavigationDelay = Duration(milliseconds: 100);
  static const Duration _authNavigationDelay = Duration(milliseconds: 200);

  /// Navigate to home (replaces entire stack - for auth transitions)
  static Future<void> goToHome() async {
    AppLogger.debug('Navigation', 'Navigating to home');
    await Future.delayed(_defaultNavigationDelay);
    try {
      Get.offAllNamed('/');
      AppLogger.debug('Navigation', 'Successfully navigated to home');
    } catch (e) {
      AppLogger.error('Navigation', 'Failed to navigate to home', e);
      rethrow;
    }
  }

  /// Navigate to profile setup (replaces entire stack - for auth transitions)
  static Future<void> goToProfileSetup() async {
    AppLogger.debug('Navigation', 'Navigating to profile setup');
    await Future.delayed(_authNavigationDelay);
    try {
      Get.offAllNamed('/profile-setup');
      AppLogger.debug('Navigation', 'Successfully navigated to profile setup');
    } catch (e) {
      AppLogger.error('Navigation', 'Failed to navigate to profile setup', e);
      rethrow;
    }
  }

  /// Navigate to auth options (replaces entire stack - for auth transitions)
  static Future<void> goToAuthOptions() async {
    AppLogger.debug('Navigation', 'Navigating to auth options');
    await Future.delayed(_defaultNavigationDelay);
    Get.offAllNamed('/auth-options');
  }

  /// Navigate to email sign-in (preserves back stack)
  static Future<void> goToEmailSignIn() async {
    AppLogger.debug('Navigation', 'Navigating to email sign-in');
    await Future.delayed(_defaultNavigationDelay);
    Get.toNamed('/auth/email-signin');
  }

  /// Navigate to phone entry (preserves back stack)
  static Future<void> goToPhoneEntry() async {
    AppLogger.debug('Navigation', 'Navigating to phone entry');
    await Future.delayed(_defaultNavigationDelay);
    Get.toNamed('/phone-entry');
  }

  /// Navigate to OTP verification (preserves back stack)
  static Future<void> goToOTPVerification(String phone) async {
    AppLogger.debug('Navigation', 'Navigating to OTP verification');
    await Future.delayed(_defaultNavigationDelay);
    Get.toNamed('/otp-verification', arguments: {'phone': phone});
  }

  /// Go back to previous screen
  static void back() {
    AppLogger.debug('Navigation', 'Going back');
    try {
      Get.back();
    } catch (e) {
      AppLogger.debug('Navigation', 'Cannot go back: $e');
    }
  }

  /// Go back to home (replaces entire stack)
  static Future<void> backToHome() async {
    AppLogger.debug('Navigation', 'Back to home');
    await Future.delayed(_defaultNavigationDelay);
    Get.offAllNamed('/');
  }

  /// Close all open dialogs
  static void closeAllDialogs() {
    while (Get.isDialogOpen == true) {
      Get.back();
    }
  }
}
