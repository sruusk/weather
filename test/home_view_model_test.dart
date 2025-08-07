import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:weather/app_state.dart';
import 'package:weather/data/forecast.dart';
import 'package:weather/data/forecast_point.dart';
import 'package:weather/data/geolocator.dart';
import 'package:weather/data/location.dart';
import 'package:weather/repositories/weather_repository.dart';
import 'package:weather/viewmodels/home_view_model.dart';

import 'home_view_model_test.mocks.dart';

// Create a subclass of HomeViewModel to override the startGeolocation method
class TestHomeViewModel extends HomeViewModel {
  TestHomeViewModel({required super.appState, super.weatherRepository});

  @override
  Future<void> startGeolocation() async {
    // Do nothing in tests to avoid calling actual Geolocator service
  }
}

// Generate mocks for the dependencies
@GenerateMocks([WeatherRepository, AppState])
void main() {
  late MockWeatherRepository mockWeatherRepository;
  late MockAppState mockAppState;
  late TestHomeViewModel viewModel;

  // Test location data
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
    mockWeatherRepository = MockWeatherRepository();
    mockAppState = MockAppState();

    // Set up default behavior for AppState
    when(mockAppState.favouriteLocations).thenReturn([testLocation]);
    when(mockAppState.geolocationEnabled).thenReturn(false);
    when(mockAppState.geolocation).thenReturn(null);
    when(mockAppState.activeLocationNotifier)
        .thenReturn(ValueNotifier<Location?>(null));
    when(mockAppState.geolocationEnabledNotifier)
        .thenReturn(ValueNotifier<bool>(false));
    when(mockAppState.locale).thenReturn(const Locale('en'));

    // Create the test view model with mocked dependencies
    viewModel = TestHomeViewModel(
      weatherRepository: mockWeatherRepository,
      appState: mockAppState,
    );
  });

  group('HomeViewModel', () {
    test('initial state is correct', () {
      expect(viewModel.forecast, isNull);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.locations, equals([testLocation]));
    });

    test('loadInitialForecast with favorite location loads forecast', () async {
      // Arrange
      when(mockWeatherRepository.getForecast(testLocation))
          .thenAnswer((_) async => testForecast);

      // Act
      await viewModel.loadInitialForecast();

      // Assert
      expect(viewModel.forecast, equals(testForecast));
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      verify(mockAppState.setActiveLocation(testLocation)).called(1);
    });

    test('loadInitialForecast handles error', () async {
      // Arrange
      when(mockWeatherRepository.getForecast(testLocation))
          .thenThrow(Exception('Network error'));

      // Act
      await viewModel.loadInitialForecast();

      // Assert
      expect(viewModel.forecast, isNull);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, equals('Failed to load forecast'));
    });

    test('refreshForecast refreshes current forecast', () async {
      // Arrange
      when(mockAppState.activeLocation).thenReturn(testLocation);
      when(mockWeatherRepository.getForecast(testLocation, forceRefresh: true))
          .thenAnswer((_) async => testForecast);

      // Act
      await viewModel.refreshForecast();

      // Assert
      verify(mockWeatherRepository.getForecast(testLocation,
              forceRefresh: true))
          .called(1);
    });

    test('refreshForecast handles error', () async {
      // Arrange
      when(mockAppState.activeLocation).thenReturn(testLocation);
      when(mockWeatherRepository.getForecast(testLocation, forceRefresh: true))
          .thenThrow(Exception('Network error'));

      // Act
      await viewModel.refreshForecast();

      // Assert
      expect(viewModel.errorMessage,
          equals('Failed to load forecast for Helsinki'));
    });

    test('handleGeolocationError sets appropriate error message', () {
      // Act
      viewModel.handleGeolocationError(GeolocationResult(
          status: GeolocationStatus.locationServicesDisabled));

      // Assert
      expect(viewModel.errorMessage, equals('Location services are disabled'));
    });

    test('handleGeolocationError disables geolocation for permanent denial',
        () {
      // Act
      viewModel.handleGeolocationError(
          GeolocationResult(status: GeolocationStatus.permissionDeniedForever));

      // Assert
      expect(viewModel.errorMessage,
          equals('Location permission permanently denied'));
      verify(mockAppState.setGeolocationEnabled(false)).called(1);
    });

    test('retryGeolocation clears error message', () {
      // Arrange
      viewModel.handleGeolocationError(GeolocationResult(
          status: GeolocationStatus.locationServicesDisabled));
      expect(viewModel.errorMessage, isNotNull);

      // Act
      viewModel.retryGeolocation();

      // Assert
      expect(viewModel.errorMessage, isNull);
    });
  });
}
