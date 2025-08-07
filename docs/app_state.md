# App State Management Documentation

This document provides an overview of how state is managed in the Weather App, explaining the key patterns, components,
and how they work together.

## State Management Architecture

The Weather App uses a hybrid state management approach combining:

1. **ChangeNotifier**: For global app state
2. **ValueNotifier**: For specific state elements
3. **Provider**: For dependency injection and state access
4. **ViewModels**: For page-specific state and business logic

This hybrid approach allows for efficient state management at different levels of the application.

## AppState Class

The `AppState` class is the central state management component, extending `ChangeNotifier` to provide global state
across the app.

### Key Features

- **Singleton Pattern**: Single instance shared across the app
- **Preference Management**: Stores and retrieves user preferences
- **Location Management**: Handles favorite locations and active location
- **Theme and Locale**: Manages app appearance and language
- **AppWrite Integration**: Syncs state with AppWrite cloud services

### State Elements

The `AppState` class manages several state elements using `ValueNotifier`:

```dart
// ValueNotifiers for settings
final ValueNotifier<Locale> _localeNotifier = ValueNotifier<Locale>(const Locale('en'));
final ValueNotifier<String> _temperatureUnitNotifier = ValueNotifier<String>('celsius');
final ValueNotifier<bool> _notificationsEnabledNotifier = ValueNotifier<bool>(true);
final ValueNotifier<ThemeMode> _themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);
final ValueNotifier<bool> _isAmoledThemeNotifier = ValueNotifier<bool>(false);
final ValueNotifier<List<Location>> _favouriteLocationsNotifier = ValueNotifier<List<Location>>([]);
final ValueNotifier<Location?> _activeLocationNotifier = ValueNotifier<Location?>(null);
final ValueNotifier<Location?> _geolocationNotifier = ValueNotifier<Location?>(null);
final ValueNotifier<bool> _geolocationEnabledNotifier = ValueNotifier<bool>(true);
final ValueNotifier<bool> _syncFavouritesToAppwriteNotifier = ValueNotifier<bool>(false);
```

### State Access

The `AppState` class provides both direct getters and `ValueNotifier` getters:

```dart
// Direct getters for current values
Locale get locale => _localeNotifier.value;

String get temperatureUnit => _temperatureUnitNotifier.value;
// ...

// ValueNotifier getters for reactive access
ValueNotifier<Locale> get localeNotifier => _localeNotifier;

ValueNotifier<String> get temperatureUnitNotifier => _temperatureUnitNotifier;
// ...
```

This dual approach allows for:

- Simple access when just reading the current value
- Reactive access when components need to rebuild on changes

### State Updates

The `AppState` class provides methods to update state elements:

```dart
void setLocale(Locale locale) {
  _localeNotifier.value = locale;
  _preferencesNotifier.setPreference(_localeKey, locale.languageCode);
  notifyListeners();
}
```

Each update method:

1. Updates the `ValueNotifier`
2. Persists the change to preferences
3. Notifies listeners of the change

## Preferences Management

The app uses a `PreferencesNotifier` to manage persistent preferences:

1. **Loading Preferences**: On app startup, preferences are loaded from storage
2. **Updating Preferences**: When settings change, they are persisted to storage
3. **Preference Keys**: Constants define the keys for different preferences

## ViewModels

For page-specific state and business logic, the app uses ViewModels:

### HomeViewModel

The `HomeViewModel` manages state for the Home Page:

```dart
class HomeViewModel extends ChangeNotifier {
  final AppState appState;
  Forecast? _forecast;
  bool _isLoading = false;
  String? _errorMessage;

// ...
}
```

Key features:

- Extends `ChangeNotifier` for reactive updates
- Holds reference to global `AppState`
- Manages page-specific state (forecast, loading, errors)
- Provides business logic methods (loadForecast, refreshForecast, etc.)

### Other ViewModels

Similar ViewModels exist for other pages:

- `FavoritesViewModel`: Manages favorites page state
- `WarningsViewModel`: Manages warnings page state
- `SettingsViewModel`: Manages settings page state

## State Flow

The state flow in the Weather App follows this general pattern:

1. **Initialization**:

- `AppState` is created and initialized with default values
- Preferences are loaded from storage
- Initial state is set based on preferences

2. **User Interaction**:

- User interacts with the UI (changes settings, adds favorites, etc.)
- UI components call methods on `AppState` or ViewModels

3. **State Update**:

- State is updated in `AppState` or ViewModel
- Changes are persisted to preferences if needed
- Listeners are notified of changes

4. **UI Update**:

- UI components listen to state changes via `Provider` or direct listeners
- UI rebuilds to reflect the new state

5. **AppWrite Sync** (if enabled):

- Changes to favorites are synced with AppWrite
- Changes from AppWrite are applied to local state

## Provider Usage

The app uses the `Provider` package for dependency injection and state access:

```dart
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const WeatherApp(),
    ),
  );
}
```

UI components access the state using `Provider.of` or `Consumer`:

```dart
// Access without rebuilding
final appState = Provider.of<AppState>(context, listen: false);

// Access with rebuilding on changes
Consumer<AppState>
(
builder: (context, appState, child) {
return Text(appState.temperatureUnit);
}
)
```

## State Management Best Practices

The Weather App follows several state management best practices:

1. **Single Source of Truth**: Global state is centralized in `AppState`
2. **Separation of Concerns**:

- `AppState` manages global state
- ViewModels manage page-specific state
- UI components are mostly stateless

3. **Reactive Updates**: UI rebuilds efficiently when state changes
4. **Persistence**: State is persisted to preferences for app restarts
5. **Testability**: State logic is separated from UI for easier testing

## Conclusion

The hybrid state management approach in the Weather App provides a balance of:

- Centralized global state for app-wide settings and data
- Localized state for page-specific concerns
- Efficient UI updates through reactive programming
- Persistence for user preferences and settings

This architecture allows for a maintainable and scalable application while providing a responsive user experience.
