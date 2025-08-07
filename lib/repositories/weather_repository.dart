import 'package:weather/data/forecast.dart';
import 'package:weather/data/forecast_point.dart';
import 'package:weather/data/location.dart';

/// Interface for weather data repository
abstract class WeatherRepository {
  /// Gets the current weather conditions for a given [location]
  Future<ForecastPoint> getCurrentWeather(Location location);

  /// Gets the weather forecast for [location] for the next hours/days
  ///
  /// If [forceRefresh] is true, the cache will be ignored and new data will be fetched
  Future<Forecast> getForecast(Location location, {bool forceRefresh = false});

  /// Performs reverse geocoding to get location information from coordinates
  Future<Location> reverseGeocoding(double lat, double lon,
      {String lang = 'en'});

  /// Gets autocomplete results for a location search query
  Future<List<Location>> getAutoCompleteResults(String query,
      {String lang = 'en'});

  /// Clears all cached data
  void clearCache();

  /// Clears cached data for a specific location
  void clearCacheForLocation(Location location);

  /// Sets the cache expiration duration
  void setCacheExpirationDuration(Duration duration);
}
