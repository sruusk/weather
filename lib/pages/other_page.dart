import 'package:flutter/material.dart';
import 'package:weather/l10n/app_localizations.g.dart';
import 'package:weather/pages/about_page.dart';
import 'package:weather/pages/settings_page.dart';
import 'package:weather/pages/weather_symbols_page.dart';

class OtherPage extends StatelessWidget {
  const OtherPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildNavigationCard(
                context,
                Icons.settings,
                localizations.settingsPageTitle,
                localizations.settingsPageDescription,
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildNavigationCard(
                context,
                Icons.cloud,
                localizations.weatherSymbolsPageTitle,
                localizations.weatherSymbolsPageDescription,
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const WeatherSymbolsPage(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildNavigationCard(
                context,
                Icons.info,
                localizations.aboutPageTitle,
                localizations.aboutPageDescription,
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AboutPage(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
