import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

/// Secure token storage for JWT and refresh tokens
/// Uses SharedPreferences for persistent storage
class TokenStorage {
  static const String _tokenKey = '_auth_token';
  static const String _refreshTokenKey = '_refresh_token';
  static const String _userIdKey = '_user_id';
  static const String _tokenExpiryKey = '_token_expiry';
  
  late SharedPreferences _storage;
  
  /// Initialize storage (call once at app startup)
  Future<void> initialize() async {
    _storage = await SharedPreferences.getInstance();
  }
  
  /// Save authentication token
  Future<void> saveToken(String token, {String? userId}) async {
    try {
      await _storage.setString(_tokenKey, token);
      if (userId != null) {
        await _storage.setString(_userIdKey, userId);
      }
      // Token typically expires in 7 days
      final expiry = DateTime.now().add(const Duration(days: 7));
      await _storage.setString(_tokenExpiryKey, expiry.toIso8601String());
      AppLogger.debug('TokenStorage', 'Token saved successfully');
    } catch (e) {
      AppLogger.error('TokenStorage', 'Failed to save token: $e');
      rethrow;
    }
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String refreshToken) async {
    try {
      await _storage.setString(_refreshTokenKey, refreshToken);
      AppLogger.debug('TokenStorage', 'Refresh token saved successfully');
    } catch (e) {
      AppLogger.error('TokenStorage', 'Failed to save refresh token: $e');
      rethrow;
    }
  }

  /// Get current token
  String? getToken() {
    try {
      final token = _storage.getString(_tokenKey);
      
      // Check if token is expired
      final expiryStr = _storage.getString(_tokenExpiryKey);
      if (expiryStr != null) {
        final expiry = DateTime.parse(expiryStr);
        if (DateTime.now().isAfter(expiry)) {
          AppLogger.debug('TokenStorage', 'Token has expired');
          clearTokenSync();
          return null;
        }
      }
      
      return token;
    } catch (e) {
      AppLogger.error('TokenStorage', 'Failed to get token: $e');
      return null;
    }
  }

  /// Get refresh token
  String? getRefreshToken() {
    try {
      return _storage.getString(_refreshTokenKey);
    } catch (e) {
      AppLogger.error('TokenStorage', 'Failed to get refresh token: $e');
      return null;
    }
  }

  /// Get stored user ID
  String? getUserId() {
    try {
      return _storage.getString(_userIdKey);
    } catch (e) {
      AppLogger.error('TokenStorage', 'Failed to get user ID: $e');
      return null;
    }
  }

  /// Check if token exists and is valid
  bool hasValidToken() {
    return getToken() != null;
  }

  /// Clear all tokens synchronously
  void clearTokenSync() {
    try {
      _storage.remove(_tokenKey);
      _storage.remove(_refreshTokenKey);
      _storage.remove(_userIdKey);
      _storage.remove(_tokenExpiryKey);
    } catch (e) {
      AppLogger.error('TokenStorage', 'Failed to clear tokens: $e');
    }
  }

  /// Clear all tokens asynchronously
  Future<void> clearToken() async {
    try {
      await _storage.remove(_tokenKey);
      await _storage.remove(_refreshTokenKey);
      await _storage.remove(_userIdKey);
      await _storage.remove(_tokenExpiryKey);
      AppLogger.info('TokenStorage', 'Tokens cleared successfully');
    } catch (e) {
      AppLogger.error('TokenStorage', 'Failed to clear tokens: $e');
      rethrow;
    }
  }
}
