import 'package:flutter/material.dart';
import 'package:weather/l10n/app_localizations.g.dart';
import 'package:weather/pages/about_page.dart';
import 'package:weather/pages/settings_page.dart';
import 'package:weather/pages/weather_symbols_page.dart';

const String _listViewRoute = '/'; // Route for the list of cards view

class OtherPage extends StatelessWidget {
  final GlobalKey<NavigatorState>? navigatorKey; // Add this

  const OtherPage({super.key, this.navigatorKey}); // Modify constructor

  // Route names for sub-pages, accessible for navigation
  static const String settingsRoute = '/settings';
  static const String weatherSymbolsRoute = '/weather-symbols';
  static const String aboutRoute = '/about';

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey, // Use the passed key
      initialRoute: _listViewRoute, // Display the list view by default
      onGenerateRoute: (RouteSettings settings) {
        Widget pageContent;
        switch (settings.name) {
          case _listViewRoute:
            pageContent = const _OtherPageListView();
            break;
          case settingsRoute:
            pageContent = const SettingsPage();
            break;
          case weatherSymbolsRoute:
            pageContent = const WeatherSymbolsPage();
            break;
          case aboutRoute:
            pageContent = const AboutPage();
            break;
          default:
            // Fallback to the list view if route is unknown
            pageContent = const _OtherPageListView();
            break;
        }
        return MaterialPageRoute<dynamic>(
          builder: (context) => pageContent,
          settings: settings,
        );
      },
    );
  }
}

// Private widget for displaying the list of navigation cards within OtherPage
class _OtherPageListView extends StatelessWidget {
  const _OtherPageListView();

  @override
  Widget build(BuildContext context) {
    // This context is a descendant of OtherPage's Navigator.
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.otherPageTitle,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildNavigationCard(
                context,
                Icons.settings,
                localizations.settingsPageTitle,
                localizations.settingsPageDescription,
                // Navigate using OtherPage's Navigator to the defined sub-route
                () => Navigator.of(context).pushNamed(OtherPage.settingsRoute),
              ),
              const SizedBox(height: 12),
              _buildNavigationCard(
                context,
                Icons.cloud,
                localizations.weatherSymbolsPageTitle,
                localizations.weatherSymbolsPageDescription,
                () => Navigator.of(context).pushNamed(OtherPage.weatherSymbolsRoute),
              ),
              const SizedBox(height: 12),
              _buildNavigationCard(
                context,
                Icons.info,
                localizations.aboutPageTitle,
                localizations.aboutPageDescription,
                () => Navigator.of(context).pushNamed(OtherPage.aboutRoute),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build navigation cards, now part of _OtherPageListView
  Widget _buildNavigationCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}
