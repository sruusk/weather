import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_svg/svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pmtiles/pmtiles.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_map_tiles_pmtiles/vector_map_tiles_pmtiles.dart';
import 'package:weather/data/lightning_data.dart';
import 'package:weather/l10n/app_localizations.g.dart';
import 'package:weather/widgets/weather_symbol_widget.dart';

class WeatherRadar extends StatefulWidget {
  final WeatherRadarController controller;
  final double height;
  final int flags;
  final int rotationWinGestures;
  final CursorKeyboardRotationOptions? cursorKeyboardRotationOptions;

  const WeatherRadar({
    super.key,
    required this.controller,
    this.height = 400,
    this.flags = InteractiveFlag.all & ~InteractiveFlag.rotate,
    this.cursorKeyboardRotationOptions,
    this.rotationWinGestures = MultiFingerGesture.none,
  });

  @override
  State<WeatherRadar> createState() => _WeatherRadarState();
}

class _WeatherRadarState extends State<WeatherRadar> {
  late final Future<PmTilesVectorTileProvider?> _tileProviderFuture;
  late DateTime _currentTime;
  double _sliderValue =
      5; // 5 represents the latest time, 0 represents 75 minutes ago
  bool _isPlaying = false;
  Timer? _timer;
  bool _isMapInitialized = false;
  late final StreamController<void> _resetController;
  List<LightningStrike> _currentLightningStrikes = [];
  List<LightningStrike> _pastLightningStrikes = [];
  final lightningData = LightningData();

  @override
  void initState() {
    super.initState();
    _resetController = StreamController<void>.broadcast();
    _currentTime = getTime();
    _updateLightningStrikes();
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
    _resetController.close();
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

    _updateLightningStrikes();

    setState(() {
      _sliderValue = value;
      // Calculate time based on inverted slider value (each step is 15 minutes)
      // 5 is latest time (0 minutes ago), 0 is  time (75 minutes ago)
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

      _resetController.add(null);
    });
  }

  _updateLightningStrikes() async {
    try {
      await lightningData.loadStrikes(_currentTime);
      setState(() {
        _currentLightningStrikes =
            lightningData.getStrikes(_currentTime, const Duration(minutes: 15));
        _pastLightningStrikes = lightningData.getStrikes(
            _currentTime.subtract(const Duration(minutes: 15)),
            const Duration(minutes: 15));
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading lightning strikes: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🌐 WeatherRadarWidget.build called');
    final localizations = AppLocalizations.of(context)!;

    return Builder(builder: (context) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              height: widget.height /* - 64*/, // Subtract height of controls
              child: FutureBuilder(
                  future: _tileProviderFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else {
                      final tileProvider = snapshot.data;

                      return FlutterMap(
                        mapController: widget.controller.mapController,
                        options: MapOptions(
                          initialCenter: widget.controller.initialCenter,
                          initialZoom: 10,
                          maxZoom: 12,
                          minZoom: 5,
                          keepAlive: true,
                          interactionOptions: InteractionOptions(
                            flags: widget.flags,
                            rotationWinGestures: widget.rotationWinGestures,
                            cursorKeyboardRotationOptions:
                                widget.cursorKeyboardRotationOptions ??
                                    CursorKeyboardRotationOptions.disabled(),
                          ),
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
                              minNativeZoom: 5,
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
                                    theme: ProtomapsThemes.whiteV3(),
                                    showTileDebugInfo: false,
                                    // Set a custom cache folder, so it doesn't conflict with dark mode layer cache
                                    cacheFolder: () {
                                      return getTemporaryDirectory()
                                          .then((dir) {
                                        return Directory(
                                            '${dir.path}/pmtiles_white_v3_cache');
                                      });
                                    },
                                  )
                                : VectorTileLayer(
                                    key: const Key('protomaps-black'),
                                    tileProviders: TileProviders({
                                      'protomaps': tileProvider!,
                                    }),
                                    theme: ProtomapsThemes.blackV3(
                                        /*logger: Logger.console()*/),
                                    showTileDebugInfo: false,
                                    cacheFolder: () {
                                      return getTemporaryDirectory()
                                          .then((dir) {
                                        return Directory(
                                            '${dir.path}/pmtiles_black_v3_cache');
                                      });
                                    },
                                  ),
                          TileLayer(
                            tileSize: 128,
                            // Add constraints to prevent NaN/Infinity values
                            tileProvider: CancellableNetworkTileProvider(
                                silenceExceptions: true),
                            maxNativeZoom: 12,
                            minNativeZoom: 7,
                            keepBuffer: 5,
                            panBuffer: 1,
                            wmsOptions: WMSTileLayerOptions(
                                // baseUrl: 'https://openwms.fmi.fi/geoserver/wms?',
                                baseUrl: 'https://wfs-proxy.a32.fi/wms?',
                                // baseUrl: 'https://a32.fi/radar/wms?',
                                layers: const ['Radar:suomi_rr_eureffin'],
                                version: '1.3.0',
                                crs: const Epsg3857(),
                                format: 'image/geotiff',
                                transparent: true,
                                otherParameters: {
                                  'time': _currentTime.toIso8601String(),
                                }),
                            reset: _resetController.stream,
                            userAgentPackageName: 'com.sruusk.weather',
                            evictErrorTileStrategy:
                                EvictErrorTileStrategy.dispose,
                            errorTileCallback: (TileImage image, Object error,
                                StackTrace? stackTrace) {
                              if (kDebugMode) {
                                print('Error loading tile: $error');
                              }
                            },
                          ),
                          MarkerLayer(markers: [
                            ..._pastLightningStrikes.map((strike) {
                              return Marker(
                                  point: LatLng(strike.lat, strike.lon),
                                  width: 80,
                                  height: 80,
                                  child: WeatherSymbolWidget(
                                      symbolName: 'lightning-bolt', size: 80));
                            }),
                            ..._currentLightningStrikes.map((strike) {
                              return Marker(
                                  point: LatLng(strike.lat, strike.lon),
                                  width: 80,
                                  height: 80,
                                  child: WeatherSymbolWidget(
                                      symbolName: 'lightning-bolt-red',
                                      size: 80));
                            }),
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
                          Transform.translate(
                            offset: const Offset(0, -64),
                            child: RichAttributionWidget(
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
                                  'Finnish Meteorological Institute [Radar, Lightning]',
                                  onTap: () => launchUrl(Uri.parse(
                                    'https://en.ilmatieteenlaitos.fi/open-data',
                                  )),
                                ),
                                LogoSourceAttribution(SvgPicture.asset(
                                  'assets/about/fmiodata.svg',
                                  height: 20,
                                  colorFilter: ColorFilter.mode(
                                    Theme.of(context).colorScheme.onSurface,
                                    BlendMode.srcIn,
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                  }),
            ),
            Container(
              height: 64,
              color: Theme.of(context).colorScheme.surface.withAlpha(150),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      onPressed: _togglePlayPause,
                      tooltip:
                          _isPlaying ? localizations.pause : localizations.play,
                    ),
                    Expanded(
                      child: Slider(
                          value: _sliderValue,
                          min: 0,
                          max: 5,
                          divisions: 5,
                          onChanged: _updateTime,
                          label: localizations
                              .minutesAgo(((5 - _sliderValue) * 15).toInt())),
                    ),
                    Text(
                      '${_currentTime.toLocal().hour.toString()}:${_currentTime.toLocal().minute.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
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
        currentCenter = LatLng(lat, lng) {
    // Queue an initial move operation to ensure the map renders properly
    _pendingOperations
        .add(() => mapController.move(currentCenter, initialZoom));
  }

  bool get isMapReady => _isMapReady;

  void setMapReady() {
    _isMapReady = true;

    // Execute any pending operations
    for (final operation in _pendingOperations) {
      operation();
    }
    _pendingOperations.clear();

    // Perform an additional move operation to ensure the map is properly centered and zoomed
    // This helps trigger the proper rendering of the map
    mapController.move(currentCenter, initialZoom);
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
