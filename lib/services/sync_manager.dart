import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import '../models/user_model.dart';
import '../utils/logger.dart';
import '../utils/exceptions.dart' as exceptions;
import 'api_client.dart';

/// Synchronization manager for frontend-backend data sync
/// Handles conflict resolution, deduplication, and bidirectional sync
class SyncManager extends GetxService {
  late ApiClient apiClient;
  
  // Sync state
  final RxBool isSyncing = false.obs;
  final Rx<DateTime?> lastSync = Rx<DateTime?>(null);
  final RxInt pendingChanges = 0.obs;
  final RxList<SyncError> syncErrors = <SyncError>[].obs;
  
  // Sync queue
  final List<SyncOperation> _syncQueue = [];
  Timer? _syncTimer;
  
  // Configuration
  static const Duration SYNC_INTERVAL = Duration(seconds: 30);
  static const Duration DEBOUNCE_DURATION = Duration(milliseconds: 500);
  
  @override
  void onInit() {
    super.onInit();
    try {
      apiClient = Get.find<ApiClient>();
    } catch (e) {
      AppLogger.warning('SyncManager', 'ApiClient not found: $e');
      apiClient = Get.put(ApiClient());
    }
    
    _startAutoSync();
  }

  /// Start automatic sync timer
  void _startAutoSync() {
    _syncTimer = Timer.periodic(SYNC_INTERVAL, (_) async {
      if (!isSyncing.value && _syncQueue.isNotEmpty) {
        await syncAll();
      }
    });
    AppLogger.info('SyncManager', 'Auto-sync started (interval: $SYNC_INTERVAL)');
  }

  /// Add operation to sync queue
  void queueOperation({
    required String type, // 'create', 'update', 'delete'
    required String entity, // 'profile', 'listing', etc.
    required String entityId,
    dynamic data,
    String? endpoint,
  }) {
    final operation = SyncOperation(
      id: '${entityId}_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      entity: entity,
      entityId: entityId,
      data: data,
      endpoint: endpoint ?? _getDefaultEndpoint(entity),
      timestamp: DateTime.now(),
    );

    _syncQueue.add(operation);
    pendingChanges.value = _syncQueue.length;
    
    AppLogger.debug(
      'SyncManager',
      'Queued: $type $entity ($entityId) - Total pending: ${pendingChanges.value}',
    );
  }

  /// Sync profile data
  Future<void> syncProfile(UserProfile profile) async {
    try {
      AppLogger.info('SyncManager', 'Syncing profile: ${profile.userId}');
      
      final response = await apiClient.patch(
        '/profiles/${profile.userId}',
        profile.toJson(),
      );

      if (response.statusCode == 200) {
        AppLogger.success('SyncManager', 'Profile synced successfully');
        lastSync.value = DateTime.now();
        return;
      }

      if (response.statusCode == 404) {
        // Profile doesn't exist, create it
        AppLogger.info('SyncManager', 'Profile not found, creating new profile');
        final createResponse = await apiClient.post(
          '/profiles',
          profile.toJson(),
        );

        if (createResponse.statusCode == 201) {
          AppLogger.success('SyncManager', 'Profile created successfully');
          lastSync.value = DateTime.now();
          return;
        }

        throw exceptions.SyncException(
          'Failed to create profile: ${createResponse.statusCode}',
        );
      }

      throw exceptions.SyncException(
        'Failed to sync profile: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      _handleSyncError('Profile sync', profile.userId, e);
      rethrow;
    }
  }

  /// Fetch latest profile from backend
  Future<UserProfile?> fetchProfile(String userId) async {
    try {
      AppLogger.info('SyncManager', 'Fetching profile: $userId');
      
      final response = await apiClient.get('/profiles/$userId');

      if (response.statusCode == 200) {
        final data = apiClient.parseJson(response);
        final profile = UserProfile.fromJson(data);
        AppLogger.success('SyncManager', 'Profile fetched successfully');
        return profile;
      }

      if (response.statusCode == 404) {
        AppLogger.warning('SyncManager', 'Profile not found on server');
        return null;
      }

      throw exceptions.SyncException(
        'Failed to fetch profile: ${response.statusCode}',
      );
    } catch (e) {
      _handleSyncError('Profile fetch', userId, e);
      return null;
    }
  }

  /// Sync all pending operations
  Future<void> syncAll() async {
    if (isSyncing.value || _syncQueue.isEmpty) {
      return;
    }

    isSyncing.value = true;
    AppLogger.info('SyncManager', 'Starting sync of ${_syncQueue.length} operations');

    try {
      final operationsToSync = List<SyncOperation>.from(_syncQueue);
      
      for (final operation in operationsToSync) {
        try {
          await _executeSyncOperation(operation);
          _syncQueue.remove(operation);
          pendingChanges.value = _syncQueue.length;
        } catch (e) {
          AppLogger.warning('SyncManager', 'Failed to sync operation: $e');
          _handleSyncError(operation.type, operation.entityId, e);
        }
      }

      lastSync.value = DateTime.now();
      AppLogger.success(
        'SyncManager',
        'Sync completed. Remaining: ${_syncQueue.length}',
      );
    } finally {
      isSyncing.value = false;
    }
  }

  /// Execute individual sync operation
  Future<void> _executeSyncOperation(SyncOperation operation) async {
    AppLogger.debug(
      'SyncManager',
      'Executing: ${operation.type} ${operation.entity}',
    );

    http.Response response;
    
    // For profile operations, ensure endpoint includes userId
    String endpoint = operation.endpoint;
    if (operation.type.toLowerCase() == 'profile' && 
        (endpoint == '/profiles' || !endpoint.contains('/'))) {
      endpoint = '/profiles/${operation.entityId}';
    }

    switch (operation.type.toLowerCase()) {
      case 'create':
        response = await apiClient.post(endpoint, operation.data);
        break;
      case 'update':
        response = await apiClient.patch(endpoint, operation.data);
        break;
      case 'delete':
        response = await apiClient.delete(endpoint);
        break;
      case 'profile':
        // Handle profile updates as PATCH requests
        response = await apiClient.patch(endpoint, operation.data);
        break;
      default:
        throw exceptions.SyncException('Unknown operation type: ${operation.type}');
    }

    if (response.statusCode >= 400) {
      throw exceptions.SyncException(
        '${operation.type} failed: ${response.statusCode}',
      );
    }

    AppLogger.success('SyncManager', 'Operation synced: ${operation.id}');
  }

  /// Handle sync errors
  void _handleSyncError(String operation, String entityId, dynamic error) {
    final syncError = SyncError(
      operation: operation,
      entityId: entityId,
      error: error.toString(),
      timestamp: DateTime.now(),
    );

    syncErrors.add(syncError);
    if (syncErrors.length > 50) {
      syncErrors.removeAt(0); // Keep only last 50 errors
    }

    AppLogger.error(
      'SyncManager',
      '$operation failed for $entityId: $error',
    );
  }

  /// Get default endpoint for entity
  String _getDefaultEndpoint(String entity) {
    switch (entity.toLowerCase()) {
      case 'profile':
        return '/profiles';
      case 'listing':
        return '/listings';
      case 'review':
        return '/reviews';
      case 'message':
        return '/messages';
      default:
        return '/$entity';
    }
  }

  /// Clear all pending operations
  void clearQueue() {
    _syncQueue.clear();
    pendingChanges.value = 0;
    AppLogger.info('SyncManager', 'Sync queue cleared');
  }

  /// Get sync statistics
  Map<String, dynamic> getStats() {
    return {
      'isSyncing': isSyncing.value,
      'lastSync': lastSync.value?.toIso8601String(),
      'pendingChanges': pendingChanges.value,
      'syncErrors': syncErrors.length,
      'queueSize': _syncQueue.length,
    };
  }

  @override
  void onClose() {
    _syncTimer?.cancel();
    super.onClose();
  }
}

/// Represents a single sync operation
class SyncOperation {
  final String id;
  final String type; // create, update, delete
  final String entity;
  final String entityId;
  final dynamic data;
  final String endpoint;
  final DateTime timestamp;
  int retryCount = 0;

  SyncOperation({
    required this.id,
    required this.type,
    required this.entity,
    required this.entityId,
    this.data,
    required this.endpoint,
    required this.timestamp,
  });

  @override
  String toString() => 'SyncOperation($type $entity/$entityId at $endpoint)';
}

/// Represents a sync error
class SyncError {
  final String operation;
  final String entityId;
  final String error;
  final DateTime timestamp;

  SyncError({
    required this.operation,
    required this.entityId,
    required this.error,
    required this.timestamp,
  });
}
