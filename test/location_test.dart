import 'package:flutter_test/flutter_test.dart';
import 'package:weather/data/location.dart';

void main() {
  group('Location', () {
    test('toString should return a properly formatted string', () {
      final location = Location(
        lat: 60.1695,
        lon: 24.9354,
        name: 'Helsinki',
        region: 'Uusimaa',
        countryCode: 'FI',
        country: 'Finland',
        index: 0
      );

      final result = location.toString();
      expect(result, '60.1695|24.9354|Helsinki|FI|Uusimaa|Finland|0');
    });

    test('toString should handle null region', () {
      final location = Location(
        lat: 60.1695,
        lon: 24.9354,
        name: 'Helsinki',
        region: null,
        countryCode: 'FI',
      );

      final result = location.toString();
      expect(result, '60.1695|24.9354|Helsinki|FI|||');
    });

    test('fromString should parse a valid string correctly', () {
      final str = '60.1695|24.9354|Helsinki|FI|Uusimaa|Finland|0';
      final location = Location.fromString(str);

      expect(location.lat, 60.1695);
      expect(location.lon, 24.9354);
      expect(location.name, 'Helsinki');
      expect(location.region, 'Uusimaa');
      expect(location.countryCode, 'FI');
      expect(location.country, 'Finland');
    });

    test('fromString should handle empty region', () {
      final str = '60.1695|24.9354|Helsinki|FI||';
      final location = Location.fromString(str);

      expect(location.region, null);
      expect(location.country, null);
    });

    test('fromString should throw FormatException for invalid string', () {
      final str = '60.1695|24.9354|Helsinki';
      expect(() => Location.fromString(str), throwsFormatException);
    });

    test('round-trip conversion should preserve all data', () {
      final original = Location(
        lat: 60.1695,
        lon: 24.9354,
        name: 'Helsinki',
        region: 'Uusimaa',
        countryCode: 'FI',
      );

      final roundTrip = Location.fromString(original.toString());

      expect(roundTrip.lat, original.lat);
      expect(roundTrip.lon, original.lon);
      expect(roundTrip.name, original.name);
      expect(roundTrip.region, original.region);
      expect(roundTrip.countryCode, original.countryCode);
    });

    test('toDebugString should return a debug-friendly string', () {
      final location = Location(
        lat: 60.1695,
        lon: 24.9354,
        name: 'Helsinki',
        region: 'Uusimaa',
        countryCode: 'FI',
      );

      final result = location.toDebugString();
      expect(result, 'Location(name: Helsinki, lat: 60.1695, lon: 24.9354, region: Uusimaa, countryCode: FI, country: null, index: null)');
    });
  });
}
