import 'dart:math';

import 'package:flutter/material.dart';
import 'package:weather/data/constants.dart';
import 'package:weather/data/weather_alert.dart';
import 'package:weather/data/weather_alerts.dart';
import 'package:weather/widgets/warnings/warnings_map_widget.dart';

class AlertOverlayCardWidget extends StatelessWidget {
  final dynamic hitResult;
  final String languageCode;
  final Map<int, String> municipalities;
  final double maxWidth;
  final double parentHeight;
  final VoidCallback onClose;
  final double mapRenderHeight;
  final double mapRenderWidth;

  const AlertOverlayCardWidget({
    super.key,
    required this.hitResult,
    required this.languageCode,
    required this.municipalities,
    required this.maxWidth,
    required this.parentHeight,
    required this.onClose,
    required this.mapRenderHeight,
    required this.mapRenderWidth,
  });

  Color _getSeverityColor(List<HitValue> severity) {
    switch (WeatherAlerts.sortSeverities(
        severity.map((hit) => hit.alert.severity).toList())) {
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

  String? _getLocationName(String geocode, BuildContext context) {
    final localization = Localizations.localeOf(context);

    return municipalities[int.tryParse(geocode)] ??
        seaRegions[localization.languageCode]?[geocode] ??
        regions[localization.languageCode]?[geocode];
  }

  @override
  Widget build(BuildContext context) {
    final List<HitValue> hitValues = hitResult?.hitValues ?? [];

    if (hitValues.isEmpty) {
      return SizedBox.shrink();
    }

    // If opened too low, move the overlay up
    // to avoid overflowing/clipping
    double top = (hitResult?.point.y ?? 0);

    // Scale the top to match the map scaling
    top *= (parentHeight / mapRenderHeight);

    final double expectedHeight = hitValues.length * 90 + 80;
    if (top > parentHeight - expectedHeight) {
      top = parentHeight - expectedHeight;
    }

    final double width = min(maxWidth - 20, 300);

    // Scale the left position to match the map scaling
    double left = (hitResult?.point.x ?? 0) / 2;
    if (maxWidth < mapRenderWidth) left *= (maxWidth / mapRenderWidth);
    if (left + width > maxWidth) left = maxWidth - width;

    final locationName = hitValues
        .map((hit) => _getLocationName(hit.geocode?.code ?? '', context))
        .nonNulls
        .first;

    return Positioned(
      top: top,
      left: left,
      width: width,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),
        elevation: 10,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: _getSeverityColor(
                hitValues,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (hitValues.firstOrNull?.geocode == null)
                    SizedBox.shrink()
                  else
                    Text(
                      locationName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.black),
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            for (final hitValue in hitValues)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageCode == 'fi'
                          ? hitValue.alert.fi.event
                          : hitValue.alert.en.event,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 4),
                    Text(
                      languageCode == 'fi'
                          ? hitValue.alert.fi.headline
                          : hitValue.alert.en.headline,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
