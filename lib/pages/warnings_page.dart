import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pmtiles/pmtiles.dart';
import 'package:provider/provider.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_map_tiles_pmtiles/vector_map_tiles_pmtiles.dart';
import 'package:weather/app_state.dart';
import 'package:weather/data/constants.dart';
import 'package:weather/data/map_themes.dart';
import 'package:weather/data/weather_alert.dart';
import 'package:weather/data/weather_alerts.dart';
import 'package:weather/widgets/weather_symbol_widget.dart';

class WarningsPage extends StatefulWidget {
  const WarningsPage({super.key});

  @override
  State<WarningsPage> createState() => _WarningsPageState();
}

class _WarningsPageState extends State<WarningsPage> {
  PmTilesVectorTileProvider? _tileProvider;
  DateTime _selectedDate = DateTime.now();
  List<WeatherAlert> _weatherAlerts = [];
  final LayerHitNotifier<HitValue> hitNotifier = ValueNotifier(null);
  bool showOverlay = false;
  List<LatLng> markerPoints = [];
  final launch = DateTime.now().millisecondsSinceEpoch;

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

    // Load weather alerts
    _loadWeatherAlerts();
  }

  void _loadWeatherAlerts() {
    WeatherAlerts.instance().load().then((alerts) {
      setState(() {
        _weatherAlerts = alerts.getAlerts(time: _selectedDate);
      });
    });
  }

  void _updateSelectedDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadWeatherAlerts();
  }

  Widget _buildDaySelector({
    required DateTime date,
    required bool isSelected,
    required double width,
  }) {
    // Get localized day name (Mon, Tue, etc.) using DateFormat
    final appState = Provider.of<AppState>(context, listen: false);
    final dayName = DateFormat.E(appState.locale.languageCode).format(date);

    // Format date using locale-appropriate format for day and month
    final dateStr = DateFormat.Md(appState.locale.languageCode).format(date);

    return GestureDetector(
      onTap: () => _updateSelectedDate(date),
      child: Container(
        width: width,
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: TextStyle(
                fontSize: 14,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color getColour(WeatherAlertSeverity? severity) {
    switch (severity ?? WeatherAlertSeverity.unknown) {
      case WeatherAlertSeverity.minor:
        return Colors.lightGreenAccent.withAlpha(150);
      case WeatherAlertSeverity.moderate:
        return Colors.yellowAccent.withAlpha(150);
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
    final localization = Localizations.localeOf(context);
    markerPoints = []; // Reset marker points on rebuild

    return Builder(builder: (context) {
      return SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            child: SingleChildScrollView(
              child: Column(
                spacing: 10,
                children: [
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 0; i < 5; i++)
                          _buildDaySelector(
                            date: DateTime.now().add(Duration(days: i)),
                            isSelected: DateTime.now()
                                        .add(Duration(days: i))
                                        .day ==
                                    _selectedDate.day &&
                                DateTime.now().add(Duration(days: i)).month ==
                                    _selectedDate.month &&
                                DateTime.now().add(Duration(days: i)).year ==
                                    _selectedDate.year,
                            width: min(constraints.maxWidth / 5 - 15, 100),
                          )
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: min(constraints.maxHeight - 100, 1220),
                      child: FittedBox(
                        child: SizedBox(
                          width: 600,
                          height: 1220,
                          child: Stack(
                            children: [
                              FlutterMap(
                                options: MapOptions(
                                  initialCenter: const LatLng(65.0, 25.62),
                                  initialZoom: 6,
                                  backgroundColor:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  interactionOptions: InteractionOptions(
                                    flags: InteractiveFlag.none,
                                    rotationWinGestures:
                                        MultiFingerGesture.none,
                                    cursorKeyboardRotationOptions:
                                        CursorKeyboardRotationOptions
                                            .disabled(),
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
                                      urlTemplate:
                                          'https://a32.fi/osm/tile/{z}/{x}/{y}.png',
                                      userAgentPackageName:
                                          'com.sruusk.weather',
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
                                    Theme.of(context).brightness ==
                                            Brightness.light
                                        ? VectorTileLayer(
                                            key: const Key('protomaps-light'),
                                            tileProviders: TileProviders({
                                              'protomaps': _tileProvider!,
                                            }),
                                            theme: ProtomapsThemes()
                                                .build(themeMinimalWhite),
                                            showTileDebugInfo: false,
                                            // Set a custom cache folder, so it doesn't conflict with dark mode layer cache
                                            cacheFolder: () {
                                              return getTemporaryDirectory()
                                                  .then((dir) {
                                                return Directory(
                                                    '${dir.path}/pmtiles_white_v3_warnings$launch');
                                              });
                                            },
                                          )
                                        : VectorTileLayer(
                                            key: const Key('protomaps-black'),
                                            tileProviders: TileProviders({
                                              'protomaps': _tileProvider!,
                                            }),
                                            theme: ProtomapsThemes()
                                                .build(themeMinimalBlack),
                                            showTileDebugInfo: false,
                                            cacheFolder: () {
                                              return getTemporaryDirectory()
                                                  .then((dir) {
                                                return Directory(
                                                    '${dir.path}/pmtiles_black_v3_warnings$launch');
                                              });
                                            },
                                          ),
                                  MouseRegion(
                                    hitTestBehavior:
                                        HitTestBehavior.deferToChild,
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () {
                                        final LayerHitResult<HitValue>? result = hitNotifier.value;
                                        if (result == null) return;

                                        for (final HitValue hitValue
                                            in result.hitValues) {
                                          if (kDebugMode) {
                                            print(
                                                'Tapped on a ${hitValue.alert.fi.headline}');
                                          }
                                        }
                                        if (kDebugMode) {
                                          print(
                                              'Coords: ${result.coordinate}, Screen Point: ${result.point}');
                                        }
                                        setState(() {
                                          showOverlay = true;
                                        });
                                      },
                                      child: PolygonLayer(
                                        hitNotifier: hitNotifier,
                                        polygons: [
                                          for (final alert in _weatherAlerts)
                                            for (final area in alert.areas)
                                              Polygon(
                                                points: area.points
                                                    .map((point) => LatLng(
                                                        point.latitude,
                                                        point.longitude))
                                                    .toList(),
                                                color:
                                                    getColour(alert.severity),
                                                borderColor: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                                borderStrokeWidth: 1,
                                                hitValue: HitValue(alert,
                                                    geocode: area.geocode),
                                              ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  MarkerLayer(markers: [
                                    for (final alert in _weatherAlerts)
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
                                        final area = (maxLat - minLat) *
                                            (maxLng - minLng);
                                        // print("Area: $area");
                                        if (area < 1) return null;

                                        var point = LatLng(
                                            (((minLat + maxLat) / 2) +
                                                    (polygon
                                                            .map((point) =>
                                                                point.latitude)
                                                            .reduce((a, b) =>
                                                                a + b) /
                                                        polygon.length)) /
                                                2,
                                            (((minLng + maxLng) / 2) +
                                                    (polygon
                                                            .map((point) =>
                                                                point.longitude)
                                                            .reduce((a, b) =>
                                                                a + b) /
                                                        polygon.length)) /
                                                2);

                                        if (isPointOverlapping(
                                            point, markerPoints)) {
                                          // If point overlaps with existing markers, adjust it slightly
                                          point = LatLng(
                                            point.latitude + 0.15,
                                            point.longitude + 0.35,
                                          );
                                          if (isPointOverlapping(
                                              point, markerPoints)) {
                                            return null;
                                          }
                                          markerPoints.add(point);
                                          return Marker(
                                            point: point,
                                            child: Icon(Icons.add,
                                                color: Colors.grey.shade800),
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
                                              symbolName:
                                                  getAlertSymbol(alert.type),
                                            ),
                                          ),
                                        );
                                      }).nonNulls
                                  ])
                                ],
                              ),
                              if (showOverlay)
                                Builder(builder: (context) {
                                  final LayerHitResult<HitValue>? result =
                                      hitNotifier.value;
                                  final f = DateFormat(
                                      'hh:mm', localization.languageCode);

                                  final List<HitValue> hitValues =
                                      result?.hitValues ?? [];

                                  return Positioned(
                                    top: (result?.point.y ?? 0) - 10,
                                    left: (result?.point.x ?? 0) / 1.5,
                                    width: min(
                                      constraints.maxWidth - 20,
                                      260,
                                    ),
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(0),
                                      ),
                                      elevation: 10,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            color: Colors.yellowAccent,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                if (hitValues
                                                        .firstOrNull?.geocode ==
                                                    null)
                                                  SizedBox.shrink()
                                                else
                                                  switch (hitValues
                                                      .first.geocode!.type) {
                                                    GeocodeType.municipality =>
                                                      Text(
                                                        municipalities[
                                                            int.parse(hitValues
                                                                .first
                                                                .geocode!
                                                                .code)]!,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                              color:
                                                                  Colors.black,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                    GeocodeType.iso3166_2 =>
                                                      Text(
                                                        regions[localization
                                                                .languageCode]![
                                                            hitValues
                                                                .first
                                                                .geocode!
                                                                .code]!,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                              color:
                                                                  Colors.black,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                  },
                                                IconButton(
                                                  icon: Icon(Icons.close),
                                                  onPressed: () {
                                                    setState(() {
                                                      showOverlay = false;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              spacing: 8,
                                              children: [
                                                for (final WeatherAlert alert
                                                    in hitValues
                                                        .map((a) => a.alert))
                                                  RichText(
                                                    text: TextSpan(
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface,
                                                      ),
                                                      children: [
                                                        TextSpan(
                                                          text: alert.fi.event,
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .titleMedium,
                                                        ),
                                                        TextSpan(
                                                            text:
                                                                '\n${DateFormat.Md(localization.languageCode).format(alert.onset)} '
                                                                '${f.format(alert.onset)} - '
                                                                '${DateFormat.Md(localization.languageCode).format(alert.expires)} '
                                                                '${f.format(alert.expires)}',
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyMedium),
                                                      ],
                                                    ),
                                                  )
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        }),
      );
    });
  }
}

class HitValue {
  final WeatherAlert alert;
  final GeoCode? geocode;

  HitValue(this.alert, {this.geocode});
}
