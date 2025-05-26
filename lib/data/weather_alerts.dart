import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:maps_toolkit/maps_toolkit.dart';
import 'package:xml/xml.dart';

import 'location.dart';
import 'weather_alert.dart';

class WeatherAlerts {
  final List<WeatherAlert> alerts;
  final bool hasLoaded;

  static const _severityMap = {
    'Minor': WeatherAlertSeverity.minor,
    'Moderate': WeatherAlertSeverity.moderate,
    'Severe': WeatherAlertSeverity.severe,
    'Extreme': WeatherAlertSeverity.extreme,
  };

  // Private static instance variable for singleton pattern
  static WeatherAlerts? _instance;

  // Private constructor
  WeatherAlerts._({required this.alerts, this.hasLoaded = true});

  // Public constructor for testing purposes
  factory WeatherAlerts({required List<WeatherAlert> alerts}) {
    return WeatherAlerts._(alerts: alerts);
  }

  /// Factory constructor to get the singleton instance
  factory WeatherAlerts.instance() {
    return _instance ??= WeatherAlerts._(alerts: [], hasLoaded: false);
  }

  /// Load alerts from all sources
  Future<WeatherAlerts> load() async {
    if (_instance != null && _instance!.hasLoaded) {
      // If already loaded, return the existing instance
      return _instance!;
    }

    final fmiAlerts = await loadFmiAlerts();
    final floodingAlerts = await loadFloodingAlerts();

    // Update the singleton instance with merged alerts
    _instance = WeatherAlerts._(
      alerts: [...fmiAlerts.alerts, ...floodingAlerts.alerts],
      hasLoaded: true,
    );

    return _instance!;
  }

  /// Load weather alerts from FMI
  Future<WeatherAlerts> loadFmiAlerts() async {
    if(kDebugMode) {
      print('Loading FMI alerts...');
    }

    const languageMap = {
      "fi-FI": "fi",
      "sv-FI": "sv",
      "en-GB": "en"
    };

    final url = 'https://a32.fi/proxy/proxy?apiKey=c2cf681ee102a815d7d8800a6aaa1de96998e66cb17bbcc8beb2a2d0268fd918&method=GET&url=${Uri.encodeComponent("https://alerts.fmi.fi/cap/feed/atom_fi-FI.xml")}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Failed to load FMI alerts: ${response.statusCode}');
      }

      List<WeatherAlert> getAlerts(http.Response response) {
        final xmlDoc = XmlDocument.parse(response.body);
        final entries = xmlDoc.findAllElements('entry').toList();
        final alerts = <WeatherAlert>[];

        for (final entry in entries) {
          final contentElement = entry.findElements('content').first;
          final alertElement = contentElement.findElements('alert').first;

          final msgType = alertElement.findElements('msgType').first.innerText;
          if (msgType == 'Cancel') continue;

          final infoElements = alertElement.findElements('info').toList();

          // Maps to store event data for each language
          final Map<String, WeatherEvent> eventsByLanguage = {};
          WeatherAlertSeverity? severity;
          DateTime? onset;
          DateTime? expires;
          List<List<LatLng>>? polygons;

          // Process each language
          for (final key in languageMap.keys) {
            final XmlElement? infoElement;
            try {
              infoElement = infoElements.firstWhere(
                      (element) => element.findElements('language').first.innerText == key
              );
            } catch (e) {
              // Skip if no info element for this language
              continue;
            }

            // Get common data from the first language we process
            if (severity == null) {
              severity = _severityMap[infoElement.findElements('severity').first.innerText];
              onset = DateTime.parse(infoElement.findElements('onset').first.innerText);
              expires = DateTime.parse(infoElement.findElements('expires').first.innerText);

              // Process polygons
              final areaElements = infoElement.findElements('area').toList();
              polygons = <List<LatLng>>[];

              for (final areaElement in areaElements) {
                final polygonText = areaElement.findElements('polygon').first.innerText;
                final points = polygonText.split(' ').map((point) {
                  final coords = point.split(',');
                  final lat = double.parse(coords[0]);
                  final lon = double.parse(coords[1]);
                  return LatLng(lat, lon);
                }).toList();

                polygons.add(points);
              }
            }

            // Get language-specific data
            final event = infoElement.findElements('event').first.innerText;
            final headline = infoElement.findElements('headline').first.innerText;
            final description = infoElement.findElements('description').first.innerText;

            // Create WeatherEvent for this language
            eventsByLanguage[languageMap[key]!] = WeatherEvent(
              event: event,
              headline: headline,
              description: description,
            );
          }

          // Only create alert if we have data for all languages
          if (severity != null && onset != null && expires != null && polygons != null &&
              eventsByLanguage.containsKey('fi') &&
              eventsByLanguage.containsKey('sv') &&
              eventsByLanguage.containsKey('en')) {

            final alert = WeatherAlert(
              severity: severity,
              polygons: polygons,
              onset: onset,
              expires: expires,
              fi: eventsByLanguage['fi']!,
              sv: eventsByLanguage['sv']!,
              en: eventsByLanguage['en']!,
            );

            alerts.add(alert);
          }
        }
        return alerts;
      }

      // Use compute to parse XML in a separate isolate for better performance
      // On web, this will run in the main isolate since compute is not available
      final List<WeatherAlert> alerts = await compute(getAlerts, response);

      return WeatherAlerts(alerts: alerts);

    } catch (e) {
      if (kDebugMode) {
        print('Error loading FMI alerts: $e');
      }
      return WeatherAlerts(alerts: []);
    }
  }

  /// Load flooding alerts
  Future<WeatherAlerts> loadFloodingAlerts() async {
    const url = 'https://wwwi2.ymparisto.fi/i2/vespa/alerts.json';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Failed to load flooding alerts: ${response.statusCode}');
      }

      final json = jsonDecode(response.body);
      final features = json['features'] as List;
      final alerts = <WeatherAlert>[];

      for (final feature in features) {
        final properties = feature['properties'];
        final geometry = feature['geometry'];

        final onset = DateTime.parse(properties['onset']);
        final expires = DateTime.parse(properties['expires']);
        final severity = _severityMap[properties['severity']];

        final coordinates = geometry['coordinates'] as List;
        final polygons = <List<LatLng>>[];

        for (final polygon in coordinates) {
          final points = <LatLng>[];
          for (final point in polygon) {
            final lon = (point[0] as num).toDouble();
            final lat = (point[1] as num).toDouble();

            // Transform from EPSG:3067 to EPSG:4326
            final transformed = _transformCoordinates(lon, lat);
            points.add(LatLng(transformed[1], transformed[0]));
          }
          polygons.add(points);
        }

        // Create WeatherEvent objects for each language
        final Map<String, WeatherEvent> eventsByLanguage = {};

        for (final lang in ['fi', 'sv', 'en']) {
          final event = properties['type_$lang'] ?? '';
          final headline = properties['desc_$lang'] ?? '';
          final description = properties['desc_$lang'] ?? '';

          eventsByLanguage[lang] = WeatherEvent(
            event: event,
            headline: headline,
            description: description,
          );
        }

        // Create the alert with all language data
        if(severity != null) {
          alerts.add(WeatherAlert(
            severity: severity,
            polygons: polygons,
            onset: onset,
            expires: expires,
            fi: eventsByLanguage['fi']!,
            sv: eventsByLanguage['sv']!,
            en: eventsByLanguage['en']!,
          ));
        }
      }

      return WeatherAlerts(alerts: alerts);

    } catch (e) {
      if (kDebugMode) {
        print('Error loading flooding alerts: $e');
      }
      return WeatherAlerts(alerts: []);
    }
  }

  /// Transform coordinates from EPSG:3067 to EPSG:4326
  /// This is a simplified transformation and may not be accurate for all use cases
  List<double> _transformCoordinates(double x, double y) {
    // Constants for EPSG:3067 to EPSG:4326 transformation
    // These are approximate values and should be replaced with a proper transformation library
    const double centerLon = 27.0;
    const double centerLat = 65.0;
    const double scale = 0.000009;

    // Simple linear transformation (this is a very rough approximation)
    final lon = centerLon + (x - 3500000) * scale;
    final lat = centerLat + (y - 7000000) * scale;

    return [lon, lat];
  }

  /// Get alerts for a specific location and time
  List<WeatherAlert> alertsForLocation(Location location, [DateTime? time]) {
    final position = LatLng(location.lat, location.lon);

    return alerts.where((alert) {
      // Check if the alert is active at the given time
      if (time != null) {
        if (time.isBefore(alert.onset) || time.isAfter(alert.expires)) {
          return false;
        }
      }

      return alert.polygons.any((polygon) {
        return PolygonUtil.containsLocation(position, polygon, false);
      });
    }).toList();
  }

  /// Get the highest severity for a specific location and time
  WeatherAlertSeverity? severityForLocation(Location location, [DateTime? time]) {
    final locAlerts = alertsForLocation(location, time);
    if (locAlerts.isEmpty) return null;

    const severityRank = {
      WeatherAlertSeverity.unknown: 0,
      WeatherAlertSeverity.minor: 1,
      WeatherAlertSeverity.moderate: 2,
      WeatherAlertSeverity.severe: 3,
      WeatherAlertSeverity.extreme: 4,
    };

    var highest = locAlerts.first;
    for (var alert in locAlerts.skip(1)) {
      final currentRank = severityRank[alert.severity] ?? -1;
      final highestRank = severityRank[highest.severity] ?? -1;
      if (currentRank > highestRank) {
        highest = alert;
      }
    }
    return highest.severity;
  }
}
