import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:weather/data/observation_station.dart';
import 'package:weather/data/time_series.dart';
import 'package:weather/l10n/app_localizations.g.dart';

/// Enum defining the available chart types
enum ChartType {
  temperature,
  wind,
}

/// A widget that displays observation charts (temperature, wind, etc.)
class ObservationChartWidget extends StatefulWidget {
  final ObservationStation station;

  const ObservationChartWidget({
    super.key,
    required this.station,
  });

  @override
  State<ObservationChartWidget> createState() => _ObservationChartWidgetState();
}

class _ObservationChartWidgetState extends State<ObservationChartWidget> {
  // Current selected chart type
  ChartType _selectedChartType = ChartType.temperature;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Chart type selector buttons
        if (widget.station.windSpeed != null &&
            widget.station.windSpeed!.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildChartTypeButton(
                context,
                ChartType.temperature,
                localizations.temperature,
              ),
              const SizedBox(width: 10),
              _buildChartTypeButton(
                context,
                ChartType.wind,
                localizations.windSpeed,
              ),
            ],
          ),
        const SizedBox(height: 10),
        Expanded(child: _buildChart(context, widget.station, localizations)),
      ],
    );
  }

  /// Builds a button for selecting a chart type
  Widget _buildChartTypeButton(
      BuildContext context, ChartType chartType, String label) {
    final isSelected = _selectedChartType == chartType;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedChartType = chartType;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surface,
        foregroundColor: isSelected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onSurface,
      ),
      child: Text(label),
    );
  }

  /// Builds the appropriate chart based on the selected chart type
  Widget _buildChart(BuildContext context, ObservationStation station,
      AppLocalizations localizations) {
    switch (_selectedChartType) {
      case ChartType.temperature:
        return _buildTemperatureChart(context, station, localizations);
      case ChartType.wind:
        return _buildWindChart(context, station, localizations);
    }
  }

  /// Builds the temperature chart
  Widget _buildTemperatureChart(BuildContext context,
      ObservationStation station, AppLocalizations localizations) {
    if (station.temperature == null || station.temperature!.isEmpty) {
      return Center(child: Text(localizations.noTemperatureHistoryData));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          horizontalInterval: 5,
          verticalInterval: 60 * 60 * 1000, // 1 hour in milliseconds
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
                    DateTime.fromMillisecondsSinceEpoch(value.toInt());
                // Format as HH:mm
                final formattedTime =
                    '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child:
                      Text(formattedTime, style: const TextStyle(fontSize: 10)),
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
              children: [
                Container(
                  width: 10,
                  height: 10,
                  color: Colors.green,
                ),
                const SizedBox(width: 4),
                Text(localizations.temperature,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: Colors.green)),
                const SizedBox(width: 10),
                Container(
                  width: 10,
                  height: 10,
                  color: Colors.blue,
                ),
                const SizedBox(width: 4),
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
        minY: _getMinY([...station.temperature!, ...station.dewPoint ?? []]),
        maxY: _getMaxY([...station.temperature!, ...station.dewPoint ?? []]),
        lineBarsData: [
          LineChartBarData(
            spots: _getTimeSeriesSpots(station.temperature!),
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            belowBarData: BarAreaData(show: false),
            dotData: FlDotData(show: false),
          ),
          if (station.dewPoint != null && station.dewPoint!.isNotEmpty)
            LineChartBarData(
              spots: _getTimeSeriesSpots(station.dewPoint!),
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              belowBarData: BarAreaData(show: false),
              dotData: FlDotData(show: false),
            ),
        ],
      ),
    );
  }

  /// Builds the wind chart
  Widget _buildWindChart(BuildContext context, ObservationStation station,
      AppLocalizations localizations) {
    if ((station.windSpeed == null || station.windSpeed!.isEmpty) &&
        (station.windGust == null || station.windGust!.isEmpty)) {
      return Center(child: Text(localizations.noWindHistoryData));
    }

    // Combine wind speed and gust data for min/max calculations
    final List<TimeSeries> allWindData = [
      ...station.windSpeed ?? [],
      ...station.windGust ?? [],
    ];

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          horizontalInterval: 2, // Different interval for wind speeds
          verticalInterval: 60 * 60 * 1000, // 1 hour in milliseconds
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
                    DateTime.fromMillisecondsSinceEpoch(value.toInt());
                // Format as HH:mm
                final formattedTime =
                    '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child:
                      Text(formattedTime, style: const TextStyle(fontSize: 10)),
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
              children: [
                Container(
                  width: 10,
                  height: 10,
                  color: Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(localizations.windSpeed,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: Colors.orange)),
                const SizedBox(width: 10),
                Container(
                  width: 10,
                  height: 10,
                  color: Colors.red,
                ),
                const SizedBox(width: 4),
                Text(localizations.windGust,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: Colors.red)),
              ],
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 2,
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
        minY: _getMinY(allWindData),
        maxY: _getMaxY(allWindData),
        lineBarsData: [
          if (station.windSpeed != null && station.windSpeed!.isNotEmpty)
            LineChartBarData(
              spots: _getTimeSeriesSpots(station.windSpeed!),
              isCurved: true,
              color: Colors.orange,
              barWidth: 3,
              belowBarData: BarAreaData(show: false),
              dotData: FlDotData(show: false),
            ),
          if (station.windGust != null && station.windGust!.isNotEmpty)
            LineChartBarData(
              spots: _getTimeSeriesSpots(station.windGust!),
              isCurved: true,
              color: Colors.red,
              barWidth: 3,
              belowBarData: BarAreaData(show: false),
              dotData: FlDotData(show: false),
            ),
        ],
      ),
    );
  }

  // Helper methods for chart data

  /// Filters history to only include entries from the past 12 hours and converts to FlSpot
  /// Used for all chart types (temperature, wind, etc.)
  List<FlSpot> _getTimeSeriesSpots(List<TimeSeries> history) {
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
