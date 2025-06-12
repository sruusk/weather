import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather/app_state.dart';
import 'package:weather/data/constants.dart';
import 'package:weather/data/location.dart';
import 'package:weather/widgets/weather_radar_widget.dart';

const Location defaultLocation =
    Location(lat: 60.1699, lon: 24.9384, name: 'Helsinki', countryCode: 'FI');

class WeatherRadarPage extends StatefulWidget {
  const WeatherRadarPage({super.key});

  @override
  State<WeatherRadarPage> createState() => _WeatherRadarPageState();
}

class _WeatherRadarPageState extends State<WeatherRadarPage>
    with AutomaticKeepAliveClientMixin<WeatherRadarPage> {
  late final WeatherRadarController _radarCtrl;
  Location? _currentLocation;
  Timer? _mapReadyCheckTimer;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    Location location = appState.activeLocation ??
        defaultLocation; // Default to Helsinki if no active location

    if (!radarEnabledCountries.contains(location.countryCode)) {
      location = defaultLocation; // Fallback to default if radar not enabled
    }

    _radarCtrl = WeatherRadarController(
      lat: location.lat,
      lng: location.lon,
      initialZoom: 10,
    );

    // Start a timer to check if the map is ready
    _startMapReadyCheck();
  }

  void _startMapReadyCheck() {
    // Check every 100ms if the map is ready
    _mapReadyCheckTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_radarCtrl.isMapReady) {
        // Map is ready, trigger a movement to ensure proper rendering
        _radarCtrl.moveTo(_radarCtrl.currentCenter.latitude,
            _radarCtrl.currentCenter.longitude, _radarCtrl.initialZoom);

        // Cancel the timer as we don't need to check anymore
        timer.cancel();
        _mapReadyCheckTimer = null;
      }
    });
  }

  @override
  void dispose() {
    _mapReadyCheckTimer?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Call super to ensure keep alive works

    AppState appState = Provider.of<AppState>(context);

    // Update radar controller when active location changes
    if (appState.activeLocation != null &&
        _currentLocation != appState.activeLocation &&
        radarEnabledCountries.contains(appState.activeLocation!.countryCode)) {
      final location = appState.activeLocation!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _radarCtrl.moveTo(location.lat, location.lon, 10.0);
        setState(() {
          _currentLocation = location;
        });
      });
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              WeatherRadar(
                controller: _radarCtrl,
                height: constraints.maxHeight, // Use full available height
              ),
            ],
          );
        },
      ),
    );
  }
}
