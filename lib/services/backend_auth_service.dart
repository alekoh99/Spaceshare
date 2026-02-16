import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'dart:convert';
import '../models/user_model.dart';
import '../utils/logger.dart';
import '../utils/exceptions.dart' as exceptions;
import 'api_client.dart';
import 'token_storage.dart';
import 'firebase_auth_service.dart';

/// Backend Authentication Integration Service
/// Coordinates Firebase Auth with backend JWT token management
class BackendAuthService extends GetxService {
  late ApiClient _apiClient;
  late TokenStorage _tokenStorage;
  late FirebaseAuthService _firebaseAuthService;
  
  final Rx<String?> currentToken = Rx<String?>(null);
  final Rx<String?> currentUserId = Rx<String?>(null);
  
  @override
  void onInit() {
    super.onInit();
    _initializeDependencies();
  }

  @override
  void onReady() {
    super.onReady();
    _initializeTokenStorage();
  }

  void _initializeDependencies() {
    try {
      _apiClient = Get.find<ApiClient>();
    } catch (e) {
      _apiClient = Get.put(ApiClient());
    }
    
    try {
      _firebaseAuthService = Get.find<FirebaseAuthService>();
    } catch (e) {
      _firebaseAuthService = Get.put(FirebaseAuthService());
    }
  }

  Future<void> _initializeTokenStorage() async {
    try {
      _tokenStorage = TokenStorage();
      await _tokenStorage.initialize();
    } catch (e) {
      AppLogger.error('BackendAuthService', 'Failed to initialize TokenStorage: $e');
      rethrow;
    }
  }

  /// Register new user with backend
  /// Firebase auth must be completed first
  Future<Map<String, dynamic>> registerWithBackend({
    required String firebaseToken,
    required UserProfile profileData,
  }) async {
    try {
      AppLogger.info('BackendAuth', 'Registering user with backend...');
      
      final response = await _apiClient.post(
        '/auth/register',
        {
          'firebaseToken': firebaseToken,
          'profileData': profileData.toJson(),
        },
        requireAuth: false,
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw exceptions.AuthException(
          'Backend registration failed: ${response.statusCode}',
        );
      }

      final data = _apiClient.parseJson(response);
      await _handleAuthResponse(data);
      
      AppLogger.success('BackendAuth', 'User registered successfully');
      return data;
    } catch (e) {
      AppLogger.error('BackendAuth', 'Registration failed: $e');
      rethrow;
    }
  }

  /// Sign in user with backend
  /// Firebase auth must be completed first
  Future<Map<String, dynamic>> signInWithBackend({
    required String firebaseToken,
  }) async {
    try {
      AppLogger.info('BackendAuth', 'Signing in with backend...');
      
      final response = await _apiClient.post(
        '/auth/signin',
        {'firebaseToken': firebaseToken},
        requireAuth: false,
      );

      if (response.statusCode != 200) {
        throw exceptions.AuthException(
          'Backend signin failed: ${response.statusCode}',
        );
      }

      final data = _apiClient.parseJson(response);
      await _handleAuthResponse(data);
      
      AppLogger.success('BackendAuth', 'User signed in successfully');
      return data;
    } catch (e) {
      AppLogger.error('BackendAuth', 'Sign in failed: $e');
      rethrow;
    }
  }

  /// Handle auth response from backend
  Future<void> _handleAuthResponse(Map<String, dynamic> response) async {
    try {
      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw exceptions.AuthException('Invalid auth response format');
      }

      final token = data['token'] as String?;
      final userId = data['userId'] as String?;

      if (token == null || userId == null) {
        throw exceptions.AuthException('Missing token or userId in response');
      }

      // Save token and user info
      await _tokenStorage.saveToken(token, userId: userId);
      currentToken.value = token;
      currentUserId.value = userId;

      AppLogger.success('BackendAuth', 'Token stored for userId: $userId');
    } catch (e) {
      AppLogger.error('BackendAuth', 'Failed to handle auth response: $e');
      rethrow;
    }
  }

  /// Get current authentication token
  String? getToken() {
    return currentToken.value ?? _tokenStorage.getToken();
  }

  /// Get current user ID
  String? getUserId() {
    return currentUserId.value ?? _tokenStorage.getUserId();
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return getToken() != null && getUserId() != null;
  }

  /// Refresh authentication token
  Future<void> refreshToken() async {
    try {
      AppLogger.info('BackendAuth', 'Refreshing token...');
      
      final response = await _apiClient.post(
        '/auth/refresh-token',
        {
          'refreshToken': _tokenStorage.getRefreshToken(),
        },
        requireAuth: false,
      );

      if (response.statusCode != 200) {
        throw exceptions.AuthException('Token refresh failed: ${response.statusCode}');
      }

      final data = _apiClient.parseJson(response);
      await _handleAuthResponse(data);
      
      AppLogger.success('BackendAuth', 'Token refreshed successfully');
    } catch (e) {
      AppLogger.error('BackendAuth', 'Token refresh failed: $e');
      await logout();
      rethrow;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      AppLogger.info('BackendAuth', 'Logging out...');
      
      // Call backend logout endpoint
      try {
        await _apiClient.post(
          '/auth/logout',
          {},
          requireAuth: true,
        );
      } catch (e) {
        AppLogger.warning('BackendAuth', 'Backend logout failed, proceeding with local logout: $e');
      }

      // Clear local data
      await _tokenStorage.clearToken();
      currentToken.value = null;
      currentUserId.value = null;
      
      // Sign out from Firebase
      await _firebaseAuthService.signOut();
      
      AppLogger.success('BackendAuth', 'Logged out successfully');
    } catch (e) {
      AppLogger.error('BackendAuth', 'Logout error: $e');
      // Still clear tokens even if error
      await _tokenStorage.clearToken();
      rethrow;
    }
  }

  /// Get full user info from backend
  Future<UserProfile?> getUserInfo() async {
    try {
      final response = await _apiClient.get('/auth/user');

      if (response.statusCode == 200) {
        final data = _apiClient.parseJson(response);
        final userData = data['data'] as Map<String, dynamic>?;
        
        if (userData != null) {
          return UserProfile.fromJson(userData);
        }
      }

      return null;
    } catch (e) {
      AppLogger.error('BackendAuth', 'Failed to get user info: $e');
      rethrow;
    }
  }

  /// Restore session from stored token
  Future<bool> restoreSession() async {
    try {
      AppLogger.info('BackendAuth', 'Restoring session from stored token...');
      
      final token = _tokenStorage.getToken();
      final userId = _tokenStorage.getUserId();

      if (token != null && userId != null) {
        currentToken.value = token;
        currentUserId.value = userId;
        
        // Verify token is still valid by checking user info
        try {
          await getUserInfo();
          AppLogger.success('BackendAuth', 'Session restored successfully');
          return true;
        } catch (e) {
          // Token may have expired, try refresh
          try {
            await refreshToken();
            return true;
          } catch (refreshError) {
            AppLogger.warning('BackendAuth', 'Session validation failed: $e');
            await _tokenStorage.clearToken();
            return false;
          }
        }
      }

      AppLogger.info('BackendAuth', 'No stored session found');
      return false;
    } catch (e) {
      AppLogger.error('BackendAuth', 'Failed to restore session: $e');
      return false;
    }
  }
}
