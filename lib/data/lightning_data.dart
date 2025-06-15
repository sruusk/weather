import 'package:http/http.dart';
import 'package:xml/xml.dart' as xml;

class LightningData {
  static final LightningData _instance = LightningData._internal();

  factory LightningData() {
    return _instance;
  }

  LightningData._internal();

  final List<LightningStrike> _strikes = [];
  DateTime? _lastUpdate;

  // Returns lightning strikes for the given duration backwards from the given time
  List<LightningStrike> getStrikes(DateTime time, Duration duration) {
    final startTime =
        time.subtract(duration).subtract(const Duration(seconds: 1));
    return _strikes
        .where((strike) =>
            strike.time.isAfter(startTime) && strike.time.isBefore(time))
        .toList();
  }

  Future<void> loadStrikes(DateTime time) async {
    if (_lastUpdate != null && time.isBefore(_lastUpdate!)) {
      return; // No need to reload if the data is already up-to-date
    }
    final now = DateTime.now();
    _lastUpdate = now;

    final url =
        Uri.parse('https://opendata.fmi.fi/wfs').replace(queryParameters: {
      'service': 'WFS',
      'version': '2.0.0',
      'request': 'GetFeature',
      'storedquery_id': 'fmi::observations::lightning::simple',
      'parameters': 'multiplicity',
      // 'bbox': '17.402344,59.389178,33.288574,71.230221', // Finland bounding box
      'starttime':
          '${now.toUtc().subtract(const Duration(hours: 2)).toIso8601String().split('.').first}Z',
      'endtime': '${now.toUtc().toIso8601String().split('.').first}Z',
    });

    final response = await get(url);
    if (response.statusCode != 200) {
      _lastUpdate = null; // Reset last update on error
      throw Exception('Failed to load lightning data: ${response.statusCode}');
    }

    final document = xml.XmlDocument.parse(response.body);
    final strikes = document.findAllElements('wfs:member').map((element) {
      final strike = element.childElements.first;
      final coords =
          strike.findAllElements('gml:pos').first.innerText.split(' ');
      final timeStr = strike.findElements('BsWfs:Time').first.innerText;
      return LightningStrike(
        time: DateTime.parse(timeStr),
        lat: double.parse(coords[0]),
        lon: double.parse(coords[1]),
      );
    }).toList();

    _strikes.clear();
    _strikes.addAll(strikes);
  }
}

class LightningStrike {
  final DateTime time;
  final double lat;
  final double lon;

  LightningStrike({required this.time, required this.lat, required this.lon});
}
