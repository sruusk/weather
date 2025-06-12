
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
      _pageController.jumpToPage(0); // Reset to first page when location changes
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

    return Builder(
        builder: (BuildContext context) {
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
                      if (station.temperature != null)
                        _buildInfoItem(context, localizations.temperature,
                            '${station.temperature!.toStringAsFixed(1)}${localizations.temperatureCelsius}'),
                      if (station.humidity != null)
                        _buildInfoItem(context, localizations.humidity,
                            '${station.humidity!.toStringAsFixed(0)}%'),
                      if (station.dewPoint != null)
                        _buildInfoItem(context, localizations.dewPoint,
                            '${station.dewPoint!.toStringAsFixed(1)}${localizations.temperatureCelsius}'),
                      if (station.windSpeed != null)
                        _buildInfoItem(context, localizations.windSpeed,
                            '${station.windSpeed!.toStringAsFixed(1)} m/s'),
                      if (station.windDirection != null)
                        _buildInfoItem(context, localizations.windDirection,
                            '${station.windDirection!.toStringAsFixed(0)}°'),
                      if (station.windGust != null)
                        _buildInfoItem(context, localizations.windGust,
                            '${station.windGust!.toStringAsFixed(1)} m/s'),
                      if (station.precipitation != null)
                        _buildInfoItem(context, localizations.precipitation,
                            '${station.precipitation!.toStringAsFixed(1)} mm'),
                      if (station.snowDepth != null)
                        _buildInfoItem(context, localizations.snowDepth,
                            '${station.snowDepth!.toStringAsFixed(0)} cm'),
                      if (station.pressure != null)
                        _buildInfoItem(context, localizations.pressure,
                            '${station.pressure!.toStringAsFixed(0)} hPa'),
                      if (station.cloudBase != null)
                        _buildInfoItem(context, localizations.cloudBase,
                            '${station.cloudBase!.toStringAsFixed(0)} m'),
                      if (station.visibility != null)
                        _buildInfoItem(context, localizations.visibility,
                            '${(station.visibility! / 1000).toStringAsFixed(1)} km'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                      child: station.temperatureHistory == null ||
                          station.temperatureHistory!.isEmpty
                          ? Center(
                          child: Text(localizations.noTemperatureHistoryData))
                          : Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Stack(
                          children: [
                            LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: AxisTitles(
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
                                              style:
                                              const TextStyle(fontSize: 10)),
                                        );
                                      },
                                      // Show fewer labels to avoid overcrowding
                                      reservedSize: 30,
                                      interval: 3600000 *
                                          2, // Show a label every 2 hours
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
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
                                minX: _getMinX(station.temperatureHistory!),
                                maxX: _getMaxX(station.temperatureHistory!),
                                minY: _getMinY(station.temperatureHistory!),
                                maxY: _getMaxY(station.temperatureHistory!),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _getTemperatureSpots(
                                        station.temperatureHistory!),
                                    isCurved: true,
                                    color: Colors.blue,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue,
                                        Colors.deepPurple,
                                        Colors.purple,
                                      ],
                                    ),
                                    barWidth: 4,
                                    belowBarData: BarAreaData(show: false),
                                    dotData: FlDotData(show: false),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 0,
                              left: 50,
                              child: Center(
                                child: Text(localizations.temperatureCelsius,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: Colors.green)),
                              ),
                            ),
                          ],
                        ),
                      )
                  ),
                ],
              ),
            ),
          );
        }
    );
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
    final twelveHoursAgo = now.subtract(Duration(hours: 12, minutes: now.minute, seconds: now.second));

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
  double _getMinX(List<TimeSeries> history) {
    DateTime now = DateTime.now();
    now = DateTime(now.year, now.month, now.day, now.hour, 0, 0);
    final twelveHoursAgo = now.subtract(const Duration(hours: 12));
    return twelveHoursAgo.millisecondsSinceEpoch.toDouble();
  }

  /// Gets the maximum X value for the chart
  double _getMaxX(List<TimeSeries> history) {
    DateTime now = DateTime.now();
    now = DateTime(now.year, now.month, now.day, now.hour + 1, 0, 0);
    return now.millisecondsSinceEpoch.toDouble();
  }

  /// Gets the minimum Y value for the chart with some padding
  double _getMinY(List<TimeSeries> history) {
    if (history.isEmpty) return 0;

    // Find the minimum temperature
    final minTemp = history.map((e) => e.value).reduce((a, b) => a < b ? a : b);

    // Add some padding (10% of the range, or at least 2 degrees)
    return minTemp.floor() - 2;
  }

  /// Gets the maximum Y value for the chart with some padding
  double _getMaxY(List<TimeSeries> history) {
    if (history.isEmpty) return 10;

    // Find the maximum temperature
    final maxTemp = history.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    // Add some padding (10% of the range, or at least 2 degrees)
    return maxTemp.ceil() + 2;
  }
}
