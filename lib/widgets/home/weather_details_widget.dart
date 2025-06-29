import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather/app_state.dart';
import 'package:weather/data/constants.dart';
import 'package:weather/data/forecast.dart';
import 'package:weather/data/location.dart';
import 'package:weather/l10n/app_localizations.g.dart';
import 'package:weather/widgets/home/current_forecast_widget.dart';
import 'package:weather/widgets/home/warnings_widget.dart';
import 'package:weather/widgets/weather_radar_widget.dart';

import 'forecast_widget.dart';
import 'observations_widget.dart';

class WeatherDetails extends StatefulWidget {
  final Forecast forecast;
  final List<Location> locations;
  final bool isLoading;
  final Location? geoLocation;

  const WeatherDetails({
    super.key,
    required this.forecast,
    required this.locations,
    required this.isLoading,
    this.geoLocation,
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
    if (widget.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (widget.locations.isEmpty) {
      return Card(
        elevation: 4,
        margin: const EdgeInsets.all(16),
        child: const Padding(
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

    return LayoutBuilder(builder: (builderContext, constraints) {
      final children = _buildChildren(builderContext, constraints);
      if (constraints.maxWidth > 900) {
        return Wrap(
          children: children.map((child) {
            final isObservations = child.key == Key('observations');
            return SizedBox(
              width: isObservations ? constraints.maxWidth : constraints.maxWidth / 2,
              child: child,
            );
          }).toList(),
        );
      } else {
        return Column(
          children: [...children, SizedBox(height: 8)],
        );
      }
    });
  }

  List<Widget> _buildChildren(
      BuildContext context, BoxConstraints constraints) {
    final localizations = AppLocalizations.of(context)!;
    final appState = Provider.of<AppState>(context);

    final loc = appState.activeLocation;
    final f = widget.forecast;
    final countryCode = loc?.countryCode;

    // Create a list of widgets to return
    final List<Widget> children = [
      ChildCardWidget(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // const SizedBox(height: 10),
          CurrentForecast(
            forecast: f,
            locations: widget.locations,
            geoLocation: widget.geoLocation,
            height: constraints.maxWidth > 900 ? 335 : 300,
          ),
        ],
      )),
      if (observationsEnabledCountries.contains(countryCode) &&
          constraints.maxWidth < 900)
        ChildCardWidget(child: WeatherWarnings(location: f.location)),
      ChildCardWidget(child: ForecastWidget(forecast: f)),
/*      if (radarEnabledCountries.contains(countryCode))
        ChildCardWidget(
          padding:
              EdgeInsetsGeometry.only(top: 16, left: 10, right: 10, bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(localizations.radar,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              WeatherRadar(controller: _radarCtrl, flags: InteractiveFlag.none),
            ],
          ),
        ),*/
      if (observationsEnabledCountries.contains(countryCode))
        ChildCardWidget(
          key: Key('observations'),
          padding: EdgeInsetsGeometry.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(localizations.observations,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Transform.translate(
                offset: const Offset(0, -15),
                child: ObservationsWidget(location: loc),
              )
            ],
          ),
        )
    ];

    return children;
  }
}

class ChildCardWidget extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  const ChildCardWidget({
    super.key,
    required this.child,
    this.margin = const EdgeInsetsGeometry.only(top: 8, left: 8, right: 8),
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      // shape: RoundedRectangleBorder(
      //   borderRadius: BorderRadius.zero,
      // ),
      margin: margin,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
