import 'observation_station_location.dart';
import 'time_series.dart';

/// Represents a weather observation station with its location and various measurements
class ObservationStation {
  /// The location of the observation station
  final ObservationStationLocation location;

  /// The time when the measurements were taken
  final DateTime time;

  /// Temperature in degrees Celsius
  final List<TimeSeries>? temperature;

  /// Relative humidity percentage (0-100)
  final List<TimeSeries>? humidity;

  /// Dew point temperature in degrees Celsius
  final List<TimeSeries>? dewPoint;

  /// Snow depth in centimeters
  final List<TimeSeries>? snowDepth;

  /// Air pressure in hectopascals (hPa)
  final List<TimeSeries>? pressure;

  /// Visibility in meters
  final List<TimeSeries>? visibility;

  /// Precipitation amount in millimeters
  final List<TimeSeries>? precipitation;

  /// Height of the cloud base in meters
  final List<TimeSeries>? cloudBase;

  /// Wind direction in degrees (0-360, where 0 is North)
  final List<TimeSeries>? windDirection;

  /// Wind speed in meters per second
  final List<TimeSeries>? windSpeed;

  /// Wind gust speed in meters per second
  final List<TimeSeries>? windGust;

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
  });

  @override
  String toString() {
    return 'ObservationStation(location: ${location.name}, time: $time, temperature: $temperature)';
  }

  ObservationStation copyWith({ObservationStationLocation? location}) {
    return ObservationStation(
      location: location ?? this.location,
      time: time,
      temperature: temperature,
      humidity: humidity,
      dewPoint: dewPoint,
      snowDepth: snowDepth,
      pressure: pressure,
      visibility: visibility,
      precipitation: precipitation,
      cloudBase: cloudBase,
      windDirection: windDirection,
      windSpeed: windSpeed,
      windGust: windGust,
    );
  }
}
