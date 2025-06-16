import 'dart:async';
import 'dart:math' show cos, sin, sqrt, atan2, pi;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
    with AutomaticKeepAliveClientMixin<HomePage> {
  final WeatherData _weatherData = WeatherData();
  Forecast? _forecast;
  List<Location> _locations = [];
  Location? _geoLocation;
  bool _isLoading = true;
  bool _isGeolocating = false;
  bool _geolocationTimedOut = false;
  bool _geolocatingFailed = false;
  int _selectedLocationIndex = 0;

  // Distance threshold in meters - locations closer than this won't trigger a forecast update
  static const double _locationUpdateThreshold = 500.0; // 500 meters

  @override
  void initState() {
    super.initState();
    // Wait until the Provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use a Future to ensure the Provider is ready
      Future.delayed(Duration.zero, () => _loadForecasts());
    });
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
  bool get wantKeepAlive => true;

  /// Calculates the distance between two coordinates in meters
  double _distanceBetweenCoordinates(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371e3; // Earth radius in meters
    final phi1 = lat1 * pi / 180; // φ, λ in radians
    final phi2 = lat2 * pi / 180;
    final deltaPhi = (lat2 - lat1) * pi / 180;
    final deltaLambda = (lon2 - lon1) * pi / 180;

    final a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) *
        sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c; // in meters
  }

  Future<void> _loadForecasts() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final locs = appState.favouriteLocations;

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

    // If geolocation is enabled, try to get location
    if (appState.geolocationEnabled && _geoLocation != null) {
      locationToLoad = _geoLocation;
    } else if (appState.geolocationEnabled) {
      try {
        setState(() {
          _isGeolocating = true;
        });

        // First try to get the last known position
        final lastKnownResult =
            await getLastKnownPosition().timeout(const Duration(seconds: 5));

        late final Location lastKnownLocation;
        bool hasLastKnownLocation = false;

        // If we have a valid last known position, use it first
        if (lastKnownResult.isSuccess && lastKnownResult.position != null) {
          // Use reverse geocoding to get location information for last known position
          lastKnownLocation = await _weatherData.reverseGeocoding(
            lastKnownResult.position!.latitude,
            lastKnownResult.position!.longitude,
          );

          // Update UI with last known location immediately
          setState(() {
            _geoLocation = lastKnownLocation;
            locationToLoad = lastKnownLocation;
            hasLastKnownLocation = true;
            // Don't set _isGeolocating to false yet as we'll try to get current position
          });

          // If we have a last known location, load its forecast immediately
          try {
            final forecast = await _weatherData.getForecast(lastKnownLocation);

            // Create a list of all locations (current location + favorites)
            final allLocations = <Location>[];
            allLocations.add(lastKnownLocation);
            allLocations.addAll(locs);

            if (mounted) {
              setState(() {
                _forecast = forecast;
                _locations = allLocations;
                _isLoading = false; // We have data to show now
                _selectedLocationIndex = 0;
                appState.setActiveLocation(lastKnownLocation!);
              });
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error getting forecast for last known location: $e');
            }
            // We'll continue to try getting current position
          }
                }

        // Now try to get the current position for more accuracy
        final currentResult =
            await determinePosition().timeout(const Duration(seconds: 10));

        if (currentResult.isSuccess && currentResult.position != null) {
          // Check if we need to update based on the distance from last known position
          bool shouldUpdateLocation = true;

          if (hasLastKnownLocation && lastKnownResult.position != null) {
            // Calculate distance between last known and current position
            final distance = _distanceBetweenCoordinates(
              lastKnownResult.position!.latitude,
              lastKnownResult.position!.longitude,
              currentResult.position!.latitude,
              currentResult.position!.longitude
            );

            // Only update if the distance is greater than the threshold
            shouldUpdateLocation = distance > _locationUpdateThreshold;

            if (kDebugMode && !shouldUpdateLocation) {
              print('Current location is close to last known location (${distance.toStringAsFixed(1)}m). Skipping update.');
            }
          }

          if (shouldUpdateLocation) {
            // Use reverse geocoding to get location information for current position
            locationToLoad = await _weatherData.reverseGeocoding(
              currentResult.position!.latitude,
              currentResult.position!.longitude,
            );

            setState(() {
              _geoLocation = locationToLoad;
              _isGeolocating = false;
              _geolocatingFailed = false;
            });
          } else {
            // Just update the state to indicate we're done geolocating
            setState(() {
              _isGeolocating = false;
              _geolocatingFailed = false;
            });

            // If we already loaded the forecast for the last known location,
            // and the current location is close enough, we're done
            if (hasLastKnownLocation && _forecast != null) {
              return;
            }
          }
        } else {
          // Handle geolocation errors
          setState(() {
            _isGeolocating = false;
            _geolocatingFailed = true;
          });

          // If we already have a last known location, we can use that
          if (hasLastKnownLocation && _forecast != null) {
            return;
          }

          // Show appropriate error message based on status
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final localizations = AppLocalizations.of(context)!;
            String errorMessage;

            switch (currentResult.status) {
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
              action: currentResult.status != GeolocationStatus.permissionDeniedForever
                  ? SnackBarAction(
                      label: localizations.retry,
                      onPressed: _loadForecasts,
                    )
                  : null,
            );
          });

          // Fall back to first favorite location if available and we don't have a last known location
          if (!hasLastKnownLocation && locs.isNotEmpty) {
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
        final Location activeLocation = locationToLoad!;

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
          _selectedLocationIndex = 0;
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

    final appState = Provider.of<AppState>(context);
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
                              selectedIndex: _selectedLocationIndex,
                              isLoading: _isLoading,
                              geoLocation: _geoLocation,
                              onLocationChanged: (index) async {
                                setState(() {
                                  _selectedLocationIndex = index;
                                });

                                // Get the location for the selected index
                                final location = _locations[index];
                                appState.setActiveLocation(location);

                                // Load the forecast for the selected location
                                try {
                                  final forecast =
                                      await _weatherData.getForecast(location);

                                  if (mounted) {
                                    setState(() {
                                      // Update the forecast
                                      _forecast = forecast;
                                    });
                                  }
                                } catch (e) {
                                  if (kDebugMode) {
                                    print(
                                        'Error getting selected forecast: $e');
                                  }
                                  if (mounted) {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                }
                              },
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
