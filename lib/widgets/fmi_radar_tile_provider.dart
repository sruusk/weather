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
import 'package:image/image.dart' as img;
import 'package:pool/pool.dart';

class _ColorRange {
  final int rMin, rMax, gMin, gMax, bMin, bMax;
  _ColorRange(this.rMin, this.rMax, this.gMin, this.gMax, this.bMin, this.bMax);
  bool contains(int r, int g, int b) {
    return r >= rMin && r <= rMax &&
           g >= gMin && g <= gMax &&
           b >= bMin && b <= bMax;
  }
}

// The background processing function running in Isolate
Uint8List? _processImageInIsolate(Uint8List imageBytes) {
  try {
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) return null;
    if (!image.hasAlpha) {
      image = image.convert(numChannels: 4);
    }

    final width = image.width;
    final height = image.height;
    final buffer = Uint8List(width * height * 4);
    int bufferIndex = 0;

    final bgRange = _ColorRange(250, 260, -5, 5, 250, 260); // Magenta +/- 5

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        bool isBackground = bgRange.contains(r, g, b);
        
        if (!isBackground) {
          if (r >= 183 && g >= 179 && b >= 242) {
            isBackground = true;
          } else if (r >= 220 && b >= 240) {
            isBackground = true;
          }
        }

        if (isBackground) {
          buffer[bufferIndex++] = 0;
          buffer[bufferIndex++] = 0;
          buffer[bufferIndex++] = 0;
          buffer[bufferIndex++] = 0;
        } else {
          int finalR = r;
          int finalG = g;
          int finalB = b;
          
          if (b > 180) {
            if (g - r <= 20) {
               finalR = (r * 0.8).toInt();
               finalG = (g * 1.2).toInt().clamp(0, 255);
            } else {
               finalR = (r * 0.4).toInt();
               finalG = (g * 0.8).toInt();
               finalB = (b * 0.9).toInt();
            }
          }

          buffer[bufferIndex++] = finalR;
          buffer[bufferIndex++] = finalG;
          buffer[bufferIndex++] = finalB;
          buffer[bufferIndex++] = 255;
        }
      }
    }

    final processedImage = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: buffer.buffer,
      numChannels: 4,
    );

    final pngBytes = img.encodePng(processedImage, level: 1);
    return Uint8List.fromList(pngBytes);
  } catch (e) {
    return null;
  }
}

class FmiRadarTileProvider extends TileProvider {
  static final Pool _tilePool = Pool(16);
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
        imageBytes = await FmiRadarTileProvider._tilePool.withResource(() async {
          final response = await httpClient.get(uri);
          if (response.statusCode != 200) {
            throw Exception('Failed to load tile: HTTP ${response.statusCode}');
          }
          
          final rawBytes = response.bodyBytes;
          // Process in Isolate
          final processedBytes = await compute(_processImageInIsolate, rawBytes);
          
          if (processedBytes == null) {
            throw Exception('Failed to process tile image');
          }
          return processedBytes;
        });

        // Save to cache
        if (cacheFile != null && imageBytes != null) {
          await cacheFile.writeAsBytes(imageBytes);
        }
      }

      if (imageBytes == null) {
        throw Exception('Failed to obtain image bytes');
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
