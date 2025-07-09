import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:weather/app_state.dart';
import 'package:weather/data/location.dart';
import 'package:weather/data/weather_alert.dart';
import 'package:weather/data/weather_alerts.dart';
import 'package:weather/l10n/app_localizations.g.dart';

class WeatherWarnings extends StatefulWidget {
  final Location location;

  const WeatherWarnings({super.key, required this.location});

  @override
  State<WeatherWarnings> createState() => _WeatherWarningsState();
}

class _WeatherWarningsState extends State<WeatherWarnings> with SingleTickerProviderStateMixin {
  WeatherAlerts? _weatherAlerts;
  int? _selectedDayIndex;
  late AnimationController _animationController;
  late Animation<double> _animation;
  // Map to track expansion state of each warning
  final Map<String, bool> _expandedWarnings = {};

  @override
  void initState() {
    super.initState();

    if(kDebugMode) print('Initializing WarningsWidget for ${widget.location.name}');

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Listener to reset the selected day when closing completes
    // _selectedDayIndex  needs to be reset only after the animation completes
    // otherwise the animation will not play correctly.
    _animationController.addStatusListener((status) {
      if ((status == AnimationStatus.dismissed) && _selectedDayIndex != null) {
        setState(() {
          _selectedDayIndex = null;
        });
      }
    });


    // Get the singleton instance and load alerts
    final weatherAlertsInstance = WeatherAlerts.instance();
    if(weatherAlertsInstance.hasLoaded) {
      // If already loaded, set the state directly
      _weatherAlerts = weatherAlertsInstance;
    } else {
      // Otherwise, load the alerts
      weatherAlertsInstance.load().then((alerts) {
        if (mounted) {
          setState(() {
            _weatherAlerts = alerts;
          });
        }
      }).catchError((error) {
        if (kDebugMode) print('Error loading weather alerts: $error');
        setState(() {
          _weatherAlerts = null; // Handle error by setting to null
        });
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Color> getGradientColors(WeatherAlertSeverity? severity) {
    switch (severity ?? WeatherAlertSeverity.unknown) {
      case WeatherAlertSeverity.minor:
        return [Colors.green, Color(0x0000ff0c)];
      case WeatherAlertSeverity.moderate:
        return [Color(0xCCECD900), Color(0x00FFF400)];
      case WeatherAlertSeverity.severe:
        return [Color(0xCCFFAC40), Color(0x00FF6A00)];
      case WeatherAlertSeverity.extreme:
        return [Color(0xCCFF4040), Color(0x1AFF0000)];
      default:
        return [Colors.transparent, Colors.transparent];
    }
  }

  Color getBorderColor(WeatherAlertSeverity? severity) {
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

  Widget _buildWarningsList(DateTime selectedDay) {
    final appState = Provider.of<AppState>(context);
    final alerts = _weatherAlerts!.getAlerts(location: widget.location, time: selectedDay);

    if (alerts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          AppLocalizations.of(context)!.noWeatherWarningsForDay,
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];

        final languageCode = appState.locale.languageCode;
        final WeatherEvent event;

        if (languageCode == 'sv') {
          event = alert.sv;
        } else if (languageCode == 'fi') {
          event = alert.fi;
        } else {
          event = alert.en;
        }

        return _buildWarningItem(event);
      },
    );
  }

  // Helper method to build an individual warning item
  Widget _buildWarningItem(WeatherEvent event) {
    // Use a unique key for this warning based on its content
    final String warningKey = '${event.event}_${event.headline}';
    // Initialize if not already in the map
    _expandedWarnings.putIfAbsent(warningKey, () => false);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Theme.of(context).colorScheme.surfaceDim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Always visible part (event text)
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setState(() {
                // Toggle the expansion state for this warning
                _expandedWarnings[warningKey] = !(_expandedWarnings[warningKey] ?? false);
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      event.event,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(
                    _expandedWarnings[warningKey] ?? false ? Icons.expand_less : Icons.expand_more,
                  ),
                ],
              ),
            ),
          ),
          // Expandable part (headline and description)
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.headline.isNotEmpty) ...[
                    Text(
                      event.headline,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    event.description,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            crossFadeState: (_expandedWarnings[warningKey] ?? false) ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final localizations = AppLocalizations.of(context)!;

    if (_weatherAlerts == null) {
      return const SizedBox(
        height: 71,
        child: Center(child: CircularProgressIndicator()));
    }

    final today = DateTime.now();
    final days = [
      today,
      today.add(const Duration(days: 1)),
      today.add(const Duration(days: 2)),
      today.add(const Duration(days: 3)),
      today.add(const Duration(days: 4)),
    ];

    final severity = [
      _weatherAlerts!.severityForLocation(widget.location, days[0]),
      _weatherAlerts!.severityForLocation(widget.location, days[1]),
      _weatherAlerts!.severityForLocation(widget.location, days[2]),
      _weatherAlerts!.severityForLocation(widget.location, days[3]),
      _weatherAlerts!.severityForLocation(widget.location, days[4]),
      // WeatherAlertSeverity.unknown,
      // WeatherAlertSeverity.minor,
      // WeatherAlertSeverity.moderate,
      // WeatherAlertSeverity.severe,
      // WeatherAlertSeverity.extreme,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            localizations.weatherWarnings
          ),
          Row(
            spacing: 4,
            children: [
              for(var i = 0; i < days.length; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_selectedDayIndex == i) {
                          // Trigger reverse animation; _selectedDayIndex is reset in the status listener.
                          _animationController.reverse();
                        } else {
                          // If no day selected, start forward animation.
                          if (_selectedDayIndex == null) {
                            _selectedDayIndex = i;
                            _animationController.forward();
                          } else {
                            // If switching from one day to another, update immediately.
                            _selectedDayIndex = i;
                          }
                        }
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: getGradientColors(severity[i]),
                            ),
                          ),
                          child: Text(
                            DateFormat.E(appState.locale.languageCode).format(days[i]),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: getBorderColor(severity[i]),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                )
            ],
          ),
          // Expandable warnings section
          SizeTransition(
            sizeFactor: _animation,
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              child: _selectedDayIndex != null
                ? _buildWarningsList(days[_selectedDayIndex!])
                : const SizedBox.shrink(),
            ),
          )
        ],
      ),
    );
  }
}
