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
  Map<String, int> colorCounts = {};
  for (var p in image) {
    if (p.a == 0) continue;
    String hex = '${p.r},${p.g},${p.b}';
    colorCounts[hex] = (colorCounts[hex] ?? 0) + 1;
  }
  var sortedKeys = colorCounts.keys.toList()..sort((a, b) => colorCounts[b]!.compareTo(colorCounts[a]!));
  for (int i = 0; i < 20 && i < sortedKeys.length; i++) {
    print('${sortedKeys[i]}: ${colorCounts[sortedKeys[i]]}');
  }
}
