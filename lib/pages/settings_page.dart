import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather/l10n/app_localizations.g.dart';

import '../app_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with AutomaticKeepAliveClientMixin<SettingsPage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final appState = Provider.of<AppState>(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(localizations.settingsPageTitle),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              localizations.appSettingsAndPreferences,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  // Language setting
                  ValueListenableBuilder<Locale>(
                    valueListenable: appState.localeNotifier,
                    builder: (context, locale, child) {
                      return ListTile(
                        leading: const Icon(Icons.language),
                        title: Text(localizations.language),
                        subtitle: Text(locale.languageCode == 'en'
                            ? localizations.english
                            : localizations.finnish),
                        trailing: DropdownButton<String>(
                          value: locale.languageCode,
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              appState.setLocale(Locale(newValue));
                            }
                          },
                          items: [
                            DropdownMenuItem(
                              value: 'en',
                              child: Text(localizations.english),
                            ),
                            DropdownMenuItem(
                              value: 'fi',
                              child: Text(localizations.finnish),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Temperature unit setting
                  // ValueListenableBuilder<String>(
                  //   valueListenable: appState.temperatureUnitNotifier,
                  //   builder: (context, temperatureUnit, child) {
                  //     return ListTile(
                  //       leading: const Icon(Icons.thermostat),
                  //       title: Text(localizations.temperatureUnit),
                  //       subtitle: Text(temperatureUnit == 'celsius'
                  //           ? localizations.celsius
                  //           : localizations.fahrenheit),
                  //       trailing: Switch(
                  //         value: temperatureUnit == 'celsius',
                  //         onChanged: (bool value) {
                  //           appState.setTemperatureUnit(
                  //               value ? 'celsius' : 'fahrenheit');
                  //         },
                  //       ),
                  //     );
                  //   },
                  // ),

                  // Notifications setting
                  // ValueListenableBuilder<bool>(
                  //   valueListenable: appState.notificationsEnabledNotifier,
                  //   builder: (context, notificationsEnabled, child) {
                  //     return ListTile(
                  //       leading: const Icon(Icons.notifications),
                  //       title: Text(localizations.notifications),
                  //       subtitle: Text(notificationsEnabled
                  //           ? localizations.enabled
                  //           : localizations.disabled),
                  //       trailing: Switch(
                  //         value: notificationsEnabled,
                  //         onChanged: (bool value) {
                  //           appState.setNotificationsEnabled(value);
                  //         },
                  //       ),
                  //     );
                  //   },
                  // ),

                  // Geolocation setting
                  ValueListenableBuilder<bool>(
                    valueListenable: appState.geolocationEnabledNotifier,
                    builder: (context, geolocationEnabled, child) {
                      return ListTile(
                        leading: const Icon(Icons.my_location),
                        title: Text(localizations.geolocation),
                        subtitle: Text(geolocationEnabled
                            ? localizations.enabled
                            : localizations.disabled),
                        trailing: Switch(
                          value: geolocationEnabled,
                          onChanged: (bool value) {
                            appState.setGeolocationEnabled(value);
                          },
                        ),
                      );
                    },
                  ),

                  // Theme mode setting
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: appState.themeModeNotifier,
                    builder: (context, themeMode, child) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return ListTile(
                        leading: Icon(isDark
                            ? Icons.dark_mode
                            : Icons.light_mode),
                        title: Text(localizations.theme),
                        subtitle: Text(isDark
                            ? localizations.dark
                            : localizations.light),
                        trailing: Switch(
                          value: isDark,
                          onChanged: (bool value) {
                            appState.setThemeMode(
                                value ? ThemeMode.dark : ThemeMode.light);
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
