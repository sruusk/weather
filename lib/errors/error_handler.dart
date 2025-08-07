import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:weather/errors/app_exception.dart';
import 'package:weather/l10n/app_localizations.g.dart';
import 'package:weather/utils/logger.dart';

/// A utility class for handling errors consistently across the application
class ErrorHandler {
  /// Singleton instance
  static final ErrorHandler _instance = ErrorHandler._internal();

  /// Factory constructor to return the singleton instance
  factory ErrorHandler() => _instance;

  /// Private constructor
  ErrorHandler._internal();

  /// Global navigator key for accessing the navigator from anywhere
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Handles an exception and shows appropriate UI feedback
  ///
  /// This method logs the error, converts it to a user-friendly message,
  /// and shows a snackbar or dialog based on the error type and severity.
  void handleException(
    dynamic exception, {
    StackTrace? stackTrace,
    BuildContext? context,
    bool showDialog = false,
    VoidCallback? onRetry,
  }) {
    // Log the error
    _logError(exception, stackTrace);

    // Convert to AppException if it's not already
    final appException = _convertToAppException(exception, stackTrace);

    // Get the current context
    final currentContext = context ?? navigatorKey.currentContext;
    if (currentContext == null) {
      Logger.error('No context available for error handling');
      return;
    }

    // Get localized error message
    final errorMessage =
        _getLocalizedErrorMessage(appException, currentContext);

    // Show UI feedback
    if (showDialog) {
      _showErrorDialog(currentContext, errorMessage, appException, onRetry);
    } else {
      _showErrorSnackBar(currentContext, errorMessage, onRetry);
    }

    // TODO: Report to analytics service if needed
  }

  /// Wraps a future with error handling
  ///
  /// This method executes the given future and handles any exceptions that occur.
  Future<T?> handleFuture<T>(
    Future<T> future, {
    BuildContext? context,
    bool showDialog = false,
    VoidCallback? onRetry,
  }) async {
    try {
      return await future;
    } catch (e, stackTrace) {
      handleException(
        e,
        stackTrace: stackTrace,
        context: context,
        showDialog: showDialog,
        onRetry: onRetry,
      );
      return null;
    }
  }

  /// Logs an error to the console and any configured logging services
  void _logError(dynamic exception, StackTrace? stackTrace) {
    Logger.error('Error occurred', exception);
    if (stackTrace != null) {
      Logger.debug('Stack trace: $stackTrace');
    }
  }

  /// Converts any exception to an AppException
  AppException _convertToAppException(
      dynamic exception, StackTrace? stackTrace) {
    if (exception is AppException) {
      return exception;
    }

    // Handle network-related exceptions with more specific error codes and messages
    if (exception is SocketException) {
      // Socket exceptions are typically connectivity issues
      return NetworkException(
        message: 'Unable to connect to the server',
        code: 'network_connectivity_error',
        originalException: exception,
        stackTrace: stackTrace,
      );
    } else if (exception is TimeoutException) {
      // Timeout exceptions indicate the server is taking too long to respond
      return NetworkException(
        message: 'Request timed out',
        code: 'network_timeout_error',
        originalException: exception,
        stackTrace: stackTrace,
      );
    } else if (exception is HttpException) {
      // HTTP exceptions are general HTTP protocol errors
      return NetworkException(
        message: 'HTTP error occurred',
        code: 'http_error',
        originalException: exception,
        stackTrace: stackTrace,
      );
    } else if (exception is FormatException) {
      // Format exceptions typically occur when parsing data
      return DataException(
        message: 'Error processing data from server',
        code: 'data_format_error',
        originalException: exception,
        stackTrace: stackTrace,
      );
    } else if (exception.toString().contains('Failed host lookup')) {
      // This is a specific error that occurs when there's no internet connection
      return NetworkException(
        message: 'No internet connection',
        code: 'no_internet_connection',
        originalException: exception,
        stackTrace: stackTrace,
      );
    }

    // Default to generic AppException
    return AppException(
      message: exception?.toString() ?? 'An unknown error occurred',
      code: 'unknown_error',
      originalException: exception,
      stackTrace: stackTrace,
    );
  }

  /// Gets a localized error message for an AppException
  String _getLocalizedErrorMessage(
      AppException exception, BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // Return specific messages based on exception type and code
    if (exception is NetworkException) {
      if (exception.statusCode == 401 || exception.statusCode == 403) {
        return localizations.authorizationError;
      } else if (exception.statusCode == 404) {
        return localizations.resourceNotFoundError;
      } else if (exception.statusCode == 500) {
        return localizations.serverError;
      } else {
        return localizations.networkError;
      }
    } else if (exception is DataException) {
      return localizations.dataError;
    } else if (exception is AuthException) {
      return localizations.authError;
    } else if (exception is LocationException) {
      return localizations.locationError;
    } else if (exception is CacheException) {
      return localizations.cacheError;
    } else if (exception is PermissionException) {
      return localizations.permissionError;
    }

    // Default message
    return exception.message;
  }

  /// Shows an error snackbar
  void _showErrorSnackBar(
    BuildContext context,
    String message,
    VoidCallback? onRetry,
  ) {
    final localizations = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 5),
        action: onRetry != null
            ? SnackBarAction(
                label: localizations.retry,
                textColor: Theme.of(context).colorScheme.onError,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Shows an error dialog
  void _showErrorDialog(
    BuildContext context,
    String message,
    AppException exception,
    VoidCallback? onRetry,
  ) {
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.error(exception.code)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message),
                if (exception.code != 'unknown_error') ...[
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.errorCode}: ${exception.code}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations.close),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
                child: Text(localizations.retry),
              ),
          ],
        );
      },
    );
  }
}
