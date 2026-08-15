import 'dart:async';
import 'dart:convert' hide Codec;
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

class FmiRadarTileProvider extends TileProvider {
  final http.BaseClient _httpClient;
  static Directory? _cacheDir;
  static bool _cleaningUp = false;

  FmiRadarTileProvider({http.BaseClient? httpClient})
      : _httpClient = httpClient ?? RetryClient(http.Client()) {
    _initCache();
  }

  Future<void> _initCache() async {
    if (_cacheDir == null) {
      final tempDir = await getTemporaryDirectory();
      _cacheDir = Directory('${tempDir.path}/fmi_radar_cache');
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
      _cleanupOldFiles();
    }
  }

  Future<void> _cleanupOldFiles() async {
    if (_cleaningUp || _cacheDir == null) return;
    _cleaningUp = true;
    try {
      final now = DateTime.now();
      final files = _cacheDir!.listSync();
      for (var file in files) {
        if (file is File) {
          final stat = await file.stat();
          // Delete files older than 2 hours
          if (now.difference(stat.modified) > const Duration(hours: 2)) {
            try {
              await file.delete();
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
    _cleaningUp = false;
  }

  String _getCacheFilename(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return '${digest.toString()}.png';
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    return _FmiRadarImageProvider(url, _httpClient, _cacheDir, _getCacheFilename);
  }
}

class _FmiRadarImageProvider extends ImageProvider<_FmiRadarImageProvider> {
  final String url;
  final http.BaseClient httpClient;
  final Directory? cacheDir;
  final String Function(String) getCacheFilename;

  _FmiRadarImageProvider(this.url, this.httpClient, this.cacheDir, this.getCacheFilename);

  @override
  Future<_FmiRadarImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_FmiRadarImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(_FmiRadarImageProvider key, ImageDecoderCallback decode) {
    final chunkEvents = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, decode),
      chunkEvents: chunkEvents.stream,
      scale: 1.0,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<_FmiRadarImageProvider>('Image key', key),
      ],
    );
  }

  Future<Codec> _loadAsync(
    _FmiRadarImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    ImageDecoderCallback decode,
  ) async {
    try {
      Uint8List? imageBytes;
      File? cacheFile;

      if (cacheDir != null) {
        final filename = getCacheFilename(url);
        cacheFile = File('${cacheDir!.path}/$filename');
        if (await cacheFile.exists()) {
          imageBytes = await cacheFile.readAsBytes();
        }
      }

      if (imageBytes == null) {
        final uri = Uri.parse(url);
        final response = await httpClient.get(uri);
        if (response.statusCode != 200) {
          throw Exception('Failed to load tile: HTTP ${response.statusCode}');
        }
        
        imageBytes = response.bodyBytes;

        // Save to cache
        if (cacheFile != null) {
          await cacheFile.writeAsBytes(imageBytes);
        }
      }

      final buffer = await ImmutableBuffer.fromUint8List(imageBytes);
      return decode(buffer);
    } catch (e) {
      // In case of error, just return a 1x1 transparent image to avoid crashing the map
      final transparent = Uint8List.fromList([
        137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 
        0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 11, 73, 68, 65, 84, 
        120, 156, 99, 96, 0, 2, 0, 0, 5, 0, 1, 13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 
        78, 68, 174, 66, 96, 130
      ]);
      final buffer = await ImmutableBuffer.fromUint8List(transparent);
      return decode(buffer);
    } finally {
      if (!chunkEvents.isClosed) {
        chunkEvents.close();
      }
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is _FmiRadarImageProvider && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;
}
