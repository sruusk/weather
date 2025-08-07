import 'package:flutter/material.dart';
import 'package:weather/data/forecast_point.dart';

/// Enum representing different types of precipitation
enum PrecipitationType {
  /// Rain precipitation
  rain,

  /// Snow precipitation
  snow,

  /// Sleet (mix of rain and snow)
  sleet,

  /// Freezing rain
  freezingRain,

  /// Hail
  hail,

  /// No precipitation
  none
}

/// Enum representing precipitation intensity levels
enum PrecipitationIntensity {
  /// No precipitation (0 mm/h)
  none,

  /// Very light precipitation (0-0.5 mm/h)
  veryLight,

  /// Light precipitation (0.5-2 mm/h)
  light,

  /// Moderate precipitation (2-10 mm/h)
  moderate,

  /// Heavy precipitation (10-50 mm/h)
  heavy,

  /// Violent precipitation (>50 mm/h)
  violent
}

/// Model class for detailed precipitation forecasts
///
/// This class extends the basic precipitation data available in [ForecastPoint]
/// with additional properties for more detailed precipitation visualization.
class PrecipitationForecast {
  /// The forecast point containing basic precipitation data
  final ForecastPoint forecastPoint;

  /// The type of precipitation
  final PrecipitationType type;

  /// The intensity of precipitation
  final PrecipitationIntensity intensity;

  /// The accumulated precipitation amount since a reference time (mm)
  final double accumulatedAmount;

  /// The reference time for accumulated precipitation
  final DateTime accumulationStartTime;

  /// Creates a new PrecipitationForecast instance
  const PrecipitationForecast({
    required this.forecastPoint,
    required this.type,
    required this.intensity,
    required this.accumulatedAmount,
    required this.accumulationStartTime,
  });

  /// Factory method to create a PrecipitationForecast from a ForecastPoint
  ///
  /// This method infers precipitation type and intensity from the forecast point data.
  /// Accumulation is set to the precipitation amount with the current time as reference.
  factory PrecipitationForecast.fromForecastPoint(ForecastPoint point) {
    // Infer precipitation type from weather symbol and temperature
    PrecipitationType type = _inferPrecipitationType(point);

    // Infer precipitation intensity from amount
    PrecipitationIntensity intensity =
        _inferPrecipitationIntensity(point.precipitation);

    return PrecipitationForecast(
      forecastPoint: point,
      type: type,
      intensity: intensity,
      accumulatedAmount: point.precipitation,
      accumulationStartTime: point.time,
    );
  }

  /// Factory method to create a PrecipitationForecast with accumulation
  ///
  /// This method calculates accumulated precipitation over a series of forecast points.
  factory PrecipitationForecast.withAccumulation(
    ForecastPoint point,
    List<ForecastPoint> previousPoints,
    DateTime startTime,
  ) {
    // Infer precipitation type and intensity
    PrecipitationType type = _inferPrecipitationType(point);
    PrecipitationIntensity intensity =
        _inferPrecipitationIntensity(point.precipitation);

    // Calculate accumulated precipitation since startTime
    double accumulated = 0;
    for (var p in previousPoints) {
      if (p.time.isAfter(startTime) && p.time.isBefore(point.time)) {
        accumulated += p.precipitation;
      }
    }
    accumulated += point.precipitation;

    return PrecipitationForecast(
      forecastPoint: point,
      type: type,
      intensity: intensity,
      accumulatedAmount: accumulated,
      accumulationStartTime: startTime,
    );
  }

  /// Infers precipitation type from forecast point data
  static PrecipitationType _inferPrecipitationType(ForecastPoint point) {
    // Use weather symbol and temperature to determine precipitation type
    if (point.precipitation <= 0) {
      return PrecipitationType.none;
    }

    final symbol = point.weatherSymbol.toLowerCase();
    final temp = point.temperature;

    if (symbol.contains('snow')) {
      return PrecipitationType.snow;
    } else if (symbol.contains('sleet')) {
      return PrecipitationType.sleet;
    } else if (temp < 0 && symbol.contains('rain')) {
      return PrecipitationType.freezingRain;
    } else if (symbol.contains('hail')) {
      return PrecipitationType.hail;
    } else if (symbol.contains('rain') ||
        symbol.contains('drizzle') ||
        symbol.contains('thunderstorm')) {
      return PrecipitationType.rain;
    }

    // Default to rain if precipitation is present but type can't be determined
    return point.precipitation > 0
        ? PrecipitationType.rain
        : PrecipitationType.none;
  }

  /// Infers precipitation intensity from amount
  static PrecipitationIntensity _inferPrecipitationIntensity(double amount) {
    if (amount <= 0) {
      return PrecipitationIntensity.none;
    } else if (amount <= 0.5) {
      return PrecipitationIntensity.veryLight;
    } else if (amount <= 2) {
      return PrecipitationIntensity.light;
    } else if (amount <= 10) {
      return PrecipitationIntensity.moderate;
    } else if (amount <= 50) {
      return PrecipitationIntensity.heavy;
    } else {
      return PrecipitationIntensity.violent;
    }
  }

  /// Gets the color associated with this precipitation intensity
  Color getIntensityColor() {
    switch (intensity) {
      case PrecipitationIntensity.none:
        return Colors.transparent;
      case PrecipitationIntensity.veryLight:
        return Colors.lightBlue[100]!;
      case PrecipitationIntensity.light:
        return Colors.lightBlue[300]!;
      case PrecipitationIntensity.moderate:
        return Colors.blue[500]!;
      case PrecipitationIntensity.heavy:
        return Colors.blue[700]!;
      case PrecipitationIntensity.violent:
        return Colors.purple[700]!;
    }
  }

  /// Gets the icon associated with this precipitation type
  IconData getTypeIcon() {
    switch (type) {
      case PrecipitationType.rain:
        return Icons.water_drop;
      case PrecipitationType.snow:
        return Icons.ac_unit;
      case PrecipitationType.sleet:
        return Icons.grain;
      case PrecipitationType.freezingRain:
        return Icons.ac_unit;
      case PrecipitationType.hail:
        return Icons.circle;
      case PrecipitationType.none:
        return Icons.water_drop_outlined;
    }
  }
}
