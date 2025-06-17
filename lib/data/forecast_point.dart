/// Represents a single point in a weather forecast with various meteorological measurements
class ForecastPoint {
  /// Relative humidity percentage (0-100)
  final double humidity;

  /// Temperature in degrees Celsius
  final double temperature;

  /// Wind direction in degrees (0-360, where 0 is North)
  final double windDirection;

  /// Wind speed in meters per second
  final double windSpeed;

  /// Wind gust speed in meters per second
  final double windGust;

  /// Precipitation amount in millimeters
  final double precipitation;

  /// Probability of precipitation (0-100%)
  final double probabilityOfPrecipitation;

  /// Weather symbol name
  final String weatherSymbol;

  /// Weather symbol code
  final int weatherSymbolCode;

  /// "Feels like" temperature in degrees Celsius
  final double? feelsLike;

  /// Time when this forecast point is valid
  final DateTime time;

  /// Creates a new ForecastPoint instance
  const ForecastPoint({
    required this.humidity,
    required this.temperature,
    required this.windDirection,
    required this.windSpeed,
    required this.windGust,
    required this.precipitation,
    required this.probabilityOfPrecipitation,
    required this.weatherSymbol,
    required this.weatherSymbolCode,
    this.feelsLike,
    required this.time,
  });

  @override
  String toString() {
    return 'ForecastPoint(time: $time, temperature: $temperature, humidity: $humidity)';
  }
}
