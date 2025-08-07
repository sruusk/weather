import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather/app_state.dart';
import 'package:weather/data/forecast.dart';
import 'package:weather/data/geolocator.dart';
import 'package:weather/data/location.dart';
import 'package:weather/repositories/weather_repository.dart';
import 'package:weather/services/service_locator.dart';
import 'package:weather/utils/logger.dart';

/// ViewModel for the HomePage
///
/// This class handles the business logic for the HomePage, including:
/// - Loading forecasts
/// - Managing geolocation
/// - Handling errors
class HomeViewModel extends ChangeNotifier {
  final WeatherRepository _weatherRepository;
  final AppState _appState;

  Forecast? _forecast;
  bool _isLoading = false;
  String? _errorMessage;

  /// Creates a new HomeViewModel with the given dependencies
  HomeViewModel({
    WeatherRepository? weatherRepository,
    required AppState appState,
  })  : _weatherRepository =
            weatherRepository ?? serviceLocator.get<WeatherRepository>(),
        _appState = appState {
    // Add listeners for activeLocation, geolocation, and favouriteLocations
    _appState.activeLocationNotifier.addListener(_onActiveLocationChanged);
    _appState.geolocationEnabledNotifier
        .addListener(_onGeolocationEnabledChanged);
  }

  /// The current forecast
  Forecast? get forecast => _forecast;

  /// Whether data is currently being loaded
  bool get isLoading => _isLoading;

  /// Error message to display, if any
  String? get errorMessage => _errorMessage;

  /// List of available locations (geolocation + favorites)
  List<Location> get locations => _appState.geolocation != null
      ? [_appState.geolocation!, ..._appState.favouriteLocations]
      : _appState.favouriteLocations;

  /// Handles changes to the active location
  void _onActiveLocationChanged() {
    if (_appState.activeLocation != null && _forecast != null) {
      Logger.debug("Active location changed: ${_appState.activeLocation}");
      _loadForecastForLocation(_appState.activeLocation!);
    }
  }

  /// Handles changes to the geolocation enabled setting
  void _onGeolocationEnabledChanged() {
    if (_isLoading) return;
    if (!_appState.geolocationEnabled) {
      _appState.setGeolocation(null);
    }
    Logger.debug("Geolocation changed, reloading forecasts");
    loadInitialForecast();
  }

  /// Loads the forecast for a specific location
  Future<void> _loadForecastForLocation(Location location,
      {bool forceRefresh = false}) async {
    try {
      final forecast = await _weatherRepository.getForecast(location,
          forceRefresh: forceRefresh);

      if (_forecast == null || _forecast!.location != forecast.location) {
        _forecast = forecast;
        notifyListeners();
      }
    } catch (e) {
      Logger.error('Error getting forecast for location', e);
      _errorMessage = 'Failed to load forecast for ${location.name}';
      notifyListeners();
    }
  }

  /// Refreshes the current forecast
  ///
  /// This method forces a refresh of the current forecast by bypassing the cache.
  /// Returns a Future that completes when the refresh is done.
  Future<void> refreshForecast() async {
    if (_appState.activeLocation == null) {
      Logger.debug("No active location to refresh");
      return;
    }

    Logger.debug("Refreshing forecast for ${_appState.activeLocation!.name}");
    _errorMessage = null;

    try {
      await _loadForecastForLocation(_appState.activeLocation!,
          forceRefresh: true);
      Logger.debug("Forecast refreshed successfully");
    } catch (e) {
      Logger.error('Error refreshing forecast', e);
      _errorMessage = 'Failed to refresh forecast';
      notifyListeners();
    }
  }

  /// Loads the initial forecast based on the user's settings and location
  ///
  /// Handles geolocation if enabled, or uses the first favorite location if not.
  ///
  /// If no locations are available, sets the forecast to null and stops loading.
  Future<void> loadInitialForecast() async {
    final List<Location> locs = _appState.favouriteLocations;

    Logger.debug(
        "loadInitialForecast(), geolocationEnabled: ${_appState.geolocationEnabled}, locations: ${locs.length}");

    if (locs.isEmpty && !_appState.geolocationEnabled) {
      _forecast = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Determine which location to load
    Location? locationToLoad;

    // If geolocation is enabled, try to get current location
    if (_appState.geolocationEnabled && _appState.geolocation != null) {
      locationToLoad = _appState.geolocation;
    } else if (_appState.geolocationEnabled) {
      try {
        final result = await getLastKnownPosition();
        if (result.isSuccess && result.position != null) {
          // Use reverse geocoding to get location information
          final geolocation = await _weatherRepository.reverseGeocoding(
              result.position!.latitude, result.position!.longitude,
              lang: _appState.locale.languageCode);
          _appState.setGeolocation(geolocation);
          locationToLoad = geolocation;
          startGeolocation();
        } else {
          // Handle geolocation errors
          handleGeolocationError(result);
        }
      } catch (e) {
        Logger.error('Error getting last known position', e);
        _errorMessage = 'Failed to get location';
      }
    } else if (locs.isNotEmpty) {
      // If geolocation is disabled, use first favorite
      locationToLoad = locs.first;
    }

    // If we have a location to load, get its forecast
    if (locationToLoad != null) {
      try {
        // Store the non-nullable location
        final Location activeLocation = locationToLoad;

        final forecast = await _weatherRepository.getForecast(activeLocation);

        _forecast = forecast;
        _isLoading = false;
        _errorMessage = null;
        _appState.setActiveLocation(activeLocation);
        notifyListeners();
      } catch (e) {
        Logger.error('Error getting forecast', e);
        _forecast = null;
        _isLoading = false;
        _errorMessage = 'Failed to load forecast';
        notifyListeners();
      }
    } else {
      _forecast = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Starts the geolocation process to get the current location
  Future<void> startGeolocation() async {
    try {
      final result =
          await determinePosition().timeout(const Duration(seconds: 30));

      if (result.isSuccess && result.position != null) {
        // Use reverse geocoding to get location information
        final geolocation = await _weatherRepository.reverseGeocoding(
            result.position!.latitude, result.position!.longitude,
            lang: _appState.locale.languageCode);

        // Update the app state with the new geolocation
        if (_appState.geolocation == null ||
            _appState.geolocation!.distanceTo(geolocation) > 500) {
          if (_appState.geolocation == _appState.activeLocation) {
            _appState.setActiveLocation(geolocation);
          }
          _appState.setGeolocation(geolocation);
        }
      } else {
        if (result.isSuccess) {
          startGeolocation();
        } else {
          handleGeolocationError(result);
        }
      }
    } on TimeoutException {
      // Handle timeout specifically
      Logger.warning('Geolocation timed out');
      _errorMessage = 'Geolocation timed out';
      notifyListeners();
    } catch (e) {
      // Handle any other exceptions
      Logger.error('Geolocation failed', e);
    }
  }

  /// Handles geolocation errors
  void handleGeolocationError(GeolocationResult result) {
    String errorMessage;

    switch (result.status) {
      case GeolocationStatus.locationServicesDisabled:
        errorMessage = 'Location services are disabled';
        break;
      case GeolocationStatus.permissionDenied:
        errorMessage = 'Location permission denied';
        break;
      case GeolocationStatus.permissionDeniedForever:
        // For permanently denied permissions, also disable geolocation in app state
        _appState.setGeolocationEnabled(false);
        errorMessage = 'Location permission permanently denied';
        break;
      default:
        errorMessage = 'Unknown error';
    }

    _errorMessage = errorMessage;
    notifyListeners();
  }

  /// Opens the app settings to enable location permissions
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Opens the location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Retries geolocation
  void retryGeolocation() {
    _errorMessage = null;
    notifyListeners();
    startGeolocation();
  }

  @override
  void dispose() {
    // Remove listeners
    _appState.activeLocationNotifier.removeListener(_onActiveLocationChanged);
    _appState.geolocationEnabledNotifier
        .removeListener(_onGeolocationEnabledChanged);
    super.dispose();
  }
}
