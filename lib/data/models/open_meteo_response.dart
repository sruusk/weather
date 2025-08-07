import 'package:open_meteo/open_meteo.dart';

/// Model class for OpenMeteo API response
///
/// This class represents the response from the OpenMeteo API, with a focus on
/// the hourly weather data that is used in the application.
class OpenMeteoResponse {
  /// Map of hourly weather data, keyed by weather parameter
  ///
  /// The keys are [WeatherHourly] enum values, and the values are [OpenMeteoHourlyData]
  /// objects containing the time series data for that parameter.
  final Map<WeatherHourly, OpenMeteoHourlyData> hourlyData;

  /// Creates a new OpenMeteoResponse instance
  const OpenMeteoResponse({
    required this.hourlyData,
  });

  /// Creates an OpenMeteoResponse from the raw response of the open_meteo package
  ///
  /// This factory method takes the response from the [WeatherApi.request] method
  /// and converts it to an [OpenMeteoResponse] instance.
  factory OpenMeteoResponse.fromApiResponse(dynamic response) {
    final Map<WeatherHourly, OpenMeteoHourlyData> hourlyData = {};

    // Extract hourly data from the response
    if (response.hourlyData != null) {
      for (final entry in response.hourlyData.entries) {
        final parameter = entry.key;
        final data = entry.value;
        hourlyData[parameter] = OpenMeteoHourlyData.fromApiData(data);
      }
    }

    return OpenMeteoResponse(hourlyData: hourlyData);
  }
}

/// Model class for hourly data for a specific weather parameter
///
/// This class represents the time series data for a specific weather parameter,
/// such as temperature, humidity, etc.
class OpenMeteoHourlyData {
  /// Map of weather data values, keyed by timestamp
  ///
  /// The keys are [DateTime] objects representing the time, and the values are
  /// the actual weather data values (as [num]).
  final Map<DateTime, num> values;

  /// Creates a new OpenMeteoHourlyData instance
  const OpenMeteoHourlyData({
    required this.values,
  });

  /// Creates an OpenMeteoHourlyData from the raw data of the open_meteo package
  ///
  /// This factory method takes the hourly data for a specific parameter from the
  /// response and converts it to an [OpenMeteoHourlyData] instance.
  factory OpenMeteoHourlyData.fromApiData(dynamic data) {
    final Map<DateTime, num> values = {};

    // Extract values from the data
    if (data.values != null) {
      for (final entry in data.values.entries) {
        final time = entry.key;
        final value = entry.value;
        values[time] = value;
      }
    }

    return OpenMeteoHourlyData(values: values);
  }
}
