import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:weather/data/weather_alert.dart';
import 'package:weather/widgets/weather_symbol_widget.dart';

class AlertMarkerWidget extends StatelessWidget {
  final List<WeatherAlert> weatherAlerts;

  const AlertMarkerWidget({
    super.key,
    required this.weatherAlerts,
  });

  bool isPointOverlapping(LatLng point, List<LatLng> markerPoints) {
    return markerPoints.any(
        (p) => p.latitude == point.latitude && p.longitude == point.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final List<LatLng> markerPoints = []; // Track marker points to avoid overlap

    return MarkerLayer(markers: [
      for (final alert in weatherAlerts)
        ...alert.areas.map((Area alertArea) {
          final polygon = alertArea.points;
          final minLat = polygon
              .map((point) => point.latitude)
              .reduce((a, b) => min(a, b));
          final maxLat = polygon
              .map((point) => point.latitude)
              .reduce((a, b) => max(a, b));
          final minLng = polygon
              .map((point) => point.longitude)
              .reduce((a, b) => min(a, b));
          final maxLng = polygon
              .map((point) => point.longitude)
              .reduce((a, b) => max(a, b));

          // Calculate an approximate surface area and
          // use it to hide the marker if the area is too small
          // This is done to avoid overlapping markers
          // with multiple polygons
          final area = (maxLat - minLat) * (maxLng - minLng);
          if (area < 1) return null;

          var point = LatLng(
              (((minLat + maxLat) / 2) +
                      (polygon
                              .map((point) => point.latitude)
                              .reduce((a, b) => a + b) /
                          polygon.length)) /
                  2,
              (((minLng + maxLng) / 2) +
                      (polygon
                              .map((point) => point.longitude)
                              .reduce((a, b) => a + b) /
                          polygon.length)) /
                  2);

          // Reposition specific marker to avoid overlap
          if (['B2', 'B1S'].contains(alertArea.geocode?.code ?? '')) {
            point = LatLng(
              point.latitude + 0.2,
              point.longitude - 0.4,
            );
          }

          if (isPointOverlapping(point, markerPoints)) {
            // If point overlaps with existing markers, adjust it slightly
            point = LatLng(
              point.latitude + 0.15,
              point.longitude + 0.35,
            );
            if (isPointOverlapping(point, markerPoints)) {
              return null;
            }
            markerPoints.add(point);
            return Marker(
              point: point,
              child: Icon(Icons.add, color: Colors.grey.shade800),
            );
          }

          markerPoints.add(point);

          return Marker(
            width: 0,
            height: 0,
            point: point,
            child: UnconstrainedBox(
              child: WeatherSymbolWidget(
                filled: true,
                static: true,
                size: 70,
                symbolName: alert.getAlertSymbol(),
              ),
            ),
          );
        }).nonNulls
    ]);
  }
}
