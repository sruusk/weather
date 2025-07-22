import 'package:flutter/material.dart';
import 'package:weather/data/weather_alert.dart';

class AlertCardWidget extends StatelessWidget {
  final WeatherAlert alert;

  const AlertCardWidget({
    super.key,
    required this.alert,
  });

  // Get color based on alert severity
  Color _getSeverityColor(WeatherAlertSeverity severity) {
    switch (severity) {
      case WeatherAlertSeverity.minor:
        return Colors.green;
      case WeatherAlertSeverity.moderate:
        return Colors.yellowAccent;
      case WeatherAlertSeverity.severe:
        return Colors.orange;
      case WeatherAlertSeverity.extreme:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the appropriate language based on device locale
    final locale = Localizations.localeOf(context).languageCode;
    WeatherEvent event;

    // Select the appropriate language version
    if (locale == 'sv') {
      event = alert.sv;
    } else if (locale == 'fi') {
      event = alert.fi;
    } else {
      event = alert.en;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _getSeverityColor(alert.severity),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getSeverityColor(alert.severity),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.headline,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              style: const TextStyle(fontSize: 14),
            ),
            if (event.impact != null) ...[
              const SizedBox(height: 8),
              Text(
                event.impact!,
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
