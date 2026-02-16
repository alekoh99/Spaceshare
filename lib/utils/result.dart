import 'dart:async';

/// Enterprise-grade Result type for error handling
/// Inspired by Rust's Result<T, E> and Kotlin's Result<T>
/// Provides functional error handling with better async/await support
sealed class Result<T> {
  const Result();

  /// Success state containing value
  factory Result.success(T value) = Success<T>;

  /// Error state containing exception
  factory Result.failure(Exception exception) = Failure<T>;

  /// Loading state for async operations
  factory Result.loading() = Loading<T>;

  /// Get the value or null
  T? getOrNull() {
    if (this is Success<T>) {
      return (this as Success<T>).value;
    }
    return null;
  }

  /// Get the exception or null
  Exception? getExceptionOrNull() {
    if (this is Failure<T>) {
      return (this as Failure<T>).exception;
    }
    return null;
  }

  /// Transform the success value
  Result<U> map<U>(U Function(T) transform) {
    if (this is Success<T>) {
      return Result.success(transform((this as Success<T>).value));
    } else if (this is Failure<T>) {
      return Result.failure((this as Failure<T>).exception);
    } else {
      return Result.loading();
    }
  }

  /// Transform the error
  Result<T> mapError(Exception Function(Exception) transform) {
    if (this is Failure<T>) {
      return Result.failure(transform((this as Failure<T>).exception));
    }
    return this;
  }

  /// Flat map for chaining operations
  Future<Result<U>> flatMapAsync<U>(
    Future<Result<U>> Function(T) transform,
  ) async {
    if (this is Success<T>) {
      return await transform((this as Success<T>).value);
    } else if (this is Failure<T>) {
      return Result.failure((this as Failure<T>).exception);
    } else {
      return Result.loading();
    }
  }

  /// Safe execute with error handling
  static Future<Result<T>> tryCatch<T>(
    Future<T> Function() block,
  ) async {
    try {
      final value = await block();
      return Result.success(value);
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  /// Fold the result into a single value
  U fold<U>(
    U Function(T) onSuccess,
    U Function(Exception) onFailure,
  ) {
    if (this is Success<T>) {
      return onSuccess((this as Success<T>).value);
    } else if (this is Failure<T>) {
      return onFailure((this as Failure<T>).exception);
    } else {
      throw StateError('Result is loading');
    }
  }

  /// Execute side effects
  Result<T> onSuccess(void Function(T) callback) {
    if (this is Success<T>) {
      callback((this as Success<T>).value);
    }
    return this;
  }

  /// Execute error side effects
  Result<T> onFailure(void Function(Exception) callback) {
    if (this is Failure<T>) {
      callback((this as Failure<T>).exception);
    }
    return this;
  }

  /// Get value or throw
  T getOrThrow() {
    if (this is Success<T>) {
      return (this as Success<T>).value;
    } else if (this is Failure<T>) {
      throw (this as Failure<T>).exception;
    } else {
      throw StateError('Result is loading');
    }
  }

  /// Check if successful
  bool isSuccess() => this is Success<T>;

  /// Check if failed
  bool isFailure() => this is Failure<T>;

  /// Check if loading
  bool isLoading() => this is Loading<T>;
}

/// Success result containing value
final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);

  @override
  String toString() => 'Success($value)';
}

/// Failure result containing exception
final class Failure<T> extends Result<T> {
  final Exception exception;
  const Failure(this.exception);

  @override
  String toString() => 'Failure($exception)';
}

/// Loading result
final class Loading<T> extends Result<T> {
  const Loading();

  @override
  String toString() => 'Loading()';
}

/// Extension for convenient Result access
extension ResultExtension<T> on Result<T> {
  /// Get the value (convenience property for Success results)
  T? get data {
    if (this is Success<T>) {
      return (this as Success<T>).value;
    }
    return null;
  }

  /// Get the exception (convenience property for Failure results)
  Exception? get exception {
    if (this is Failure<T>) {
      return (this as Failure<T>).exception;
    }
    return null;
  }
}

/// Custom exception for app errors
abstract class AppException implements Exception {
  final String message;
  final Exception? originalException;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException: $message';
}

/// Network errors
class NetworkException extends AppException {
  NetworkException({
    super.message = 'Network error occurred',
    super.originalException,
    super.stackTrace,
  });
}

/// Authentication errors
class AuthException extends AppException {
  AuthException({
    super.message = 'Authentication failed',
    super.originalException,
    super.stackTrace,
  });
}

/// Validation errors
class ValidationException extends AppException {
  final Map<String, String> errors;

  ValidationException({
    super.message = 'Validation failed',
    required this.errors,
    super.originalException,
    super.stackTrace,
  });
}

/// Server errors
class ServerException extends AppException {
  final int? statusCode;
  final dynamic responseBody;

  ServerException({
    super.message = 'Server error',
    this.statusCode,
    this.responseBody,
    super.originalException,
    super.stackTrace,
  });
}

/// Timeout errors
class TimeoutException extends AppException {
  TimeoutException({
    super.message = 'Request timeout',
    super.originalException,
    super.stackTrace,
  });
}

/// Cache errors
class CacheException extends AppException {
  CacheException({
    super.message = 'Cache operation failed',
    super.originalException,
    super.stackTrace,
  });
}

/// Not found errors
class NotFoundException extends AppException {
  NotFoundException({
    super.message = 'Resource not found',
    super.originalException,
    super.stackTrace,
  });
}

/// Permission/Access denied errors
class PermissionException extends AppException {
  PermissionException({
    super.message = 'Permission denied',
    super.originalException,
    super.stackTrace,
  });
}

/// Business logic errors
class BusinessException extends AppException {
  BusinessException({
    required super.message,
    super.originalException,
    super.stackTrace,
  });
}
