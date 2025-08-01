import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:weather/data/weather_alert.dart';
import 'package:weather/widgets/warnings/warnings_map_widget.dart';

class PolygonLayerWidget extends StatelessWidget {
  final List<WeatherAlert> weatherAlerts;
  final LayerHitNotifier<HitValue> hitNotifier;
  final Function(bool) onOverlayVisibilityChanged;

  const PolygonLayerWidget({
    super.key,
    required this.weatherAlerts,
    required this.hitNotifier,
    required this.onOverlayVisibilityChanged,
  });

  Color getColour(WeatherAlertSeverity? severity, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (severity ?? WeatherAlertSeverity.unknown) {
      case WeatherAlertSeverity.minor:
        return Color(0xFF2AC02A);
      case WeatherAlertSeverity.moderate:
        return isDark ? Color(0xFFBFAF1F) : Colors.yellowAccent.shade700;
      case WeatherAlertSeverity.severe:
        return isDark ? Color(0xFFDE8D00) : Colors.orangeAccent.shade400;
      case WeatherAlertSeverity.extreme:
        return Colors.red.withAlpha(150);
      default:
        return Colors.lightGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      hitTestBehavior: HitTestBehavior.deferToChild,
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          final LayerHitResult<HitValue>? result = hitNotifier.value;
          if (result == null) return;

          onOverlayVisibilityChanged(true);
        },
        child: PolygonLayer(
          hitNotifier: hitNotifier,
          polygons: [
            for (final alert in weatherAlerts)
              for (final area in alert.areas.where(
                  (area) => area.geocode?.type != GeocodeType.metarea))
                Polygon(
                  points: area.points
                      .map((point) =>
                          LatLng(point.latitude, point.longitude))
                      .toList(),
                  color: getColour(alert.severity, context),
                  borderColor: Theme.of(context).colorScheme.onSurface,
                  borderStrokeWidth: 1,
                  hitValue: HitValue(alert, geocode: area.geocode),
                ),
            for (final alert in weatherAlerts)
              for (final area in alert.areas.where(
                  (area) => area.geocode?.type == GeocodeType.metarea))
                Polygon(
                  points: area.points
                      .map((point) =>
                          LatLng(point.latitude, point.longitude))
                      .toList(),
                  color: getColour(alert.severity, context),
                  borderColor: Theme.of(context).colorScheme.surface,
                  borderStrokeWidth: 1,
                  hitValue: HitValue(alert, geocode: area.geocode),
                ),
          ],
        ),
      ),
    );
  }
}
