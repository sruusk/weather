# Data Models Documentation

This document provides an overview of the data models used in the Weather App, explaining their structure,
relationships, and how they work together.

## Core Data Models

### Location

The `Location` class represents a geographical location with coordinates and descriptive information.

**Key Properties:**

- `lat`: Latitude coordinate
- `lon`: Longitude coordinate
- `name`: Name of the location
- `countryCode`: Country code (e.g., "FI" for Finland)
- `region`: Optional region where the location is situated
- `country`: Optional full country name
- `index`: Optional index for ordering in favorites list

**Key Methods:**

- `toString()`: Converts the location to a string representation for storage
- `fromString()`: Creates a Location object from its string representation
- `distanceTo()`: Calculates the distance to another location in meters
- `distanceBetweenCoordinates()`: Static method to calculate distance between coordinates

**Usage:**

- Used to identify and store locations for weather forecasts
- Used in the app state for managing favorite locations
- Used in AppWrite integration for syncing locations between devices

### Forecast

The `Forecast` class represents a weather forecast for a specific location.

**Key Properties:**

- `location`: The Location object this forecast is for
- `forecast`: A list of ForecastPoint objects representing the forecast at different times

**Usage:**

- Returned by the WeatherData service when fetching forecasts
- Used by UI components to display weather information

### ForecastPoint

The `ForecastPoint` class represents weather conditions at a specific point in time.

**Key Properties:**

- `time`: The DateTime when this forecast point is valid
- `temperature`: Temperature in degrees Celsius
- `humidity`: Relative humidity percentage (0-100)
- `windDirection`: Wind direction in degrees (0-360, where 0 is North)
- `windSpeed`: Wind speed in meters per second
- `windGust`: Wind gust speed in meters per second
- `precipitation`: Precipitation amount in millimeters
- `probabilityOfPrecipitation`: Probability of precipitation (0-100%)
- `weatherSymbol`: Weather symbol name for UI representation
- `weatherSymbolCode`: Weather symbol code
- `feelsLike`: "Feels like" temperature in degrees Celsius

**Usage:**

- Used to display current weather conditions and forecasts
- Each Forecast contains multiple ForecastPoint objects

## Service Models

### WeatherData

The `WeatherData` class is a singleton service for fetching and managing weather data.

**Key Features:**

- Caches forecast data for different locations
- Supports multiple weather data sources:
  - OpenMeteo: Primary source for global weather data
  - Harmonie: Regional forecast model for Nordic/Baltic countries
- Maps weather codes to weather symbols for UI representation

**Key Methods:**

- `getCurrentWeather()`: Gets the current weather for a location
- `getForecast()`: Gets the weather forecast for a location
- `clearCache()`: Clears all cached data
- `clearCacheForLocation()`: Clears cached data for a specific location
- `getAutoCompleteResults()`: Gets location suggestions based on a search query
- `reverseGeocoding()`: Gets location information from coordinates

**Data Flow:**

1. UI requests weather data for a location
2. WeatherData checks if cached data exists
3. If not, it fetches data from external APIs:

- OpenMeteo API for global forecasts
- FMI's Harmonie model for Nordic/Baltic countries

4. It parses and transforms the data into application models
5. It caches the results for performance
6. It returns the data to the UI

### Weather Alerts

The `WeatherAlerts` class manages weather alerts and warnings.

**Key Features:**

- Fetches weather alerts from external APIs
- Caches alerts for performance
- Provides methods to get alerts for specific locations

## Data Source Models

### OpenMeteoResponse

The `OpenMeteoResponse` class handles parsing and transforming data from the OpenMeteo API.

**Key Features:**

- Maps API response to application models
- Handles different weather parameters

### HarmonieResponse

The `HarmonieResponse` class handles parsing and transforming data from the FMI's Harmonie model.

**Key Features:**

- Parses XML responses from the FMI API
- Extracts weather parameters for different time points

## Data Flow

The data flow in the Weather App follows this general pattern:

1. **User Interaction**: User selects a location or the app uses geolocation
2. **Data Request**: The app requests weather data for the selected location
3. **Data Retrieval**:

- If cached data exists and is valid, it's used
- Otherwise, new data is fetched from external APIs

4. **Data Processing**:

- API responses are parsed and transformed into application models
- Weather codes are mapped to weather symbols
- Data from different sources may be merged (e.g., OpenMeteo and Harmonie)

5. **Data Storage**:

- Processed data is cached for future use

6. **Data Display**:

- UI components use the data models to display weather information

## Model Relationships

- A `Location` is used to identify where weather data is for
- A `Forecast` contains a `Location` and multiple `ForecastPoint` objects
- `WeatherData` service uses `Location` to fetch and cache `Forecast` objects
- UI components use these models to display weather information

This architecture allows for efficient data management, caching, and display of weather information for multiple
locations.
