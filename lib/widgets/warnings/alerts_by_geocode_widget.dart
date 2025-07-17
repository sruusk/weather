import 'package:flutter/material.dart';
import 'package:weather/data/constants.dart';
import 'package:weather/data/weather_alert.dart';
import 'package:weather/l10n/app_localizations.g.dart';

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

  // Get color based on alert severity
  Color _getSeverityColor(WeatherAlertSeverity severity) {
    switch (severity) {
      case WeatherAlertSeverity.minor:
        return Colors.green;
      case WeatherAlertSeverity.moderate:
        return Colors.yellowAccent;
      case WeatherAlertSeverity.severe:
        return Colors.orange;
      case WeatherAlertSeverity.extreme:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Build alert card
  Widget _buildAlertCard(WeatherAlert alert) {
    // Get the appropriate language based on device locale
    final locale = Localizations.localeOf(context).languageCode;
    WeatherEvent event;

    // Select the appropriate language version
    if (locale == 'sv') {
      event = alert.sv;
    } else if (locale == 'fi') {
      event = alert.fi;
    } else {
      event = alert.en;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _getSeverityColor(alert.severity),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getSeverityColor(alert.severity),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.headline,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              style: const TextStyle(fontSize: 14),
            ),
            if (event.impact != null) ...[
              const SizedBox(height: 8),
              Text(
                event.impact!,
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Get sorted entries of alerts by geocode
  List<MapEntry<String, List<WeatherAlert>>> _getSortedAlertEntries() {
    final sortedEntries = _groupedAlerts.entries.toList();
    sortedEntries.sort((a, b) => _getLocationName(a.key, context)
        .compareTo(_getLocationName(b.key, context)));
    return sortedEntries;
  }

  // Build geocode section
  Widget _buildGeocodeSection(String geocode, List<WeatherAlert> alerts) {
    // Initialize if not already in the map
    _expandedSections.putIfAbsent(geocode, () => false);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Always visible part (location name)
          InkWell(
            onTap: () {
              setState(() {
                // Toggle the expansion state for this section
                _expandedSections[geocode] =
                    !(_expandedSections[geocode] ?? false);
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _getLocationName(geocode, context),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    _expandedSections[geocode] ?? false
                        ? Icons.expand_less
                        : Icons.expand_more,
                  ),
                ],
              ),
            ),
          ),
          // Expandable part (alerts)
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...alerts.map((alert) => _buildAlertCard(alert)),
              ],
            ),
            crossFadeState: (_expandedSections[geocode] ?? false)
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
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
                .map((entry) => _buildGeocodeSection(entry.key, entry.value)),
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
