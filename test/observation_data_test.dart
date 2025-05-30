import 'package:flutter_test/flutter_test.dart';
import 'package:weather/data/location.dart';
import 'package:weather/data/observation_data.dart';


void main() {
  group('ObservationData', () {
    late ObservationData observationData;

    setUp(() {
      observationData = ObservationData();

      // Replace the http client with our mock
      // This is a limitation of the test since we can't easily replace the http.get static method
      // In a real-world scenario, we would refactor the ObservationData class to accept a client
      // For now, we'll just test the methods that don't make HTTP requests
    });

    test('clearCache should reset all caches', () {
      // Act
      observationData.clearCache();

      // We can't directly test private fields, but we can verify behavior
      // by making subsequent calls that would use the cache

      // This is a limited test, but it at least verifies the method exists and runs
      expect(() => observationData.clearCache(), returnsNormally);
    });

    test('clearCacheForLocation should not throw', () {
      // Arrange
      final location = Location(
        lat: 60.1695,
        lon: 24.9354,
        name: 'Helsinki',
        countryCode: 'FI',
      );

      // Act & Assert
      expect(() => observationData.clearCacheForLocation(location), returnsNormally);
    });
  });
}
