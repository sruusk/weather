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
  bool _isLoading = true;
  bool _isGeolocating = false;
  int _prevFavouriteLocationsLength = 0;

  @override
  void initState() {
    super.initState();
    // Wait until the Provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use a Future to ensure the Provider is ready
      Future.delayed(Duration.zero, () {
        if (!mounted) return; // Ensure widget is still mounted
        final appState = Provider.of<AppState>(context, listen: false);
        // Add listeners for activeLocation, geolocation, and favouriteLocations
        appState.activeLocationNotifier.addListener(_onActiveLocationChanged);
        appState.geolocationEnabledNotifier
            .addListener(_onGeolocationEnabledChanged);
        appState.favouriteLocationsNotifier
            .addListener(_onFavouriteLocationsChanged);
        _loadForecasts();
      });
    });
  }

  void _onActiveLocationChanged() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.activeLocation != null && mounted) {
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
    _loadForecasts();
  }

  void _onFavouriteLocationsChanged() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (_isLoading) return;

    if (appState.favouriteLocations.length  != _prevFavouriteLocationsLength) {
      if (kDebugMode) {
        print("Favourite locations changed, reloading forecasts (on change)");
      }
      _prevFavouriteLocationsLength = appState.favouriteLocations.length;
      _loadForecasts();
    }
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
        _loadForecasts();
      }
      WidgetsBinding.instance.removeObserver(this);
    }
  }

  void _handleGeolocationError(GeolocationResult result) {
    final appState = Provider.of<AppState>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localizations = AppLocalizations.of(context)!;
      String errorMessage;

      switch (result.status) {
        case GeolocationStatus.locationServicesDisabled:
          errorMessage = localizations.locationServicesDisabled;
          break;
        case GeolocationStatus.permissionDenied:
          errorMessage = localizations.locationPermissionDenied;
          break;
        case GeolocationStatus.permissionDeniedForever:
        // For permanently denied permissions, also disable geolocation in app state
          appState.setGeolocationEnabled(false);
          errorMessage =
              localizations.locationPermissionPermanentlyDenied;
          break;
        default:
          errorMessage = localizations.unknownError;
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
          onPressed: _loadForecasts,
        ),
      );
    });
  }

  void _startGeolocation() async {
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      setState(() {
        _isGeolocating = true;
      });

      final result =
      await determinePosition().timeout(const Duration(seconds: 10));

      if (result.isSuccess && result.position != null) {
        // Use reverse geocoding to get location information
        final geolocation = await _weatherData.reverseGeocoding(
          result.position!.latitude,
          result.position!.longitude,
        );
        setState(() {
          _isGeolocating = false;
        });
        // Update the forecast if new location more than 500 different
        if(appState.geoLocation == null ||
            appState.geoLocation!.distanceTo(geolocation) > 500) {
          _weatherData.getForecast(geolocation).then((forecast) {
            if (mounted) {
              setState(() {
                _forecast = forecast;
              });
            }
          }).catchError((e) {
            if (kDebugMode) {
              print('Error getting forecast for geolocation: $e');
            }
          });
        }
        appState.setGeolocation(geolocation);
      } else {
        // Handle geolocation errors
        setState(() {
          _isGeolocating = false;
        });
        appState.setGeolocation(null);

        _handleGeolocationError(result);
      }
    } on TimeoutException {
      // Handle timeout specifically
      if (kDebugMode) {
        print('Geolocation timed out, using first favorite location');
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final localizations = AppLocalizations.of(context)!;
        showGlobalSnackBar(
          message: localizations.geolocationTimeout,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
              label: localizations.retry, onPressed: _loadForecasts),
        );
      });

      setState(() {
        _isGeolocating = false;
      });
    } catch (e) {
      // Handle any other exceptions
      if (kDebugMode) {
        print('Geolocation failed, using first favorite location: $e');
      }
      setState(() {
        _isGeolocating = false;
      });
    }
  }

  @override
  void dispose() {
    // Remove listeners
    final appState = Provider.of<AppState>(context, listen: false);
    appState.activeLocationNotifier.removeListener(_onActiveLocationChanged);
    appState.geoLocationNotifier.removeListener(_onGeolocationEnabledChanged);
    appState.favouriteLocationsNotifier
        .removeListener(_onFavouriteLocationsChanged);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _loadForecasts() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final List<Location>locs = appState.favouriteLocations;

    if (kDebugMode) {
      print(
          "_loadForecasts(), geolocationEnabled: ${appState.geolocationEnabled}, locations: ${locs.length}");
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
    if (appState.geolocationEnabled && appState.geoLocation != null) {
      locationToLoad = appState.geoLocation;
    } else if (appState.geolocationEnabled) {
      final result = await getLastKnownPosition();
      if(result.isSuccess && result.position != null) {
        // Use reverse geocoding to get location information
        final geolocation = await _weatherData.reverseGeocoding(
          result.position!.latitude,
          result.position!.longitude,
        );
        appState.setGeolocation(geolocation);
        locationToLoad = geolocation;
        _startGeolocation();
      } else {
        // Handle geolocation errors
        _handleGeolocationError(result);
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
    } else {
      setState(() {
        _forecast = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Call super to ensure keep alive works

    final appState = Provider.of<AppState>(context);
    final localizations = AppLocalizations.of(context)!;

    List<Location> locations = appState.geoLocation != null
        ? [appState.geoLocation!, ...appState.favouriteLocations]
        : appState.favouriteLocations;

    if(appState.favouriteLocations.length != _prevFavouriteLocationsLength) {
      _prevFavouriteLocationsLength = appState.favouriteLocations.length;
      if (kDebugMode) {
        print("Favourite locations changed, reloading forecasts (build)");
      }
      _loadForecasts();
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
                    _isGeolocating
                        ? localizations.locating
                        : localizations.loadingForecasts,
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
