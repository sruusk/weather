import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:open_meteo/open_meteo.dart';
import 'package:weather/appwrite_client.dart';
import 'package:weather/data/forecast_point.dart';
import 'package:weather/data/models/harmonie_response.dart';
import 'package:weather/data/models/open_meteo_response.dart';

import 'forecast.dart';
import 'location.dart';

/// Enum to distinguish between different weather data sources
enum WeatherDataSource {
  /// OpenMeteo weather data source using WMO codes
  openMeteo,

  /// Harmonie weather data source using WeatherSymbol3 codes
  harmonie
}

/// A singleton class for handling weather data
class WeatherData {
  // Private constructor
  WeatherData._();

  static final WeatherData _instance = WeatherData._();

  factory WeatherData() => _instance;

  // Cache for open_meteo forecasts
  final Map<String, Forecast> _openMeteoCache = {};

  // Cache for harmonie forecasts
  final Map<String, Forecast> _harmonieCache = {};

  /// Clears all cached data
  void clearCache() {
    if (kDebugMode) print('Clearing all cached forecast data');
    _openMeteoCache.clear();
    _harmonieCache.clear();
  }

  /// Clears cached data for a specific location
  void clearCacheForLocation(Location location) {
    final cacheKey = '${location.lat},${location.lon}';
    if (kDebugMode) {
      print('Clearing cached forecast data for location $cacheKey');
    }
    _openMeteoCache.remove(cacheKey);
    _harmonieCache.remove(cacheKey);
  }

  final WeatherApi _weatherApi = WeatherApi(
      temperatureUnit: TemperatureUnit.celsius,
      windspeedUnit: WindspeedUnit.ms);

  /// Gets the current weather conditions for a given [location]
  Future<ForecastPoint> getCurrentWeather(Location location) async {
    if (kDebugMode) {
      print('Getting current weather...');
    }

    try {
      final forecast = await getForecast(location);

      // Return the first point in the forecast (current conditions)
      if (forecast.forecast.isNotEmpty) {
        return forecast.forecast.first;
      } else {
        throw Exception('No forecast data available');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current weather: $e');
      }
      rethrow;
    }
  }

  /// Gets the weather forecast for [location] for the next hours/days
  Future<Forecast> getForecast(Location location) async {
    if (kDebugMode) {
      print('Getting forecast...');
    }

    try {
      // Check if the location is in one of the countries that support Harmonie forecast
      final bool useHarmonie = _isHarmonieSupportedCountry(location);

      // Get the open_meteo forecast
      final openMeteoForecast = await _getOpenMeteoForecast(location);

      // Create a map of precipitation probability data for easy lookup
      final precipProbMap = <DateTime, double>{};
      for (final point in openMeteoForecast.forecast) {
        precipProbMap[point.time] = point.probabilityOfPrecipitation;
      }

      // If the location is in a supported country, get the Harmonie forecast and merge it
      if (useHarmonie) {
        try {
          final harmonieForecast = await _getHarmonieForecast(location);

          // Get the last time point in the Harmonie forecast
          final lastHarmonieTime = harmonieForecast.forecast.isNotEmpty
              ? harmonieForecast.forecast.last.time
              : DateTime.now().toUtc();

          // Create the merged forecast points
          final mergedPoints = <ForecastPoint>[];

          // First, add all Harmonie forecast points with precipitation probability from open_meteo
          for (final point in harmonieForecast.forecast) {
            // Find the precipitation probability for this time
            final precipProb = precipProbMap[point.time.toLocal()];

            // Create a new forecast point with the precipitation probability
            mergedPoints.add(ForecastPoint(
              time: point.time.toLocal(),
              temperature: point.temperature,
              humidity: point.humidity,
              windDirection: point.windDirection,
              windSpeed: point.windSpeed,
              windGust: point.windGust,
              precipitation: point.precipitation,
              weatherSymbol: point.weatherSymbol,
              weatherSymbolCode: point.weatherSymbolCode,
              feelsLike: point.feelsLike,
              probabilityOfPrecipitation: precipProb!,
            ));
          }

          // Then, add all open_meteo forecast points that come after the Harmonie forecast
          for (final point in openMeteoForecast.forecast) {
            if (point.time.isAfter(lastHarmonieTime.toLocal())) {
              mergedPoints.add(point);
            }
          }

          // Sort the merged points by time
          mergedPoints.sort((a, b) => a.time.compareTo(b.time));

          return Forecast(
            location: location,
            forecast: mergedPoints,
          );
        } catch (e) {
          if (kDebugMode) {
            print(
                'Error getting Harmonie forecast, falling back to open_meteo: $e');
          }
          // If there's an error with the Harmonie forecast, fall back to open_meteo
        }
      }

      // If Harmonie is not supported or there's an error, return the open_meteo forecast
      return openMeteoForecast;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting forecast data: $e');
      }
      rethrow;
    }
  }

  /// Checks if the location is in a country that supports Harmonie forecast
  bool _isHarmonieSupportedCountry(Location location) {
    final supportedCountries = [
      'NO', // Norway
      'SE', // Sweden
      'FI', // Finland
      'AX', // Åland
      'DK', // Denmark
      'EE', // Estonia
      'LV', // Latvia
      'LT', // Lithuania
    ];

    return supportedCountries.contains(location.countryCode.toUpperCase());
  }

  /// Maps weather codes to weather symbols based on the data source
  ///
  /// This unified method replaces the separate mapping methods for OpenMeteo and Harmonie
  /// weather codes, reducing code duplication while maintaining the distinct mappings.
  String _mapWeatherCodeToSymbol(int weatherCode, WeatherDataSource source) {
    switch (source) {
      case WeatherDataSource.openMeteo:
        return _openMeteoWeatherSymbols[weatherCode] ?? 'unknown';
      case WeatherDataSource.harmonie:
        return _harmonieWeatherSymbols[weatherCode] ?? 'unknown';
    }
  }

  /// Static map for OpenMeteo weather codes to weather symbols
  ///
  /// Based on WMO Weather interpretation codes
  /// https://open-meteo.com/en/docs/weather-api
  static final Map<int, String> _openMeteoWeatherSymbols = {
    0: 'clear-day',
    1: 'partly-cloudy-day',
    2: 'cloudy',
    3: 'overcast',
    45: 'fog',
    48: 'fog',
    51: 'drizzle',
    53: 'drizzle',
    55: 'drizzle',
    56: 'sleet', // freezing-drizzle doesn't exist in our weather symbols
    57: 'sleet', // freezing-drizzle doesn't exist in our weather symbols
    61: 'rain',
    63: 'overcast-rain',
    65: 'extreme-rain',
    66: 'sleet',
    67: 'extreme-sleet',
    71: 'snow',
    73: 'overcast-snow',
    75: 'extreme-snow',
    77: 'snow',
    80: 'partly-cloudy-day-rain',
    81: 'partly-cloudy-day-rain',
    82: 'partly-cloudy-day-rain',
    85: 'partly-cloudy-day-snow',
    86: 'partly-cloudy-day-snow',
    95: 'thunderstorms-extreme',
    96: 'thunderstorm-extreme-snow', // Should be thunderstorms-hail
    99: 'thunderstorm-extreme-snow', // Should be thunderstorms-hail
  };

  /// Static map for Harmonie WeatherSymbol3 codes to weather symbols
  ///
  /// WeatherSymbol3 descriptions:
  /// 1 selkeää (clear)
  /// 2 puolipilvistä (partly cloudy)
  /// 21 heikkoja sadekuuroja (light rain showers)
  /// 22 sadekuuroja (rain showers)
  /// 23 voimakkaita sadekuuroja (heavy rain showers)
  /// 3 pilvistä (cloudy)
  /// 31 heikkoa vesisadetta (light rain)
  /// 32 vesisadetta (rain)
  /// 33 voimakasta vesisadetta (heavy rain)
  /// 41 heikkoja lumikuuroja (light snow showers)
  /// 42 lumikuuroja (snow showers)
  /// 43 voimakkaita lumikuuroja (heavy snow showers)
  /// 51 heikkoa lumisadetta (light snow)
  /// 52 lumisadetta (snow)
  /// 53 voimakasta lumisadetta (heavy snow)
  /// 61 ukkoskuuroja (thunderstorms)
  /// 62 voimakkaita ukkoskuuroja (heavy thunderstorms)
  /// 63 ukkosta (thunder)
  /// 64 voimakasta ukkosta (heavy thunder)
  /// 71 heikkoja räntäkuuroja (light sleet showers)
  /// 72 räntäkuuroja (sleet showers)
  /// 73 voimakkaita räntäkuuroja (heavy sleet showers)
  /// 81 heikkoa räntäsadetta (light sleet)
  /// 82 räntäsadetta (sleet)
  /// 83 voimakasta räntäsadetta (heavy sleet)
  /// 91 utua (mist)
  /// 92 sumua (fog)
  static final Map<int, String> _harmonieWeatherSymbols = {
    1: 'clear-day',
    2: 'partly-cloudy-day',
    21: 'partly-cloudy-day-rain',
    22: 'partly-cloudy-day-rain',
    23: 'extreme-rain',
    3: 'cloudy',
    31: 'rain',
    32: 'overcast-rain',
    33: 'extreme-rain',
    41: 'partly-cloudy-day-snow',
    42: 'partly-cloudy-day-snow',
    43: 'extreme-snow',
    51: 'snow',
    52: 'overcast-snow',
    53: 'extreme-snow',
    61: 'thunderstorms',
    62: 'thunderstorms-extreme',
    63: 'thunderstorms',
    64: 'thunderstorms-extreme',
    71: 'sleet',
    72: 'sleet',
    73: 'extreme-sleet',
    81: 'sleet',
    82: 'sleet',
    83: 'extreme-sleet',
    91: 'fog',
    92: 'fog',
  };

  /// Gets the Harmonie forecast from FMI for a given [location]
  ///
  /// The Harmonie is a 66 hour forecast model, updated 4 times per day.
  /// This method fetches the forecast from the current time forward to the maximum available.
  Future<Forecast> _getHarmonieForecast(Location location) async {
    // Create a cache key based on the location coordinates
    final cacheKey = '${location.lat},${location.lon}';

    // Check if we have cached data for this location
    if (_harmonieCache.containsKey(cacheKey)) {
      if (kDebugMode) {
        print('Using cached Harmonie forecast data for location $cacheKey');
      }
      return _harmonieCache[cacheKey]!;
    }

    if (kDebugMode) {
      print('Fetching new Harmonie forecast for location $cacheKey...');
    }

    try {
      // Calculate start and end times for the forecast
      // Start from now and go 66 hours ahead (maximum for Harmonie model)
      final now = DateTime.now().toUtc();
      final endTime = now.add(const Duration(hours: 66));

      // Format dates for the URL
      final dateFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
      final startTimeStr = dateFormat.format(now);
      final endTimeStr = dateFormat.format(endTime);

      // Construct the URL with the required parameters
      final url = Uri.parse('https://opendata.fmi.fi/wfs'
          '?request=getFeature'
          '&starttime=$startTimeStr'
          '&endtime=$endTimeStr'
          '&latlon=${location.lat},${location.lon}'
          '&storedquery_id=fmi::forecast::harmonie::surface::point::timevaluepair'
          '&parameters=Humidity,Temperature,WindDirection,WindSpeedMS,WindGust,Precipitation1h,WeatherSymbol3,feelslike');

      // Fetch the data directly without retries
      final response = await get(url);

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to fetch Harmonie forecast: ${response.statusCode}');
      }

      // Parse the XML response using our model
      final harmonieResponse = HarmonieResponse.fromXml(response.body);

      // Get all time points
      final sortedTimePoints = harmonieResponse.getAllTimePoints();

      // Create forecast points for each time point
      final forecastPoints = <ForecastPoint>[];

      for (final time in sortedTimePoints) {
        // Find data for this time point for each parameter
        final humidity =
            harmonieResponse.findValueForTime('Humidity', time) ?? 0.0;
        final temperature =
            harmonieResponse.findValueForTime('Temperature', time) ?? 0.0;
        final windDirection =
            harmonieResponse.findValueForTime('WindDirection', time) ?? 0.0;
        final windSpeed =
            harmonieResponse.findValueForTime('WindSpeedMS', time) ?? 0.0;
        final windGust =
            harmonieResponse.findValueForTime('WindGust', time) ?? 0.0;
        final precipitation =
            harmonieResponse.findValueForTime('Precipitation1h', time) ?? 0.0;
        final weatherSymbolCode = harmonieResponse
                .findValueForTime('WeatherSymbol3', time)
                ?.toInt() ??
            0;
        final feelsLike = harmonieResponse.findValueForTime('feelslike', time);

        // Convert weather symbol code to symbol name
        final weatherSymbol = _mapWeatherCodeToSymbol(
            weatherSymbolCode, WeatherDataSource.harmonie);

        // Create a forecast point
        forecastPoints.add(ForecastPoint(
          time: time,
          temperature: temperature,
          humidity: humidity,
          windDirection: windDirection,
          windSpeed: windSpeed,
          windGust: windGust,
          precipitation: precipitation,
          weatherSymbol: weatherSymbol,
          weatherSymbolCode: weatherSymbolCode,
          feelsLike: feelsLike,
          // probabilityOfPrecipitation is not available in Harmonie model
          probabilityOfPrecipitation: 0,
        ));
      }

      // Sort forecast points by time
      forecastPoints.sort((a, b) => a.time.compareTo(b.time));

      final forecast = Forecast(
        location: location,
        forecast: forecastPoints,
      );

      // Cache the result
      _harmonieCache[cacheKey] = forecast;

      return forecast;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting Harmonie forecast: $e');
      }
      rethrow;
    }
  }

  Future<Forecast> _getOpenMeteoForecast(Location location) async {
    // Create a cache key based on the location coordinates
    final cacheKey = '${location.lat},${location.lon}';

    // Check if we have cached data for this location
    if (_openMeteoCache.containsKey(cacheKey)) {
      if (kDebugMode) {
        print('Using cached open_meteo forecast data for location $cacheKey');
      }
      return _openMeteoCache[cacheKey]!;
    }

    if (kDebugMode) {
      print('Fetching new open_meteo forecast data for location $cacheKey');
    }

    // Use the open_meteo package to make the request
    final apiResponse = await _weatherApi.request(
        latitude: location.lat,
        longitude: location.lon,
        hourly: {
          WeatherHourly.temperature_2m,
          WeatherHourly.relative_humidity_2m,
          WeatherHourly.precipitation_probability,
          WeatherHourly.precipitation,
          WeatherHourly.weather_code,
          WeatherHourly.wind_direction_10m,
          WeatherHourly.wind_speed_10m,
          WeatherHourly.wind_gusts_10m,
          WeatherHourly.apparent_temperature,
        },
        pastDays: 1,
        forecastDays: 7);

    // Convert the API response to our model
    final response = OpenMeteoResponse.fromApiResponse(apiResponse);

    // Convert the response to our Forecast model
    final forecastPoints = <ForecastPoint>[];

    // Get the hourly data for temperature to determine the time points
    final temperatureData = response.hourlyData[WeatherHourly.temperature_2m];
    if (temperatureData == null || temperatureData.values.isEmpty) {
      throw Exception('No temperature data available');
    }

    // Process each hourly data point
    for (var currentTime in temperatureData.values.keys) {
      // Get the weather data for this time point
      final temperature = temperatureData.values[currentTime]!.toDouble();
      final humidity = response.hourlyData[WeatherHourly.relative_humidity_2m]
              ?.values[currentTime]
              ?.toDouble() ??
          0.0;
      final precipitationProb = response
              .hourlyData[WeatherHourly.precipitation_probability]
              ?.values[currentTime]
              ?.toDouble() ??
          0.0;
      final precipitation = response
              .hourlyData[WeatherHourly.precipitation]?.values[currentTime]
              ?.toDouble() ??
          0.0;
      final weatherCode = response
              .hourlyData[WeatherHourly.weather_code]?.values[currentTime]
              ?.toInt() ??
          0;
      final windDirection = response
              .hourlyData[WeatherHourly.wind_direction_10m]?.values[currentTime]
              ?.toDouble() ??
          0.0;
      final windSpeed = response
              .hourlyData[WeatherHourly.wind_speed_10m]?.values[currentTime]
              ?.toDouble() ??
          0.0;
      final windGust = response
              .hourlyData[WeatherHourly.wind_gusts_10m]?.values[currentTime]
              ?.toDouble() ??
          0.0;
      final feelsLike = response.hourlyData[WeatherHourly.apparent_temperature]
              ?.values[currentTime]
              ?.toDouble() ??
          temperature;

      // Convert weather code to symbol name
      final weatherSymbol =
          _mapWeatherCodeToSymbol(weatherCode, WeatherDataSource.openMeteo);

      // Create a forecast point
      forecastPoints.add(ForecastPoint(
        time: currentTime,
        temperature: temperature,
        humidity: humidity,
        probabilityOfPrecipitation: precipitationProb,
        precipitation: precipitation,
        windDirection: windDirection,
        windSpeed: windSpeed,
        windGust: windGust,
        weatherSymbol: weatherSymbol,
        weatherSymbolCode: weatherCode,
        feelsLike: feelsLike,
      ));
    }

    final forecast = Forecast(
      location: location,
      forecast: forecastPoints,
    );

    // Cache the result
    _openMeteoCache[cacheKey] = forecast;

    return forecast;
  }

  // These methods have been replaced by the HarmonieResponse and OpenMeteoResponse models

  /// Performs reverse geocoding using an AppWrite function to get location information from coordinates
  Future<Location> reverseGeocoding(double lat, double lon,
      {String lang = 'fi'}) async {
    if (kDebugMode) {
      print('Performing reverse geocoding for lat: $lat, lon: $lon...');
    }

    final client = AppwriteClient();
    final result = await client.getReverseGeocoding(lat, lon, lang: lang);
    if (result.isEmpty) {
      throw Exception('No location found for the given coordinates');
    }

    return Location(
      lat: lat,
      lon: lon,
      name: result['name'] as String,
      countryCode: result['countryCode'] as String,
      country: result['country'] as String?,
      region: result['region'] as String?,
    );
  }

  Future<List<Location>> getAutoCompleteResults(String query,
      {lang = 'fi'}) async {
    if (kDebugMode) {
      print('Getting autocomplete results for $query...');
    }
    final url = Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search'
      '?name=$query&language=$lang&count=50&format=json',
    );
    final response = await get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch autocomplete results');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? [];

    // sort descending by population
    final sorted = results.cast<Map<String, dynamic>>()
      ..sort((a, b) => (b['population'] as num? ?? 0)
          .compareTo(a['population'] as num? ?? 0));

    // take top 5 and map to Location
    return sorted
        .take(5)
        .map((m) => Location(
              lat: (m['latitude'] as num).toDouble(),
              lon: (m['longitude'] as num).toDouble(),
              name: m['name'] as String,
              countryCode: m['country_code'] as String,
              country: m['country'],
              region: m['admin3'] ?? m['admin2'] ?? m['admin1'],
            ))
        .toList();
  }
}
