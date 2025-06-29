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
  List<Location> _locations = [];
  Location? _geoLocation;
  bool _isLoading = true;
  bool _isGeolocating = false;
  bool _geolocationTimedOut = false;
  bool _geolocatingFailed = false;

  @override
  void initState() {
    super.initState();
    // Wait until the Provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use a Future to ensure the Provider is ready
      Future.delayed(Duration.zero, () {
        final appState = Provider.of<AppState>(context, listen: false);
        // Add listener for activeLocation changes
        appState.activeLocationNotifier.addListener(_onActiveLocationChanged);
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppState>(context, listen: false);
    final locs = appState.favouriteLocations;
    if (_isLoading) return;
    if (!appState.geolocationEnabled) _geolocatingFailed = false;

    if (locs.length !=
        _locations.length -
            ((appState.geolocationEnabled && !_geolocatingFailed) ? 1 : 0)) {
      if (kDebugMode) {
        print("didChangeDependencies: Reloading forecasts, locations changed");
      }
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

  @override
  void dispose() {
    // Remove the activeLocation listener
    final appState = Provider.of<AppState>(context, listen: false);
    appState.activeLocationNotifier.removeListener(_onActiveLocationChanged);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _loadForecasts() async {
    final appState = Provider.of<AppState>(context, listen: false);

    // If the locations is empty, it might mean that the AppState has not been initialized yet
    // so we wait a bit to ensure it is ready.
    final List<Location>locs = appState.favouriteLocations.isEmpty
        ? await () async {
            await Future.delayed(const Duration(milliseconds: 100));
            return appState.favouriteLocations;
          }()
        : appState.favouriteLocations;

    if (kDebugMode) {
      print(
          "_loadForecasts(), geolocationEnabled: ${appState.geolocationEnabled}, locations: ${locs.length}");
    }

    if (locs.isEmpty && !appState.geolocationEnabled) {
      setState(() {
        _forecast = null;
        _locations = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    // Determine which location to load
    Location? locationToLoad;

    // If geolocation is enabled, try to get current location
    if (appState.geolocationEnabled && _geoLocation != null) {
      locationToLoad = _geoLocation;
    } else if (appState.geolocationEnabled) {
      try {
        setState(() {
          _isGeolocating = true;
        });

        final result =
            await determinePosition().timeout(const Duration(seconds: 10));

        if (result.isSuccess && result.position != null) {
          // Use reverse geocoding to get location information
          locationToLoad = await _weatherData.reverseGeocoding(
            result.position!.latitude,
            result.position!.longitude,
          );
          setState(() {
            _geoLocation = locationToLoad;
            _isGeolocating = false;
            _geolocatingFailed = false;
          });
        } else {
          // Handle geolocation errors
          setState(() {
            _isGeolocating = false;
            _geolocatingFailed = true;
          });

          // Show appropriate error message based on status
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

          // Fall back to first favorite location if available
          if (locs.isNotEmpty) {
            locationToLoad = locs.first;
          }
        }
      } on TimeoutException {
        // Handle timeout specifically
        if (kDebugMode) {
          print('Geolocation timed out, using first favorite location');
        }
        setState(() {
          _isGeolocating = false;
          _geolocationTimedOut = true;
        });
        // If geolocation times out, fall back to first favorite
        if (locs.isNotEmpty) {
          locationToLoad = locs.first;
        }
      } catch (e) {
        // Handle any other exceptions
        if (kDebugMode) {
          print('Geolocation failed, using first favorite location: $e');
        }
        setState(() {
          _isGeolocating = false;
        });
        // If geolocation fails for any reason, fall back to first favorite
        if (locs.isNotEmpty) {
          locationToLoad = locs.first;
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

        // Create a list of all locations (current location + favorites)
        final allLocations = <Location>[];
        if (appState.geolocationEnabled && _geoLocation != null) {
          allLocations.add(activeLocation);
        }
        allLocations.addAll(locs);

        setState(() {
          _forecast = forecast;
          _locations = allLocations;
          _isLoading = false;
          appState.setActiveLocation(activeLocation);
        });
      } catch (e) {
        if (kDebugMode) {
          print('Error getting forecast: $e');
        }
        setState(() {
          _forecast = null;
          _locations = [];
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _forecast = null;
        _locations = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Call super to ensure keep alive works

    Provider.of<AppState>(context);
    final localizations = AppLocalizations.of(context)!;

    if (_geolocationTimedOut) {
      // Show a message if geolocation timed out
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showGlobalSnackBar(
          message: localizations.geolocationTimeout,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
              label: localizations.retry, onPressed: _loadForecasts),
        );
      });
      _geolocationTimedOut = false; // Reset the flag after showing the message
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
            : _forecast == null || _locations.isEmpty
                ? NoLocations()
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            WeatherDetails(
                              forecast: _forecast!,
                              locations: _locations,
                              isLoading: _isLoading,
                              geoLocation: _geoLocation,
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
