import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../utils/result.dart';

/// Biometric Authentication & Device Security - Production-grade
/// Supports fingerprint, face recognition, and pin fallback
class BiometricAuthService {
  static const String _tag = 'BiometricAuthService';
  static const platform = MethodChannel('com.spaceshare.app/security');
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check device biometric capabilities
  Future<Result<BiometricCapabilities>> checkCapabilities() async {
    try {
      final isDeviceSupported = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      final hasBiometric = availableBiometrics.isNotEmpty;
      final hasFingerprint = availableBiometrics.contains(BiometricType.fingerprint);
      final hasFace = availableBiometrics.contains(BiometricType.face);

      return Result.success(BiometricCapabilities(
        isDeviceSupported: isDeviceSupported,
        isDeviceSecure: hasBiometric,
        hasBiometric: hasBiometric,
        hasFingerprint: hasFingerprint,
        hasFaceRecognition: hasFace,
        availableBiometrics: availableBiometrics,
      ));
    } on PlatformException catch (e) {
      return Result.failure(
        Exception('Failed to check biometric capabilities: ${e.message}'),
      );
    }
  }

  /// Authenticate user with biometrics
  Future<Result<BiometricAuthResult>> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
    bool sensitiveTransaction = true,
  }) async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason,
      );

      if (!isAuthenticated) {
        return Result.failure(Exception('Biometric authentication failed'));
      }

      return Result.success(BiometricAuthResult(
        authenticated: true,
        timestamp: DateTime.now(),
        method: 'biometric',
      ));
    } on PlatformException catch (e) {
      return _handleBiometricError(e);
    }
  }

  /// Fallback to device PIN/password
  Future<Result<BiometricAuthResult>> authenticateWithDeviceLock({
    required String reason,
  }) async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason,
      );

      if (!isAuthenticated) {
        return Result.failure(Exception('Device authentication failed'));
      }

      return Result.success(BiometricAuthResult(
        authenticated: true,
        timestamp: DateTime.now(),
        method: 'device_lock',
      ));
    } on PlatformException catch (e) {
      return _handleBiometricError(e);
    }
  }

  /// Store sensitive data in secure enclave
  Future<Result<void>> storeSecureToken(String key, String value) async {
    try {
      final result = await platform.invokeMethod('storeSecureToken', {
        'key': key,
        'value': value,
      });

      if (result == true) {
        return Result.success(null);
      }
      return Result.failure(Exception('Failed to store secure token'));
    } on PlatformException catch (e) {
      return Result.failure(Exception('Secure storage error: ${e.message}'));
    }
  }

  /// Retrieve secure token with biometric verification
  Future<Result<String>> getSecureToken(String key) async {
    try {
      final result = await platform.invokeMethod('getSecureToken', {
        'key': key,
      });

      if (result is String) {
        return Result.success(result);
      }
      return Result.failure(Exception('Failed to retrieve secure token'));
    } on PlatformException catch (e) {
      return Result.failure(Exception('Secure retrieval error: ${e.message}'));
    }
  }

  /// Enable biometric security for sensitive operations
  Future<Result<void>> enableBiometricSecurity() async {
    try {
      // Check if device supports biometrics
      final capabilities = await checkCapabilities();
      if (capabilities.isFailure()) {
        return Result.failure(
          Exception('Device does not support biometric security'),
        );
      }

      // Initialize biometric
      final result = await platform.invokeMethod('enableBiometricSecurity');
      if (result == true) {
        return Result.success(null);
      }
      return Result.failure(Exception('Failed to enable biometric security'));
    } on PlatformException catch (e) {
      return Result.failure(
        Exception('Enable biometric security error: ${e.message}'),
      );
    }
  }

  /// Check if PIN/password authentication is required
  Future<Result<bool>> isDeviceLocked() async {
    try {
      final result = await platform.invokeMethod('isDeviceLocked');
      return Result.success(result == true);
    } on PlatformException catch (e) {
      return Result.failure(
        Exception('Failed to check device lock: ${e.message}'),
      );
    }
  }

  /// Handle biometric authentication errors
  Result<BiometricAuthResult> _handleBiometricError(PlatformException e) {
    final errorCode = e.code;
    final message = e.message ?? 'Unknown biometric error';

    return switch (errorCode) {
      'NotAvailable' => Result.failure(
        Exception('Biometric is not available on this device'),
      ),
      'NotEnrolled' => Result.failure(
        Exception('No biometric data enrolled on this device'),
      ),
      'LockOut' => Result.failure(
        Exception(
          'Too many biometric attempts. Device is locked. Try PIN instead.',
        ),
      ),
      'LockedOut' => Result.failure(
        Exception(
          'Biometric sensor is locked due to too many failed attempts',
        ),
      ),
      'PermanentlyLockedOut' => Result.failure(
        Exception('Biometric is permanently locked out. Use PIN instead.'),
      ),
      'NotInitialized' => Result.failure(
        Exception('Biometric not initialized properly'),
      ),
      'NotEnoughData' => Result.failure(
        Exception('Not enough biometric data. Please try again.'),
      ),
      'UserCanceled' => Result.failure(
        Exception('Biometric authentication canceled by user'),
      ),
      'HardwareNotPresent' => Result.failure(
        Exception('Biometric hardware not present on this device'),
      ),
      'HardwareNotAvailable' => Result.failure(
        Exception('Biometric hardware is not available'),
      ),
      'NegativeButton' => Result.failure(
        Exception('Authentication canceled'),
      ),
      'SystemNotAvailable' => Result.failure(
        Exception('Biometric system temporarily unavailable'),
      ),
      'TimeoutException' => Result.failure(
        Exception('Biometric authentication timeout'),
      ),
      _ => Result.failure(
        Exception('Biometric authentication failed: $message'),
      ),
    };
  }
}

/// Biometric device capabilities
class BiometricCapabilities {
  final bool isDeviceSupported; // Device supports biometric API
  final bool isDeviceSecure; // Device has secure lock screen
  final bool hasBiometric; // At least one biometric enrolled
  final bool hasFingerprint; // Fingerprint available
  final bool hasFaceRecognition; // Face recognition available
  final List<BiometricType> availableBiometrics; // All available types

  BiometricCapabilities({
    required this.isDeviceSupported,
    required this.isDeviceSecure,
    required this.hasBiometric,
    required this.hasFingerprint,
    required this.hasFaceRecognition,
    required this.availableBiometrics,
  });

  bool get isReadyForBiometric => isDeviceSupported && isDeviceSecure && hasBiometric;
  bool get preferredMethod => hasFingerprint ? true : hasFaceRecognition;
}

/// Result of biometric authentication
class BiometricAuthResult {
  final bool authenticated;
  final DateTime timestamp;
  final String method; // 'biometric', 'device_lock', 'fallback'
  final String? biometricType; // 'fingerprint', 'face', etc.

  BiometricAuthResult({
    required this.authenticated,
    required this.timestamp,
    required this.method,
    this.biometricType,
  });

  /// Check if authentication is still valid (within 5 minutes)
  bool get isStillValid {
    return DateTime.now().difference(timestamp).inMinutes < 5;
  }
}
