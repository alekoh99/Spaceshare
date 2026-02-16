import 'package:get/get.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';
import '../utils/exceptions.dart' as exceptions;

/// Represents a pending request in the offline queue
class PendingRequest {
  final String id;
  final String method;
  final String endpoint;
  final Map<String, dynamic>? body;
  final DateTime timestamp;
  final int retryCount;
  final int maxRetries;

  PendingRequest({
    required this.method,
    required this.endpoint,
    this.body,
    this.retryCount = 0,
    this.maxRetries = 3,
  })  : id = '${DateTime.now().millisecondsSinceEpoch}-${endpoint.hashCode}',
        timestamp = DateTime.now();

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'method': method,
    'endpoint': endpoint,
    'body': body,
    'timestamp': timestamp.toIso8601String(),
    'retryCount': retryCount,
    'maxRetries': maxRetries,
  };

  /// Create from JSON
  factory PendingRequest.fromJson(Map<String, dynamic> json) {
    return PendingRequest(
      method: json['method'] as String,
      endpoint: json['endpoint'] as String,
      body: json['body'] as Map<String, dynamic>?,
      retryCount: json['retryCount'] as int? ?? 0,
      maxRetries: json['maxRetries'] as int? ?? 3,
    );
  }

  /// Check if request can be retried
  bool canRetry() => retryCount < maxRetries;

  /// Create a copy with incremented retry count
  PendingRequest copyWithRetry() {
    final copy = PendingRequest(
      method: method,
      endpoint: endpoint,
      body: body,
      retryCount: retryCount + 1,
      maxRetries: maxRetries,
    );
    return copy;
  }
}

/// Manages offline request queue for when network is unavailable
class OfflineQueueManager extends GetxService {
  static const String _queueKey = '_offline_queue';
  
  late final SharedPreferences _storage;
  final RxList<PendingRequest> queue = <PendingRequest>[].obs;
  final RxBool isProcessing = false.obs;
  
  @override
  Future<void> onInit() async {
    super.onInit();
    _storage = await SharedPreferences.getInstance();
    await loadQueue();
  }
  
  /// Add request to offline queue
  Future<void> addRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final request = PendingRequest(
        method: method,
        endpoint: endpoint,
        body: body,
      );
      
      queue.add(request);
      await _persistQueue();
      
      AppLogger.info(
        'OfflineQueue',
        'Request queued: $method $endpoint (Total: ${queue.length})',
      );
    } catch (e) {
      AppLogger.error('OfflineQueue', 'Failed to add request to queue: $e');
      rethrow;
    }
  }

  /// Get all pending requests
  List<PendingRequest> getPendingRequests() {
    return List.from(queue);
  }

  /// Remove request from queue
  Future<void> removeRequest(String requestId) async {
    try {
      queue.removeWhere((req) => req.id == requestId);
      await _persistQueue();
      AppLogger.debug('OfflineQueue', 'Request removed: $requestId');
    } catch (e) {
      AppLogger.error('OfflineQueue', 'Failed to remove request: $e');
    }
  }

  /// Process all pending requests
  Future<void> processPendingRequests(
    Future<dynamic> Function(PendingRequest) processor,
  ) async {
    if (queue.isEmpty || isProcessing.value) return;

    isProcessing.value = true;
    try {
      final requestsToProcess = List.from(queue);
      
      for (final request in requestsToProcess) {
        try {
          AppLogger.info(
            'OfflineQueue',
            'Processing: ${request.method} ${request.endpoint}',
          );
          
          await processor(request);
          await removeRequest(request.id);
          
          AppLogger.success('OfflineQueue', 'Request processed: ${request.id}');
        } catch (e) {
          AppLogger.warning('OfflineQueue', 'Failed to process request: $e');
          
          // Retry logic
          if (request.canRetry()) {
            final retryRequest = request.copyWithRetry();
            queue[queue.indexWhere((req) => req.id == request.id)] = retryRequest;
            await _persistQueue();
            
            AppLogger.debug(
              'OfflineQueue',
              'Request queued for retry (${retryRequest.retryCount}/${retryRequest.maxRetries})',
            );
          } else {
            // Max retries exceeded
            await removeRequest(request.id);
            AppLogger.error('OfflineQueue', 'Max retries exceeded, request dropped');
          }
        }
      }
    } finally {
      isProcessing.value = false;
    }
  }

  /// Clear all pending requests
  Future<void> clearQueue() async {
    try {
      queue.clear();
      await _storage.remove(_queueKey);
      AppLogger.info('OfflineQueue', 'Queue cleared');
    } catch (e) {
      AppLogger.error('OfflineQueue', 'Failed to clear queue: $e');
    }
  }

  /// Load queue from persistent storage
  Future<void> loadQueue() async {
    try {
      final stored = _storage.getStringList(_queueKey);
      if (stored != null && stored.isNotEmpty) {
        queue.value = stored
            .map((item) => PendingRequest.fromJson(jsonDecode(item) as Map<String, dynamic>))
            .toList();
        AppLogger.info('OfflineQueue', 'Queue loaded with ${queue.length} requests');
      }
    } catch (e) {
      AppLogger.error('OfflineQueue', 'Failed to load queue: $e');
    }
  }

  /// Persist queue to storage
  Future<void> _persistQueue() async {
    try {
      final jsonList = queue.map((req) => jsonEncode(req.toJson())).toList();
      await _storage.setStringList(_queueKey, jsonList);
    } catch (e) {
      AppLogger.error('OfflineQueue', 'Failed to persist queue: $e');
    }
  }

  /// Get queue statistics
  Map<String, dynamic> getStats() {
    return {
      'totalRequests': queue.length,
      'isProcessing': isProcessing.value,
      'oldestRequest': queue.isEmpty ? null : queue.first.timestamp,
    };
  }
}
