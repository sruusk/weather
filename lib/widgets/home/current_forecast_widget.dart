import 'package:flutter/material.dart';
import 'package:weather/data/forecast.dart';
import 'package:weather/data/location.dart';
import 'package:weather/widgets/home/precipitation.dart';
import 'package:weather/widgets/home/sunrise_sunset_widget.dart';
import 'package:weather/widgets/home/wind_arrow.dart';
import 'package:weather/widgets/location_dropdown.dart';
import 'package:weather/widgets/weather_symbol_widget.dart';

class CurrentForecast extends StatelessWidget {
  final Forecast forecast;
  final List<Location> locations;
  final double height;

  const CurrentForecast({
    super.key,
    required this.forecast,
    required this.locations,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    final f = forecast;
    final p = f.forecast.firstWhere(
      (p) => p.time.isAfter(DateTime.now()),
    );

    return SizedBox(
      height: height,
      child: Column(
        children: [
          const LocationDropdown(),

          const Spacer(),

          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 8,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  WeatherSymbolWidget(
                    symbolName: p.weatherSymbol,
                    size: 150,
                  ),
                  RichText(
                    text: TextSpan(
                      text: '${p.temperature >= 0 ? '+' : ''}'
                          '${p.temperature.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.w300,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      children: const [
                        TextSpan(
                          text: '°C',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              )),

          const SizedBox(height: 16),

          // Bottom info bar
          Card(
              margin: const EdgeInsets.all(0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: IntrinsicHeight(
                  child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Precipitation(p: p),
                  ),
                  const VerticalDivider(
                      thickness: 1,
                      color: Colors.grey,
                      indent: 8,
                      endIndent: 8),
                  Expanded(
                    flex: 2,
                    child: SunriseSunsetWidget(location: f.location),
                  ),
                  const VerticalDivider(
                      thickness: 1,
                      color: Colors.grey,
                      indent: 8,
                      endIndent: 8),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        WindArrow(
                          degrees: p.windDirection,
                          windSpeed: p.windSpeed,
                          size: 55,
                        ),
                      ],
                    ),
                  ),
                ],
              ))),
        ],
      ),
    );
  }
}
