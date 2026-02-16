import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/logger.dart';
import '../utils/exceptions.dart' as exceptions;
import 'token_storage.dart';
import 'offline_queue_manager.dart';

/// HTTP API Client for backend communication
/// Handles authentication, error handling, retries, synchronization, and offline mode
class ApiClient extends GetxService {
  static const int RETRY_COUNT = 3;
  static const Duration RETRY_DELAY = Duration(milliseconds: 1000);
  static const Duration REQUEST_TIMEOUT = Duration(seconds: 30);
  
  late String baseUrl;
  final http.Client _httpClient = http.Client();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TokenStorage _tokenStorage;
  late OfflineQueueManager _offlineQueue;
  final Connectivity _connectivity = Connectivity();
  
  // Track pending requests for sync
  final List<PendingRequest> _pendingRequests = [];
  final RxBool isSyncing = false.obs;
  final RxBool isOnline = true.obs;
  
  @override
  void onInit() {
    super.onInit();
    baseUrl = _getBaseUrl();
    _setupRequestInterceptor();
    _setupConnectivityListener();
  }

  @override
  void onReady() {
    super.onReady();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      _tokenStorage = TokenStorage();
      await _tokenStorage.initialize();
      _initOfflineQueue();
    } catch (e) {
      AppLogger.error('ApiClient', 'Failed to initialize services: $e');
      rethrow;
    }
  }

  void _initOfflineQueue() {
    try {
      _offlineQueue = Get.find<OfflineQueueManager>();
    } catch (e) {
      _offlineQueue = Get.put(OfflineQueueManager());
    }
  }

  void _setupConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((result) {
      final wasOnline = isOnline.value;
      isOnline.value = result != ConnectivityResult.none;
      
      if (!wasOnline && isOnline.value) {
        AppLogger.success('ApiClient', 'Connection restored');
        _processPendingRequests();
      } else if (wasOnline && !isOnline.value) {
        AppLogger.warning('ApiClient', 'Connection lost - enabling offline mode');
      }
    });
  }

  String _getBaseUrl() {
    // Allow override via environment or config
    const String defaultUrl = 'http://localhost:8080/api';
    const String productionUrl = 'https://api.spaceshare.app/api';
    
    final env = const String.fromEnvironment('API_URL', defaultValue: defaultUrl);
    return env.isNotEmpty ? env : defaultUrl;
  }

  void _setupRequestInterceptor() {
    // Log all requests
    AppLogger.debug('ApiClient', 'Initialized with base URL: $baseUrl');
  }

  /// Get headers with JWT authentication
  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    try {
      // Try to use stored JWT token first
      final jwtToken = _tokenStorage.getToken();
      if (jwtToken != null && jwtToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $jwtToken';
        AppLogger.debug('ApiClient', 'Using stored JWT token');
        return headers;
      }

      // Fallback to Firebase token if no JWT
      final user = _auth.currentUser;
      if (user != null) {
        final idToken = await user.getIdToken();
        headers['Authorization'] = 'Bearer $idToken';
        headers['x-user-id'] = user.uid;
        AppLogger.debug('ApiClient', 'Using Firebase ID token');
        return headers;
      }

      // If auth is required but no token available, throw error
      if (requireAuth) {
        throw exceptions.AuthException('User not authenticated - no token available');
      }
    } catch (e) {
      if (requireAuth) {
        AppLogger.error('ApiClient', 'Failed to get auth headers: $e');
        rethrow;
      }
      AppLogger.debug('ApiClient', 'Auth headers not available: $e');
    }

    return headers;
  }

  /// Make GET request with retry logic
  Future<http.Response> get(
    String endpoint, {
    bool requireAuth = true,
    Map<String, String>? queryParams,
  }) async {
    final url = _buildUrl(endpoint, queryParams);
    
    return _executeWithRetry(
      () => _perform('GET', url, null, requireAuth),
      endpoint: endpoint,
      method: 'GET',
    );
  }

  /// Make POST request with retry logic
  Future<http.Response> post(
    String endpoint,
    dynamic body, {
    bool requireAuth = true,
  }) async {
    final url = _buildUrl(endpoint);
    
    return _executeWithRetry(
      () => _perform('POST', url, body, requireAuth),
      endpoint: endpoint,
      method: 'POST',
      body: body,
    );
  }

  /// Make PUT request with retry logic
  Future<http.Response> put(
    String endpoint,
    dynamic body, {
    bool requireAuth = true,
  }) async {
    final url = _buildUrl(endpoint);
    
    return _executeWithRetry(
      () => _perform('PUT', url, body, requireAuth),
      endpoint: endpoint,
      method: 'PUT',
      body: body,
    );
  }

  /// Make PATCH request with retry logic
  Future<http.Response> patch(
    String endpoint,
    dynamic body, {
    bool requireAuth = true,
  }) async {
    final url = _buildUrl(endpoint);
    
    return _executeWithRetry(
      () => _perform('PATCH', url, body, requireAuth),
      endpoint: endpoint,
      method: 'PATCH',
      body: body,
    );
  }

  /// Make DELETE request with retry logic
  Future<http.Response> delete(
    String endpoint, {
    bool requireAuth = true,
  }) async {
    final url = _buildUrl(endpoint);
    
    return _executeWithRetry(
      () => _perform('DELETE', url, null, requireAuth),
      endpoint: endpoint,
      method: 'DELETE',
    );
  }

  /// Perform actual HTTP request
  Future<http.Response> _perform(
    String method,
    Uri url,
    dynamic body,
    bool requireAuth,
  ) async {
    try {
      final headers = await _getHeaders(requireAuth: requireAuth);

      final request = http.Request(method, url)
        ..headers.addAll(headers);

      if (body != null) {
        if (body is String) {
          request.body = body;
        } else {
          request.body = jsonEncode(body);
        }
      }

      AppLogger.debug(
        'ApiClient',
        '$method $url',
      );

      final streamedResponse = await _httpClient.send(request).timeout(REQUEST_TIMEOUT);
      final response = await http.Response.fromStream(streamedResponse);

      // Log response
      if (response.statusCode >= 400) {
        AppLogger.warning(
          'ApiClient',
          '$method $url returned ${response.statusCode}',
        );
      } else {
        AppLogger.debug(
          'ApiClient',
          '$method $url returned ${response.statusCode}',
        );
      }

      return response;
    } catch (e) {
      AppLogger.error('ApiClient', 'Request failed: $method $url - $e');
      rethrow;
    }
  }

  /// Execute request with retry logic and offline fallback
  Future<http.Response> _executeWithRetry(
    Future<http.Response> Function() operation, {
    required String endpoint,
    required String method,
    dynamic body,
  }) async {
    // Check if we're online
    if (!isOnline.value) {
      AppLogger.warning('ApiClient', 'Offline - queuing request: $method $endpoint');
      await _offlineQueue.addRequest(method, endpoint, body: body as Map<String, dynamic>?);
      throw exceptions.NetworkException(message: 'Device is offline - request queued for later');
    }

    int attempt = 0;
    dynamic lastError;

    while (attempt < RETRY_COUNT) {
      try {
        final response = await operation();
        
        // Success on any 2xx or 3xx status
        if (response.statusCode < 400) {
          return response;
        }

        // Handle 401 Unauthorized - try to refresh token
        if (response.statusCode == 401) {
          AppLogger.warning('ApiClient', 'Received 401 - attempting token refresh');
          try {
            await _refreshToken();
            // Retry the request with new token
            if (attempt < RETRY_COUNT - 1) {
              attempt++;
              AppLogger.debug('ApiClient', 'Retrying request after token refresh (attempt $attempt)');
              await Future.delayed(RETRY_DELAY);
              continue;
            }
          } catch (e) {
            AppLogger.error('ApiClient', 'Token refresh failed: $e');
            return response; // Return 401 error
          }
        }

        // Don't retry on other 4xx client errors (except 429 rate limit)
        if (response.statusCode >= 400 && response.statusCode < 500) {
          if (response.statusCode != 429) {
            return response; // Return error response
          }
        }

        lastError = 'HTTP ${response.statusCode}';
      } catch (e) {
        // If offline, queue the request
        if (!isOnline.value) {
          AppLogger.warning('ApiClient', 'Lost connection - queuing request');
          await _offlineQueue.addRequest(method, endpoint, body: body as Map<String, dynamic>?);
          rethrow;
        }
        lastError = e;
      }

      attempt++;
      if (attempt < RETRY_COUNT) {
        AppLogger.debug(
          'ApiClient',
          'Retry $attempt/$RETRY_COUNT for $method $endpoint after $lastError',
        );
        await Future.delayed(RETRY_DELAY * attempt);
      }
    }

    throw exceptions.NetworkException(
      message: 'Request failed after $RETRY_COUNT attempts: $method $endpoint - $lastError',
    );
  }

  /// Refresh JWT token using refresh token
  Future<void> _refreshToken() async {
    try {
      final refreshToken = _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        throw exceptions.AuthException('No refresh token available');
      }

      final response = await _httpClient.post(
        Uri.parse('$baseUrl/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(REQUEST_TIMEOUT);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newToken = data['data']?['token'] as String?;
        
        if (newToken != null) {
          await _tokenStorage.saveToken(newToken);
          AppLogger.success('ApiClient', 'Token refreshed successfully');
          return;
        }
      }

      throw exceptions.AuthException('Failed to refresh token: ${response.statusCode}');
    } catch (e) {
      AppLogger.error('ApiClient', 'Token refresh error: $e');
      // Clear tokens on refresh failure
      await _tokenStorage.clearToken();
      rethrow;
    }
  }

  /// Process pending requests when coming back online
  Future<void> _processPendingRequests() async {
    final pending = _offlineQueue.getPendingRequests();
    if (pending.isEmpty) return;

    AppLogger.info('ApiClient', 'Processing ${pending.length} pending requests...');
    
    await _offlineQueue.processPendingRequests((request) async {
      switch (request.method.toUpperCase()) {
        case 'GET':
          return get(request.endpoint);
        case 'POST':
          return post(request.endpoint, request.body);
        case 'PATCH':
          return patch(request.endpoint, request.body);
        case 'PUT':
          return put(request.endpoint, request.body);
        case 'DELETE':
          return delete(request.endpoint);
        default:
          throw exceptions.NetworkException(message: 'Unknown HTTP method: ${request.method}');
      }
    });
  }

  /// Build complete URL
  Uri _buildUrl(String endpoint, [Map<String, String>? queryParams]) {
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final url = Uri.parse('$baseUrl$path');
    
    if (queryParams != null && queryParams.isNotEmpty) {
      return url.replace(queryParameters: queryParams);
    }
    
    return url;
  }

  /// Parse response as JSON
  Map<String, dynamic> parseJson(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('ApiClient', 'Failed to parse response: $e');
      throw exceptions.NetworkException(message: 'Invalid response format');
    }
  }

  /// Check if API is healthy
  Future<bool> isHealthy() async {
    try {
      final response = await get('/health', requireAuth: false).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.debug('ApiClient', 'Health check failed: $e');
      return false;
    }
  }

  @override
  void onClose() {
    _httpClient.close();
    super.onClose();
  }
}

/// Pending request for offline queue
class PendingRequest {
  final String method;
  final String endpoint;
  final dynamic body;
  final DateTime timestamp;
  
  PendingRequest({
    required this.method,
    required this.endpoint,
    this.body,
  }) : timestamp = DateTime.now();
}
