import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:weather/app_state.dart';
import 'package:weather/appwrite_client.dart';
import 'package:weather/l10n/app_localizations.g.dart';
import 'package:weather/routes.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin<SettingsPage> {
  @override
  bool get wantKeepAlive => true;

  bool? _isLoggedIn;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final appState = Provider.of<AppState>(context);
    final localizations = AppLocalizations.of(context)!;
    AppwriteClient().isLoggedIn().then((val) {
      if (val != _isLoggedIn) {
        setState(() {
          _isLoggedIn = val;
        });
      }
    });

    final settingsItems = <Widget>[
      // Language setting
      ValueListenableBuilder<Locale>(
        valueListenable: appState.localeNotifier,
        builder: (context, locale, child) {
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: ListTile(
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
                    })),
          );
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

      // Settings Sync
      Column(
        children: [
          _buildLoginLogoutButton(
              localizations, appState, context, _isLoggedIn),
          if (_isLoggedIn != null && _isLoggedIn!) ...[
            _buildSyncSwitch(localizations, appState, context),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAccountDeleteButton(context, localizations),
              ],
            )
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(localizations.settingsSyncDesc,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          ]
        ],
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
        child: ListView.separated(
          itemCount: settingsItems.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: settingsItems[index],
            );
          },
          separatorBuilder: (context, index) =>
              const Divider(indent: 10, endIndent: 10),
        ),
      ),
    );
  }

  ListTile _buildLoginLogoutButton(AppLocalizations localizations,
      AppState appState, BuildContext context, bool? isLoggedIn) {
    return ListTile(
      leading: (isLoggedIn != null &&
              isLoggedIn &&
              appState.syncFavouritesToAppwrite)
          ? const Icon(Icons.sync)
          : const Icon(Icons.sync_disabled),
      title: Text(localizations.settingsSync),
      trailing: isLoggedIn == null
          ? const CircularProgressIndicator()
          : !isLoggedIn
              ? ElevatedButton(
                  onPressed: () {
                    context.goNamed(AppRoutes.login.name);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.login),
                      const SizedBox(width: 8),
                      Text(localizations.login),
                    ],
                  ),
                )
              : ElevatedButton(
                  onPressed: () {
                    // Confirm logout using a dialog
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text(localizations.logoutConfirmationTitle),
                          content:
                              Text(localizations.logoutConfirmationMessage),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(localizations.cancel),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                AppwriteClient().logout();
                                // Refresh the state
                                setState(() {
                                  _isLoggedIn = false;
                                });
                              },
                              child: Text(localizations.logout),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.logout),
                      const SizedBox(width: 8),
                      Text(localizations.logout),
                    ],
                  ),
                ),
    );
  }

  ListTile _buildSyncSwitch(
      AppLocalizations localizations, AppState appState, BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.favorite),
      title: Text(localizations.syncFavourites),
      subtitle: Text(localizations.syncFavouritesDesc),
      trailing: Switch(
        value: appState.syncFavouritesToAppwrite,
        onChanged: (bool value) async {
          appState.setSyncFavouritesToAppwrite(value);
          if (value) {
            try {
              final client = AppwriteClient();
              await client.syncFavourites(appState,
                  direction: SyncDirection.fromAppwrite);
              client.subscribe();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(localizations.syncFavouritesSuccess),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(localizations.syncFavouritesError(e.toString())),
                  ),
                );
              }
            }
          } else {
            AppwriteClient().unsubscribe();
          }
        },
      ),
    );
  }

  ElevatedButton _buildAccountDeleteButton(
      BuildContext context, AppLocalizations localizations) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        foregroundColor: Colors.white,
      ),
      onPressed: () {
        // Confirm logout using a dialog
        showDialog(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(localizations.deleteAccountConfirmationTitle),
              content: Text(localizations.deleteAccountConfirmationMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(localizations.cancel),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    final bool success = await AppwriteClient().deleteAccount();
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(localizations.deleteAccountSuccess),
                        ),
                      );
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(localizations.deleteAccountError),
                        ),
                      );
                    }
                    // Refresh the state
                    setState(() {
                      _isLoggedIn = false;
                    });
                  },
                  child: Text(localizations.deleteAccount),
                ),
              ],
            );
          },
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.delete_forever),
          const SizedBox(width: 8),
          Text(localizations.deleteAccount),
        ],
      ),
    );
  }
}
