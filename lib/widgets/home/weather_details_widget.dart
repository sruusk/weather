import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather/app_state.dart';
import 'package:weather/data/constants.dart';
import 'package:weather/data/forecast.dart';
import 'package:weather/data/location.dart';
import 'package:weather/widgets/home/weather_content_widget.dart';
import 'package:weather/widgets/skeleton/weather_skeleton.dart';
import 'package:weather/widgets/weather_radar_widget.dart';

class WeatherDetails extends StatefulWidget {
  final Forecast forecast;
  final List<Location> locations;
  final bool isLoading;

  const WeatherDetails({
    super.key,
    required this.forecast,
    required this.locations,
    required this.isLoading,
  });

  @override
  State<WeatherDetails> createState() => _WeatherDetailsState();
}

class _WeatherDetailsState extends State<WeatherDetails> {
  late final WeatherRadarController _radarCtrl;
  Timer? _mapReadyCheckTimer;

  // Location change is now handled directly by the LocationDropdown widget

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    final loc = appState.activeLocation ??
        (widget.locations.isNotEmpty
            ? widget.locations[0]
            : Location(
                lat: 0, lon: 0, name: 'Unknown', countryCode: 'Unknown'));
    _radarCtrl = WeatherRadarController(
      lat: loc.lat,
      lng: loc.lon,
      initialZoom: 10.0,
    );
  }

  @override
  void didUpdateWidget(WeatherDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldLoc = oldWidget.forecast.location;
    final newLoc = widget.forecast.location;

    if (newLoc != oldLoc) {
      // Only update radar controller if the new location has radar enabled
      if (radarEnabledCountries.contains(newLoc.countryCode)) {
        if (_radarCtrl.isMapReady) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _radarCtrl.moveTo(newLoc.lat, newLoc.lon, 10.0);
          });
        } else {
          _mapReadyCheckTimer =
              Timer.periodic(const Duration(milliseconds: 100), (timer) {
            if (_radarCtrl.isMapReady) {
              // Map is ready, trigger a movement to ensure proper rendering
              _radarCtrl.moveTo(newLoc.lat, newLoc.lon, 10.0);
              setState(() {});

              // Cancel the timer as we don't need to check anymore
              timer.cancel();
              _mapReadyCheckTimer = null;
            }
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _mapReadyCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show skeleton loading screen if data is loading
    if (widget.isLoading) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 900;
          return WeatherSkeleton(isWideScreen: isWideScreen);
        },
      );
    }

    // Show empty state if no locations are available
    if (widget.locations.isEmpty) {
      return const Card(
        elevation: 4,
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No locations found. Add some in the Favorites tab.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }

    // Use LayoutBuilder to adapt to different screen sizes
    return LayoutBuilder(builder: (builderContext, constraints) {
      final isWideScreen = constraints.maxWidth > 900;

      // Use the extracted WeatherContentWidget to build the content
      return WeatherContentWidget(
        forecast: widget.forecast,
        locations: widget.locations,
        isWideScreen: isWideScreen,
      );
    });
  }
}

