import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:open_meteo/open_meteo.dart';
import 'package:weather/data/forecast_point.dart';

import 'credentials.dart';
import 'forecast.dart';
import 'location.dart';

/// A singleton class for handling weather data
class WeatherData {
  // Private constructor
  WeatherData._();

  static final WeatherData _instance = WeatherData._();

  factory WeatherData() => _instance;

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
      // Calculate start and end dates (today and 7 days from now)
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day - 1);
      final endDate = startDate.add(const Duration(days: 7));

      // Use the open_meteo package to make the request
      final response = await _weatherApi.request(
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
        startDate: startDate,
        endDate: endDate,
      );

      // Convert the response to our Forecast model
      final forecastPoints = <ForecastPoint>[];

      // Create a list of DateTime objects for the forecast period
      // Since we're requesting hourly data, we'll create a DateTime for each hour
      final times = <DateTime>[];
      for (int i = 0; i < 24 * 7; i++) {
        // 7 days of hourly data
        times.add(startDate.add(Duration(hours: i)));
      }

      // Get the hourly data
      final temperatureData = response.hourlyData[WeatherHourly.temperature_2m];
      final humidityData =
          response.hourlyData[WeatherHourly.relative_humidity_2m];
      final precipitationProbData =
          response.hourlyData[WeatherHourly.precipitation_probability];
      final precipitationData =
          response.hourlyData[WeatherHourly.precipitation];
      final weatherCodeData = response.hourlyData[WeatherHourly.weather_code];
      final windDirectionData =
          response.hourlyData[WeatherHourly.wind_direction_10m];
      final windSpeedData = response.hourlyData[WeatherHourly.wind_speed_10m];
      final windGustData = response.hourlyData[WeatherHourly.wind_gusts_10m];
      final apparentTempData =
          response.hourlyData[WeatherHourly.apparent_temperature];

      // Process each hourly data point
      for (var i = 0; i < times.length; i++) {
        // Skip if we don't have temperature data for this time point
        final currentTime = times[i];
        if (temperatureData == null ||
            !temperatureData.values.containsKey(currentTime)) {
          continue;
        }

        // Get the weather data for this time point
        final temperature = temperatureData.values[currentTime]?.toDouble();
        final humidity = humidityData?.values[currentTime]?.toDouble();
        final precipitationProb =
            precipitationProbData?.values[currentTime]?.toDouble();
        final precipitation =
            precipitationData?.values[currentTime]?.toDouble();
        final weatherCode = weatherCodeData?.values[currentTime]?.toInt() ?? 0;
        final windDirection =
            windDirectionData?.values[currentTime]?.toDouble();
        final windSpeed = windSpeedData?.values[currentTime]?.toDouble();
        final windGust = windGustData?.values[currentTime]?.toDouble();
        final feelsLike = apparentTempData?.values[currentTime]?.toDouble();

        // Convert weather code to symbol name
        final weatherSymbol = _mapWeatherCodeToSymbol(weatherCode);

        // Create a forecast point
        forecastPoints.add(ForecastPoint(
          time: times[i],
          temperature: temperature,
          humidity: humidity,
          probabilityOfPrecipitation: precipitationProb,
          precipitation: precipitation,
          windDirection: windDirection,
          windSpeed: windSpeed,
          windGust: windGust,
          weatherSymbol: weatherSymbol,
          feelsLike: feelsLike,
        ));
      }

      return Forecast(
        location: location,
        forecast: forecastPoints,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting forecast: $e');
      }
      rethrow;
    }
  }

  /// Maps OpenMeteo weather codes to weather symbols
  String _mapWeatherCodeToSymbol(int weatherCode) {
    // Simplified mapping based on WMO Weather interpretation codes
    // https://open-meteo.com/en/docs/weather-api
    switch (weatherCode) {
      case 0:
        return 'clear-day';
      case 1:
        return 'partly-cloudy-day';
      case 2:
        return 'cloudy';
      case 3:
        return 'overcast';
      case 45:
      case 48:
        return 'fog';
      case 51:
      case 53:
      case 55:
        return 'drizzle';
      case 56:
      case 57:
        // return 'freezing-drizzle'; // Doesn't exist in our weather symbols
        return 'sleet';
      case 61:
        return 'rain';
      case 63:
        return 'overcast-rain';
      case 65:
        return 'extreme-rain';
      case 66:
        return 'sleet';
      case 67:
        return 'extreme-sleet';
      case 71:
        return 'snow';
      case 73:
        return 'overcast-snow';
      case 75:
        return 'extreme-snow';
      case 77:
        return 'snow';
      case 80:
      case 81:
      case 82:
        return 'partly-cloudy-day-rain';
      case 85:
      case 86:
        return 'partly-cloudy-day-snow';
      case 95:
        return 'thunderstorms-extreme';
      case 96:
      case 99:
        return 'thunderstorm-extreme-snow'; // Should be thunderstorms-hail
      default:
        return 'unknown';
    }
  }

  Future<void> getWarnings() async {
    // Implementation will be added later
    if (kDebugMode) {
      print('Getting weather warnings...');
    }
  }

  /// Returns top 5 locations matching [query], sorted by population.
  /// Performs reverse geocoding using OpenWeatherMap API to get location information from coordinates
  Future<Location> reverseGeocoding(double lat, double lon) async {
    if (kDebugMode) {
      print('Performing reverse geocoding for lat: $lat, lon: $lon...');
    }

    final url = Uri.parse(
      'https://api.openweathermap.org/geo/1.0/reverse?lat=$lat&lon=$lon&limit=1&appid=$openWeatherMapApiKey'
    );

    final response = await get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch reverse geocoding results');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    if (data.isEmpty) {
      throw Exception('No location found for the given coordinates');
    }

    final locationData = data[0] as Map<String, dynamic>;

    return Location(
      lat: lat,
      lon: lon,
      name: locationData['name'] as String,
      countryCode: locationData['country'] as String,
      country: locationData['country'] as String,
      region: locationData['state'],
    );
  }

  Future<List<Location>> getAutoCompleteResults(String query) async {
    if (kDebugMode) {
      print('Getting autocomplete results for $query...');
    }
    final url = Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search'
      '?name=$query&language=fi&count=50&format=json', // TODO: add language dynamically
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
