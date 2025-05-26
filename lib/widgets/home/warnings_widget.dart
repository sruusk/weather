import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:weather/app_state.dart';
import 'package:weather/data/location.dart';
import 'package:weather/data/weather_alert.dart';
import 'package:weather/data/weather_alerts.dart';
import 'package:weather/l10n/app_localizations.g.dart';

class WeatherWarnings extends StatefulWidget {
  final Location location;

  const WeatherWarnings({super.key, required this.location});

  @override
  State<WeatherWarnings> createState() => _WeatherWarningsState();
}

class _WeatherWarningsState extends State<WeatherWarnings> {
  WeatherAlerts? _weatherAlerts;

  @override
  void initState() {
    super.initState();

    if(kDebugMode) print('Initializing WarningsWidget for ${widget.location.name}');

    // Get the singleton instance and load alerts
    final weatherAlertsInstance = WeatherAlerts.instance();
    if(weatherAlertsInstance.hasLoaded) {
      // If already loaded, set the state directly
      _weatherAlerts = weatherAlertsInstance;
    } else {
      // Otherwise, load the alerts
      weatherAlertsInstance.load().then((alerts) {
        if (mounted) {
          setState(() {
            _weatherAlerts = alerts;
          });
        }
      }).catchError((error) {
        if (kDebugMode) print('Error loading weather alerts: $error');
        setState(() {
          _weatherAlerts = null; // Handle error by setting to null
        });
      });
    }
  }

  List<Color> getGradientColors(WeatherAlertSeverity? severity) {
    switch (severity ?? WeatherAlertSeverity.unknown) {
      case WeatherAlertSeverity.minor:
        return [Colors.green, Color(0x0000ff0c)];
      case WeatherAlertSeverity.moderate:
        return [Color(0xCCFAE500), Color(0x00FFF400)];
      case WeatherAlertSeverity.severe:
        return [Color(0xCCFFAC40), Color(0x00FF6A00)];
      case WeatherAlertSeverity.extreme:
        return [Color(0xCCFF4040), Color(0x1AFF0000)];
      default:
        return [Colors.transparent, Colors.transparent];
    }
  }

  Color getBorderColor(WeatherAlertSeverity? severity) {
    switch (severity ?? WeatherAlertSeverity.unknown) {
      case WeatherAlertSeverity.minor:
        return Colors.lightGreenAccent;
      case WeatherAlertSeverity.moderate:
        return Colors.yellowAccent;
      case WeatherAlertSeverity.severe:
        return Colors.orange;
      case WeatherAlertSeverity.extreme:
        return Colors.red;
      default:
        return Colors.lightGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final localizations = AppLocalizations.of(context)!;

    if (_weatherAlerts == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final today = DateTime.now();
    final days = [
      today,
      today.add(const Duration(days: 1)),
      today.add(const Duration(days: 2)),
      today.add(const Duration(days: 3)),
      today.add(const Duration(days: 4)),
    ];

    final severity = [
      _weatherAlerts!.severityForLocation(widget.location, days[0]),
      _weatherAlerts!.severityForLocation(widget.location, days[1]),
      _weatherAlerts!.severityForLocation(widget.location, days[2]),
      _weatherAlerts!.severityForLocation(widget.location, days[3]),
      _weatherAlerts!.severityForLocation(widget.location, days[4]),
      // WeatherAlertSeverity.unknown,
      // WeatherAlertSeverity.minor,
      // WeatherAlertSeverity.moderate,
      // WeatherAlertSeverity.severe,
      // WeatherAlertSeverity.extreme,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            localizations.weatherWarnings
          ),
          Row(
            spacing: 5,
            children: [
              for(var i = 0; i < days.length; i++)
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: getGradientColors(severity[i]),
                          ),
                        ),
                        child:Text(
                          DateFormat.E(appState.locale.languageCode).format(days[i]),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: getBorderColor(severity[i]),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                )
            ],
          )
        ],
      ),
    );
  }
}
