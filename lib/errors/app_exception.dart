import 'package:flutter/foundation.dart';

/// Base class for all application exceptions
///
/// This class serves as the foundation for all custom exceptions in the app,
/// providing a consistent interface for error handling.
class AppException implements Exception {
  /// A user-friendly message describing the error
  final String message;

  /// A technical error code for identifying the error type
  final String code;

  /// The original exception that caused this error, if any
  final dynamic originalException;

  /// Stack trace for the exception, if available
  final StackTrace? stackTrace;

  /// Creates a new AppException
  const AppException({
    required this.message,
    this.code = 'unknown_error',
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() {
    String result = 'AppException: $code - $message';
    if (originalException != null) {
      result += '\nCaused by: $originalException';
    }
    if (kDebugMode && stackTrace != null) {
      result += '\n$stackTrace';
    }
    return result;
  }
}

/// Exception thrown when a network request fails
class NetworkException extends AppException {
  /// HTTP status code, if applicable
  final int? statusCode;

  /// Creates a new NetworkException
  const NetworkException({
    required String message,
    String code = 'network_error',
    this.statusCode,
    dynamic originalException,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          originalException: originalException,
          stackTrace: stackTrace,
        );
}

/// Exception thrown when data parsing or processing fails
class DataException extends AppException {
  /// Creates a new DataException
  const DataException({
    required String message,
    String code = 'data_error',
    dynamic originalException,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          originalException: originalException,
          stackTrace: stackTrace,
        );
}

/// Exception thrown when authentication fails
class AuthException extends AppException {
  /// Creates a new AuthException
  const AuthException({
    required String message,
    String code = 'auth_error',
    dynamic originalException,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          originalException: originalException,
          stackTrace: stackTrace,
        );
}

/// Exception thrown when a location-related operation fails
class LocationException extends AppException {
  /// Creates a new LocationException
  const LocationException({
    required String message,
    String code = 'location_error',
    dynamic originalException,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          originalException: originalException,
          stackTrace: stackTrace,
        );
}

/// Exception thrown when a cache-related operation fails
class CacheException extends AppException {
  /// Creates a new CacheException
  const CacheException({
    required String message,
    String code = 'cache_error',
    dynamic originalException,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          originalException: originalException,
          stackTrace: stackTrace,
        );
}

/// Exception thrown when a permission-related operation fails
class PermissionException extends AppException {
  /// Creates a new PermissionException
  const PermissionException({
    required String message,
    String code = 'permission_error',
    dynamic originalException,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          originalException: originalException,
          stackTrace: stackTrace,
        );
}
