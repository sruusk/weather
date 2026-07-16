import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'package:weather/data/location.dart';
import 'package:weather/data/weather_data.dart';
import 'package:weather/data/geolocator.dart';

Future<void> updateWeatherWidget() async {
  try {
    // 1. Fetch active widgets list configured by Android
    final activeWidgetsStr = await HomeWidget.getWidgetData<String>('active_widgets');
    
    List<String> activeWidgetIds = [];
    if (activeWidgetsStr != null && activeWidgetsStr.isNotEmpty) {
      activeWidgetIds = activeWidgetsStr.split(',');
    }

    // 2. Fetch the default location (first favourite or Helsinki) as fallback
    final prefs = await SharedPreferences.getInstance();
    final String? favouriteLocationsStr = prefs.getString('favouriteLocations');
    Location? defaultLocation;
    if (favouriteLocationsStr != null && favouriteLocationsStr.isNotEmpty) {
      try {
        final List<String> locationStrings = favouriteLocationsStr.split(',');
        if (locationStrings.isNotEmpty) {
          defaultLocation = Location.fromString(locationStrings.first);
        }
      } catch (e) {
        debugPrint('Error parsing favourite locations: $e');
      }
    }
    defaultLocation ??= Location(lat: 60.1699, lon: 24.9384, name: 'Helsinki', countryCode: 'FI');

    // 3. Update weather data for each active widget
    for (String widgetId in activeWidgetIds) {
      if (widgetId.isEmpty) continue;

      // Get location specific to this widget
      final locationStr = await HomeWidget.getWidgetData<String>('widget_${widgetId}_location');
      Location widgetLocation = defaultLocation;
      if (locationStr == 'current_location') {
        try {
          final position = await getLastKnownPosition();
          if (position.position != null) {
            widgetLocation = Location(
              lat: position.position!.latitude,
              lon: position.position!.longitude,
              name: 'Current Location',
              countryCode: '',
            );
          }
        } catch (e) {
          debugPrint('Error getting last known position for widget: $e');
        }
      } else if (locationStr != null && locationStr.isNotEmpty) {
        try {
          widgetLocation = Location.fromString(locationStr);
        } catch (e) {
          debugPrint('Error parsing widget $widgetId location: $e');
        }
      }

      await _fetchAndSaveWeatherDataForLocation(widgetLocation, suffix: '_$widgetId');
    }

    // 4. Update the default keys (for widgets that might not be in the active_widgets list yet)
    await _fetchAndSaveWeatherDataForLocation(defaultLocation, suffix: '');

    // 5. Trigger the native UI update
    await HomeWidget.updateWidget(
      androidName: 'WeatherWidgetReceiver',
    );
  } catch (e) {
    debugPrint("Widget update error: $e");
  }
}

Future<void> _fetchAndSaveWeatherDataForLocation(Location location, {required String suffix}) async {
  try {
    final forecast = await WeatherData().getForecast(location);
    if (forecast.forecast.isNotEmpty) {
      final current = forecast.forecast.first;
      
      // Calculate high/low for the day
      final today = DateTime.now();
      final todayPoints = forecast.forecast.where((p) => p.time.day == today.day).toList();
      double? highTemp;
      double? lowTemp;
      if (todayPoints.isNotEmpty) {
        highTemp = todayPoints.map((p) => p.temperature).reduce((a, b) => a > b ? a : b);
        lowTemp = todayPoints.map((p) => p.temperature).reduce((a, b) => a < b ? a : b);
      }
      
      // Prepare hourly forecast string
      final now = DateTime.now();
      final nextFewHours = forecast.forecast.where((h) => h.time.isAfter(now)).take(12).map((p) {
        final timeStr = DateFormat('HH:00').format(p.time);
        return "$timeStr|${p.weatherSymbol}|${p.temperature.round()}°";
      }).join(",");

      // Prepare daily forecast string (5 days)
      final dailyList = <String>[];
      for (int i = 0; i < 5; i++) {
        final targetDate = now.add(Duration(days: i));
        final dayPoints = forecast.forecast.where((p) => p.time.day == targetDate.day && p.time.month == targetDate.month).toList();
        if (dayPoints.isNotEmpty) {
          final dayHigh = dayPoints.map((p) => p.temperature).reduce((a, b) => a > b ? a : b);
          final dayLow = dayPoints.map((p) => p.temperature).reduce((a, b) => a < b ? a : b);
          final noonPoint = dayPoints.reduce((a, b) => (a.time.hour - 12).abs() < (b.time.hour - 12).abs() ? a : b);
          final dayStr = DateFormat('EEE').format(targetDate);
          dailyList.add("$dayStr|${noonPoint.weatherSymbol}|${dayHigh.round()}°|${dayLow.round()}°");
        }
      }
      final dailyStr = dailyList.join(",");

      // Save data to HomeWidget with suffix
      await HomeWidget.saveWidgetData<String>('temp$suffix', current.temperature.round().toString());
      await HomeWidget.saveWidgetData<String>('condition$suffix', current.weatherSymbol);
      await HomeWidget.saveWidgetData<String>('location$suffix', location.name);
      
      if (highTemp != null && lowTemp != null) {
        await HomeWidget.saveWidgetData<String>('highLow$suffix', "${highTemp.round()}°|${lowTemp.round()}°");
      }
      await HomeWidget.saveWidgetData<String>('hourly$suffix', nextFewHours);
      await HomeWidget.saveWidgetData<String>('daily$suffix', dailyStr);
    }
  } catch (e) {
    debugPrint("Failed to update widget data for location ${location.name}: $e");
  }
}
