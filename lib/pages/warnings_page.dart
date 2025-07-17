import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:weather/app_state.dart';
import 'package:weather/data/constants.dart';
import 'package:weather/data/weather_alert.dart';
import 'package:weather/data/weather_alerts.dart';
import 'package:weather/widgets/warnings/alerts_by_geocode_widget.dart';
import 'package:weather/widgets/warnings/warnings_map_widget.dart';
import 'package:weather/widgets/warnings/warnings_overlay_widget.dart';

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
      });
    });
  }

  void _updateSelectedDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadWeatherAlerts();
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

    return GestureDetector(
      onTap: () => _updateSelectedDate(date),
      child: Container(
        width: width,
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: TextStyle(
                fontSize: 14,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = Localizations.localeOf(context);

    return Builder(builder: (context) {
      return SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            child: SingleChildScrollView(
              child: Column(
                spacing: 10,
                children: [
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                            width: min(constraints.maxWidth / 5 - 15, 100),
                          )
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: min(constraints.maxHeight - 100, 1220),
                      child: FittedBox(
                        child: SizedBox(
                          width: 600,
                          height: 1220,
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
                                WarningsOverlayWidget(
                                  hitResult: hitNotifier.value,
                                  languageCode: localization.languageCode,
                                  municipalities: municipalities,
                                  maxWidth: constraints.maxWidth,
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
