import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pmtiles/pmtiles.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_map_tiles_pmtiles/vector_map_tiles_pmtiles.dart';

class WeatherRadarWidget extends StatefulWidget {
  final WeatherRadarController controller;
  final double? height;

  const WeatherRadarWidget({
    super.key,
    required this.controller,
    this.height = 350,
  });

  @override
  State<WeatherRadarWidget> createState() => _WeatherRadarWidgetState();
}

class _WeatherRadarWidgetState extends State<WeatherRadarWidget> {
  late final Future<PmTilesVectorTileProvider?> _tileProviderFuture;
  late DateTime _currentTime;
  double _sliderValue =
      5; // 5 represents the latest time, 0 represents 75 minutes ago
  bool _isPlaying = false;
  Timer? _timer;
  bool _isMapInitialized = false;

  @override
  void initState() {
    super.initState();
    _currentTime = getTime();
    _tileProviderFuture = () async {
      if (kIsWeb || kIsWasm) {
        return null;
      } else {
        // Load PMTiles asset and write to temp file
        final asset = await rootBundle.load('assets/map/finland-z9.pmtiles');
        final bytes = asset.buffer.asUint8List();
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/finland-z9.pmtiles');
        await file.writeAsBytes(bytes, flush: true);
        final archive = await PmTilesArchive.fromFile(file);
        return PmTilesVectorTileProvider.fromArchive(archive);
      }
    }();
  }

  @override
  void dispose() {
    _stopAutoPlay();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _startAutoPlay();
      } else {
        _stopAutoPlay();
      }
    });
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      // Decrement slider value to show older data
      double newValue = _sliderValue + 1;
      // Loop back to 5 when we reach 0
      if (newValue > 5) {
        newValue = 0;
      }
      _updateTime(newValue, fromAutoPlay: true);
    });
  }

  void _stopAutoPlay() {
    _timer?.cancel();
    _timer = null;
  }

  // Update time based on slider value
  void _updateTime(double value, {bool fromAutoPlay = false}) {
    // Stop auto-play if user manually changes the slider (but not if change is from auto-play)
    if (_isPlaying && value != _sliderValue && !fromAutoPlay) {
      _stopAutoPlay();
      _isPlaying = false;
    }

    setState(() {
      _sliderValue = value;
      // Calculate time based on inverted slider value (each step is 15 minutes)
      // 5 is latest time (0 minutes ago), 0 is oldest time (75 minutes ago)
      final minutesToSubtract = (5 - value.toInt()) * 15;

      try {
        // Get the base time and subtract the minutes
        final baseTime = getTime();
        _currentTime = baseTime.subtract(Duration(minutes: minutesToSubtract));
      } catch (e) {
        // Fallback to current time if there's an error
        _currentTime = DateTime.now().toUtc();
        if (kDebugMode) {
          print('Error updating time: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🌐 WeatherRadarWidget.build called');

    return Builder(
      builder: (context) {
        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: SizedBox(
                height: widget.height,
                child: FutureBuilder(
                    future: _tileProviderFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else {
                        final tileProvider = snapshot.data;

                      if (kDebugMode &&
                          tileProvider == null &&
                          !kIsWeb &&
                          !kIsWasm) {
                        // ignore: avoid_print
                          print('Tile provider is null, using web tile provider');
                        }
                        // Use provided location or default to Helsinki

                        return FlutterMap(
                          mapController: widget.controller.mapController,
                          options: MapOptions(
                            initialCenter: widget.controller.initialCenter,
                            initialZoom: 10,
                            maxZoom: 12,
                            minZoom: 7,
                            keepAlive: true,
                            interactionOptions: InteractionOptions(
                                flags:
                                    InteractiveFlag.all & ~InteractiveFlag.rotate,
                                rotationWinGestures: MultiFingerGesture.none),
                            onMapReady: () {
                              // Notify controller that map is ready
                              if (!_isMapInitialized) {
                                widget.controller.setMapReady();
                                _isMapInitialized = true;
                              }
                            },
                          ),
                          children: [
                            // Use raster layer for web, vector layer for mobile
                          if (kIsWeb || kIsWasm)
                            TileLayer(
                                urlTemplate:
                                    'https://a32.fi/osm/tile/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.sruusk.weather',
                                tileSize: 256,
                                zoomOffset: 0,
                                // Add constraints to prevent NaN/Infinity values
                                tileProvider: NetworkTileProvider(),
                                maxNativeZoom: 12,
                                minNativeZoom: 7,
                                keepBuffer: 5,
                                errorImage: NetworkImage(
                                    'https://a32.fi/osm/tile/10/588/282.png'), // Fallback image
                              )
                            else
                              Theme.of(context).brightness == Brightness.light
                                  ? VectorTileLayer(
                                      key: const Key('protomaps-light'),
                                      tileProviders: TileProviders({
                                        'protomaps': tileProvider!,
                                      }),
                                      theme: ProtomapsThemes.whiteV4(),
                                      showTileDebugInfo: true,
                                      // Set a custom cache folder, so it doesn't conflict with dark mode layer cache
                                      cacheFolder: () {
                                        return getTemporaryDirectory().then((dir) {
                                          return Directory(
                                              '${dir.path}/pmtiles_light_cache');
                                        });
                                      },
                                    )
                                  : VectorTileLayer(
                                      key: const Key('protomaps-dark'),
                                      tileProviders: TileProviders({
                                        'protomaps': tileProvider!,
                                      }),
                                      theme: ProtomapsThemes.blackV4(),
                                      showTileDebugInfo: true,
                                    ),
                            TileLayer(
                              tileSize: 256,
                              // Add constraints to prevent NaN/Infinity values
                              tileProvider: NetworkTileProvider(silenceExceptions: true),
                              maxNativeZoom: 12,
                              minNativeZoom: 7,
                              keepBuffer: 5,
                              wmsOptions: WMSTileLayerOptions(
                                  baseUrl: 'https://a32.fi/radar/wms?',
                                  layers: const ['Radar:suomi_rr_eureffin'],
                                  version: '1.3.0',
                                  crs: const Epsg3857(),
                                  format: 'image/png',
                                  transparent: true,
                                  otherParameters: {
                                    'time': _currentTime.toIso8601String(),
                                  }),
                              evictErrorTileStrategy:
                                  EvictErrorTileStrategy.dispose,
                              errorTileCallback: (TileImage image, Object error,
                                  StackTrace? stackTrace) {
                                if (kDebugMode) print('Error loading tile: $error');
                              },
                            ),
                            MarkerLayer(markers: [
                              Marker(
                                point: widget.controller.currentCenter,
                                alignment: Alignment.topCenter,
                                child: Icon(
                                  Icons.location_on,
                                color: (kIsWeb || kIsWasm)
                                    ? Colors.black
                                      : Theme.of(context).colorScheme.onSurface,
                                  size: 40,
                                ),
                              ),
                            ]),
                            RichAttributionWidget(
                              showFlutterMapAttribution: false,
                              popupInitialDisplayDuration: Duration(seconds: 5),
                              attributions: [
                                TextSourceAttribution(
                                  'OpenStreetMap [Map]',
                                  onTap: () => launchUrl(Uri.parse(
                                    'https://www.openstreetmap.org/copyright',
                                  )),
                                  prependCopyright: true,
                                ),
                                TextSourceAttribution(
                                  'Finnish Meteorological Institute [Radar]',
                                  onTap: () => launchUrl(Uri.parse(
                                    'https://en.ilmatieteenlaitos.fi/open-data',
                                  )),
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                    }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: _togglePlayPause,
                    tooltip: _isPlaying ? 'Pause' : 'Play',
                  ),
                  Expanded(
                    child: Slider(
                      value: _sliderValue,
                      min: 0,
                      max: 5,
                      divisions: 5,
                      onChanged: _updateTime,
                      label: '${((5 - _sliderValue) * 15).toInt()} min ago',
                    ),
                  ),
                  Text(
                    '${_currentTime.toLocal().hour.toString()}:${_currentTime.toLocal().minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        );
      }
    );
  }

  // Return the latest quarter hour time in UTC
  DateTime getTime() {
    final now = DateTime.now().toUtc();
    DateTime roundedTime =
        DateTime.utc(now.year, now.month, now.day, now.hour, now.minute);
    if (roundedTime.minute % 15 < 3) {
      roundedTime = roundedTime
          .subtract(Duration(minutes: (roundedTime.minute % 15) + 15));
    } else {
      roundedTime =
          roundedTime.subtract(Duration(minutes: roundedTime.minute % 15));
    }
    return roundedTime;
  }
}

// A simple controller to manage the map state (move, zoom, etc.)
class WeatherRadarController {
  final MapController mapController = MapController();
  final LatLng initialCenter;
  LatLng currentCenter;
  final double initialZoom;

  // Queue for postponed operations
  final List<Function> _pendingOperations = [];
  bool _isMapReady = false;

  WeatherRadarController({
    required double lat,
    required double lng,
    this.initialZoom = 8.0,
  })  : initialCenter = LatLng(lat, lng),
        currentCenter = LatLng(lat, lng);

  void setMapReady() {
    _isMapReady = true;
    // Execute any pending operations
    for (final operation in _pendingOperations) {
      operation();
    }
    _pendingOperations.clear();
  }

  void moveTo(double lat, double lng, double zoom) {
    // Update current center
    currentCenter = LatLng(lat, lng);

    if (_isMapReady) {
      mapController.move(currentCenter, zoom);
    } else {
      // Store the operation for later execution
      _pendingOperations.add(() => mapController.move(currentCenter, zoom));
    }
  }
}
