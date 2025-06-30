import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:weather/appwrite_client.dart';

import 'data/location.dart';
import 'preferences.dart';

// App state provider
class AppState extends ChangeNotifier {
  // Keys for shared preferences
  static const String _localeKey = 'locale';
  static const String _temperatureUnitKey = 'temperatureUnit';
  static const String _notificationsEnabledKey = 'notificationsEnabled';
  static const String _themeModeKey = 'themeMode';
  static const String _isAmoledThemeKey = 'isAmoledTheme';
  static const String _favouriteLocationsKey = 'favouriteLocations';
  static const String _geolocationEnabledKey = 'geolocationEnabled';
  static const String _syncFavouritesToAppwriteKey = 'syncFavouritesToAppwrite';

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
  final ValueNotifier<bool> _isAmoledThemeNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<List<Location>> _favouriteLocationsNotifier =
      ValueNotifier<List<Location>>([]);
  final ValueNotifier<Location?> _activeLocationNotifier =
      ValueNotifier<Location?>(null);
  final ValueNotifier<Location?> _geoLocationNotifier =
  ValueNotifier<Location?>(null);
  final ValueNotifier<bool> _geolocationEnabledNotifier =
      ValueNotifier<bool>(true);
  final ValueNotifier<bool> _syncFavouritesToAppwriteNotifier =
      ValueNotifier<bool>(false);

  // Getters for ValueNotifiers
  ValueNotifier<Locale> get localeNotifier => _localeNotifier;

  ValueNotifier<String> get temperatureUnitNotifier => _temperatureUnitNotifier;

  ValueNotifier<bool> get notificationsEnabledNotifier =>
      _notificationsEnabledNotifier;

  ValueNotifier<bool> get geolocationEnabledNotifier =>
      _geolocationEnabledNotifier;

  ValueNotifier<ThemeMode> get themeModeNotifier => _themeModeNotifier;

  ValueNotifier<bool> get isAmoledThemeNotifier => _isAmoledThemeNotifier;

  ValueNotifier<List<Location>> get favouriteLocationsNotifier =>
      _favouriteLocationsNotifier;

  ValueNotifier<Location?> get activeLocationNotifier =>
      _activeLocationNotifier;

  ValueNotifier<Location?> get geoLocationNotifier => _geoLocationNotifier;

  ValueNotifier<bool> get syncFavouritesToAppwriteNotifier =>
      _syncFavouritesToAppwriteNotifier;

  // Getters for current values
  Locale get locale => _localeNotifier.value;

  String get temperatureUnit => _temperatureUnitNotifier.value;

  bool get notificationsEnabled => _notificationsEnabledNotifier.value;

  bool get geolocationEnabled => _geolocationEnabledNotifier.value;

  ThemeMode get themeMode => _themeModeNotifier.value;

  bool get isAmoledTheme => _isAmoledThemeNotifier.value;

  List<Location> get favouriteLocations {
    // Sort by index if available
    final locations = List<Location>.from(_favouriteLocationsNotifier.value);
    locations.sort((a, b) {
      if (a.index == null && b.index == null) return 0;
      if (a.index == null) return 1;
      if (b.index == null) return -1;
      return a.index!.compareTo(b.index!);
    });
    return locations;
  }

  Location? get activeLocation => _activeLocationNotifier.value;

  Location? get geoLocation => _geoLocationNotifier.value;

  bool get syncFavouritesToAppwrite => _syncFavouritesToAppwriteNotifier.value;

  // Getter for preferences notifier
  PreferencesNotifier get preferencesNotifier => _preferencesNotifier;

  AppState() {
    _preferencesNotifier.addListener(_updateFromPreferences);
    _updateFromPreferences();
  }

  @override
  void dispose() {
    _preferencesNotifier.removeListener(_updateFromPreferences);
    _localeNotifier.dispose();
    _temperatureUnitNotifier.dispose();
    _notificationsEnabledNotifier.dispose();
    _themeModeNotifier.dispose();
    _isAmoledThemeNotifier.dispose();
    _favouriteLocationsNotifier.dispose();
    _activeLocationNotifier.dispose();
    _geoLocationNotifier.dispose();
    _geolocationEnabledNotifier.dispose();
    _syncFavouritesToAppwriteNotifier.dispose();
    super.dispose();
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

    // Load sync favourites to Appwrite setting
    final String? syncFavouritesVal = preferences[_syncFavouritesToAppwriteKey];
    if (syncFavouritesVal != null) {
      _syncFavouritesToAppwriteNotifier.value = syncFavouritesVal == 'true';
    }

    // Load AMOLED theme setting
    final String? isAmoledVal = preferences[_isAmoledThemeKey];
    if (isAmoledVal != null) {
      _isAmoledThemeNotifier.value = isAmoledVal == 'true';
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

  void setSyncFavouritesToAppwrite(bool enabled) {
    _syncFavouritesToAppwriteNotifier.value = enabled;
    _preferencesNotifier.setPreference(
        _syncFavouritesToAppwriteKey, enabled.toString());
    notifyListeners();
  }

  void setAmoledTheme(bool enabled) {
    _isAmoledThemeNotifier.value = enabled;
    _preferencesNotifier.setPreference(_isAmoledThemeKey, enabled.toString());
    notifyListeners();
  }

  // Add a location to favourites
  void addFavouriteLocation(Location location, {bool sync = true}) {
    final currentLocations =
        List<Location>.from(_favouriteLocationsNotifier.value);

    // Check if location already exists
    if (!currentLocations.any((loc) =>
        loc.lat == location.lat &&
        loc.lon == location.lon &&
        loc.name == location.name)) {
      // Create a new Location with an index if not provided
      final newIndex = location.index ??
          (currentLocations.isEmpty ? 0 : _getNextIndex(currentLocations));
      final locationWithIndex = Location(
        lat: location.lat,
        lon: location.lon,
        name: location.name,
        countryCode: location.countryCode,
        region: location.region,
        country: location.country,
        index: newIndex,
      );

      currentLocations.add(locationWithIndex);
      _favouriteLocationsNotifier.value = currentLocations;

      // If this is the first location, set it as active
      if (_activeLocationNotifier.value == null) {
        _activeLocationNotifier.value = locationWithIndex;
      }

      // Save to preferences
      _saveFavouriteLocations(); // Save to local preferences

      if (syncFavouritesToAppwrite && sync) {
        if (kDebugMode) {
          print("Syncing new favourite to Appwrite...");
        }
        _appwriteClient
            .syncFavourites(this, direction: SyncDirection.toAppwrite)
            .then((_) {
          if (kDebugMode) {
            print("Favourite added and synced to Appwrite.");
          }
        }).catchError((e, s) {
          if (kDebugMode) {
            print("Error syncing favourite to Appwrite after adding: $e");
            print("Stack trace: $s");
          }
        });
      }
      notifyListeners();
    }
  }

  // Get the next available index for a new favourite location
  int _getNextIndex(List<Location> locations) {
    if (locations.isEmpty) return 0;

    // Find the highest index and add 1
    int maxIndex = 0;
    for (var location in locations) {
      if (location.index != null && location.index! > maxIndex) {
        maxIndex = location.index!;
      }
    }
    return maxIndex + 1;
  }

  // Remove all locations from favourites
  void removeAllLocalFavouriteLocations() {
    _favouriteLocationsNotifier.value = [];
    _activeLocationNotifier.value = null;

    // Save to preferences
    _saveFavouriteLocations();

    notifyListeners();
  }

  // Remove a location from favourites
  void removeFavouriteLocation(Location location, {bool sync = true}) {
    final currentLocations =
        List<Location>.from(_favouriteLocationsNotifier.value);
    bool removed = false;
    currentLocations.removeWhere((loc) {
      if (loc.lat == location.lat && loc.lon == location.lon) {
        removed = true;
        return true;
      }
      return false;
    });

    if (removed) {
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
      _saveFavouriteLocations(); // Save to local preferences

      if (syncFavouritesToAppwrite && sync) {
        if (kDebugMode) {
          print("Syncing favourite removal to Appwrite...");
        }
        _appwriteClient
            .syncFavourites(this, direction: SyncDirection.toAppwrite)
            .then((_) {
          if (kDebugMode) {
            print("Favourite removed and synced to Appwrite.");
          }
        }).catchError((e, s) {
          if (kDebugMode) {
            print("Error syncing favourite to Appwrite after removing: $e");
            print("Stack trace: $s");
          }
        });
      }
      notifyListeners();
    }
  }

  void setActiveLocation(Location location) {
    _activeLocationNotifier.value = location;
    notifyListeners();
  }

  void setGeoLocation(Location? location) {
    _geoLocationNotifier.value = location;
    notifyListeners();
  }

  // Save favourite locations to preferences
  void _saveFavouriteLocations() {
    final locationStrings = _favouriteLocationsNotifier.value
        .map((location) => location.toString())
        .join(',');
    _preferencesNotifier.setPreference(_favouriteLocationsKey, locationStrings);
  }

  // Reorder favourite locations
  void reorderFavouriteLocations(int oldIndex, int newIndex) {
    final currentLocations =
        List<Location>.from(_favouriteLocationsNotifier.value);

    // Adjust for removing the item
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    // Move the item
    final location = currentLocations.removeAt(oldIndex);
    currentLocations.insert(newIndex, location);

    // Update indices for all locations
    final updatedLocations = <Location>[];
    for (int i = 0; i < currentLocations.length; i++) {
      final loc = currentLocations[i];
      updatedLocations.add(Location(
        lat: loc.lat,
        lon: loc.lon,
        name: loc.name,
        countryCode: loc.countryCode,
        region: loc.region,
        country: loc.country,
        index: i,
      ));
    }

    _favouriteLocationsNotifier.value = updatedLocations;

    // Save to preferences
    _saveFavouriteLocations();

    // Sync to Appwrite if enabled
    if (syncFavouritesToAppwrite) {
      if (kDebugMode) {
        print("Syncing reordered favourites to Appwrite...");
      }
      _appwriteClient
          .syncFavourites(this, direction: SyncDirection.toAppwrite)
          .then((_) {
        if (kDebugMode) {
          print("Reordered favourites synced to Appwrite.");
        }
      }).catchError((e, s) {
        if (kDebugMode) {
          print("Error syncing reordered favourites to Appwrite: $e");
          print("Stack trace: $s");
        }
      });
    }

    notifyListeners();
  }

  final AppwriteClient _appwriteClient =
      AppwriteClient(); // Initialize Appwrite client
}
