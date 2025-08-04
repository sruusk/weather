import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:weather/data/location.dart';
import 'package:weather/data/observation_data.dart';
import 'package:weather/data/observation_station.dart';
import 'package:weather/l10n/app_localizations.g.dart';
import 'package:weather/widgets/home/observation_chart_widget.dart';

class ObservationsWidget extends StatefulWidget {
  final Location? location;
  final double maxWidth;

  const ObservationsWidget({super.key, this.location, this.maxWidth = 600});

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

    // This should not happen, but just in case
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
              height: widget.maxWidth > 390 ? 410 : 500,
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
                child: ObservationChartWidget(
                  station: station,
                ),
              ),
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
}
