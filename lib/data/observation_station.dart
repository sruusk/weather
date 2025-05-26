import 'observation_station_location.dart';
import 'time_series.dart';

/// Represents a weather observation station with its location and various measurements
class ObservationStation {
  /// The location of the observation station
  final ObservationStationLocation location;

  /// The time when the measurements were taken
  final DateTime time;

  /// Temperature in degrees Celsius
  final double? temperature;

  /// Relative humidity percentage (0-100)
  final double? humidity;

  /// Dew point temperature in degrees Celsius
  final double? dewPoint;

  /// Snow depth in centimeters
  final double? snowDepth;

  /// Air pressure in hectopascals (hPa)
  final double? pressure;

  /// Visibility in meters
  final double? visibility;

  /// Precipitation amount in millimeters
  final double? precipitation;

  /// Height of the cloud base in meters
  final double? cloudBase;

  /// Wind direction in degrees (0-360, where 0 is North)
  final double? windDirection;

  /// Wind speed in meters per second
  final double? windSpeed;

  /// Wind gust speed in meters per second
  final double? windGust;

  /// Historical temperature measurements
  final List<TimeSeries>? temperatureHistory;

  /// Historical precipitation measurements
  final List<TimeSeries>? precipitationHistory;

  /// Creates a new ObservationStation instance
  const ObservationStation({
    required this.location,
    required this.time,
    this.temperature,
    this.humidity,
    this.dewPoint,
    this.snowDepth,
    this.pressure,
    this.visibility,
    this.precipitation,
    this.cloudBase,
    this.windDirection,
    this.windSpeed,
    this.windGust,
    this.temperatureHistory,
    this.precipitationHistory,
  });

  @override
  String toString() {
    return 'ObservationStation(location: ${location.name}, time: $time, temperature: $temperature)';
  }
}
