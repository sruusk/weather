import 'package:flutter/material.dart';
import 'package:weather/data/constants.dart';
import 'package:weather/data/weather_alert.dart';
import 'package:weather/l10n/app_localizations.g.dart';
import 'package:weather/widgets/warnings/geocode_section_widget.dart';

class AlertsByGeocodeWidget extends StatefulWidget {
  final List<WeatherAlert> alerts;

  const AlertsByGeocodeWidget({
    super.key,
    required this.alerts,
  });

  @override
  State<AlertsByGeocodeWidget> createState() => _AlertsByGeocodeWidgetState();
}

class _AlertsByGeocodeWidgetState extends State<AlertsByGeocodeWidget> {
  // Map to store grouped alerts by geocode
  Map<String, List<WeatherAlert>> _groupedAlerts = {};

  // Map to track expansion state of each geocode section
  final Map<String, bool> _expandedSections = {};

  @override
  void initState() {
    super.initState();
    _groupAlertsByGeocode();
  }

  @override
  void didUpdateWidget(AlertsByGeocodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Regroup alerts if the list changes
    if (widget.alerts != oldWidget.alerts) {
      _groupAlertsByGeocode();
    }
  }

  // Group alerts by geocode
  void _groupAlertsByGeocode() {
    // Clear previous groupings
    _groupedAlerts = {};

    // Create a set of all unique geocodes
    Set<String> geocodes = {};
    for (var alert in widget.alerts) {
      for (var area in alert.areas) {
        if (area.geocode != null) {
          geocodes.add(area.geocode!.code);
        }
      }
    }

    // Group alerts by geocode
    for (var geocode in geocodes) {
      List<WeatherAlert> alertsForGeocode = [];

      for (var alert in widget.alerts) {
        // Check if any area in this alert has the current geocode
        bool hasGeocode = alert.areas.any(
            (area) => area.geocode != null && area.geocode!.code == geocode);

        if (hasGeocode) {
          alertsForGeocode.add(alert);
        }
      }

      if (alertsForGeocode.isNotEmpty) {
        _groupedAlerts[geocode] = alertsForGeocode;
      }
    }

    setState(() {});
  }

  // Get sorted entries of alerts by geocode
  List<MapEntry<String, List<WeatherAlert>>> _getSortedAlertEntries() {
    final sortedEntries = _groupedAlerts.entries.toList();
    sortedEntries.sort((a, b) => _getLocationName(a.key, context)
        .compareTo(_getLocationName(b.key, context)));
    return sortedEntries;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if (widget.alerts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            localizations.noActiveAlerts,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              localizations.activeWeatherAlerts,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_groupedAlerts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else
            ..._getSortedAlertEntries()
                .map((entry) => GeocodeSectionWidget(
                      geocode: entry.key,
                      alerts: entry.value,
                      initiallyExpanded: _expandedSections[entry.key] ?? false,
                    )),
        ],
      ),
    );
  }
}

String _getLocationName(String geocode, BuildContext context) {
  final localization = Localizations.localeOf(context);

  return municipalities[int.tryParse(geocode)] ??
      seaRegions[localization.languageCode]?[geocode] ??
      regions[localization.languageCode]?[geocode] ??
      geocode;
}
