import 'dart:async';

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
  int _selectedLocationIndex = 0;

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

    if (locs.length !=
        _locations.length -
            ((appState.geolocationEnabled && _geoLocation != null) ? 1 : 0)) {
      // If the number of locations has changed, reload forecasts
      _loadForecasts();
    }
  }

  @override
  bool get wantKeepAlive => true;

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

    // If geolocation is enabled, try to get current location
    if (appState.geolocationEnabled && _geoLocation != null) {
      locationToLoad = _geoLocation;
    } else if (appState.geolocationEnabled) {
      try {
        setState(() {
          _isGeolocating = true;
        });
        final pos =
            await determinePosition().timeout(const Duration(seconds: 10));
        // Use reverse geocoding to get location information
        locationToLoad = await _weatherData.reverseGeocoding(
          pos.latitude,
          pos.longitude,
        );
        setState(() {
          _geoLocation = locationToLoad;
          _isGeolocating = false;
        });
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(localizations.geolocationTimeout),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                  label: localizations.retry, onPressed: _loadForecasts)),
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
