import 'package:flutter_test/flutter_test.dart';
import 'package:weather/data/weather_data.dart';
import 'package:weather/data/location.dart';
import 'package:weather/data/forecast_point.dart';
import 'package:weather/data/forecast.dart';

void main() {
  final weatherData = WeatherData();

  // Dummy location for testing
  final testLocation = Location(
    lat: 60.1699,
    lon: 24.9384,
    name: 'Helsinki',
    countryCode: 'FI',
  );

  group('WeatherData', () {
    test('getForecast returns a Forecast with points', () async {
      final forecast = await weatherData.getForecast(testLocation);
      expect(forecast, isA<Forecast>());
      expect(forecast.location.name, equals('Helsinki'));
      expect(forecast.forecast, isNotEmpty);
      expect(forecast.forecast.first, isA<ForecastPoint>());
    });

    test('getCurrentWeather returns a ForecastPoint', () async {
      final point = await weatherData.getCurrentWeather(testLocation);
      expect(point, isA<ForecastPoint>());
      expect(point.temperature, isNotNull);
    });

    test('getAutoCompleteResults returns a list of Location', () async {
      final results = await weatherData.getAutoCompleteResults('Tampere');
      expect(results, isA<List<Location>>());
      expect(results, isNotEmpty);
      expect(results.first.name, contains('Tampere'));
    });

    test('getWarnings does not throw', () async {
      await weatherData.getWarnings();
    });
  });
}
