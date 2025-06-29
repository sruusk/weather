import 'package:maps_toolkit/maps_toolkit.dart';

enum WeatherAlertSeverity {
  unknown,
  minor,
  moderate,
  severe,
  extreme,
}

class WeatherEvent {
  final String event;
  final String headline;
  final String description;

  WeatherEvent({
    required this.event,
    required this.headline,
    required this.description,
  });

  // Convert WeatherEvent to JSON
  Map<String, dynamic> toJson() {
    return {
      'event': event,
      'headline': headline,
      'description': description,
    };
  }

  // Create WeatherEvent from JSON
  factory WeatherEvent.fromJson(Map<String, dynamic> json) {
    return WeatherEvent(
      event: json['event'] as String,
      headline: json['headline'] as String,
      description: json['description'] as String,
    );
  }
}

class WeatherAlert {
  final WeatherAlertSeverity severity;
  final List<List<LatLng>> polygons;
  final DateTime onset;
  final DateTime expires;
  final WeatherEvent fi;
  final WeatherEvent sv;
  final WeatherEvent en;

  WeatherAlert({
    required this.severity,
    required this.polygons,
    required this.onset,
    required this.expires,
    required this.fi,
    required this.sv,
    required this.en,
  });

  // Convert WeatherAlert to JSON
  Map<String, dynamic> toJson() {
    return {
      'severity': severity.index,
      'polygons': polygons
          .map((polygon) => polygon
              .map((point) => {'lat': point.latitude, 'lng': point.longitude})
              .toList())
          .toList(),
      'onset': onset.toIso8601String(),
      'expires': expires.toIso8601String(),
      'fi': fi.toJson(),
      'sv': sv.toJson(),
      'en': en.toJson(),
    };
  }

  // Create WeatherAlert from JSON
  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    return WeatherAlert(
      severity: WeatherAlertSeverity.values[json['severity'] as int],
      polygons: (json['polygons'] as List)
          .map((polygonJson) => (polygonJson as List)
              .map((pointJson) => LatLng(
                  (pointJson as Map<String, dynamic>)['lat'] as double,
                  (pointJson)['lng'] as double))
              .toList())
          .toList(),
      onset: DateTime.parse(json['onset'] as String),
      expires: DateTime.parse(json['expires'] as String),
      fi: WeatherEvent.fromJson(json['fi'] as Map<String, dynamic>),
      sv: WeatherEvent.fromJson(json['sv'] as Map<String, dynamic>),
      en: WeatherEvent.fromJson(json['en'] as Map<String, dynamic>),
    );
  }
}
