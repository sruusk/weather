import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather/app_state.dart';
import 'package:weather/data/forecast.dart';
import 'package:weather/data/location.dart';
import 'package:weather/widgets/home/precipitation.dart';
import 'package:weather/widgets/home/sunrise_sunset_widget.dart';
import 'package:weather/widgets/home/wind_arrow.dart';
import 'package:weather/widgets/weather_symbol_widget.dart';

class CurrentForecast extends StatelessWidget {
  final Forecast forecast;
  final List<Location> locations;
  final int selectedIndex;
  final Function(int) onLocationChanged;
  final Location? geoLocation;

  const CurrentForecast({
    super.key,
    required this.forecast,
    required this.locations,
    required this.selectedIndex,
    required this.onLocationChanged,
    this.geoLocation,
  });

  @override
  Widget build(BuildContext context) {
    final f = forecast;
    final p = f.forecast.firstWhere(
      (p) => p.time.isAfter(DateTime.now()),
    );
    final appState = Provider.of<AppState>(context);

    return SizedBox(
      height: 300,
      child: Column(
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedIndex,
              icon: const Icon(Icons.arrow_drop_down),
              borderRadius: BorderRadius.circular(8),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              items: [
                for (int i = 0; i < locations.length; i++)
                  DropdownMenuItem<int>(
                    value: i,
                    child: Row(
                      children: [
                        Icon(i == 0 &&
                                appState.geolocationEnabled &&
                                geoLocation != null
                            ? Icons.my_location
                            : Icons.place),
                        SizedBox(width: 8),
                        Text(
                          locations[i].name +
                              (locations[i].region != null
                                  ? ', ${locations[i].region}'
                                  : ''),
                        ),
                      ],
                    ),
                  ),
              ],
              onChanged: (i) {
                if (i == null) return;
                onLocationChanged(i);
              },
            ),
          ),

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
                    symbolName: p.weatherSymbol ?? 'error',
                    size: 150,
                  ),
                  RichText(
                    text: TextSpan(
                      text: '${p.temperature! >= 0 ? '+' : ''}'
                          '${p.temperature!.toStringAsFixed(0)}',
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
                          degrees: p.windDirection ?? 0,
                          windSpeed: p.windSpeed ?? 0,
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
