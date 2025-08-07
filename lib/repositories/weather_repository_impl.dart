import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:weather/data/cached_forecast.dart';
import 'package:weather/data/forecast.dart';
import 'package:weather/data/forecast_point.dart';
import 'package:weather/data/location.dart';
import 'package:weather/data/weather_data.dart';
import 'package:weather/errors/app_exception.dart';
// Import the global ErrorHandler instance from main.dart
import 'package:weather/main.dart' show errorHandler;
import 'package:weather/repositories/weather_repository.dart';
import 'package:weather/services/connectivity_service.dart';
import 'package:weather/services/service_locator.dart';
import 'package:weather/utils/logger.dart';

/// Implementation of the WeatherRepository interface using the WeatherData singleton
class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherData _weatherData;

  // Cache for forecasts with expiration
  final Map<String, CachedForecast> _forecastCache = {};

  // Default cache expiration duration
  Duration _cacheExpirationDuration = const Duration(hours: 1);

  // Connectivity service for checking network status
  final ConnectivityService _connectivityService;

  // Maximum number of retry attempts for network requests
  static const int _maxRetryAttempts = 3;

  // Delay between retry attempts (increases exponentially)
  static const Duration _initialRetryDelay = Duration(seconds: 1);

  /// Creates a new WeatherRepositoryImpl with the given WeatherData instance
  /// If no instance is provided, the singleton instance is used
  WeatherRepositoryImpl({
    WeatherData? weatherData,
    ConnectivityService? connectivityService,
  })  : _weatherData = weatherData ?? WeatherData(),
        _connectivityService =
            connectivityService ?? serviceLocator.get<ConnectivityService>();

  /// Checks if the device is connected to the internet
  ///
  /// Throws a NetworkException if the device is offline
  Future<void> _checkConnectivity() async {
    final isConnected = _connectivityService.isConnected;

    if (!isConnected) {
      // Check connectivity again to be sure
      final result = await _connectivityService.checkConnectivity();

      if (result == ConnectivityResult.none) {
        Logger.warning('Device is offline, cannot make network request');
        throw NetworkException(
          message: 'No internet connection',
          code: 'no_internet_connection',
        );
      }
    }
  }

  /// Executes a network request with retry logic
  ///
  /// This method will retry the request up to [_maxRetryAttempts] times
  /// with exponential backoff if a network error occurs.
  Future<T> _executeWithRetry<T>(Future<T> Function() request) async {
    int attempts = 0;
    Duration delay = _initialRetryDelay;

    while (true) {
      try {
        // Check connectivity before making the request
        await _checkConnectivity();

        // Execute the request
        return await request();
      } catch (e) {
        attempts++;

        // Only retry on network errors and if we haven't exceeded max attempts
        if (e is NetworkException && attempts < _maxRetryAttempts) {
          Logger.warning(
              'Network error, retrying (attempt $attempts of $_maxRetryAttempts): ${e.message}');

          // Wait before retrying with exponential backoff
          await Future.delayed(delay);

          // Increase delay for next attempt (exponential backoff)
          delay *= 2;
        } else {
          // For other errors or if we've exceeded max attempts, rethrow
          rethrow;
        }
      }
    }
  }

  @override
  Future<ForecastPoint> getCurrentWeather(Location location) async {
    try {
      // Try to get the forecast from cache first
      final forecast = await getForecast(location);

      // Return the first point in the forecast (current conditions)
      if (forecast.forecast.isNotEmpty) {
        return forecast.forecast.first;
      } else {
        throw DataException(
          message: 'No forecast data available',
          code: 'no_forecast_data',
        );
      }
    } catch (e, stackTrace) {
      // Convert to AppException if it's not already
      final exception = e is AppException
          ? e
          : DataException(
              message: 'Error getting current weather',
              code: 'current_weather_error',
              originalException: e,
              stackTrace: stackTrace,
            );

      // Log the error
      Logger.error('Error getting current weather', exception);

      // Rethrow as AppException
      throw exception;
    }
  }

  @override
  Future<Forecast> getForecast(Location location,
      {bool forceRefresh = false}) async {
    try {
      // Create a cache key based on the location coordinates
      final cacheKey = '${location.lat},${location.lon}';

      // Check if we have valid cached data for this location
      if (!forceRefresh && _forecastCache.containsKey(cacheKey)) {
        final cachedForecast = _forecastCache[cacheKey]!;

        // If the cache is still valid, return the cached forecast
        if (cachedForecast.isValid) {
          Logger.debug(
              'Using cached forecast for ${location.name}, expires in ${cachedForecast.timeRemaining.inMinutes}m');
          return cachedForecast.forecast;
        } else {
          Logger.debug('Cache expired for ${location.name}, fetching new data');
        }
      }

      // If we don't have valid cached data, fetch new data with retry logic
      final forecast = await _executeWithRetry(() async {
        return await _weatherData.getForecast(location);
      });

      // Cache the result with expiration
      _forecastCache[cacheKey] = CachedForecast(
        forecast: forecast,
        expirationDuration: _cacheExpirationDuration,
      );

      Logger.debug(
          'Cached new forecast for ${location.name}, expires in ${_cacheExpirationDuration.inMinutes}m');

      return forecast;
    } catch (e, stackTrace) {
      // Determine the type of exception
      final exception = _determineExceptionType(e, stackTrace,
          defaultMessage: 'Error getting forecast for ${location.name}',
          defaultCode: 'forecast_error');

      // Log the error
      Logger.error('Error getting forecast for ${location.name}', exception);

      // Rethrow as AppException
      throw exception;
    }
  }

  /// Helper method to determine the type of exception and convert it to an AppException
  AppException _determineExceptionType(
    dynamic e,
    StackTrace? stackTrace, {
    required String defaultMessage,
    required String defaultCode,
  }) {
    if (e is AppException) {
      return e;
    } else if (e is SocketException || e is TimeoutException) {
      return NetworkException(
        message: 'Network connection error',
        code: 'network_error',
        originalException: e,
        stackTrace: stackTrace,
      );
    } else if (e is FormatException) {
      return DataException(
        message: 'Error processing weather data',
        code: 'data_format_error',
        originalException: e,
        stackTrace: stackTrace,
      );
    } else {
      return DataException(
        message: defaultMessage,
        code: defaultCode,
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Location> reverseGeocoding(double lat, double lon,
      {String lang = 'en'}) async {
    try {
      // Use retry logic for network request
      return await _executeWithRetry(() async {
        return await _weatherData.reverseGeocoding(lat, lon, lang: lang);
      });
    } catch (e, stackTrace) {
      // Determine the type of exception
      final exception = _determineExceptionType(e, stackTrace,
          defaultMessage: 'Error finding location for coordinates',
          defaultCode: 'reverse_geocoding_error');

      // If it's not already a LocationException, convert it
      final locationException = exception is LocationException
          ? exception
          : LocationException(
              message: exception.message,
              code: exception.code,
              originalException: exception.originalException,
              stackTrace: exception.stackTrace,
            );

      // Log the error
      Logger.error('Error performing reverse geocoding', locationException);

      // Rethrow as LocationException
      throw locationException;
    }
  }

  @override
  Future<List<Location>> getAutoCompleteResults(String query,
      {String lang = 'en'}) async {
    try {
      // Use retry logic for network request
      return await _executeWithRetry(() async {
        return await _weatherData.getAutoCompleteResults(query, lang: lang);
      });
    } catch (e, stackTrace) {
      // Determine the type of exception
      final exception = _determineExceptionType(e, stackTrace,
          defaultMessage: 'Error searching for locations',
          defaultCode: 'location_search_error');

      // If it's not already a LocationException, convert it
      final locationException = exception is LocationException
          ? exception
          : LocationException(
              message: exception.message,
              code: exception.code,
              originalException: exception.originalException,
              stackTrace: exception.stackTrace,
            );

      // Log the error
      Logger.error('Error getting autocomplete results', locationException);

      // Rethrow as LocationException
      throw locationException;
    }
  }

  @override
  void clearCache() {
    try {
      _forecastCache.clear();
      _weatherData.clearCache();
      Logger.debug('Cleared all cached forecast data');
    } catch (e, stackTrace) {
      // Create a CacheException
      final exception = CacheException(
        message: 'Error clearing cache',
        code: 'cache_clear_error',
        originalException: e,
        stackTrace: stackTrace,
      );

      // Log the error
      Logger.error('Error clearing cache', exception);

      // Use ErrorHandler to display an error message to the user
      errorHandler.handleException(
        exception,
        showDialog: false,
      );
    }
  }

  @override
  void clearCacheForLocation(Location location) {
    try {
      final cacheKey = '${location.lat},${location.lon}';
      _forecastCache.remove(cacheKey);
      _weatherData.clearCacheForLocation(location);
      Logger.debug(
          'Cleared cached forecast data for location ${location.name}');
    } catch (e, stackTrace) {
      // Create a CacheException
      final exception = CacheException(
        message: 'Error clearing cache for location ${location.name}',
        code: 'cache_clear_location_error',
        originalException: e,
        stackTrace: stackTrace,
      );

      // Log the error
      Logger.error('Error clearing cache for location', exception);

      // Use ErrorHandler to display an error message to the user
      errorHandler.handleException(
        exception,
        showDialog: false,
      );
    }
  }

  @override
  void setCacheExpirationDuration(Duration duration) {
    try {
      _cacheExpirationDuration = duration;
      Logger.debug('Set cache expiration duration to ${duration.inMinutes}m');
    } catch (e, stackTrace) {
      // Create a CacheException
      final exception = CacheException(
        message: 'Error setting cache expiration duration',
        code: 'cache_expiration_error',
        originalException: e,
        stackTrace: stackTrace,
      );

      // Log the error
      Logger.error('Error setting cache expiration duration', exception);

      // Use ErrorHandler to display an error message to the user
      errorHandler.handleException(
        exception,
        showDialog: false,
      );
    }
  }
}
