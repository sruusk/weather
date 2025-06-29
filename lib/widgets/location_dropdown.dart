import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:weather/app_state.dart';
import 'package:weather/data/location.dart';
import 'package:weather/data/weather_data.dart';
import 'package:weather/l10n/app_localizations.g.dart';
import 'package:weather/routes.dart';

class LocationDropdown extends StatelessWidget {
  final Location? geoLocation;
  final WeatherData? weatherData;

  const LocationDropdown({
    super.key,
    this.geoLocation,
    this.weatherData,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final localizations = AppLocalizations.of(context)!;
    final locations = appState.favouriteLocations;

    // Find the index of the active location in the locations list
    int activeIndex = 0;
    if (appState.activeLocation != null) {
      for (int i = 0; i < locations.length; i++) {
        if (locations[i].lat == appState.activeLocation!.lat &&
            locations[i].lon == appState.activeLocation!.lon) {
          activeIndex = i;
          break;
        }
      }
    }

    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: activeIndex,
                icon: const Icon(Icons.arrow_drop_down),
                borderRadius: BorderRadius.circular(8),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                items: [
                  for (int i = 0; i < locations.length; i++)
                    DropdownMenuItem<int>(
                      value: i,
                      child: Row(
                        children: [
                          Icon(i == 0 &&
                                  appState.geolocationEnabled &&
                                  geoLocation != null
                              ? Icons.my_location
                              : Icons.place),
                          SizedBox(width: 8),
                          Text(
                            locations[i].name +
                                (locations[i].region != null
                                    ? locations[i].region! ==
                                                locations[i].name &&
                                            locations[i].country != null
                                        ? ', ${locations[i].country}'
                                        : ', ${locations[i].region}'
                                    : ''),
                          ),
                        ],
                      ),
                    ),
                ],
                onChanged: (i) async {
                  if (i == null) return;

                  // Update the active location in AppState
                  final location = locations[i];
                  appState.setActiveLocation(location);

                  // If weatherData is provided, load the forecast for the selected location
                  if (weatherData != null) {
                    try {
                      await weatherData!.getForecast(location);
                    } catch (e) {
                      if (kDebugMode) {
                        print('Error getting selected forecast: $e');
                      }
                    }
                  }
                },
              ),
            ),
          ],
        ),
        Positioned(
          right: 3,
          top: 3,
          child: IconButton(
            icon: const Icon(Icons.edit_location_outlined),
            tooltip: localizations.favouritesPageTitle,
            onPressed: () {
              context.goNamed(AppRoutes.favourites.name);
            },
          ),
        )
      ],
    );
  }
}
