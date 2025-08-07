import 'package:weather/data/forecast.dart';
import 'package:weather/utils/logger.dart';

/// A wrapper class for Forecast that adds caching metadata
class CachedForecast {
  /// The wrapped forecast
  final Forecast forecast;

  /// The time when the forecast was cached
  final DateTime timestamp;

  /// The expiration duration for this cache entry
  final Duration expirationDuration;

  /// Creates a new CachedForecast
  CachedForecast({
    required this.forecast,
    DateTime? timestamp,
    this.expirationDuration = const Duration(hours: 1),
  }) : timestamp = timestamp ?? DateTime.now();

  /// Checks if the cached forecast is still valid
  bool get isValid {
    final now = DateTime.now();
    final expirationTime = timestamp.add(expirationDuration);
    final isValid = now.isBefore(expirationTime);

    if (!isValid) {
      Logger.debug('Cache expired for ${forecast.location.name}');
    }

    return isValid;
  }

  /// Returns the time remaining until expiration
  Duration get timeRemaining {
    final now = DateTime.now();
    final expirationTime = timestamp.add(expirationDuration);

    if (now.isAfter(expirationTime)) {
      return Duration.zero;
    }

    return expirationTime.difference(now);
  }

  /// Returns the percentage of time remaining until expiration (0.0 to 1.0)
  double get freshnessPercentage {
    final totalDuration = expirationDuration.inMilliseconds;
    final remaining = timeRemaining.inMilliseconds;

    if (totalDuration == 0) return 0.0;

    return remaining / totalDuration;
  }

  @override
  String toString() {
    return 'CachedForecast(location: ${forecast.location.name}, '
        'timestamp: $timestamp, '
        'valid: $isValid, '
        'timeRemaining: ${timeRemaining.inMinutes}m)';
  }
}
