import 'dart:math';

/// Represents a geographical location with coordinates and descriptive information
class Location {
  /// Latitude coordinate
  final double lat;

  /// Longitude coordinate
  final double lon;

  /// Name of the location
  final String name;

  /// Region where the location is situated
  final String? region;

  /// Country where the location is situated
  final String countryCode;

  final String? country;

  /// Index for ordering in favourites list
  final int? index;

  /// Creates a new Location instance
  const Location({
    required this.lat,
    required this.lon,
    required this.name,
    required this.countryCode,
    this.country,
    this.region,
    this.index,
  });

  /// Converts the location object to a string representation that can be parsed back
  /// Format: lat|lon|name|countryCode|region|country|index
  /// Note: region, country, and index can be null, in which case they're represented as empty strings
  @override
  String toString() {
    return '$lat|$lon|$name|$countryCode|${region ?? ""}|${country ??
        ""}|${index?.toString() ?? ""}';
  }

  /// Creates a Location object from its string representation
  /// Expected format: lat|lon|name|countryCode|region|country|index
  static Location fromString(String str) {
    final parts = str.split('|');
    if (parts.length < 6) {
      throw FormatException('Invalid location string format: $str');
    }

    // Handle both old format (without index) and new format (with index)
    int? indexValue;
    if (parts.length >= 7 && parts[6].isNotEmpty) {
      indexValue = int.parse(parts[6]);
    }

    return Location(
      lat: double.parse(parts[0]),
      lon: double.parse(parts[1]),
      name: parts[2],
      countryCode: parts[3],
      region: parts[4].isNotEmpty ? parts[4] : null,
      country: parts[5].isNotEmpty ? parts[5] : null,
      index: indexValue,
    );
  }

  /// Returns a debug string representation of this location
  String toDebugString() {
    return 'Location(name: $name, lat: $lat, lon: $lon, region: $region, countryCode: $countryCode, country: $country, index: $index)';
  }

  /// Checks if two locations are equal based on their coordinates
  /// Two locations are considered equal if their latitude and longitude are the same
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Location) return false;
    return lat == other.lat && lon == other.lon;
  }

  @override
  int get hashCode => lat.hashCode ^ lon.hashCode;

  /// Calculates the distance to another location in meters
  /// Uses the Haversine formula to compute the distance between two points on the Earth
  double distanceTo(Location other) {
    return Location.distanceBetweenCoordinates(lat, lon, other.lat, other.lon);
  }

  /// Calculates the distance between two coordinates in meters
  static double distanceBetweenCoordinates(double lat1, double lon1, double lat2,
      double lon2) {
    const R = 6371e3; // Earth radius in meters
    final phi1 = lat1 * pi / 180; // φ, λ in radians
    final phi2 = lat2 * pi / 180;
    final deltaPhi = (lat2 - lat1) * pi / 180;
    final deltaLambda = (lon2 - lon1) * pi / 180;

    final a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) *
            sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c; // in meters
  }
}
