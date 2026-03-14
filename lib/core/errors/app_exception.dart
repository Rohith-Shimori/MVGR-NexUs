/// Custom exception classes for MVGR NexUs
/// Provides structured error handling throughout the app
library;
/// Base exception class for all app exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// Network-related exceptions (API calls, connectivity)
class NetworkException extends AppException {
  final int? statusCode;

  const NetworkException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
    this.statusCode,
  });

  factory NetworkException.noConnection() => const NetworkException(
        message: 'No internet connection. Please check your network.',
        code: 'NO_CONNECTION',
      );

  factory NetworkException.timeout() => const NetworkException(
        message: 'Request timed out. Please try again.',
        code: 'TIMEOUT',
      );

  factory NetworkException.serverError([int? statusCode]) => NetworkException(
        message: 'Server error. Please try again later.',
        code: 'SERVER_ERROR',
        statusCode: statusCode,
      );

  factory NetworkException.fromStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return const NetworkException(
          message: 'Invalid request',
          code: 'BAD_REQUEST',
          statusCode: 400,
        );
      case 401:
        return const NetworkException(
          message: 'Unauthorized. Please login again.',
          code: 'UNAUTHORIZED',
          statusCode: 401,
        );
      case 403:
        return const NetworkException(
          message: 'Access denied',
          code: 'FORBIDDEN',
          statusCode: 403,
        );
      case 404:
        return const NetworkException(
          message: 'Resource not found',
          code: 'NOT_FOUND',
          statusCode: 404,
        );
      case 429:
        return const NetworkException(
          message: 'Too many requests. Please wait.',
          code: 'RATE_LIMITED',
          statusCode: 429,
        );
      default:
        return NetworkException.serverError(statusCode);
    }
  }
}

/// Authentication exceptions
class AppAuthException extends AppException {
  const AppAuthException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory AppAuthException.invalidCredentials() => const AppAuthException(
        message: 'Invalid email or password',
        code: 'INVALID_CREDENTIALS',
      );

  factory AppAuthException.emailNotVerified() => const AppAuthException(
        message: 'Please verify your email before logging in',
        code: 'EMAIL_NOT_VERIFIED',
      );

  factory AppAuthException.userNotFound() => const AppAuthException(
        message: 'No account found with this email',
        code: 'USER_NOT_FOUND',
      );

  factory AppAuthException.emailAlreadyInUse() => const AppAuthException(
        message: 'An account already exists with this email',
        code: 'EMAIL_IN_USE',
      );

  factory AppAuthException.weakPassword() => const AppAuthException(
        message: 'Password is too weak. Use at least 8 characters.',
        code: 'WEAK_PASSWORD',
      );

  factory AppAuthException.sessionExpired() => const AppAuthException(
        message: 'Session expired. Please login again.',
        code: 'SESSION_EXPIRED',
      );

  factory AppAuthException.notLoggedIn() => const AppAuthException(
        message: 'Please login to continue',
        code: 'NOT_LOGGED_IN',
      );
}

/// Validation exceptions for form inputs
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException({
    required super.message,
    super.code,
    this.fieldErrors,
  });

  factory ValidationException.requiredField(String fieldName) =>
      ValidationException(
        message: '$fieldName is required',
        code: 'REQUIRED_FIELD',
        fieldErrors: {fieldName: '$fieldName is required'},
      );

  factory ValidationException.invalidFormat(String fieldName, String expected) =>
      ValidationException(
        message: 'Invalid $fieldName format. Expected: $expected',
        code: 'INVALID_FORMAT',
        fieldErrors: {fieldName: 'Invalid format'},
      );

  factory ValidationException.multipleErrors(Map<String, String> errors) =>
      ValidationException(
        message: 'Please fix the following errors',
        code: 'MULTIPLE_ERRORS',
        fieldErrors: errors,
      );
}

/// Database/Storage operation exceptions
class DataException extends AppException {
  const DataException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory DataException.notFound(String resource) => DataException(
        message: '$resource not found',
        code: 'NOT_FOUND',
      );

  factory DataException.alreadyExists(String resource) => DataException(
        message: '$resource already exists',
        code: 'ALREADY_EXISTS',
      );

  factory DataException.operationFailed(String operation) => DataException(
        message: 'Failed to $operation. Please try again.',
        code: 'OPERATION_FAILED',
      );

  factory DataException.permissionDenied() => const DataException(
        message: 'You don\'t have permission to perform this action',
        code: 'PERMISSION_DENIED',
      );
}

/// Unexpected/Unknown exceptions
class UnknownException extends AppException {
  const UnknownException({
    super.message = 'An unexpected error occurred',
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory UnknownException.fromError(dynamic error, [StackTrace? stackTrace]) =>
      UnknownException(
        message: error.toString(),
        originalError: error,
        stackTrace: stackTrace,
      );
}
