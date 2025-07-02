import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:weather/app_state.dart';
import 'package:weather/data/forecast.dart';
import 'package:weather/data/forecast_point.dart';
import 'package:weather/widgets/home/precipitation.dart';
import 'package:weather/widgets/home/wind_arrow.dart';
import 'package:weather/widgets/weather_symbol_widget.dart';

class ForecastWidget extends StatefulWidget {
  final Forecast? forecast;

  const ForecastWidget({super.key, this.forecast});

  @override
  State<ForecastWidget> createState() => _ForecastWidgetState();
}

class _ForecastWidgetState extends State<ForecastWidget> {
  final ScrollController _scrollController = ScrollController();
  String _currentDay = '';
  Map<String, int> _dayPositions = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateCurrentDay);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateCurrentDay);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateCurrentDay() {
    if (_dayPositions.isEmpty) return;

    final offset = _scrollController.offset;
    String currentDay = _dayPositions.keys.first;

    // Find which day section we're currently viewing
    for (final entry in _dayPositions.entries) {
      if (offset >= entry.value) {
        currentDay = entry.key;
      } else {
        break;
      }
    }

    if (currentDay != _currentDay) {
      setState(() {
        _currentDay = currentDay;
      });
    }
  }

  void _scrollToDay(String day) {
    if (_dayPositions.containsKey(day)) {
      double delta =
          _scrollController.position.pixels - _dayPositions[day]!.toDouble();
      _scrollController.animateTo(
        _dayPositions[day]!.toDouble(),
        duration: Duration(milliseconds: (delta / 2).abs().floor()),
        curve: Curves.linearToEaseOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.forecast == null) {
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

    // Filter and sort forecast points
    final filteredPoints = widget.forecast!.forecast
        .where((p) => !p.time.isBefore(DateTime.now()))
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    // Group points by day
    final grouped = groupByDay(filteredPoints);
    final days = grouped.keys.toList();

    // If no current day is set, set it to the first day
    if (_currentDay.isEmpty && days.isNotEmpty) {
      _currentDay = days.first;
    }

    // Create a flat list of all points for continuous scrolling
    final allPoints = <ForecastPoint>[];
    final cardWidth = 75.0; // Width of each forecast card including margins

    // Calculate positions for each day in the scrollable list
    _dayPositions = {};
    int position = 0;

    for (final day in days) {
      _dayPositions[day] = (position * cardWidth).toInt();
      final points = grouped[day]!;
      allPoints.addAll(points);
      position += points.length;
    }

    return SizedBox(
      height: 335,
      child: Column(
        children: [
          // Day selector row
          SizedBox(
            height: 92,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final (symbol, temp) = getDaySymbolTemp(grouped[day]!);
                final isSelected = day == _currentDay;

                return GestureDetector(
                  onTap: () => _scrollToDay(day),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          day[0].toUpperCase() + day.substring(1).toLowerCase(),
                          style: TextStyle(
                            fontSize: 16,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          height: 63,
                          child: Stack(
                            children: [
                              Transform.translate(
                                offset: const Offset(0, -6),
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
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Indicator line for active day
                        SizedOverflowBox(
                          size: const Size(50, 3),
                          child: ClipRect(
                            clipBehavior: Clip.hardEdge,
                            clipper: TopHalfClipper(),
                            child: Container(
                              height: 6,
                              width: 50,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Transform.translate(
            offset: const Offset(0, -1),
            child: Divider(
              height: 1,
            ),
          ),

          // Continuous horizontal list of hourly forecasts
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: allPoints.length,
              itemBuilder: (ctx, i) {
                final data = allPoints[i];

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
                            size: 60,
                          ),
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
            ),
          ),
        ],
      ),
    );
  }
}

class TopHalfClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width, size.height / 2);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return false;
  }
}
