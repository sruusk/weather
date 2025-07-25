import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:weather/app_state.dart';
import 'package:weather/data/constants.dart';
import 'package:weather/data/weather_alert.dart';
import 'package:weather/data/weather_alerts.dart';
import 'package:weather/widgets/warnings/alert_overlay_card_widget.dart';
import 'package:weather/widgets/warnings/alerts_by_geocode_widget.dart';
import 'package:weather/widgets/warnings/warnings_map_widget.dart';

class WarningsPage extends StatefulWidget {
  const WarningsPage({super.key});

  @override
  State<WarningsPage> createState() => _WarningsPageState();
}

class _WarningsPageState extends State<WarningsPage> {
  DateTime _selectedDate = DateTime.now();
  List<WeatherAlert> _weatherAlerts = [];
  final LayerHitNotifier<HitValue> hitNotifier = ValueNotifier(null);
  bool showOverlay = false;
  WeatherAlerts? alerts;

  @override
  void initState() {
    super.initState();

    // Load weather alerts
    _loadWeatherAlerts();
  }

  void _loadWeatherAlerts() {
    WeatherAlerts.instance().load().then((alerts) {
      setState(() {
        _weatherAlerts = alerts.getAlerts(time: _selectedDate);
        this.alerts = alerts;
      });
    });
  }

  void _updateSelectedDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadWeatherAlerts();
  }

  Color getDaySelectorColor(WeatherAlertSeverity? severity) {
    switch (severity ?? WeatherAlertSeverity.unknown) {
      case WeatherAlertSeverity.minor:
        return Colors.lightGreenAccent;
      case WeatherAlertSeverity.moderate:
        return Colors.yellowAccent;
      case WeatherAlertSeverity.severe:
        return Colors.orange;
      case WeatherAlertSeverity.extreme:
        return Colors.red;
      default:
        return Colors.lightGreen;
    }
  }

  Widget _buildDaySelector({
    required DateTime date,
    required bool isSelected,
    required double width,
  }) {
    // Get localized day name (Mon, Tue, etc.) using DateFormat
    final appState = Provider.of<AppState>(context, listen: false);
    final dayName = DateFormat.E(appState.locale.languageCode).format(date);

    // Format date using locale-appropriate format for day and month
    final dateStr = DateFormat.Md(appState.locale.languageCode).format(date);

    if(alerts == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _updateSelectedDate(date),
      child: Column(
        children: [
          Container(
            width: width,
            height: 60,
            // margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: getDaySelectorColor(WeatherAlerts.sortSeverities(alerts!
                      .getAlerts(time: date)
                      .map((alert) => alert.severity)
                      .toList())),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayName,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 4,
            width: width,
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            child: isSelected
                ? Transform.translate(
                    offset: const Offset(0, -13),
                    child: Icon(
                      size: 40,
                      Icons.arrow_drop_down,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : const SizedBox.shrink(),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = Localizations.localeOf(context);

    return Builder(builder: (context) {
      return SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          const double mapHeight = 1220; // Fixed height for the map
          return SizedBox(
            width: constraints.maxWidth,
            child: SingleChildScrollView(
              child: Column(
                spacing: 10,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 3,
                    children: [
                      for (int i = 0; i < 5; i++)
                        _buildDaySelector(
                          date: DateTime.now().add(Duration(days: i)),
                          isSelected: DateTime.now()
                                      .add(Duration(days: i))
                                      .day ==
                                  _selectedDate.day &&
                              DateTime.now().add(Duration(days: i)).month ==
                                  _selectedDate.month &&
                              DateTime.now().add(Duration(days: i)).year ==
                                  _selectedDate.year,
                          width: min(constraints.maxWidth / 5 - 3, 100),
                        )
                    ],
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: min(constraints.maxHeight - 100, mapHeight),
                      child: FittedBox(
                        child: SizedBox(
                          width: 600,
                          height: mapHeight,
                          child: Stack(
                            children: [
                              WarningsMapWidget(
                                weatherAlerts: _weatherAlerts,
                                hitNotifier: hitNotifier,
                                onOverlayVisibilityChanged: (visible) {
                                  setState(() {
                                    showOverlay = visible;
                                  });
                                },
                              ),
                              if (showOverlay)
                                AlertOverlayCardWidget(
                                  hitResult: hitNotifier.value,
                                  languageCode: localization.languageCode,
                                  municipalities: municipalities,
                                  maxWidth: constraints.maxWidth,
                                  parentHeight: mapHeight,
                                  onClose: () {
                                    setState(() {
                                      showOverlay = false;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AlertsByGeocodeWidget(alerts: _weatherAlerts),
                ],
              ),
            ),
          );
        }),
      );
    });
  }
}
