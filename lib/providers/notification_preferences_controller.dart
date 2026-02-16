import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../services/notification_preferences_service.dart';
import '../models/notification_preferences_model.dart';
import 'auth_controller.dart';

class NotificationPreferencesController extends GetxController {
  final NotificationPreferencesService _preferencesService =
      NotificationPreferencesService();

  late AuthController authController;

  final Rx<NotificationPreferences?> preferences = Rx(null);
  final RxBool isLoading = false.obs;
  final RxString selectedMessageFrequency = RxString('instant');
  final RxString selectedMatchFrequency = RxString('instant');
  
  bool _isInitializing = true;

  /// Safe snackbar that checks if widget tree is ready
  /// Skips snackbar during initialization when overlay is not available
  void _showSnackbar(String title, String message) {
    // Never show snackbars during initialization - overlay not ready
    if (_isInitializing) {
      debugPrint('[NotificationPreferencesController] Skipping snackbar during init: $title - $message');
      return;
    }
    
    try {
      if (Get.context != null) {
        Get.snackbar(title, message);
      } else {
        debugPrint('[NotificationPreferencesController] Widget tree not ready for snackbar: $title - $message');
      }
    } catch (e) {
      debugPrint('[NotificationPreferencesController] Error showing snackbar: $e');
    }
  }

  @override
  void onInit() {
    super.onInit();
    authController = Get.find<AuthController>();
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    try {
      isLoading(true);
      final userId = authController.currentUserId.value;
      if (userId == null) {
        // Don't show snackbar during initialization, log instead
        debugPrint('[NotificationPreferencesController] User not authenticated');
        return;
      }
      final prefsResult = await _preferencesService.getPreferences(userId);
      if (prefsResult.isSuccess()) {
        final prefsData = prefsResult.getOrNull() ?? {};
        final prefs = NotificationPreferences(
          userId: userId,
          preferences: prefsData,
          messageFrequency: 'instant',
          matchFrequency: 'instant',
          updatedAt: DateTime.now(),
        );
        preferences(prefs);
        selectedMessageFrequency.value = prefs.messageFrequency;
        selectedMatchFrequency.value = prefs.matchFrequency;
      }
    } catch (e) {
      debugPrint('[NotificationPreferencesController] Error loading preferences: $e');
      // Don't show snackbar during initialization - widget tree not ready yet
    } finally {
      isLoading(false);
      // Mark initialization complete - now snackbars can be shown
      _isInitializing = false;
    }
  }

  Future<void> toggleMatchNotifications(bool value) async {
    try {
      final prefs = preferences.value;
      if (prefs == null) {
        _showSnackbar('Error', 'Preferences not loaded');
        return;
      }
      final updated = prefs.copyWith(
        preferences: {...prefs.preferences, 'matchNotifications': value},
      );
      await _preferencesService.updatePreferences(updated.toJson());
      preferences(updated);
      _showSnackbar('Success', 'Match notifications updated');
    } catch (e) {
      _showSnackbar('Error', 'Failed to update: $e');
    }
  }

  Future<void> toggleMessageNotifications(bool value) async {
    try {
      final prefs = preferences.value;
      if (prefs == null) {
        _showSnackbar('Error', 'Preferences not loaded');
        return;
      }
      final updated = prefs.copyWith(
        preferences: {...prefs.preferences, 'messageNotifications': value},
      );
      await _preferencesService.updatePreferences(updated.toJson());
      preferences(updated);
      _showSnackbar('Success', 'Message notifications updated');
    } catch (e) {
      _showSnackbar('Error', 'Failed to update: $e');
    }
  }

  Future<void> togglePaymentNotifications(bool value) async {
    try {
      final prefs = preferences.value;
      if (prefs == null) {
        _showSnackbar('Error', 'Preferences not loaded');
        return;
      }
      final updated = prefs.copyWith(
        preferences: {...prefs.preferences, 'paymentNotifications': value},
      );
      await _preferencesService.updatePreferences(updated.toJson());
      preferences(updated);
      _showSnackbar('Success', 'Payment notifications updated');
    } catch (e) {
      _showSnackbar('Error', 'Failed to update: $e');
    }
  }

  Future<void> toggleVerificationNotifications(bool value) async {
    try {
      final prefs = preferences.value;
      if (prefs == null) {
        _showSnackbar('Error', 'Preferences not loaded');
        return;
      }
      final updated = prefs.copyWith(
        preferences: {...prefs.preferences, 'verificationNotifications': value},
      );
      await _preferencesService.updatePreferences(updated.toJson());
      preferences(updated);
      _showSnackbar('Success', 'Verification notifications updated');
    } catch (e) {
      _showSnackbar('Error', 'Failed to update: $e');
    }
  }

  Future<void> toggleComplianceNotifications(bool value) async {
    try {
      final prefs = preferences.value;
      if (prefs == null) {
        _showSnackbar('Error', 'Preferences not loaded');
        return;
      }
      final updated = prefs.copyWith(
        preferences: {...prefs.preferences, 'complianceNotifications': value},
      );
      await _preferencesService.updatePreferences(updated.toJson());
      preferences(updated);
      _showSnackbar('Success', 'Compliance notifications updated');
    } catch (e) {
      _showSnackbar('Error', 'Failed to update: $e');
    }
  }

  Future<void> togglePushNotifications(bool value) async {
    try {
      final prefs = preferences.value;
      if (prefs == null) {
        _showSnackbar('Error', 'Preferences not loaded');
        return;
      }
      final updated = prefs.copyWith(
        preferences: {...prefs.preferences, 'pushNotifications': value},
      );
      await _preferencesService.updatePreferences(updated.toJson());
      preferences(updated);
      _showSnackbar('Success', 'Push notifications updated');
    } catch (e) {
      _showSnackbar('Error', 'Failed to update: $e');
    }
  }

  Future<void> toggleEmailNotifications(bool value) async {
    try {
      final prefs = preferences.value;
      if (prefs == null) {
        _showSnackbar('Error', 'Preferences not loaded');
        return;
      }
      final updated = prefs.copyWith(
        preferences: {...prefs.preferences, 'emailNotifications': value},
      );
      await _preferencesService.updatePreferences(updated.toJson());
      preferences(updated);
      _showSnackbar('Success', 'Email notifications updated');
    } catch (e) {
      _showSnackbar('Error', 'Failed to update: $e');
    }
  }

  Future<void> toggleSmsNotifications(bool value) async {
    try {
      final prefs = preferences.value;
      if (prefs == null) {
        _showSnackbar('Error', 'Preferences not loaded');
        return;
      }
      final updated = prefs.copyWith(
        preferences: {...prefs.preferences, 'smsNotifications': value},
      );
      await _preferencesService.updatePreferences(updated.toJson());
      preferences(updated);
      _showSnackbar('Success', 'SMS notifications updated');
    } catch (e) {
      _showSnackbar('Error', 'Failed to update: $e');
    }
  }

  Future<void> updateMessageFrequency(String frequency) async {
    try {
      final prefs = preferences.value;
      if (prefs == null) {
        _showSnackbar('Error', 'Preferences not loaded');
        return;
      }
      final updated = prefs.copyWith(
        messageFrequency: frequency,
      );
      await _preferencesService.updatePreferences(updated.toJson());
      preferences(updated);
      selectedMessageFrequency.value = frequency;
    } catch (e) {
      _showSnackbar('Error', 'Failed to update: $e');
    }
  }

  Future<void> updateMatchFrequency(String frequency) async {
    try {
      final prefs = preferences.value;
      if (prefs == null) {
        _showSnackbar('Error', 'Preferences not loaded');
        return;
      }
      final updated = prefs.copyWith(
        matchFrequency: frequency,
      );
      await _preferencesService.updatePreferences(updated.toJson());
      preferences(updated);
      selectedMatchFrequency.value = frequency;
    } catch (e) {
      _showSnackbar('Error', 'Failed to update: $e');
    }
  }

  Future<void> setQuietHours(String startTime, String endTime) async {
    try {
      final prefs = preferences.value;
      if (prefs == null) {
        _showSnackbar('Error', 'Preferences not loaded');
        return;
      }
      final userId = authController.currentUserId.value;
      if (userId == null) {
        _showSnackbar('Error', 'User not authenticated');
        return;
      }
      await _preferencesService.setQuietHours(userId, startTime, endTime);
      final updated = prefs.copyWith(
        quietHoursStart: startTime,
        quietHoursEnd: endTime,
      );
      preferences(updated);
      _showSnackbar('Success', 'Quiet hours set: $startTime - $endTime');
    } catch (e) {
      _showSnackbar('Error', 'Failed to set quiet hours: $e');
    }
  }

  Future<void> clearQuietHours() async {
    try {
      final prefs = preferences.value;
      if (prefs == null) {
        _showSnackbar('Error', 'Preferences not loaded');
        return;
      }
      final userId = authController.currentUserId.value;
      if (userId == null) {
        _showSnackbar('Error', 'User not authenticated');
        return;
      }
      await _preferencesService.clearQuietHours(userId);
      final updated = prefs.copyWith(
        quietHoursStart: null,
        quietHoursEnd: null,
      );
      preferences(updated);
      _showSnackbar('Success', 'Quiet hours cleared');
    } catch (e) {
      _showSnackbar('Error', 'Failed to clear quiet hours: $e');
    }
  }

  Future<void> unsubscribeFromAll(bool value) async {
    try {
      final prefs = preferences.value;
      if (prefs == null) {
        _showSnackbar('Error', 'Preferences not loaded');
        return;
      }
      final updated = prefs.copyWith(
        preferences: {...prefs.preferences, 'unsubscribeFromAll': value},
      );
      await _preferencesService.updatePreferences(updated.toJson());
      preferences(updated);
      Get.snackbar(
        'Success',
        value
            ? 'Unsubscribed from all notifications'
            : 'Subscribed to notifications',
      );
    } catch (e) {
      _showSnackbar('Error', 'Failed to update: $e');
    }
  }
}
