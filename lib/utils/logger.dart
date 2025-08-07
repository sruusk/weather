import 'package:flutter/foundation.dart';

/// A utility class for logging messages across the application
///
/// This class provides a centralized way to log messages with different
/// severity levels. It can be configured to log to different outputs
/// based on the build configuration.
class Logger {
  /// Whether to show debug logs
  static bool _showDebugLogs = kDebugMode;

  /// Sets whether to show debug logs
  static void setShowDebugLogs(bool show) {
    _showDebugLogs = show;
  }

  /// Logs a debug message
  ///
  /// Debug messages are only shown in debug mode or if explicitly enabled
  static void debug(String message, [dynamic details]) {
    if (_showDebugLogs) {
      _log(Level.debug, message, details);
    }
  }

  /// Logs an info message
  static void info(String message, [dynamic details]) {
    _log(Level.info, message, details);
  }

  /// Logs a warning message
  static void warning(String message, [dynamic details]) {
    _log(Level.warning, message, details);
  }

  /// Logs an error message
  static void error(String message, [dynamic details]) {
    _log(Level.error, message, details);
  }

  /// Internal method to log a message with the given level
  static void _log(Level level, String message, [dynamic details]) {
    final prefix = _getLevelPrefix(level);
    final formattedMessage = '$prefix $message';

    if (details != null) {
      if (kDebugMode) {
        print('$formattedMessage: $details');

        // If details is an exception with a stack trace, print the stack trace
        if (details is Error) {
          print(details.stackTrace);
        }
      }
    } else {
      if (kDebugMode) {
        print(formattedMessage);
      }
    }

    // In a production app, you might want to send logs to a remote service
    // or store them locally for later analysis
  }

  /// Gets a prefix string for the given log level
  static String _getLevelPrefix(Level level) {
    switch (level) {
      case Level.debug:
        return '[DEBUG]';
      case Level.info:
        return '[INFO]';
      case Level.warning:
        return '[WARNING]';
      case Level.error:
        return '[ERROR]';
    }
  }
}

/// Log levels for different types of messages
enum Level {
  debug,
  info,
  warning,
  error,
}
