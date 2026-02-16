import 'package:dio/dio.dart';
import 'dart:async';
import '../utils/logger.dart';
import '../utils/result.dart';

class NetworkConfig {
  static const int connectTimeoutMs = 30000;
  static const int receiveTimeoutMs = 60000;
  static const int sendTimeoutMs = 60000;
  static const int maxRetries = 3;
  static const Duration retryDelayBase = Duration(milliseconds: 100);
}

class RetryConfig {
  final int maxRetries;
  final Duration delayBase;
  final double delayMultiplier;
  final Duration maxDelay;

  RetryConfig({
    this.maxRetries = 3,
    this.delayBase = const Duration(milliseconds: 100),
    this.delayMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 10),
  });
}

/// Enterprise-grade HTTP client with retry logic, timeouts, and error handling
class HttpClient {
  late final Dio _dio;
  final RetryConfig retryConfig;

  HttpClient({RetryConfig? retryConfig})
      : retryConfig = retryConfig ?? RetryConfig() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(milliseconds: NetworkConfig.connectTimeoutMs),
        receiveTimeout: const Duration(milliseconds: NetworkConfig.receiveTimeoutMs),
        sendTimeout: const Duration(milliseconds: NetworkConfig.sendTimeoutMs),
        contentType: Headers.jsonContentType,
      ),
    );

    _dio.interceptors.add(_RequestInterceptor());
    _dio.interceptors.add(_ResponseInterceptor());
  }

  /// GET request with retry logic
  Future<Result<T>> get<T>({
    required String path,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    return _requestWithRetry(
      () async {
        final response = await _dio.get<dynamic>(
          path,
          queryParameters: queryParameters,
        );
        return _handleResponse<T>(response, fromJson);
      },
    );
  }

  /// POST request with retry logic
  Future<Result<T>> post<T>({
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    return _requestWithRetry(
      () async {
        final response = await _dio.post<dynamic>(
          path,
          data: data,
          queryParameters: queryParameters,
        );
        return _handleResponse<T>(response, fromJson);
      },
      retryable: _isRetryableMethod(true), // POST can be retried on idempotent endpoints
    );
  }

  /// PUT request
  Future<Result<T>> put<T>({
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    return _requestWithRetry(
      () async {
        final response = await _dio.put<dynamic>(
          path,
          data: data,
          queryParameters: queryParameters,
        );
        return _handleResponse<T>(response, fromJson);
      },
    );
  }

  /// PATCH request
  Future<Result<T>> patch<T>({
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    return _requestWithRetry(
      () async {
        final response = await _dio.patch<dynamic>(
          path,
          data: data,
          queryParameters: queryParameters,
        );
        return _handleResponse<T>(response, fromJson);
      },
    );
  }

  /// DELETE request
  Future<Result<T>> delete<T>({
    required String path,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    return _requestWithRetry(
      () async {
        final response = await _dio.delete<dynamic>(
          path,
          queryParameters: queryParameters,
        );
        return _handleResponse<T>(response, fromJson);
      },
    );
  }

  /// Internal method to handle requests with exponential backoff retry
  Future<Result<T>> _requestWithRetry<T>(
    Future<Result<T>> Function() request, {
    bool retryable = true,
  }) async {
    int attemptCount = 0;
    Duration currentDelay = retryConfig.delayBase;

    while (true) {
      try {
        attemptCount++;
        final result = await request();
        
        // If successful or not retryable, return immediately
        if (result.isSuccess() || !retryable || attemptCount >= retryConfig.maxRetries) {
          return result;
        }

        // Check if we should retry based on failure type
        if (result.isFailure()) {
          final exception = result.getExceptionOrNull();

          final shouldRetry = exception is TimeoutException || exception is NetworkException;
          if (!shouldRetry || attemptCount >= retryConfig.maxRetries) {
            return result;
          }

          // Wait before retry with exponential backoff
          await Future.delayed(currentDelay);
          currentDelay = Duration(
            milliseconds: (currentDelay.inMilliseconds * retryConfig.delayMultiplier).toInt(),
          );
          if (currentDelay > retryConfig.maxDelay) {
            currentDelay = retryConfig.maxDelay;
          }
          continue;
        }

        return result;
      } on TimeoutException catch (e) {
        if (attemptCount >= retryConfig.maxRetries || !retryable) {
          AppLogger.error('HttpClient', 'Request timeout after $attemptCount attempts', e);
          return Result.failure(e);
        }
        await Future.delayed(currentDelay);
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * retryConfig.delayMultiplier).toInt(),
        );
        if (currentDelay > retryConfig.maxDelay) {
          currentDelay = retryConfig.maxDelay;
        }
      } on NetworkException catch (e) {
        if (attemptCount >= retryConfig.maxRetries || !retryable) {
          AppLogger.error('HttpClient', 'Network error after $attemptCount attempts', e);
          return Result.failure(e);
        }
        await Future.delayed(currentDelay);
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * retryConfig.delayMultiplier).toInt(),
        );
        if (currentDelay > retryConfig.maxDelay) {
          currentDelay = retryConfig.maxDelay;
        }
      } on Exception catch (e) {
        if (attemptCount >= retryConfig.maxRetries || !retryable) {
          AppLogger.error('HttpClient', 'Unexpected error after $attemptCount attempts', e);
          return Result.failure(e);
        }
        return Result.failure(e);
      }
    }
  }

  /// Handle HTTP response and map to Result
  Result<T> _handleResponse<T>(
    Response<dynamic> response,
    T Function(dynamic)? fromJson,
  ) {
    try {
      if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
        return Result.failure(
          ServerException(
            message: 'HTTP ${response.statusCode}: ${response.statusMessage}',
            statusCode: response.statusCode,
            responseBody: response.data,
          ),
        );
      }

      if (fromJson != null) {
        final value = fromJson(response.data);
        return Result.success(value);
      }

      return Result.success(response.data as T);
    } on Exception catch (e) {
      AppLogger.error('HttpClient', 'Response handling error', e);
      return Result.failure(e);
    }
  }

  /// Check if HTTP method is retryable
  bool _isRetryableMethod(bool isPost) {
    // Only retry GET, PUT, DELETE by default
    // POST only if idempotent (has Idempotency-Key header)
    return !isPost;
  }

  /// Set authorization header
  void setAuthorizationHeader(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Clear authorization header
  void clearAuthorizationHeader() {
    _dio.options.headers.remove('Authorization');
  }

  /// Dispose resources
  void dispose() {
    _dio.close(force: true);
  }
}

/// Request interceptor for logging and modifications
class _RequestInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.debug(
      'HttpRequest',
      '${options.method} ${options.path}${options.queryParameters.isNotEmpty ? '?${options.queryParameters}' : ''}',
    );
    handler.next(options);
  }
}

/// Response interceptor for logging and error handling
class _ResponseInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.debug(
      'HttpResponse',
      '${response.statusCode} ${response.requestOptions.path}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.error(
      'HttpError',
      err.requestOptions.path,
      err,
    );
    handler.next(err);
  }
}
