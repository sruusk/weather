import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:weather/data/location.dart';
import 'package:weather/data/observation_data.dart';
import 'package:weather/data/observation_station.dart';
import 'package:weather/data/time_series.dart';
import 'package:weather/l10n/app_localizations.g.dart';

class ObservationsWidget extends StatefulWidget {
  final Location? location;

  const ObservationsWidget({super.key, this.location});

  @override
  State<ObservationsWidget> createState() => _ObservationsWidgetState();
}

class _ObservationsWidgetState extends State<ObservationsWidget> {
  final ObservationData _observationData = ObservationData();
  final PageController _pageController = PageController(initialPage: 0);
  late Future<List<ObservationStation>> _stationsFuture;

  Future<List<ObservationStation>> _getStations() async {
    if (widget.location == null) return [];
    return await _observationData.getClosestStations(widget.location!);
  }

  @override
  void initState() {
    super.initState();
    // Initialize the future to fetch stations
    _stationsFuture = _getStations();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Rebuild the stations future when the location changes
  @override
  void didUpdateWidget(covariant ObservationsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _stationsFuture = _getStations();
      _stationsFuture.then((_) {
        // Reset the page controller to the first page when location changes
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
      if (_pageController.hasClients) {
        _pageController
            .jumpToPage(0); // Reset to first page when location changes
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if (widget.location == null) {
      return SizedBox(
        height: 100,
        child: Center(child: Text(localizations.noLocationSelected)),
      );
    }

    return FutureBuilder<List<ObservationStation>>(
      future: _stationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 200,
            child: Center(
                child: Text(localizations.error(snapshot.error.toString()))),
          );
        }

        final stations = snapshot.data ?? [];

        if (stations.isEmpty) {
          return SizedBox(
            height: 200,
            child:
                Center(child: Text(localizations.noObservationStationsFound)),
          );
        }

        // Ensure we start at the first page when stations are loaded
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(0);
          }
        });

        return Column(
          children: [
            SmoothPageIndicator(
              controller: _pageController,
              count: stations.length,
              effect: const WormEffect(dotWidth: 10, dotHeight: 10),
              onDotClicked: (i) => _pageController.animateToPage(
                i,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 390,
              child: PageView.builder(
                controller: _pageController,
                itemCount: stations.length,
                itemBuilder: (context, index) {
                  return _buildStationCard(context, stations[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStationCard(BuildContext context, ObservationStation station) {
    final localizations = AppLocalizations.of(context)!;

    return Builder(builder: (BuildContext context) {
      return Container(
        margin: const EdgeInsets.all(0),
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${station.location.name} (${station.time.toLocal().hour}:${station.time.toLocal().minute.toString().padLeft(2, '0')})",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                localizations.distance(
                    station.location.distance?.toStringAsFixed(1) ?? "0.0"),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16, // horizontal space between items
                runSpacing: 8, // vertical space between lines
                children: [
                  if (station.temperature != null &&
                      station.temperature!.isNotEmpty)
                    _buildInfoItem(context, localizations.temperature,
                        '${station.temperature!.last.value.toStringAsFixed(1)}${localizations.temperatureCelsius}'),
                  if (station.humidity != null && station.humidity!.isNotEmpty)
                    _buildInfoItem(context, localizations.humidity,
                        '${station.humidity!.last.value.toStringAsFixed(0)}%'),
                  if (station.dewPoint != null && station.dewPoint!.isNotEmpty)
                    _buildInfoItem(context, localizations.dewPoint,
                        '${station.dewPoint!.last.value.toStringAsFixed(1)}${localizations.temperatureCelsius}'),
                  if (station.windSpeed != null &&
                      station.windSpeed!.isNotEmpty)
                    _buildInfoItem(context, localizations.windSpeed,
                        '${station.windSpeed!.last.value.toStringAsFixed(1)} m/s'),
                  if (station.windDirection != null &&
                      station.windDirection!.isNotEmpty)
                    _buildInfoItem(context, localizations.windDirection,
                        '${station.windDirection!.last.value.toStringAsFixed(0)}°'),
                  if (station.windGust != null && station.windGust!.isNotEmpty)
                    _buildInfoItem(context, localizations.windGust,
                        '${station.windGust!.last.value.toStringAsFixed(1)} m/s'),
                  if (station.precipitation != null &&
                      station.precipitation!.isNotEmpty)
                    _buildInfoItem(context, localizations.precipitation,
                        '${station.precipitation!.last.value.toStringAsFixed(1)} mm'),
                  if (station.snowDepth != null &&
                      station.snowDepth!.isNotEmpty)
                    _buildInfoItem(context, localizations.snowDepth,
                        '${station.snowDepth!.last.value.toStringAsFixed(0)} cm'),
                  if (station.pressure != null && station.pressure!.isNotEmpty)
                    _buildInfoItem(context, localizations.pressure,
                        '${station.pressure!.last.value.toStringAsFixed(0)} hPa'),
                  if (station.cloudBase != null &&
                      station.cloudBase!.isNotEmpty)
                    _buildInfoItem(context, localizations.cloudBase,
                        '${station.cloudBase!.last.value.toStringAsFixed(0)} m'),
                  if (station.visibility != null &&
                      station.visibility!.isNotEmpty)
                    _buildInfoItem(context, localizations.visibility,
                        '${(station.visibility!.last.value / 1000).toStringAsFixed(1)} km'),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                  child: station.temperature == null ||
                          station.temperature!.isEmpty
                      ? Center(
                          child: Text(localizations.noTemperatureHistoryData))
                      : LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            horizontalInterval: 5,
                            verticalInterval:
                                60 * 60 * 1000, // 1 hour in milliseconds
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              axisNameWidget: SizedBox.shrink(),
                              axisNameSize: 20,
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  // Convert milliseconds to DateTime
                                  final dateTime =
                                      DateTime.fromMillisecondsSinceEpoch(
                                          value.toInt());
                                  // Format as HH:mm
                                  final formattedTime =
                                      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(top: 8.0),
                                    child: Text(formattedTime,
                                        style: const TextStyle(
                                            fontSize: 10)),
                                  );
                                },
                                // Show fewer labels to avoid overcrowding
                                reservedSize: 30,
                                interval: 3600000 * 2,
                                // Show a label every 2 hours
                                maxIncluded: false,
                                minIncluded: false,
                              ),
                              axisNameSize: 20,
                              axisNameWidget: Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 4,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    color: Colors.green,
                                  ),
                                  Text(localizations.temperature,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                              color: Colors.green)),
                                  const SizedBox(width: 10),
                                  Container(
                                    width: 10,
                                    height: 10,
                                    color: Colors.blue,
                                  ),
                                  Text(localizations.dewPoint,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(color: Colors.blue)),
                                ],
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                interval: 5,
                                // maxIncluded: false,
                                // minIncluded: false,
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(
                              color: Colors.grey,
                              width: 1,
                            ),
                          ),
                          // minX: _getMinX(station.temperature!),
                          // maxX: _getMaxX(station.temperature!),
                          minY: _getMinY([
                            ...station.temperature!,
                            ...station.dewPoint ?? []
                          ]),
                          maxY: _getMaxY([
                            ...station.temperature!,
                            ...station.dewPoint ?? []
                          ]),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _getTemperatureSpots(
                                  station.temperature!),
                              isCurved: true,
                              color: Colors.green,
                              barWidth: 3,
                              belowBarData: BarAreaData(show: false),
                              dotData: FlDotData(show: false),
                            ),
                            LineChartBarData(
                              spots:
                                  _getTemperatureSpots(station.dewPoint!),
                              isCurved: true,
                              color: Colors.blue,
                              barWidth: 3,
                              belowBarData: BarAreaData(show: false),
                              dotData: FlDotData(show: false),
                            ),
                          ],
                        ),
                      )),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildInfoItem(BuildContext context, String label, String value) {
    return SizedBox(
      width: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  // Helper methods for temperature history chart

  /// Filters history to only include entries from the past 12 hours and converts to FlSpot
  List<FlSpot> _getTemperatureSpots(List<TimeSeries> history) {
    final DateTime now = DateTime.now();
    final twelveHoursAgo = now.subtract(
        Duration(hours: 12, minutes: now.minute, seconds: now.second));

    // Filter for last 12 hours and sort by time
    final filteredHistory = history
        .where((item) =>
            item.time.isAfter(twelveHoursAgo) && item.time.isBefore(now))
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    if (filteredHistory.isEmpty) {
      return [];
    }

    // Convert to FlSpot using timestamp as X value
    return filteredHistory.map((item) {
      // Use milliseconds since epoch as X value
      return FlSpot(item.time.millisecondsSinceEpoch.toDouble(), item.value);
    }).toList();
  }

  /// Gets the minimum X value for the chart
  // ignore: unused_element
  double _getMinX(List<TimeSeries> history) {
    if (history.isEmpty) return 0;

    // Find the earliest time in the history
    final minTime =
        history.map((e) => e.time).reduce((a, b) => a.isBefore(b) ? a : b);

    // Round down to the nearest hour
    final roundedMinTime = DateTime.utc(
        minTime.year, minTime.month, minTime.day, minTime.hour, 0, 0);

    return roundedMinTime.millisecondsSinceEpoch.toDouble();
  }

  /// Gets the maximum X value for the chart
  // ignore: unused_element
  double _getMaxX(List<TimeSeries> history) {
    if (history.isEmpty) return 0;

    // Find the latest time in the history
    final maxTime =
        history.map((e) => e.time).reduce((a, b) => a.isAfter(b) ? a : b);

    // Round up to the nearest hour
    final roundedMaxTime = DateTime.utc(maxTime.year, maxTime.month,
        maxTime.day, maxTime.hour + 1 + (maxTime.hour % 2 == 0 ? 1 : 0), 0, 0);

    return roundedMaxTime.millisecondsSinceEpoch.toDouble();
  }

  /// Gets the minimum Y value for the chart with some padding
  double _getMinY(List<TimeSeries> history) {
    if (history.isEmpty) return 0;

    // Find the minimum temperature
    final minTemp =
        history.map((e) => e.value).reduce((a, b) => a < b ? a : b).floor();

    // Add some padding
    return minTemp - minTemp % 5;
  }

  /// Gets the maximum Y value for the chart with some padding
  double _getMaxY(List<TimeSeries> history) {
    if (history.isEmpty) return 10;

    // Find the maximum temperature
    final maxTemp =
        history.map((e) => e.value).reduce((a, b) => a > b ? a : b).ceil();

    // Add some padding
    return maxTemp + (5 - maxTemp % 5);
  }
}
