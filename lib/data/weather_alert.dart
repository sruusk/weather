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
}
