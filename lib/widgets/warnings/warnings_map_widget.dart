import 'dart:io';
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
import 'package:weather/widgets/warnings/alert_marker_widget.dart';
import 'package:weather/widgets/warnings/polygon_layer_widget.dart';

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

  @override
  Widget build(BuildContext context) {
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
                      return Directory('${dir.path}/white_v3_warnings');
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
                      return Directory('${dir.path}/black_v3_warnings');
                    });
                  },
                ),
        // Use our extracted widget classes
        PolygonLayerWidget(
          weatherAlerts: widget.weatherAlerts,
          hitNotifier: widget.hitNotifier,
          onOverlayVisibilityChanged: widget.onOverlayVisibilityChanged,
        ),
        AlertMarkerWidget(
          weatherAlerts: widget.weatherAlerts,
        ),
      ],
    );
  }
}
