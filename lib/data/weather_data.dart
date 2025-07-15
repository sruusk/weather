import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:open_meteo/open_meteo.dart';
import 'package:weather/data/forecast_point.dart';
import 'package:xml/xml.dart' as xml;

import 'credentials.dart';
import 'forecast.dart';
import 'location.dart';

/// A simple class to hold a time and a value
class _TimeValue {
  final DateTime time;
  final double value;

  _TimeValue({required this.time, required this.value});
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

  /// Maps Harmonie WeatherSymbol3 codes to weather symbols
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
  String _mapHarmonieWeatherCodeToSymbol(int weatherCode) {
    switch (weatherCode) {
      case 1:
        return 'clear-day';
      case 2:
        return 'partly-cloudy-day';
      case 21:
        return 'partly-cloudy-day-rain';
      case 22:
        return 'partly-cloudy-day-rain';
      case 23:
        return 'extreme-rain';
      case 3:
        return 'cloudy';
      case 31:
        return 'rain';
      case 32:
        return 'overcast-rain';
      case 33:
        return 'extreme-rain';
      case 41:
        return 'partly-cloudy-day-snow';
      case 42:
        return 'partly-cloudy-day-snow';
      case 43:
        return 'extreme-snow';
      case 51:
        return 'snow';
      case 52:
        return 'overcast-snow';
      case 53:
        return 'extreme-snow';
      case 61:
        return 'thunderstorms';
      case 62:
        return 'thunderstorms-extreme';
      case 63:
        return 'thunderstorms';
      case 64:
        return 'thunderstorms-extreme';
      case 71:
        return 'sleet';
      case 72:
        return 'sleet';
      case 73:
        return 'extreme-sleet';
      case 81:
        return 'sleet';
      case 82:
        return 'sleet';
      case 83:
        return 'extreme-sleet';
      case 91:
        return 'fog';
      case 92:
        return 'fog';
      default:
        return 'unknown';
    }
  }

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

      // Parse the XML response
      final document = xml.XmlDocument.parse(response.body);
      final members = document.findAllElements('wfs:member').toList();

      if (members.isEmpty) {
        throw Exception('No forecast data available from FMI Harmonie model');
      }

      // Parse the time series data for each parameter
      final humidityData = _parseHarmonieTimeSeries(members[0]);
      final temperatureData = _parseHarmonieTimeSeries(members[1]);
      final windDirectionData = _parseHarmonieTimeSeries(members[2]);
      final windSpeedData = _parseHarmonieTimeSeries(members[3]);
      final windGustData = _parseHarmonieTimeSeries(members[4]);
      final precipitationData = _parseHarmonieTimeSeries(members[5]);
      final weatherSymbolData = _parseHarmonieTimeSeries(members[6]);
      final feelsLikeData = _parseHarmonieTimeSeries(members[7]);

      // Create a set of all time points
      final allTimePoints = <DateTime>{};
      for (final series in [
        humidityData,
        temperatureData,
        windDirectionData,
        windSpeedData,
        windGustData,
        precipitationData,
        weatherSymbolData,
        feelsLikeData
      ]) {
        for (final point in series) {
          allTimePoints.add(point.time);
        }
      }

      // Sort time points chronologically
      final sortedTimePoints = allTimePoints.toList()..sort();

      // Create forecast points for each time point
      final forecastPoints = <ForecastPoint>[];

      for (final time in sortedTimePoints) {
        // Find data for this time point in each series
        final humidity = _findValueForTime(humidityData, time);
        final temperature = _findValueForTime(temperatureData, time);
        final windDirection = _findValueForTime(windDirectionData, time);
        final windSpeed = _findValueForTime(windSpeedData, time);
        final windGust = _findValueForTime(windGustData, time);
        final precipitation = _findValueForTime(precipitationData, time);
        final weatherSymbolCode =
            _findValueForTime(weatherSymbolData, time)?.toInt();
        final feelsLike = _findValueForTime(feelsLikeData, time);

        // Convert weather symbol code to symbol name
        final weatherSymbol = weatherSymbolCode != null
            ? _mapHarmonieWeatherCodeToSymbol(weatherSymbolCode)
            : null;

        // Create a forecast point
        forecastPoints.add(ForecastPoint(
          time: time,
          temperature: temperature!,
          humidity: humidity!,
          windDirection: windDirection!,
          windSpeed: windSpeed!,
          windGust: windGust!,
          precipitation: precipitation!,
          weatherSymbol: weatherSymbol!,
          weatherSymbolCode: weatherSymbolCode!,
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
        pastDays: 1,
        forecastDays: 7);

    // Convert the response to our Forecast model
    final forecastPoints = <ForecastPoint>[];

    // Get the hourly data
    final temperatureData = response.hourlyData[WeatherHourly.temperature_2m];
    final humidityData =
        response.hourlyData[WeatherHourly.relative_humidity_2m];
    final precipitationProbData =
        response.hourlyData[WeatherHourly.precipitation_probability];
    final precipitationData = response.hourlyData[WeatherHourly.precipitation];
    final weatherCodeData = response.hourlyData[WeatherHourly.weather_code];
    final windDirectionData =
        response.hourlyData[WeatherHourly.wind_direction_10m];
    final windSpeedData = response.hourlyData[WeatherHourly.wind_speed_10m];
    final windGustData = response.hourlyData[WeatherHourly.wind_gusts_10m];
    final apparentTempData =
        response.hourlyData[WeatherHourly.apparent_temperature];

    // Process each hourly data point
    for (var currentTime in temperatureData!.values.keys) {
      // Get the weather data for this time point
      final temperature = temperatureData.values[currentTime]!.toDouble();
      final humidity = humidityData!.values[currentTime]!.toDouble();
      final precipitationProb =
          precipitationProbData!.values[currentTime]!.toDouble();
      final precipitation = precipitationData!.values[currentTime]!.toDouble();
      final weatherCode = weatherCodeData!.values[currentTime]!.toInt();
      final windDirection = windDirectionData!.values[currentTime]!.toDouble();
      final windSpeed = windSpeedData!.values[currentTime]!.toDouble();
      final windGust = windGustData!.values[currentTime]!.toDouble();
      final feelsLike = apparentTempData!.values[currentTime]!.toDouble();

      // Convert weather code to symbol name
      final weatherSymbol = _mapWeatherCodeToSymbol(weatherCode);

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

  /// Parses time series data from a member element
  List<_TimeValue> _parseHarmonieTimeSeries(xml.XmlElement member) {
    final result = <_TimeValue>[];

    try {
      final points = member
          .findAllElements('omso:PointTimeSeriesObservation')
          .first
          .findAllElements('om:result')
          .first
          .findAllElements('wml2:MeasurementTimeseries')
          .first
          .findAllElements('wml2:point');

      for (final point in points) {
        try {
          final timeElement = point
              .findAllElements('wml2:MeasurementTVP')
              .first
              .findAllElements('wml2:time')
              .first;

          final valueElement = point
              .findAllElements('wml2:MeasurementTVP')
              .first
              .findAllElements('wml2:value')
              .first;

          final time = DateTime.parse(timeElement.innerText);
          final value = double.tryParse(valueElement.innerText);

          if (value != null && !value.isNaN) {
            result.add(_TimeValue(time: time, value: value));
          }
        } catch (e) {
          // Skip this point if there's an error
          if (kDebugMode) {
            print('Error parsing time series point: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing time series: $e');
      }
    }

    return result;
  }

  /// Finds a value for a specific time in a list of time-value pairs
  double? _findValueForTime(List<_TimeValue> data, DateTime time) {
    for (final point in data) {
      if (point.time.isAtSameMomentAs(time)) {
        return point.value;
      }
    }
    return null;
  }

  /// Returns top 5 locations matching [query], sorted by population.
  /// Performs reverse geocoding using OpenWeatherMap API to get location information from coordinates
  Future<Location> reverseGeocoding(double lat, double lon) async {
    if (kDebugMode) {
      print('Performing reverse geocoding for lat: $lat, lon: $lon...');
    }

    final url = Uri.parse(
        'https://api.openweathermap.org/geo/1.0/reverse?lat=$lat&lon=$lon&limit=1&appid=$openWeatherMapApiKey');

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
