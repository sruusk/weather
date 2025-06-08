import 'package:flutter_test/flutter_test.dart';
import 'package:maps_toolkit/maps_toolkit.dart';
import 'package:weather/data/location.dart';
import 'package:weather/data/weather_alert.dart';
import 'package:weather/data/weather_alerts.dart';

void main() {
  group('WeatherAlerts', () {
    late WeatherAlerts weatherAlerts;
    late Location testLocation;

    // Create test data
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final tomorrow = now.add(const Duration(days: 1));
    final dayAfterTomorrow = now.add(const Duration(days: 2));

    // Create test WeatherEvent objects for each language
    final activeEventFi = WeatherEvent(
      event: 'Test Event',
      headline: 'Test Headline',
      description: 'Test Description',
    );

    final activeEventSv = WeatherEvent(
      event: 'Test Event SV',
      headline: 'Test Headline SV',
      description: 'Test Description SV',
    );

    final activeEventEn = WeatherEvent(
      event: 'Test Event EN',
      headline: 'Test Headline EN',
      description: 'Test Description EN',
    );

    final futureEventFi = WeatherEvent(
      event: 'Future Event',
      headline: 'Future Headline',
      description: 'Future Description',
    );

    final futureEventSv = WeatherEvent(
      event: 'Future Event SV',
      headline: 'Future Headline SV',
      description: 'Future Description SV',
    );

    final futureEventEn = WeatherEvent(
      event: 'Future Event EN',
      headline: 'Future Headline EN',
      description: 'Future Description EN',
    );

    // Create test alerts
    final activeAlert = WeatherAlert(
      severity: WeatherAlertSeverity.moderate,
      polygons: [
        [
          LatLng(60.0, 25.0),
          LatLng(60.0, 26.0),
          LatLng(61.0, 26.0),
          LatLng(61.0, 25.0),
          LatLng(60.0, 25.0),
        ]
      ],
      onset: yesterday,
      expires: tomorrow,
      fi: activeEventFi,
      sv: activeEventSv,
      en: activeEventEn,
    );

    final futureAlert = WeatherAlert(
      severity: WeatherAlertSeverity.severe,
      polygons: [
        [
          LatLng(60.0, 25.0),
          LatLng(60.0, 26.0),
          LatLng(61.0, 26.0),
          LatLng(61.0, 25.0),
          LatLng(60.0, 25.0),
        ]
      ],
      onset: tomorrow,
      expires: dayAfterTomorrow,
      fi: futureEventFi,
      sv: futureEventSv,
      en: futureEventEn,
    );

    setUp(() {
      // Create a test location inside the polygon
      testLocation = Location(
        lat: 60.5,
        lon: 25.5,
        name: 'Test Location',
        countryCode: 'TC',
        region: 'Test Region',
        country: 'Test Country',
      );

      // Create WeatherAlerts with test data
      weatherAlerts = WeatherAlerts(alerts: [activeAlert, futureAlert]);
    });

    test('alertsForLocation should return all alerts for a location without time filter', () {
      final alerts = weatherAlerts.alertsForLocation(testLocation);
      expect(alerts.length, 2);
      expect(alerts.map((a) => a.fi.event).toList(), ['Test Event', 'Future Event']);
    });

    test('alertsForLocation should filter alerts by time', () {
      // Current time - should only return the active alert
      final alerts = weatherAlerts.alertsForLocation(testLocation, now);
      expect(alerts.length, 1);
      expect(alerts.first.fi.event, 'Test Event');

      // Future time - should only return the future alert
      final futureAlerts = weatherAlerts.alertsForLocation(
          testLocation, tomorrow.add(const Duration(hours: 24)));
      expect(futureAlerts.length, 1);
      expect(futureAlerts.first.fi.event, 'Future Event');
    });

    test('severityForLocation should return highest severity for a location without time filter', () {
      final severity = weatherAlerts.severityForLocation(testLocation);
      expect(severity, WeatherAlertSeverity.severe);
    });

    test('severityForLocation should filter alerts by time', () {
      // Current time - should return the active alert's severity
      final severity = weatherAlerts.severityForLocation(testLocation, now);
      expect(severity, WeatherAlertSeverity.moderate);

      // Future time - should return the future alert's severity
      final futureSeverity = weatherAlerts.severityForLocation(testLocation, tomorrow.add(const Duration(hours: 12)));
      expect(futureSeverity, WeatherAlertSeverity.severe);
    });
  });
}
