import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:weather/app_state.dart';
import 'package:weather/data/forecast.dart';
import 'package:weather/data/forecast_point.dart';
import 'package:weather/widgets/home/precipitation.dart';
import 'package:weather/widgets/home/wind_arrow.dart';
import 'package:weather/widgets/weather_symbol_widget.dart';

class ForecastWidget extends StatelessWidget {
  final Forecast? forecast;

  const ForecastWidget({super.key, this.forecast});

  @override
  Widget build(BuildContext context) {
    if (forecast == null) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('No forecast data available')),
      );
    }

    final appState = Provider.of<AppState>(context);

    // Helper to group points by day label
    Map<String, List<ForecastPoint>> groupByDay(List<ForecastPoint> points) {
      final Map<String, List<ForecastPoint>> map = {};
      for (var p in points) {
        // Skip past data
        if (p.time.isBefore(DateTime.now())) continue;
        final dayLabel =
            DateFormat('EEE', appState.locale.languageCode).format(p.time);
        map.putIfAbsent(dayLabel, () => []).add(p);
      }
      return map;
    }

    (String, String) getDaySymbolTemp(List<ForecastPoint> points) {
      // Count occurrences of weather symbols and store their codes
      final symbolCounts = <String, int>{};
      final symbolCodes = <String, int>{};

      // Filter points between 9:00 and 18:00 and count symbols
      for (var p in points) {
        if (p.time.hour >= 9 && p.time.hour <= 18) {
          symbolCounts[p.weatherSymbol] =
              (symbolCounts[p.weatherSymbol] ?? 0) + 1;
          symbolCodes[p.weatherSymbol] = p.weatherSymbolCode;
        }
      }

      // Use all points if no symbols found in the time range
      if (symbolCounts.isEmpty) {
        for (var p in points) {
          symbolCounts[p.weatherSymbol] =
              (symbolCounts[p.weatherSymbol] ?? 0) + 1;
          symbolCodes[p.weatherSymbol] = p.weatherSymbolCode;
        }
      }

      // Determine the most frequent symbol
      String mostFrequentSymbol = points.first.weatherSymbol;
      int maxCount = 0;

      symbolCounts.forEach((symbol, count) {
        if (count > maxCount ||
            (count == maxCount &&
                symbolCodes[symbol]! > symbolCodes[mostFrequentSymbol]!)) {
          maxCount = count;
          mostFrequentSymbol = symbol;
        }
      });

      // Find the highest temperature
      double highestTemp = points.fold(
          0, (maxTemp, p) => p.temperature > maxTemp ? p.temperature : maxTemp);

      return (mostFrequentSymbol, highestTemp.toStringAsFixed(0));
    }

    final grouped = groupByDay(forecast!.forecast);
    final days = grouped.keys.toList();

    return SizedBox(
      height: 335,
      child: DefaultTabController(
        length: days.length,
        child: Column(
          children: [
            SizedBox(
              height: 92,
              child: TabBar(
                isScrollable: true,
                labelPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                tabAlignment: TabAlignment.start,
                tabs: days.map((day) {
                  final (symbol, temp) = getDaySymbolTemp(grouped[day]!);
                  return Column(
                    children: [
                      Text(
                        day[0].toUpperCase() + day.substring(1).toLowerCase(),
                        style: const TextStyle(fontSize: 16),
                      ),
                      SizedBox(
                        width: 50,
                        height: 63,
                        child: Stack(
                          children: [
                            Transform.translate(
                              offset: const Offset(0, -8),
                              child: WeatherSymbolWidget(
                                symbolName: symbol,
                                useFilled: false,
                                size: 50,
                              ),
                            ),
                            Positioned(
                                bottom: 0,
                                right: 5,
                                child: Text(
                                  '$temp°C',
                                  style: const TextStyle(fontSize: 16),
                                ))
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey,
              ),
            ),
            Expanded(
              child: TabBarView(
                children: days.map((day) {
                  final points = grouped[day]!;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: points.length,
                    itemBuilder: (ctx, i) {
                      final data = points[i];

                      // Skip past data
                      if (data.time.isBefore(DateTime.now())) {
                        return const SizedBox.shrink();
                      }

                      return Card(
                        margin: const EdgeInsets.only(
                            top: 10, left: 2, right: 2, bottom: 2),
                        color: Theme.of(context).colorScheme.surfaceDim,
                        child: SizedBox(
                          width: 71,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Column(
                                  children: [
                                    Text(DateFormat.Hm().format(data.time)),
                                    Divider(),
                                  ],
                                ),
                                Text(
                                  '${data.temperature.toStringAsFixed(0)}°C',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                WeatherSymbolWidget(
                                    symbolName: data.weatherSymbol,
                                    useFilled: false,
                                    size: 60),
                                WindArrow(
                                  degrees: data.windDirection,
                                  windSpeed: data.windSpeed,
                                ),
                                Precipitation(p: data, compact: true),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
