import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'logger.dart';

class ErrorHandler {
  static void showError(String message, {String title = 'Error'}) {
    AppLogger.warning('ErrorHandler', message);
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      shouldIconPulse: true,
      isDismissible: true,
    );
  }

  static void showSuccess(String message, {String title = 'Success'}) {
    AppLogger.success('ErrorHandler', message);
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade600,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      shouldIconPulse: false,
      isDismissible: true,
    );
  }

  static void showWarning(String message, {String title = 'Warning'}) {
    AppLogger.warning('ErrorHandler', message);
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange.shade600,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      shouldIconPulse: false,
      isDismissible: true,
    );
  }

  static void showInfo(String message, {String title = 'Info'}) {
    AppLogger.info('ErrorHandler', message);
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.shade600,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      shouldIconPulse: false,
      isDismissible: true,
    );
  }

  static void showDialog(
    String message, {
    String title = 'Dialog',
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    Get.defaultDialog(
      title: title,
      content: Text(message),
      confirm: confirmText != null
          ? ElevatedButton(
              onPressed: () {
                Get.back();
                onConfirm?.call();
              },
              child: Text(confirmText),
            )
          : null,
      cancel: cancelText != null
          ? TextButton(
              onPressed: () {
                Get.back();
                onCancel?.call();
              },
              child: Text(cancelText),
            )
          : null,
    );
  }

  static void dismissSnackbars() {
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }
  }

  static void dismissAllDialogs() {
    while (Get.isDialogOpen == true) {
      Get.back();
    }
  }
}
