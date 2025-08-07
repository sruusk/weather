import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:weather/data/forecast.dart';
import 'package:weather/data/forecast_point.dart';
import 'package:weather/data/location.dart';
import 'package:weather/data/weather_data.dart';
import 'package:weather/errors/app_exception.dart';
import 'package:weather/repositories/weather_repository_impl.dart';
import 'package:weather/services/connectivity_service.dart';

import 'weather_repository_impl_test.mocks.dart';

// Generate mocks for the dependencies
@GenerateMocks([WeatherData, ConnectivityService])
void main() {
  late MockWeatherData mockWeatherData;
  late MockConnectivityService mockConnectivityService;
  late WeatherRepositoryImpl repository;

  // Test data
  final testLocation = Location(
    lat: 60.1699,
    lon: 24.9384,
    name: 'Helsinki',
    countryCode: 'FI',
  );

  final testForecastPoint = ForecastPoint(
    humidity: 80,
    temperature: 20,
    windDirection: 180,
    windSpeed: 5,
    windGust: 8,
    precipitation: 0,
    probabilityOfPrecipitation: 10,
    weatherSymbol: 'cloudy',
    weatherSymbolCode: 3,
    time: DateTime.now(),
  );

  final testForecast = Forecast(
    location: testLocation,
    forecast: [testForecastPoint],
  );

  setUp(() {
    mockWeatherData = MockWeatherData();
    mockConnectivityService = MockConnectivityService();

    // Set up default behavior for ConnectivityService
    when(mockConnectivityService.isConnected).thenReturn(true);
    when(mockConnectivityService.checkConnectivity())
        .thenAnswer((_) async => ConnectivityResult.wifi);

    // Create the repository with mocked dependencies
    repository = WeatherRepositoryImpl(
      weatherData: mockWeatherData,
      connectivityService: mockConnectivityService,
    );
  });

  group('WeatherRepositoryImpl', () {
    group('getForecast', () {
      test('returns forecast from WeatherData when cache is empty', () async {
        // Arrange
        when(mockWeatherData.getForecast(testLocation))
            .thenAnswer((_) async => testForecast);

        // Act
        final result = await repository.getForecast(testLocation);

        // Assert
        expect(result, equals(testForecast));
        verify(mockWeatherData.getForecast(testLocation)).called(1);
      });

      test('returns cached forecast when available and not expired', () async {
        // Arrange
        when(mockWeatherData.getForecast(testLocation))
            .thenAnswer((_) async => testForecast);

        // First call to populate cache
        await repository.getForecast(testLocation);

        // Reset the mock to verify it's not called again
        reset(mockWeatherData);
        when(mockWeatherData.getForecast(testLocation))
            .thenAnswer((_) async => testForecast);

        // Act
        final result = await repository.getForecast(testLocation);

        // Assert
        expect(result, equals(testForecast));
        verifyNever(mockWeatherData.getForecast(testLocation));
      });

      test('fetches new data when forceRefresh is true', () async {
        // Arrange
        when(mockWeatherData.getForecast(testLocation))
            .thenAnswer((_) async => testForecast);

        // First call to populate cache
        await repository.getForecast(testLocation);

        // Reset the mock to verify it's called again
        reset(mockWeatherData);
        when(mockWeatherData.getForecast(testLocation))
            .thenAnswer((_) async => testForecast);

        // Act
        final result =
            await repository.getForecast(testLocation, forceRefresh: true);

        // Assert
        expect(result, equals(testForecast));
        verify(mockWeatherData.getForecast(testLocation)).called(1);
      });

      test('retries on network error', () async {
        // Arrange
        // First call throws a NetworkException, second call succeeds
        int callCount = 0;
        when(mockWeatherData.getForecast(testLocation)).thenAnswer((_) {
          callCount++;
          if (callCount == 1) {
            throw NetworkException(
              message: 'Network error',
              code: 'network_error',
            );
          } else {
            return Future.value(testForecast);
          }
        });

        // Act
        final result = await repository.getForecast(testLocation);

        // Assert
        expect(result, equals(testForecast));
        verify(mockWeatherData.getForecast(testLocation)).called(2);
      });

      test('throws NetworkException when device is offline', () async {
        // Arrange
        when(mockConnectivityService.isConnected).thenReturn(false);
        when(mockConnectivityService.checkConnectivity())
            .thenAnswer((_) async => ConnectivityResult.none);

        // Act & Assert
        expect(
          () => repository.getForecast(testLocation),
          throwsA(isA<NetworkException>()),
        );
      });

      test('throws DataException on format error', () async {
        // Arrange
        when(mockWeatherData.getForecast(testLocation)).thenAnswer((_) async {
          throw const FormatException('Invalid data format');
        });

        // Act & Assert
        expect(
          () => repository.getForecast(testLocation),
          throwsA(isA<DataException>()),
        );
      });
    });

    group('getCurrentWeather', () {
      test('returns first forecast point', () async {
        // Arrange
        when(mockWeatherData.getForecast(testLocation))
            .thenAnswer((_) async => testForecast);

        // Act
        final result = await repository.getCurrentWeather(testLocation);

        // Assert
        expect(result, equals(testForecastPoint));
        verify(mockWeatherData.getForecast(testLocation)).called(1);
      });

      test('throws DataException when forecast is empty', () async {
        // Arrange
        when(mockWeatherData.getForecast(testLocation))
            .thenAnswer((_) async => Forecast(
                  location: testLocation,
                  forecast: [],
                ));

        // Act & Assert
        expect(
          () => repository.getCurrentWeather(testLocation),
          throwsA(isA<DataException>()),
        );
      });
    });

    group('reverseGeocoding', () {
      test('returns location from WeatherData', () async {
        // Arrange
        when(mockWeatherData.reverseGeocoding(
                testLocation.lat, testLocation.lon,
                lang: 'en'))
            .thenAnswer((_) async => testLocation);

        // Act
        final result = await repository.reverseGeocoding(
            testLocation.lat, testLocation.lon);

        // Assert
        expect(result, equals(testLocation));
        verify(mockWeatherData.reverseGeocoding(
                testLocation.lat, testLocation.lon,
                lang: 'en'))
            .called(1);
      });

      test('throws LocationException on error', () async {
        // Arrange
        when(mockWeatherData.reverseGeocoding(
                testLocation.lat, testLocation.lon,
                lang: 'en'))
            .thenAnswer((_) async {
          throw Exception('Error in reverse geocoding');
        });

        // Act & Assert
        expect(
          () => repository.reverseGeocoding(testLocation.lat, testLocation.lon),
          throwsA(isA<LocationException>()),
        );
      });
    });

    group('getAutoCompleteResults', () {
      test('returns locations from WeatherData', () async {
        // Arrange
        when(mockWeatherData.getAutoCompleteResults('Helsinki', lang: 'en'))
            .thenAnswer((_) async => [testLocation]);

        // Act
        final result = await repository.getAutoCompleteResults('Helsinki');

        // Assert
        expect(result, equals([testLocation]));
        verify(mockWeatherData.getAutoCompleteResults('Helsinki', lang: 'en'))
            .called(1);
      });

      test('throws LocationException on error', () async {
        // Arrange
        when(mockWeatherData.getAutoCompleteResults('Helsinki', lang: 'en'))
            .thenAnswer((_) async {
          throw Exception('Error in autocomplete');
        });

        // Act & Assert
        expect(
          () => repository.getAutoCompleteResults('Helsinki'),
          throwsA(isA<LocationException>()),
        );
      });
    });

    group('clearCache', () {
      test('clears internal cache and calls WeatherData.clearCache', () async {
        // Arrange
        when(mockWeatherData.getForecast(testLocation))
            .thenAnswer((_) async => testForecast);

        // Populate cache
        await repository.getForecast(testLocation);

        // Reset mock to verify it's not called after cache is populated
        reset(mockWeatherData);
        when(mockWeatherData.getForecast(testLocation))
            .thenAnswer((_) async => testForecast);

        // Verify cache is working
        await repository.getForecast(testLocation);
        verifyNever(mockWeatherData.getForecast(testLocation));

        // Set up the mock for clearCache
        when(mockWeatherData.clearCache()).thenReturn(null);

        // Act
        repository.clearCache();

        // Verify clearCache was called
        verify(mockWeatherData.clearCache()).called(1);

        // Reset mock again
        reset(mockWeatherData);
        when(mockWeatherData.getForecast(testLocation))
            .thenAnswer((_) async => testForecast);

        // Verify cache is cleared
        await repository.getForecast(testLocation);
        verify(mockWeatherData.getForecast(testLocation)).called(1);
      });
    });

    group('clearCacheForLocation', () {
      test('clears cache for specific location', () async {
        // Arrange
        final testLocation2 = Location(
          lat: 61.4978,
          lon: 23.7610,
          name: 'Tampere',
          countryCode: 'FI',
        );

        when(mockWeatherData.getForecast(testLocation))
            .thenAnswer((_) async => testForecast);
        when(mockWeatherData.getForecast(testLocation2))
            .thenAnswer((_) async => Forecast(
                  location: testLocation2,
                  forecast: [testForecastPoint],
                ));

        // Populate cache for both locations
        await repository.getForecast(testLocation);
        await repository.getForecast(testLocation2);

        // Reset mocks
        reset(mockWeatherData);
        when(mockWeatherData.getForecast(testLocation))
            .thenAnswer((_) async => testForecast);
        when(mockWeatherData.getForecast(testLocation2))
            .thenAnswer((_) async => Forecast(
                  location: testLocation2,
                  forecast: [testForecastPoint],
                ));
        when(mockWeatherData.clearCacheForLocation(testLocation))
            .thenReturn(null);

        // Act
        repository.clearCacheForLocation(testLocation);

        // Verify clearCacheForLocation was called
        verify(mockWeatherData.clearCacheForLocation(testLocation)).called(1);

        // Assert
        // Cache for testLocation should be cleared
        await repository.getForecast(testLocation);
        verify(mockWeatherData.getForecast(testLocation)).called(1);

        // Cache for testLocation2 should still be valid
        await repository.getForecast(testLocation2);
        verifyNever(mockWeatherData.getForecast(testLocation2));
      });
    });
  });
}
