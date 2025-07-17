import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pmtiles/pmtiles.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_map_tiles_pmtiles/vector_map_tiles_pmtiles.dart';
import 'package:weather/data/map_themes.dart';
import 'package:weather/data/weather_alert.dart';
import 'package:weather/widgets/weather_symbol_widget.dart';

class HitValue {
  final WeatherAlert alert;
  final GeoCode? geocode;

  HitValue(this.alert, {this.geocode});
}

class WarningsMapWidget extends StatefulWidget {
  final List<WeatherAlert> weatherAlerts;
  final LayerHitNotifier<HitValue> hitNotifier;
  final Function(bool) onOverlayVisibilityChanged;

  const WarningsMapWidget({
    super.key,
    required this.weatherAlerts,
    required this.hitNotifier,
    required this.onOverlayVisibilityChanged,
  });

  @override
  State<WarningsMapWidget> createState() => _WarningsMapWidgetState();
}

class _WarningsMapWidgetState extends State<WarningsMapWidget> {
  PmTilesVectorTileProvider? _tileProvider;

  @override
  void initState() {
    super.initState();

    if (!kIsWeb && !kIsWasm) {
      // Load PMTiles asset and write to temp file
      rootBundle.load('assets/map/finland-z9.pmtiles').then((asset) async {
        final bytes = asset.buffer.asUint8List();
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/finland-z9.pmtiles');
        await file.writeAsBytes(bytes, flush: true);
        final archive = await PmTilesArchive.fromFile(file);
        setState(() {
          _tileProvider = PmTilesVectorTileProvider.fromArchive(archive);
        });
      });
    }
  }

  Color getColour(WeatherAlertSeverity? severity) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (severity ?? WeatherAlertSeverity.unknown) {
      case WeatherAlertSeverity.minor:
        return Colors.lightGreenAccent.withAlpha(150);
      case WeatherAlertSeverity.moderate:
        return isDark ? Color(0xFFAAAA1F) : Colors.yellowAccent;
      case WeatherAlertSeverity.severe:
        return Color(0xFFDE8D00);
      case WeatherAlertSeverity.extreme:
        return Colors.red.withAlpha(150);
      default:
        return Colors.lightGreen;
    }
  }

  String getAlertSymbol(WeatherAlertType type) {
    switch (type) {
      case WeatherAlertType.hotWeather:
        return 'thermometer-warmer';
      case WeatherAlertType.rain:
        return 'raindrop';
      case WeatherAlertType.seaWind:
      case WeatherAlertType.wind:
        return 'wind-alert';
      case WeatherAlertType.seaWaveHeight:
        return 'flag-small-craft-advisory';
      case WeatherAlertType.uvNote:
        return 'uv-index';
      case WeatherAlertType.forestFireWeather:
        return 'fire';
      case WeatherAlertType.seaThunderstorm:
        return 'lightning-bolt-red';
      case WeatherAlertType.thunderstorm:
        return 'lightning-bolt-red';
      case WeatherAlertType.trafficWeather:
        // TODO: Handle this case.
        throw UnimplementedError();
      case WeatherAlertType.pedestrianSafety:
        // TODO: Handle this case.
        throw UnimplementedError();
      case WeatherAlertType.grassFireWeather:
        return 'fire';
      case WeatherAlertType.coldWeather:
        // TODO: Handle this case.
        throw UnimplementedError();
      case WeatherAlertType.floodLevel:
        // TODO: Handle this case.
        throw UnimplementedError();
      case WeatherAlertType.seaWaterHeightHighWater:
        // TODO: Handle this case.
        throw UnimplementedError();
      case WeatherAlertType.seaWaterHeightShallowWater:
        // TODO: Handle this case.
        throw UnimplementedError();
      case WeatherAlertType.seaIcing:
        // TODO: Handle this case.
        throw UnimplementedError();
      case WeatherAlertType.unknown:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  bool isPointOverlapping(LatLng point, List<LatLng> markerPoints) {
    return markerPoints.any(
        (p) => p.latitude == point.latitude && p.longitude == point.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final List<LatLng> markerPoints =
        []; // Track marker points to avoid overlap

    return FlutterMap(
      options: MapOptions(
        initialCenter: const LatLng(65.0, 25.62),
        initialZoom: 6,
        backgroundColor: Colors.transparent,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.none,
          rotationWinGestures: MultiFingerGesture.none,
          cursorKeyboardRotationOptions:
              CursorKeyboardRotationOptions.disabled(),
        ),
        onMapReady: () {
          if (kDebugMode) {
            print('Map is ready');
          }
        },
      ),
      children: [
        // Use raster layer for web, vector layer for mobile
        if (kIsWeb || kIsWasm)
          TileLayer(
            urlTemplate: 'https://a32.fi/osm/tile/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.sruusk.weather',
            tileSize: 256,
            zoomOffset: 0,
            // Add constraints to prevent NaN/Infinity values
            tileProvider: NetworkTileProvider(),
            maxNativeZoom: 12,
            minNativeZoom: 5,
            keepBuffer: 5,
            errorImage: NetworkImage(
                'https://a32.fi/osm/tile/10/588/282.png'), // Fallback image
          )
        else if (_tileProvider != null)
          Theme.of(context).brightness == Brightness.light
              ? VectorTileLayer(
                  key: const Key('protomaps-light'),
                  tileProviders: TileProviders({
                    'protomaps': _tileProvider!,
                  }),
                  theme: ProtomapsThemes().build(themeMinimalWhite),
                  showTileDebugInfo: false,
                  // Set a custom cache folder, so it doesn't conflict with dark mode layer cache
                  cacheFolder: () {
                    return getTemporaryDirectory().then((dir) {
                      return Directory('${dir.path}/pmtiles_white_v3_warnings');
                    });
                  },
                )
              : VectorTileLayer(
                  key: const Key('protomaps-black'),
                  tileProviders: TileProviders({
                    'protomaps': _tileProvider!,
                  }),
                  theme: ProtomapsThemes().build(themeMinimalBlack),
                  showTileDebugInfo: false,
                  cacheFolder: () {
                    return getTemporaryDirectory().then((dir) {
                      return Directory('${dir.path}/pmtiles_black_v3_warnings');
                    });
                  },
                ),
        MouseRegion(
          hitTestBehavior: HitTestBehavior.deferToChild,
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              final LayerHitResult<HitValue>? result = widget.hitNotifier.value;
              if (result == null) return;

              for (final HitValue hitValue in result.hitValues) {
                if (kDebugMode) {
                  print('Tapped on a ${hitValue.alert.fi.headline}');
                }
              }
              if (kDebugMode) {
                print(
                    'Coords: ${result.coordinate}, Screen Point: ${result.point}');
              }
              widget.onOverlayVisibilityChanged(true);
            },
            child: PolygonLayer(
              hitNotifier: widget.hitNotifier,
              polygons: [
                for (final alert in widget.weatherAlerts)
                  for (final area in alert.areas.where(
                      (area) => area.geocode?.type != GeocodeType.metarea))
                    Polygon(
                      points: area.points
                          .map((point) =>
                              LatLng(point.latitude, point.longitude))
                          .toList(),
                      color: getColour(alert.severity),
                      borderColor: Theme.of(context).colorScheme.onSurface,
                      borderStrokeWidth: 1,
                      hitValue: HitValue(alert, geocode: area.geocode),
                    ),
                for (final alert in widget.weatherAlerts)
                  for (final area in alert.areas.where(
                      (area) => area.geocode?.type == GeocodeType.metarea))
                    Polygon(
                      points: area.points
                          .map((point) =>
                              LatLng(point.latitude, point.longitude))
                          .toList(),
                      color: getColour(alert.severity),
                      borderColor: Theme.of(context).colorScheme.surface,
                      borderStrokeWidth: 1,
                      hitValue: HitValue(alert, geocode: area.geocode),
                    ),
              ],
            ),
          ),
        ),
        MarkerLayer(markers: [
          for (final alert in widget.weatherAlerts)
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
                    useFilled: true,
                    size: 70,
                    symbolName: getAlertSymbol(alert.type),
                  ),
                ),
              );
            }).nonNulls
        ])
      ],
    );
  }
}
