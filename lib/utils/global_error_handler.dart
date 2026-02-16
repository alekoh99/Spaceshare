import 'dart:ui';
import 'package:flutter/material.dart';
import 'logger.dart';

class GlobalErrorHandler {
  static void setup() {
    FlutterError.onError = (FlutterErrorDetails details) {
      AppLogger.error('FlutterError', 'Flutter error occurred', details.exception, details.stack);
      if (!_isUserFacingError(details.exception.toString())) {
        FlutterError.presentError(details);
      }
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      AppLogger.error('PlatformDispatcher', 'Unhandled platform error', error, stack);
      return true;
    };
  }

  static bool _isUserFacingError(String errorMessage) {
    // List of errors that should not be shown to user
    final hiddenErrors = [
      'Connection reset by peer',
      'SocketException',
      'TimeoutException',
      'XMLHttpRequest',
      'setState',
      'disposed',
      'RangeError',
      'NoSuchMethodError',
    ];

    return hiddenErrors.any((error) => errorMessage.contains(error));
  }
}
