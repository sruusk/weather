import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin<HomePage> {
  final WeatherData _weatherData = WeatherData();
  Forecast? _forecast;
  List<Location> _locations = [];
  bool _isLoading = true;
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
    // _loadForecasts();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _loadForecasts() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final locs = appState.favouriteLocations;

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
    if (appState.geolocationEnabled) {
      try {
        final pos = await determinePosition();
        // Use reverse geocoding to get location information
        locationToLoad = await _weatherData.reverseGeocoding(
          pos.latitude,
          pos.longitude,
        );
      } catch (e) {
        if (kDebugMode) {
          print('Error getting current location: $e');
        }
        // If geolocation fails, fall back to first favorite
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
        if (appState.geolocationEnabled) {
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

    return Scaffold(
      appBar: _forecast == null || _locations.isEmpty
          ? AppBar(
              title: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            )
          : null,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _forecast == null || _locations.isEmpty
                ? Center(
                    child: Text(AppLocalizations.of(context)!.noSavedLocations))
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
                              onLocationChanged: (index) async {
                                setState(() {
                                  _selectedLocationIndex = index;
                                  _isLoading = true;
                                });

                                // Get the location for the selected index
                                final location = _locations[index];
                                appState.setActiveLocation(location);

                                // Load the forecast for the selected location
                                try {
                                  final forecast = await _weatherData.getForecast(location);

                                  if (mounted) {
                                    setState(() {
                                      // Update the forecast
                                      _forecast = forecast;
                                      _isLoading = false;
                                    });
                                  }
                                } catch (e) {
                                  if (kDebugMode) {
                                    print('Error getting forecast: $e');
                                  }
                                  if (mounted) {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                }
                              },
                            ),
                            Positioned(
                              top: 10,
                              left: 10,
                              child: IconButton(
                                icon: const Icon(Icons.menu),
                                onPressed: () {
                                  Scaffold.of(context).openDrawer();
                                },
                              )
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
