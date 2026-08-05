import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

void main() async {
  var url = Uri.parse('https://openwms.fmi.fi/geoserver/wms?service=WMS&version=1.3.0&request=GetMap&format=image/png&transparent=true&crs=EPSG:4326&layers=Radar:radar_finland_cappi_rate&width=512&height=512&bbox=59.0,20.0,70.0,32.0');
  var res = await http.get(url);
  var image = img.decodeImage(res.bodyBytes);
  if (image == null) {
    print('Failed to decode');
    return;
  }
  Map<String, int> highBlue = {};
  Map<String, int> lowBlue = {};
  for (var p in image) {
    if (p.a == 0) continue;
    String hex = '${p.r},${p.g},${p.b}';
    if (p.b > 180) {
      highBlue[hex] = (highBlue[hex] ?? 0) + 1;
    } else {
      lowBlue[hex] = (lowBlue[hex] ?? 0) + 1;
    }
  }
  var sortedHigh = highBlue.keys.toList()..sort((a, b) => highBlue[b]!.compareTo(highBlue[a]!));
  print('--- High Blue (>180) ---');
  for (int i = 0; i < 5 && i < sortedHigh.length; i++) {
    print('${sortedHigh[i]}: ${highBlue[sortedHigh[i]]}');
  }
  var sortedLow = lowBlue.keys.toList()..sort((a, b) => lowBlue[b]!.compareTo(lowBlue[a]!));
  print('--- Low Blue (<=180) ---');
  for (int i = 0; i < 5 && i < sortedLow.length; i++) {
    print('${sortedLow[i]}: ${lowBlue[sortedLow[i]]}');
  }
}
