import 'package:daylight/daylight.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather/data/location.dart';
import 'package:weather/widgets/weather_symbol_widget.dart';

class SunriseSunsetWidget extends StatelessWidget {
  final Location location;

  const SunriseSunsetWidget({
    super.key,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final cal = DaylightCalculator(
      DaylightLocation(location.lat, location.lon),
    );

    final todayCalc = cal.calculateForDay(now);
    final bool isMidnightSun = todayCalc.type == DayType.allDay;

    DateTime? sunrise;
    DateTime? sunset;

    if (isMidnightSun) {
      // start at today’s noon
      DateTime cursor = DateTime(now.year, now.month, now.day, 12);
      // find last day that has a sunrise
      while (cal.calculateForDay(cursor).type == DayType.allDay) {
        cursor = cursor.subtract(const Duration(days: 1));
      }
      sunrise = cal.calculateForDay(cursor).sunrise;
      // reset cursor for sunset search
      cursor = DateTime(now.year, now.month, now.day, 12);
      // find first day that has a sunset
      while (cal.calculateForDay(cursor).type == DayType.allDay) {
        cursor = cursor.add(const Duration(days: 1));
      }
      sunset = cal.calculateForDay(cursor).sunset;
    } else {
      sunrise = todayCalc.sunrise;
      sunset = todayCalc.sunset;
    }

    final format = isMidnightSun ? DateFormat('d.M', 'fi_FI') : DateFormat.Hm();
    final String sunriseStr = format.format(sunrise!.toLocal());
    final String sunsetStr = format.format(sunset!.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Transform.translate(
          offset: const Offset(0, 2),
          child: WeatherSymbolWidget(symbolName: "sunrise"),
        ),
        Transform.translate(
          offset: const Offset(0, -10),
          child: Text(
            "$sunriseStr - $sunsetStr",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
