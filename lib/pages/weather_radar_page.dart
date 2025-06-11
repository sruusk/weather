import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather/app_state.dart';
import 'package:weather/data/location.dart';
import 'package:weather/l10n/app_localizations.g.dart';
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

    final localizations = AppLocalizations.of(context)!;
    final appState = Provider.of<AppState>(context);

    // Calculate available height (subtract app bar, status bar, navigation bar)
    final mediaQuery = MediaQuery.of(context);
    final availableHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom -
        kToolbarHeight -
        8;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: WeatherRadar(
                controller: _radarCtrl,
                height: availableHeight, // Use full available height
              ),
            ),
          ],
        ),
      ),
    );
  }
}
