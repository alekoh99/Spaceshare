import 'package:flutter/foundation.dart';

class AppLogger {
  static const String _prefix = '[SpaceShare]';
  static bool _loggingEnabled = !kReleaseMode;

  static void enable() {
    _loggingEnabled = true;
  }

  static void disable() {
    _loggingEnabled = false;
  }

  static void debug(String tag, String message) {
    if (_loggingEnabled && !kReleaseMode) {
      debugPrint('$_prefix [$tag] DEBUG: $message');
    }
  }

  static void info(String tag, String message) {
    if (_loggingEnabled) {
      debugPrint('$_prefix [$tag] INFO: $message');
    }
  }

  static void warning(String tag, String message) {
    if (_loggingEnabled) {
      debugPrint('$_prefix [$tag] ⚠️ WARNING: $message');
    }
  }

  static void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    if (_loggingEnabled) {
      debugPrint('$_prefix [$tag] ❌ ERROR: $message');
      if (error != null && !kReleaseMode) {
        debugPrint('Error details: $error');
      }
      if (stackTrace != null && !kReleaseMode) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  static void success(String tag, String message) {
    if (_loggingEnabled) {
      debugPrint('$_prefix [$tag] ✅ SUCCESS: $message');
    }
  }
}
