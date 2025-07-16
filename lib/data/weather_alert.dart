import 'package:maps_toolkit/maps_toolkit.dart';

enum WeatherAlertSeverity {
  unknown,
  minor,
  moderate,
  severe,
  extreme,
}

enum GeocodeType {
  iso3166_2, // ISO 3166-2 code (e.g., FI-01)
  municipality, // Finnish municipality code (e.g., 123) "kuntanumero"
  metarea,
}

// This enum represents different types of weather alerts.
// The value appears in the <eventCode><value> field of the alert xml.
enum WeatherAlertType {
  thunderstorm,
  wind,
  rain,
  trafficWeather,
  pedestrianSafety,
  forestFireWeather,
  grassFireWeather,
  hotWeather,
  coldWeather,
  uvNote,
  floodLevel,
  seaWind,
  seaThunderstorm,
  seaWaterHeightHighWater,
  seaWaterHeightShallowWater,
  seaWaveHeight,
  seaIcing,
  unknown,
}

class GeoCode {
  final GeocodeType type;
  final String code;

  GeoCode({
    required this.type,
    required this.code,
  });

  // Convert GeoCode to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'code': code,
    };
  }

  // Create GeoCode from JSON
  factory GeoCode.fromJson(Map<String, dynamic> json) {
    return GeoCode(
      type: GeocodeType.values[json['type'] as int],
      code: json['code'] as String,
    );
  }

  @override
  String toString() {
    return 'GeoCode(type: $type, code: $code)';
  }
}

class Area {
  final List<LatLng> points;
  final GeoCode? geocode;

  Area({
    required this.points,
    this.geocode,
  });

  // Convert Polygon to JSON
  Map<String, dynamic> toJson() {
    return {
      'points': points
          .map((point) => {'lat': point.latitude, 'lng': point.longitude})
          .toList(),
      'geocode': geocode?.toJson(),
    };
  }

  // Create Polygon from JSON
  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(
      points: (json['points'] as List)
          .map((pointJson) => LatLng(
              (pointJson as Map<String, dynamic>)['lat'] as double,
              (pointJson)['lng'] as double))
          .toList(),
      geocode: json['geocode'] != null
          ? GeoCode.fromJson(json['geocode'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  String toString() {
    return 'Polygon(points: $points, geocode: $geocode)';
  }
}

class WeatherEvent {
  final String event;
  final String headline;
  final String description;
  final String? impact; // Optional field for impact description

  WeatherEvent({
    required this.event,
    required this.headline,
    required this.description,
    this.impact,
  });

  // Convert WeatherEvent to JSON
  Map<String, dynamic> toJson() {
    return {
      'event': event,
      'headline': headline,
      'description': description,
      'impact': impact,
    };
  }

  // Create WeatherEvent from JSON
  factory WeatherEvent.fromJson(Map<String, dynamic> json) {
    return WeatherEvent(
      event: json['event'] as String,
      headline: json['headline'] as String,
      description: json['description'] as String,
      impact: json['impact'] as String?,
    );
  }
}

class WeatherAlert {
  final WeatherAlertSeverity severity;
  final List<Area> areas;
  final DateTime onset;
  final DateTime expires;
  final WeatherEvent fi;
  final WeatherEvent sv;
  final WeatherEvent en;
  final WeatherAlertType type;

  WeatherAlert({
    required this.severity,
    required this.areas,
    required this.onset,
    required this.expires,
    required this.fi,
    required this.sv,
    required this.en,
    required this.type,
  });

  // Convert WeatherAlert to JSON
  Map<String, dynamic> toJson() {
    return {
      'severity': severity.index,
      'areas': areas.map((area) => area.toJson()).toList(),
      'onset': onset.toIso8601String(),
      'expires': expires.toIso8601String(),
      'fi': fi.toJson(),
      'sv': sv.toJson(),
      'en': en.toJson(),
      'type': type.index,
    };
  }

  // Create WeatherAlert from JSON
  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    return WeatherAlert(
      severity: WeatherAlertSeverity.values[json['severity'] as int],
      areas: (json['areas'] as List)
          .map((areaJson) => Area.fromJson(areaJson as Map<String, dynamic>))
          .toList(),
      onset: DateTime.parse(json['onset'] as String),
      expires: DateTime.parse(json['expires'] as String),
      fi: WeatherEvent.fromJson(json['fi'] as Map<String, dynamic>),
      sv: WeatherEvent.fromJson(json['sv'] as Map<String, dynamic>),
      en: WeatherEvent.fromJson(json['en'] as Map<String, dynamic>),
      type: WeatherAlertType.values[json['type'] as int],
    );
  }
}
