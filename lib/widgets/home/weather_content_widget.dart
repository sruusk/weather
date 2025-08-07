import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather/app_state.dart';
import 'package:weather/data/constants.dart';
import 'package:weather/data/forecast.dart';
import 'package:weather/data/location.dart';
import 'package:weather/l10n/app_localizations.g.dart';
import 'package:weather/widgets/common/child_card_widget.dart';
import 'package:weather/widgets/home/current_forecast_widget.dart';
import 'package:weather/widgets/home/forecast_widget.dart';
import 'package:weather/widgets/home/observations_widget.dart';
import 'package:weather/widgets/home/warnings_widget.dart';

/// A widget that builds the weather content based on screen size and available data.
///
/// This widget is responsible for creating the appropriate layout of weather components
/// based on the screen size (wide or narrow) and the available data for the location.
class WeatherContentWidget extends StatelessWidget {
  /// The forecast data to display.
  final Forecast forecast;

  /// The list of available locations.
  final List<Location> locations;

  /// Whether the content is in a wide screen layout.
  final bool isWideScreen;

  /// Creates a WeatherContentWidget.
  ///
  /// The [forecast], [locations], and [isWideScreen] parameters are required.
  const WeatherContentWidget({
    super.key,
    required this.forecast,
    required this.locations,
    required this.isWideScreen,
  });

  @override
  Widget build(BuildContext context) {
    final children = _buildChildren(context);

    // Use different layouts based on screen width
    if (isWideScreen) {
      return Wrap(
        children: children.map((child) {
          // Check if this is the observations widget which should take full width
          final isObservations = child.key == const Key('observations');
          return SizedBox(
            width: isObservations
                ? double.infinity
                : MediaQuery.of(context).size.width / 2,
            child: child,
          );
        }).toList(),
      );
    } else {
      return Column(
        children: [
          ...children,
          const SizedBox(height: 8),
        ],
      );
    }
  }

  /// Builds the list of child widgets based on the forecast and location data.
  List<Widget> _buildChildren(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final appState = Provider.of<AppState>(context, listen: false);

    final loc = appState.activeLocation;
    final countryCode = loc?.countryCode;

    // Create a list of widgets to return
    final List<Widget> children = [
      ChildCardWidget(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CurrentForecast(
              forecast: forecast,
              locations: locations,
              height: isWideScreen ? 335 : 300,
            ),
          ],
        ),
      ),
      if (observationsEnabledCountries.contains(countryCode) && !isWideScreen)
        ChildCardWidget(child: WeatherWarnings(location: forecast.location)),
      ChildCardWidget(child: ForecastWidget(forecast: forecast)),
      if (observationsEnabledCountries.contains(countryCode))
        ChildCardWidget(
          key: const Key('observations'),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.observations,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Transform.translate(
                offset: const Offset(0, -15),
                child: ObservationsWidget(
                  location: loc,
                  maxWidth: isWideScreen
                      ? MediaQuery.of(context).size.width
                      : MediaQuery.of(context).size.width -
                          32, // Account for padding
                ),
              )
            ],
          ),
        )
    ];

    return children;
  }
}
