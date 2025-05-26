import 'forecast_point.dart';
import 'location.dart';

class Forecast {
  final Location location;

  final List<ForecastPoint> forecast;

  const Forecast({
    required this.location,
    required this.forecast,
  });

  @override
  String toString() {
    return 'Forecast(location: ${location.name}, points: ${forecast.length})';
  }
}
