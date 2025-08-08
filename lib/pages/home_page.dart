import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:weather/app_state.dart';
import 'package:weather/data/forecast.dart';
import 'package:weather/data/geolocator.dart';
import 'package:weather/data/location.dart';
import 'package:weather/data/weather_data.dart';
import 'package:weather/l10n/app_localizations.g.dart';
import 'package:weather/main.dart' show showGlobalSnackBar;
import 'package:weather/widgets/home/weather_details_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin<HomePage>, WidgetsBindingObserver {
  final WeatherData _weatherData = WeatherData();
  Forecast? _forecast;
  bool _isLoading = false;
  bool _locationDenied = false; // Prevents causing loops

  @override
  void initState() {
    super.initState();
    if (!mounted) return; // Ensure widget is still mounted
    final appState = Provider.of<AppState>(context, listen: false);
    // Add listeners for activeLocation, geolocation, and favouriteLocations
    appState.activeLocationNotifier.addListener(_onActiveLocationChanged);
    appState.geolocationEnabledNotifier
        .addListener(_onGeolocationEnabledChanged);
  }

  void _onActiveLocationChanged() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.activeLocation != null && mounted && _forecast != null) {
      if (kDebugMode) {
        print("Active location changed: ${appState.activeLocation}");
      }
      // Load the forecast for the active location
      _weatherData.getForecast(appState.activeLocation!).then((forecast) {
        if (mounted) {
          setState(() {
            _forecast = forecast;
          });
        }
      }).catchError((e) {
        if (kDebugMode) {
          print('Error getting forecast for active location: $e');
        }
      });
    }
  }

  void _onGeolocationEnabledChanged() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (_isLoading) return;
    if (!appState.geolocationEnabled) {
      appState.setGeolocation(null);
    }
    if (kDebugMode) {
      print("Geolocation changed, reloading forecasts");
    }
    _loadInitialForecast();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App has come back to the foreground
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.geolocationEnabled) {
        // Only reload if geolocation is enabled in app settings
        if (kDebugMode) {
          print("App resumed, reloading forecasts");
        }
        _loadInitialForecast();
      }
      WidgetsBinding.instance.removeObserver(this);
    }
  }

  void _handleGeolocationError(GeolocationResult result) {
    final appState = Provider.of<AppState>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;
    String errorMessage;

    switch (result.status) {
      case GeolocationStatus.locationServicesDisabled:
        errorMessage = localizations.locationServicesDisabled;
        setState(() {
          _locationDenied = true;
        });
        break;
      case GeolocationStatus.permissionDenied:
        errorMessage = localizations.locationPermissionDenied;
        setState(() {
          _locationDenied = true;
        });
        break;
      case GeolocationStatus.permissionDeniedForever:
        // For permanently denied permissions, also disable geolocation in app state
        appState.setGeolocationEnabled(false);
        errorMessage = localizations.locationPermissionPermanentlyDenied;
        break;
      default:
        errorMessage = localizations.unknownError;
        setState(() {
          _locationDenied = true;
        });
    }

    showGlobalSnackBar(
      message: errorMessage,
      duration: const Duration(seconds: 5),
      action: result.status == GeolocationStatus.permissionDeniedForever
          ? SnackBarAction(
              label: localizations.openSettings,
              onPressed: () {
                // Open app settings
                WidgetsBinding.instance.addObserver(this);
                Geolocator.openAppSettings();
              },
            )
          : result.status == GeolocationStatus.locationServicesDisabled
              ? SnackBarAction(
                  label: localizations.openSettings,
                  onPressed: () {
                    // Open location settings
                    WidgetsBinding.instance.addObserver(this);
                    Geolocator.openLocationSettings();
                  },
                )
              : SnackBarAction(
                  label: localizations.retry,
                  onPressed: _startGeolocation,
                ),
    );
  }

  void _startGeolocation() async {
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      final result =
          await determinePosition().timeout(const Duration(seconds: 30));

      if (result.isSuccess && result.position != null) {
        // Use reverse geocoding to get location information
        final geolocation = await _weatherData.reverseGeocoding(
          result.position!.latitude,
          result.position!.longitude,
            lang: appState.locale.languageCode);

        // Update the app state with the new geolocation
        if (appState.geolocation == null ||
            appState.geolocation!.distanceTo(geolocation) > 500) {
          if (appState.geolocation == appState.activeLocation) {
            appState.setActiveLocation(geolocation);
          }
          appState.setGeolocation(geolocation);
          setState(() {
            _isLoading = false;
            _locationDenied = false;
          });
        }
      } else {
        if (result.isSuccess) {
          // This case should not happen, but handle it gracefully
          _startGeolocation();
        } else {
          _handleGeolocationError(result);
          setState(() {
            _isLoading = false;
          });
        }
      }
    } on TimeoutException {
      // Handle timeout specifically
      if (kDebugMode) {
        print('Geolocation timed out');
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final localizations = AppLocalizations.of(context)!;
        showGlobalSnackBar(
          message: localizations.geolocationTimeout,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
              label: localizations.retry, onPressed: _startGeolocation),
        );
      });
    } catch (e) {
      // Handle any other exceptions
      if (kDebugMode) {
        print('Geolocation failed: $e');
      }
    }
  }

  @override
  void dispose() {
    // Remove listeners
    final appState = Provider.of<AppState>(context, listen: false);
    appState.activeLocationNotifier.removeListener(_onActiveLocationChanged);
    appState.geoLocationNotifier.removeListener(_onGeolocationEnabledChanged);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  /// Loads the initial forecast based on the user's settings and location.
  ///
  /// Handles geolocation if enabled, or uses the first favorite location if not.
  ///
  /// If no locations are available, sets the forecast to null and stops loading.
  Future<void> _loadInitialForecast() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final List<Location>locs = appState.favouriteLocations;

    if (kDebugMode) {
      print(
          "_loadInitialForecast(), geolocationEnabled: ${appState.geolocationEnabled}, locations: ${locs.length}");
    }

    if (locs.isEmpty && !appState.geolocationEnabled) {
      setState(() {
        _forecast = null;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    // Determine which location to load
    Location? locationToLoad;

    // If geolocation is enabled, try to get current location
    if (appState.geolocationEnabled && appState.geolocation != null) {
      locationToLoad = appState.geolocation;
    } else if (appState.geolocationEnabled) {
      final result = await getLastKnownPosition();
      if(result.isSuccess && result.position != null) {
        // Use reverse geocoding to get location information
        final geolocation = await _weatherData.reverseGeocoding(
          result.position!.latitude,
          result.position!.longitude,
            lang: appState.locale.languageCode);
        appState.setGeolocation(geolocation);
        locationToLoad = geolocation;
        _startGeolocation();
      } else {
        if (result.isSuccess) {
          _startGeolocation();
        } else {
          _handleGeolocationError(result);
          if (locs.isNotEmpty) {
            locationToLoad = locs.first;
          } else {
            setState(() {
              _forecast = null;
              _isLoading = false;
            });
            return;
          }
        }
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

        final forecast = await _weatherData.getForecast(activeLocation);

        setState(() {
          _forecast = forecast;
          _isLoading = false;
          appState.setActiveLocation(activeLocation);
        });
      } catch (e) {
        if (kDebugMode) {
          print('Error getting forecast: $e');
        }
        setState(() {
          _forecast = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Call super to ensure keep alive works

    final appState = Provider.of<AppState>(context);
    final localizations = AppLocalizations.of(context)!;

    List<Location> locations = appState.geolocation != null
        ? [appState.geolocation!, ...appState.favouriteLocations]
        : appState.favouriteLocations;

    if (!_isLoading &&
        _forecast == null &&
        (locations.isNotEmpty ||
            (appState.geolocationEnabled && !_locationDenied))) {
      setState(() {
        _isLoading = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInitialForecast();
      });
    }

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    localizations.loadingForecasts,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ))
            : _forecast == null || locations.isEmpty
                ? NoLocations()
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            WeatherDetails(
                              forecast: _forecast!,
                              locations: locations,
                              isLoading: _isLoading,
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class NoLocations extends StatelessWidget {
  const NoLocations({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context)!;

    return Center(
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_off,
                size: 48.0,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16.0),
              Text(
                localisations.noSavedLocations,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12.0),
              Text(
                localisations.addLocationsInFavourites,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24.0),
              SizedBox(
                width: 200.0, // Make button wider
                height: 48.0, // Make button taller
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to the favourites page
                    context.go('/favourites');
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  child: Text(
                    localisations.goToFavourites,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
