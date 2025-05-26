import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'data/location.dart';
import 'preferences.dart';

// App state provider
class AppState extends ChangeNotifier {
  // Keys for shared preferences
  static const String _localeKey = 'locale';
  static const String _temperatureUnitKey = 'temperatureUnit';
  static const String _notificationsEnabledKey = 'notificationsEnabled';
  static const String _themeModeKey = 'themeMode';
  static const String _favouriteLocationsKey = 'favouriteLocations';
  static const String _geolocationEnabledKey = 'geolocationEnabled';

  // PreferencesNotifier for storing settings
  final PreferencesNotifier _preferencesNotifier = PreferencesNotifier();

  // ValueNotifiers for settings
  final ValueNotifier<Locale> _localeNotifier =
      ValueNotifier<Locale>(const Locale('en'));
  final ValueNotifier<String> _temperatureUnitNotifier =
      ValueNotifier<String>('celsius');
  final ValueNotifier<bool> _notificationsEnabledNotifier =
      ValueNotifier<bool>(true);
  final ValueNotifier<ThemeMode> _themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.system);
  final ValueNotifier<List<Location>> _favouriteLocationsNotifier =
      ValueNotifier<List<Location>>([]);
  final ValueNotifier<Location?> _activeLocationNotifier =
      ValueNotifier<Location?>(null);
  final ValueNotifier<bool> _geolocationEnabledNotifier =
      ValueNotifier<bool>(true);

  // Getters for ValueNotifiers
  ValueNotifier<Locale> get localeNotifier => _localeNotifier;

  ValueNotifier<String> get temperatureUnitNotifier => _temperatureUnitNotifier;

  ValueNotifier<bool> get notificationsEnabledNotifier =>
      _notificationsEnabledNotifier;

  ValueNotifier<bool> get geolocationEnabledNotifier =>
      _geolocationEnabledNotifier;

  ValueNotifier<ThemeMode> get themeModeNotifier => _themeModeNotifier;

  ValueNotifier<List<Location>> get favouriteLocationsNotifier =>
      _favouriteLocationsNotifier;

  ValueNotifier<Location?> get activeLocationNotifier =>
      _activeLocationNotifier;

  // Getters for current values
  Locale get locale => _localeNotifier.value;

  String get temperatureUnit => _temperatureUnitNotifier.value;

  bool get notificationsEnabled => _notificationsEnabledNotifier.value;

  bool get geolocationEnabled => _geolocationEnabledNotifier.value;

  ThemeMode get themeMode => _themeModeNotifier.value;

  List<Location> get favouriteLocations => _favouriteLocationsNotifier.value;

  Location? get activeLocation => _activeLocationNotifier.value;

  // Getter for preferences notifier
  PreferencesNotifier get preferencesNotifier => _preferencesNotifier;

  AppState() {
    _preferencesNotifier.addListener(_updateFromPreferences);
    _updateFromPreferences();
  }

  // Update settings from preferences
  void _updateFromPreferences() {
    final preferences = _preferencesNotifier.value.preferences;

    // Load locale
    final String? localeCode = preferences[_localeKey];
    if (localeCode != null) {
      _localeNotifier.value = Locale(localeCode);
    }

    // Load temperature unit
    final String? tempUnit = preferences[_temperatureUnitKey];
    if (tempUnit != null) {
      _temperatureUnitNotifier.value = tempUnit;
    }

    // Load notifications setting
    final String? notificationsEnabled = preferences[_notificationsEnabledKey];
    if (notificationsEnabled != null) {
      _notificationsEnabledNotifier.value = notificationsEnabled == 'true';
    }

    // Load theme mode setting
    final String? themeModeValue = preferences[_themeModeKey];
    if (themeModeValue != null) {
      switch (themeModeValue) {
        case 'dark':
          _themeModeNotifier.value = ThemeMode.dark;
          break;
        case 'light':
          _themeModeNotifier.value = ThemeMode.light;
          break;
        case 'system':
          _themeModeNotifier.value = ThemeMode.system;
          break;
      }
    }

    // Load geolocation setting
    final String? geolocVal = preferences[_geolocationEnabledKey];
    if (geolocVal != null) {
      _geolocationEnabledNotifier.value = geolocVal == 'true';
    }

    // Load favourite locations
    final String? favouriteLocationsStr = preferences[_favouriteLocationsKey];
    if (favouriteLocationsStr != null) {
      try {
        final List<String> locationStrings = favouriteLocationsStr.split(',');
        final List<Location> locations = locationStrings
            .map((locationStr) => Location.fromString(locationStr))
            .toList();
        _favouriteLocationsNotifier.value = locations;

        // Set the first location as active if there's no active location
        if (_activeLocationNotifier.value == null && locations.isNotEmpty) {
          _activeLocationNotifier.value = locations.first;
        }
      } catch (e) {
        // Handle parsing errors
        if (kDebugMode) {
          print('Error parsing favourite locations: $e');
        }
      }
    }

    // Notify listeners after loading all settings
    notifyListeners();
  }

  // Setters for settings
  void setLocale(Locale locale) {
    _localeNotifier.value = locale;
    _preferencesNotifier.setPreference(_localeKey, locale.languageCode);
    notifyListeners();
  }

  void setTemperatureUnit(String unit) {
    _temperatureUnitNotifier.value = unit;
    _preferencesNotifier.setPreference(_temperatureUnitKey, unit);
    notifyListeners();
  }

  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabledNotifier.value = enabled;
    _preferencesNotifier.setPreference(
        _notificationsEnabledKey, enabled.toString());
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeModeNotifier.value = mode;
    String themeModeString;
    switch (mode) {
      case ThemeMode.dark:
        themeModeString = 'dark';
        break;
      case ThemeMode.light:
        themeModeString = 'light';
        break;
      case ThemeMode.system:
        themeModeString = 'system';
        break;
    }
    _preferencesNotifier.setPreference(_themeModeKey, themeModeString);
    notifyListeners();
  }

  void setGeolocationEnabled(bool enabled) {
    _geolocationEnabledNotifier.value = enabled;
    _preferencesNotifier.setPreference(
        _geolocationEnabledKey, enabled.toString());
    notifyListeners();
  }

  // Add a location to favourites
  void addFavouriteLocation(Location location) {
    final currentLocations =
        List<Location>.from(_favouriteLocationsNotifier.value);

    // Check if location already exists
    if (!currentLocations.any((loc) =>
        loc.lat == location.lat &&
        loc.lon == location.lon &&
        loc.name == location.name)) {
      currentLocations.add(location);
      _favouriteLocationsNotifier.value = currentLocations;

      // If this is the first location, set it as active
      if (_activeLocationNotifier.value == null) {
        _activeLocationNotifier.value = location;
      }

      // Save to preferences
      _saveFavouriteLocations();
      notifyListeners();
    }
  }

  // Remove a location from favourites
  void removeFavouriteLocation(Location location) {
    final currentLocations =
        List<Location>.from(_favouriteLocationsNotifier.value);

    // Remove the location
    currentLocations.removeWhere((loc) =>
        loc.lat == location.lat &&
        loc.lon == location.lon &&
        loc.name == location.name);

    _favouriteLocationsNotifier.value = currentLocations;

    // If the active location was removed, set a new active location
    if (_activeLocationNotifier.value != null &&
        _activeLocationNotifier.value!.lat == location.lat &&
        _activeLocationNotifier.value!.lon == location.lon &&
        _activeLocationNotifier.value!.name == location.name) {
      _activeLocationNotifier.value =
          currentLocations.isNotEmpty ? currentLocations.first : null;
    }

    // Save to preferences
    _saveFavouriteLocations();
    notifyListeners();
  }

  // Set the active location
  void setActiveLocation(Location location) {
    _activeLocationNotifier.value = location;
    notifyListeners();
  }

  // Save favourite locations to preferences
  void _saveFavouriteLocations() {
    final locationStrings = _favouriteLocationsNotifier.value
        .map((location) => location.toString())
        .join(',');
    _preferencesNotifier.setPreference(_favouriteLocationsKey, locationStrings);
  }
}
