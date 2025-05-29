import 'package:flutter/material.dart';
import 'package:weather/data/forecast.dart';
import 'package:weather/data/location.dart';
import 'package:weather/l10n/app_localizations.g.dart';
import 'package:weather/widgets/home/current_forecast_widget.dart';
import 'package:weather/widgets/home/warnings_widget.dart';
import 'package:weather/widgets/home/weather_radar_widget.dart';

import 'forecast_widget.dart';
import 'observations_widget.dart';

class WeatherDetails extends StatefulWidget {
  final Forecast forecast;
  final List<Location> locations;
  final int selectedIndex;
  final bool isLoading;
  final Function(int)? onLocationChanged;

  const WeatherDetails({
    super.key,
    required this.forecast,
    required this.locations,
    required this.selectedIndex,
    required this.isLoading,
    this.onLocationChanged,
  });

  @override
  State<WeatherDetails> createState() => _WeatherDetailsState();
}

class _WeatherDetailsState extends State<WeatherDetails> {
  late final WeatherRadarController _radarCtrl;

  // Arrays of country codes that define if radar and observations should be shown
  final List<String> _radarEnabledCountries = ['FI', 'AX']; // Finland and Åland Islands
  final List<String> _observationsEnabledCountries = ['FI', 'AX'];

  void _handleLocationChanged(int index) {
    if (widget.selectedIndex != index) {
      // We need to notify the parent (HomePage) about the change
      // This is done through a callback that we'll add to the WeatherDetails widget
      if (widget.onLocationChanged != null) {
        widget.onLocationChanged!(index);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final loc = widget.locations.isNotEmpty
        ? widget.locations[widget.selectedIndex]
        : Location(lat: 0, lon: 0, name: 'Unknown', countryCode: 'Unknown');
    _radarCtrl = WeatherRadarController(
      lat: loc.lat,
      lng: loc.lon,
      initialZoom: 10.0,
    );
  }

  @override
  void didUpdateWidget(covariant WeatherDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldLoc = oldWidget.locations.isNotEmpty
        ? oldWidget.locations[oldWidget.selectedIndex]
        : null;
    final newLoc = widget.locations.isNotEmpty
        ? widget.locations[widget.selectedIndex]
        : null;

    if (newLoc != null && newLoc != oldLoc) {
      // Only update radar controller if the new location has radar enabled
      if (_radarEnabledCountries.contains(newLoc.countryCode)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _radarCtrl.moveTo(newLoc.lat, newLoc.lon, 10.0);
        });
      }
    }
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
            return SizedBox(
              width: constraints.maxWidth / 2,
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

  List<Widget> _buildChildren(BuildContext context, BoxConstraints constraints) {
    final localizations = AppLocalizations.of(context)!;

    final loc = widget.locations[widget.selectedIndex];
    final f = widget.forecast;
    final countryCode = loc.countryCode;

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
            selectedIndex: widget.selectedIndex,
            onLocationChanged: _handleLocationChanged,
          ),
        ],
      )),
      if(_radarEnabledCountries.contains(countryCode) && constraints.maxWidth < 900)
        ChildCardWidget(child: WeatherWarnings(location: f.location)),

      ChildCardWidget(child: ForecastWidget(forecast: f)),
      if(_radarEnabledCountries.contains(countryCode))
        ChildCardWidget(
          padding: EdgeInsetsGeometry.only(top: 16, left: 16, right: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(localizations.radar,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              WeatherRadarWidget(controller: _radarCtrl),
            ],
          ),
        ),
      if(_observationsEnabledCountries.contains(countryCode))
        ChildCardWidget(
          padding: EdgeInsetsGeometry.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(localizations.observations,
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
