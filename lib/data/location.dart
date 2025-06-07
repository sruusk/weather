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
    return '$lat|$lon|$name|$countryCode|${region ?? ""}|${country ?? ""}|${index?.toString() ?? ""}';
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
}
