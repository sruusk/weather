# Widget Trees Documentation

This document provides an overview of the widget trees for each page in the Weather App, explaining their structure, key
components, and how they work together.

## Main Application Structure

The Weather App uses a bottom navigation bar to navigate between different pages:

- Home Page: Displays weather information for the selected location
- Favorites Page: Manages favorite locations
- Warnings Page: Shows weather warnings and alerts
- Settings Page: Configures app settings

## Home Page

The Home Page displays weather information for the currently selected location.

### Widget Hierarchy

```
HomePage
├── Scaffold
│   └── SafeArea
│       └── LayoutBuilder
│           ├── WeatherSkeleton (when loading)
│           ├── NoLocations (when no locations available)
│           └── RefreshIndicator (when data available)
│               └── SingleChildScrollView
│                   └── Column
│                       └── WeatherContentWidget
│                           └── LayoutBuilder
│                               ├── Wrap (for wide screens)
│                               │   └── SizedBox (for each child)
│                               │       └── ChildCardWidget
│                               │           └── [Weather Components]
│                               └── Column (for narrow screens)
│                                   └── ChildCardWidget
│                                       └── [Weather Components]
```

### Key Components

1. **WeatherContentWidget**: Adapts layout based on screen size

- For wide screens: Uses a `Wrap` layout with widgets taking half the screen width
- For narrow screens: Uses a `Column` layout with widgets stacked vertically

2. **Weather Components**:

- **CurrentForecast**: Displays current weather conditions
  - Shows temperature, weather symbol, location name
  - Includes a location dropdown for switching between locations
- **WeatherWarnings**: Shows weather warnings (conditionally displayed based on country)
- **ForecastWidget**: Shows the weather forecast
  - Displays hourly and daily forecasts
  - Includes temperature, precipitation, wind information
- **ObservationsWidget**: Shows weather observations (conditionally displayed based on country)
  - Displays temperature and wind history charts

3. **State Management**:

- Uses a `HomeViewModel` to manage business logic and state
- Reacts to changes using `AnimatedBuilder`
- Handles loading, error, and data states

## Favorites Page

The Favorites Page allows users to manage their favorite locations.

### Widget Hierarchy

```
FavouritesPage
├── Scaffold
│   └── Column
│       ├── Padding
│       │   └── SearchBar
│       └── Expanded
│           ├── ListView (for search results)
│           │   └── ListTile (for each result)
│           └── ReorderableListView (for favorites)
│               └── ListTile (for each favorite)
```

### Key Components

1. **SearchBar**: Allows users to search for locations

- Autocompletes location names
- Shows search results as they type

2. **ReorderableListView**: Displays favorite locations

- Allows reordering by drag and drop
- Each item has a delete button

3. **State Management**:

- Uses the app state to manage favorite locations
- Updates when locations are added, removed, or reordered

## Warnings Page

The Warnings Page displays weather warnings and alerts for the user's region.

### Widget Hierarchy

```
WarningsPage
├── Scaffold
│   └── SafeArea
│       └── Column
│           ├── WarningsMap (when map view selected)
│           │   └── FlutterMap
│           └── ListView (when list view selected)
│               └── WarningCard (for each warning)
```

### Key Components

1. **View Toggle**: Switches between map and list views

- Map view shows warnings on a geographical map
- List view shows warnings as a scrollable list

2. **WarningsMap**: Displays warnings on a map

- Uses `FlutterMap` for map rendering
- Shows warning areas with color coding

3. **WarningCard**: Displays detailed information about a warning

- Shows severity, type, time period, and description
- Color-coded based on severity

4. **State Management**:

- Fetches warnings from the `WeatherAlerts` service
- Filters warnings based on location and severity

## Settings Page

The Settings Page allows users to configure app settings.

### Widget Hierarchy

```
SettingsPage
├── Scaffold
│   └── SafeArea
│       └── ListView
│           ├── SettingsSection (for each section)
│           │   ├── SettingsHeader
│           │   └── SettingsItem (for each setting)
│           └── AboutListTile
```

### Key Components

1. **SettingsSection**: Groups related settings

- Appearance settings (theme, language)
- Units settings (temperature)
- Notification settings
- Account settings (AppWrite integration)

2. **SettingsItem**: Individual setting control

- Toggle switches for boolean settings
- Radio buttons for selection settings
- Buttons for actions

3. **State Management**:

- Uses the app state to read and update settings
- Changes are immediately applied and persisted

## Responsive Design

The Weather App implements responsive design to adapt to different screen sizes:

1. **LayoutBuilder**: Used throughout the app to adapt layouts based on available width

- Wide screens (> 900px): Multi-column layouts, side-by-side components
- Narrow screens: Single-column layouts, stacked components

2. **Adaptive Components**:

- Charts and graphs resize based on available space
- Text sizes adjust for readability
- Touch targets maintain minimum size for usability

3. **Orientation Support**:

- Layouts adapt to both portrait and landscape orientations
- Critical information remains visible in all orientations

## Widget Reuse and Composition

The app uses a component-based architecture with reusable widgets:

1. **ChildCardWidget**: Provides consistent card styling for content
2. **WeatherSkeleton**: Shows loading placeholders with consistent styling
3. **Common Components**: Reused across different pages (e.g., location dropdown)

This approach ensures consistency in the UI while allowing for flexible composition of pages and screens.
