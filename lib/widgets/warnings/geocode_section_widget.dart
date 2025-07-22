import 'package:flutter/material.dart';
import 'package:weather/data/constants.dart';
import 'package:weather/data/weather_alert.dart';
import 'package:weather/widgets/warnings/alert_card_widget.dart';
import 'package:weather/widgets/weather_symbol_widget.dart';

class GeocodeSectionWidget extends StatefulWidget {
  final String geocode;
  final List<WeatherAlert> alerts;
  final bool initiallyExpanded;

  const GeocodeSectionWidget({
    super.key,
    required this.geocode,
    required this.alerts,
    this.initiallyExpanded = false,
  });

  @override
  State<GeocodeSectionWidget> createState() => _GeocodeSectionWidgetState();
}

class _GeocodeSectionWidgetState extends State<GeocodeSectionWidget> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  String? _getLocationName(String geocode, BuildContext context) {
    final localization = Localizations.localeOf(context);

    return municipalities[int.tryParse(geocode)] ??
        seaRegions[localization.languageCode]?[geocode] ??
        regions[localization.languageCode]?[geocode];
  }

  Color getSeverityColor(WeatherAlertSeverity? severity) {
    switch (severity ?? WeatherAlertSeverity.unknown) {
      case WeatherAlertSeverity.minor:
        return Colors.lightGreenAccent;
      case WeatherAlertSeverity.moderate:
        return Colors.yellowAccent;
      case WeatherAlertSeverity.severe:
        return Colors.orange;
      case WeatherAlertSeverity.extreme:
        return Colors.red;
      default:
        return Colors.lightGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationName = _getLocationName(widget.geocode, context);
    if (locationName == null || widget.alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Always visible part (location name)
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      locationName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    spacing: 10,
                    children: [
                      ...widget.alerts.map((alert) => SizedOverflowBox(
                        size: const Size(30, 25),
                        child: Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: getSeverityColor(alert.severity),
                              width: 2,
                            ),
                          ),
                          child: WeatherSymbolWidget(
                            useFilled: true,
                            size: 40,
                            symbolName: alert.getAlertSymbol(),
                          ),
                        ),
                      )),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                      ),
                    ],
                  )
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
                ...widget.alerts.map((alert) => AlertCardWidget(alert: alert)),
              ],
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
