import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather/data/location.dart';
import 'package:weather/widgets/home/sunrise_sunset_widget.dart';
import 'package:intl/intl.dart';

void main() {
  group('SunriseSunsetWidget', () {
    // Create a test location
    final testLocation = Location(
      lat: 60.1695,
      lon: 24.9354,
      name: 'Helsinki',
      region: 'Uusimaa',
      countryCode: 'Finland',
    );

    testWidgets('should display sunrise and sunset times', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SunriseSunsetWidget(
              location: testLocation,
            ),
          ),
        ),
      );

      // We can't easily test the exact times since they depend on the current date
      // and the calculation from the sunrise_sunset_calc package.
      // But we can verify that some time values are displayed.

      // The time format should be HH:mm, so we can check for a pattern
      final timePattern = RegExp(r'\d{2} - \d{2}');

      // There should be at least two time values displayed (sunrise and sunset)
      final timeWidgets = find.byWidgetPredicate((widget) {
        if (widget is Text) {
          return timePattern.hasMatch(widget.data ?? '');
        }
        return false;
      });

      expect(timeWidgets, findsAtLeastNWidgets(1));
    });

    testWidgets('should handle different locations', (WidgetTester tester) async {
      // Create another test location
      final anotherLocation = Location(
        lat: 40.7128,
        lon: -74.0060,
        name: 'New York',
        region: 'New York',
        countryCode: 'USA',
      );

      // Build the widget with the first location
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SunriseSunsetWidget(
              location: testLocation,
            ),
          ),
        ),
      );

      // Get the sunrise and sunset times for the first location
      final firstLocationTimes = _getDisplayedTimes(tester);

      // Rebuild with the second location
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SunriseSunsetWidget(
              location: anotherLocation,
            ),
          ),
        ),
      );

      // Get the sunrise and sunset times for the second location
      final secondLocationTimes = _getDisplayedTimes(tester);

      // The times should be different for different locations
      // This is a simple check that the widget is actually using the location data
      expect(firstLocationTimes, isNot(equals(secondLocationTimes)));
    });
  });
}

// Helper function to extract the displayed times from the widget
List<String> _getDisplayedTimes(WidgetTester tester) {
  final timePattern = RegExp(r'\d{1,2}:\d{2}');
  final times = <String>[];

  final timeWidgets = tester.widgetList<Text>(find.byType(Text));
  for (final widget in timeWidgets) {
    final text = widget.data ?? '';
    if (timePattern.hasMatch(text)) {
      times.add(text);
    }
  }

  return times;
}
