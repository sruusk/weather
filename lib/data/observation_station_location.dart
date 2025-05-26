import 'location.dart';

/// Represents the location of an observation station, extending the base Location class
/// with additional properties specific to observation stations
class ObservationStationLocation extends Location {
  /// Unique identifier for the observation station
  final String identifier;

  /// Distance to the observation station in kilometers
  final double? distance;

  /// Creates a new ObservationStationLocation instance
  const ObservationStationLocation({
    required super.lat,
    required super.lon,
    required super.name,
    required super.countryCode,
    super.region,
    super.country,
    required this.identifier,
    this.distance,
  });

  @override
  String toString() {
    return 'ObservationStationLocation(identifier: $identifier, name: $name, distance: $distance, lat: $lat, lon: $lon)';
  }
}
