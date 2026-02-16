/// Custom exceptions for SpaceShare app
///
/// All app-level exceptions should inherit from [SpaceShareException]
library;

class SpaceShareException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;
  final StackTrace? stackTrace;

  SpaceShareException({
    required this.message,
    this.code,
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() => 'SpaceShareException: $message (code: $code)';
}

class AuthException extends SpaceShareException {
  AuthException(String message, {
    super.code,
    super.originalException,
    super.stackTrace,
  }) : super(
    message: message,
  );
}

class NetworkException extends SpaceShareException {
  NetworkException({
    required super.message,
    String? code,
    super.originalException,
    super.stackTrace,
  }) : super(
    code: code ?? 'NETWORK_ERROR',
  );
}

class ValidationException extends SpaceShareException {
  ValidationException({
    required super.message,
    String? code,
    super.originalException,
    super.stackTrace,
  }) : super(
    code: code ?? 'VALIDATION_ERROR',
  );
}

class PaymentException extends SpaceShareException {
  PaymentException({
    required super.message,
    String? code,
    super.originalException,
    super.stackTrace,
  }) : super(
    code: code ?? 'PAYMENT_ERROR',
  );
}

class FirebaseException extends SpaceShareException {
  FirebaseException({
    required super.message,
    String? code,
    super.originalException,
    super.stackTrace,
  }) : super(
    code: code ?? 'FIREBASE_ERROR',
  );
}

class NotImplementedException extends SpaceShareException {
  NotImplementedException({
    required super.message,
    String? code,
    super.originalException,
    super.stackTrace,
  }) : super(
    code: code ?? 'NOT_IMPLEMENTED',
  );
}

class NotFoundException extends SpaceShareException {
  NotFoundException({
    required super.message,
    String? code,
    super.originalException,
    super.stackTrace,
  }) : super(
    code: code ?? 'NOT_FOUND',
  );
}

class UnauthorizedException extends SpaceShareException {
  UnauthorizedException({
    required super.message,
    String? code,
    super.originalException,
    super.stackTrace,
  }) : super(
    code: code ?? 'UNAUTHORIZED',
  );
}

class TimeoutException extends SpaceShareException {
  TimeoutException({
    required super.message,
    String? code,
    super.originalException,
    super.stackTrace,
  }) : super(
    code: code ?? 'TIMEOUT',
  );
}

class RateLimitException extends SpaceShareException {
  RateLimitException({
    required super.message,
    String? code,
    super.originalException,
    super.stackTrace,
  }) : super(
    code: code ?? 'RATE_LIMIT',
  );
}

class ServiceException extends SpaceShareException {
  ServiceException(String message, {
    String? code,
    super.originalException,
    super.stackTrace,
  }) : super(
    message: message,
    code: code ?? 'SERVICE_ERROR',
  );
}

class MessagingException extends SpaceShareException {
  MessagingException(String message, {
    String? code,
    super.originalException,
    super.stackTrace,
  }) : super(
    message: message,
    code: code ?? 'MESSAGING_ERROR',
  );
}

class UserException extends SpaceShareException {
  UserException(String message, {
    String? code,
    super.originalException,
    super.stackTrace,
  }) : super(
    message: message,
    code: code ?? 'USER_ERROR',
  );
}

class NotificationException extends SpaceShareException {
  NotificationException(String message, {
    String? code,
    super.originalException,
    super.stackTrace,
  }) : super(
    message: message,
    code: code ?? 'NOTIFICATION_ERROR',
  );
}

class MatchException extends SpaceShareException {
  MatchException(String message, {
    String? code,
    super.originalException,
    super.stackTrace,
  }) : super(
    message: message,
    code: code ?? 'MATCH_ERROR',
  );
}

class SyncException extends SpaceShareException {
  SyncException(String message, {
    String? code,
    dynamic originalException,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code ?? 'SYNC_ERROR',
    originalException: originalException,
    stackTrace: stackTrace,
  );
}

// Helper function to handle exceptions
String getExceptionMessage(dynamic exception) {
  if (exception is SpaceShareException) {
    return exception.message;
  } else if (exception is Exception) {
    return exception.toString();
  } else {
    return 'An unexpected error occurred';
  }
}
