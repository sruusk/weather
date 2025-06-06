import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather/l10n/app_localizations.g.dart';

import '../app_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin<SettingsPage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final appState = Provider.of<AppState>(context);
    final localizations = AppLocalizations.of(context)!;

    final settingsItems = <Widget>[
      // Language setting
      ValueListenableBuilder<Locale>(
        valueListenable: appState.localeNotifier,
        builder: (context, locale, child) {
          return ListTile(
              leading: const Icon(Icons.language),
              title: Text(localizations.language),
              trailing: SegmentedButton<Locale>(
                  segments: [
                    ButtonSegment<Locale>(
                      value: const Locale('en'),
                      label: Text(localizations.english),
                    ),
                    ButtonSegment<Locale>(
                      value: const Locale('fi'),
                      label: Text(localizations.finnish),
                    ),
                  ],
                  selected: {
                    locale
                  },
                  onSelectionChanged: (Set<Locale> newSelection) {
                    if (newSelection.isNotEmpty) {
                      appState.setLocale(newSelection.first);
                    }
                  }));
        },
      ),

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
          final tilePadding =
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);

          return Padding(
            padding: tilePadding,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.0,
              runSpacing: 10.0,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                    SizedBox(width: 16),
                    Text(localizations.theme,
                        style: const TextStyle(fontSize: 16)),
                  ],
                ),
                SegmentedButton<ThemeMode>(
                  direction: Axis.horizontal,
                  segments: [
                    ButtonSegment<ThemeMode>(
                        value: ThemeMode.system,
                        label: Text(localizations.system),
                        icon: Icon(Icons.settings)),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      label: Text(localizations.light),
                      icon:
                          Icon(Icons.light_mode, color: Colors.yellow.shade700),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      label: Text(localizations.dark),
                      icon: Icon(Icons.dark_mode,
                          color: Colors.blueGrey.shade700),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (Set<ThemeMode> newSelection) {
                    if (newSelection.isNotEmpty) {
                      appState.setThemeMode(newSelection.first);
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    ];

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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ListView.separated(
                  itemCount: settingsItems.length,
                  itemBuilder: (context, index) {
                    return settingsItems[index];
                  },
                  separatorBuilder: (context, index) => const Divider(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
