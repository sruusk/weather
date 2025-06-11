import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather/app_state.dart';
import 'package:weather/data/location.dart';
import 'package:weather/widgets/weather_radar_widget.dart';

class WeatherRadarPage extends StatefulWidget {
  const WeatherRadarPage({super.key});

  @override
  State<WeatherRadarPage> createState() => _WeatherRadarPageState();
}

class _WeatherRadarPageState extends State<WeatherRadarPage>
    with AutomaticKeepAliveClientMixin<WeatherRadarPage> {
  late final WeatherRadarController _radarCtrl;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    final Location location = appState.activeLocation ??
        Location(
            lat: 60.1699,
            lon: 24.9384,
            name: 'Helsinki',
            countryCode: 'FI'); // Default to Helsinki if no active location

    _radarCtrl = WeatherRadarController(
      lat: location.lat,
      lng: location.lon,
      initialZoom: 8.0,
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Call super to ensure keep alive works

    // Listen for changes to the active location
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Update radar controller when active location changes
        if (appState.activeLocation != null) {
          final location = appState.activeLocation!;
          _radarCtrl.moveTo(location.lat, location.lon, 8.0);
        }

        return Scaffold(
          body: SafeArea(child: LayoutBuilder(
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
          )),
        );
      },
    );
  }
}
