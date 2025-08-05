// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.g.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get webPerformanceWarningTitle => 'Web Version Notice';

  @override
  String get webPerformanceWarningMessage =>
      'This web version has sub-par performance and is only for demonstration purposes.';

  @override
  String get webMapDifferenceMessage =>
      'The web version uses a different base map for weather radar and warnings.';

  @override
  String get acknowledge => 'I Understand';

  @override
  String get signUp => 'Sign Up';

  @override
  String get name => 'Name';

  @override
  String get enterYourName => 'Enter your name';

  @override
  String get email => 'Email';

  @override
  String get enterYourEmail => 'Enter your email';

  @override
  String get password => 'Password';

  @override
  String get enterYourPassword => 'Enter your password';

  @override
  String get createAccount => 'Create an account';

  @override
  String get haveAccountLogin => 'Have an account? Login';

  @override
  String get or => 'Or';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get unknownError => 'An unknown error occurred';

  @override
  String get appTitle => 'Weather';

  @override
  String get noLocationSelected => 'No location selected';

  @override
  String error(String error) {
    return 'Error: $error';
  }

  @override
  String get noObservationStationsFound => 'No observation stations found';

  @override
  String distance(String distance) {
    return 'Distance: $distance km';
  }

  @override
  String get temperature => 'Temperature';

  @override
  String get humidity => 'Humidity';

  @override
  String get dewPoint => 'Dew Point';

  @override
  String get windSpeed => 'Wind Speed';

  @override
  String get windDirection => 'Wind Direction';

  @override
  String get windGust => 'Wind Gust';

  @override
  String get precipitation => 'Precipitation';

  @override
  String get snowDepth => 'Snow Depth';

  @override
  String get pressure => 'Pressure';

  @override
  String get cloudBase => 'Cloud Base';

  @override
  String get visibility => 'Visibility';

  @override
  String get noTemperatureHistoryData =>
      'No temperature history data available';

  @override
  String get noWindHistoryData => 'No wind history data available';

  @override
  String get temperatureCelsius => '°C';

  @override
  String get homePageTitle => 'Weather';

  @override
  String get favouritesPageTitle => 'Favourites';

  @override
  String get warningsPageTitle => 'Warnings';

  @override
  String get weatherSymbolsPageTitle => 'Weather Symbols';

  @override
  String get settingsPageTitle => 'Settings';

  @override
  String get aboutPageTitle => 'About';

  @override
  String get getCurrentWeather => 'Get Current Weather';

  @override
  String get checkForWarnings => 'Check for Warnings';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get language => 'Language';

  @override
  String get temperatureUnit => 'Temperature Unit';

  @override
  String get notifications => 'Notifications';

  @override
  String get version => 'Version';

  @override
  String get appDescription =>
      'A simple weather application that provides current weather conditions, forecasts, and weather warnings.';

  @override
  String get languageSupport =>
      'This app supports both English and Finnish languages.';

  @override
  String get clearDay => 'Clear Day';

  @override
  String get clearNight => 'Clear Night';

  @override
  String get partlyCloudyDay => 'Partly Cloudy Day';

  @override
  String get partlyCloudyNight => 'Partly Cloudy Night';

  @override
  String get cloudy => 'Cloudy';

  @override
  String get rain => 'Rain';

  @override
  String get thunderstorm => 'Thunderstorm';

  @override
  String get thunderstormWithRain => 'Thunderstorm with Rain';

  @override
  String get snow => 'Snow';

  @override
  String get fog => 'Fog';

  @override
  String get wind => 'Wind';

  @override
  String get tornado => 'Tornado';

  @override
  String get thunderstormLine => 'Thunderstorm (Line)';

  @override
  String get windLine => 'Wind (Line)';

  @override
  String get clearDayDesc => 'Clear sky during daytime';

  @override
  String get clearNightDesc => 'Clear sky during nighttime';

  @override
  String get partlyCloudyDayDesc => 'Some clouds during daytime';

  @override
  String get partlyCloudyNightDesc => 'Some clouds during nighttime';

  @override
  String get cloudyDesc => 'Mostly or completely cloudy';

  @override
  String get rainDesc => 'Rainfall';

  @override
  String get thunderstormDesc => 'Storm with thunder and lightning';

  @override
  String get thunderstormWithRainDesc =>
      'Storm with thunder, lightning and rain';

  @override
  String get snowDesc => 'Snowfall';

  @override
  String get fogDesc => 'Reduced visibility due to fog';

  @override
  String get windDesc => 'Strong winds';

  @override
  String get tornadoDesc => 'Violent rotating column of air';

  @override
  String get lineStyleDesc => 'Line style version';

  @override
  String get radar => 'Weather Radar';

  @override
  String get appSettingsAndPreferences => 'App settings and preferences';

  @override
  String get english => 'English';

  @override
  String get finnish => 'Suomi';

  @override
  String get celsius => 'Celsius';

  @override
  String get fahrenheit => 'Fahrenheit';

  @override
  String get enabled => 'Enabled';

  @override
  String get geolocation => 'Geolocation';

  @override
  String get disabled => 'Disabled';

  @override
  String get settingsSync => 'Preferences Sync';

  @override
  String get settingsSyncDesc =>
      'Synchronize your app preferences and favourites across devices';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirmationTitle => 'Logout?';

  @override
  String get logoutConfirmationMessage =>
      'Are you sure you want to logout? Your preferences and favourites will not be lost.';

  @override
  String get cancel => 'Cancel';

  @override
  String get dataSourcesHeader => 'Data Sources';

  @override
  String get openMeteoDescription => 'Weather forecasts by Open-Meteo.com';

  @override
  String get fmiDescription =>
      'Observations, alerts, radar images and HARMONIE forecast by the Finnish Meteorological Institute.';

  @override
  String get openStreetMapDescription => 'Map data by OpenStreetMap';

  @override
  String get visitWebsite => 'Visit Website';

  @override
  String get theme => 'Theme';

  @override
  String get dark => 'Dark';

  @override
  String get light => 'Light';

  @override
  String get system => 'System';

  @override
  String get searchForLocation => 'Search for location';

  @override
  String get searchAndAddFavourites => 'Search and add to favourites';

  @override
  String get supportContactNotImplemented =>
      'Support contact feature not implemented yet.';

  @override
  String get noSavedLocations => 'No saved locations';

  @override
  String get licensesHeader => 'Licenses';

  @override
  String get smartmetAlertClientName => 'SmartMet Alert Client';

  @override
  String get smartmetAlertClientLicense => 'MIT License';

  @override
  String get viewLicense => 'View License';

  @override
  String get observations => 'Observations';

  @override
  String get weatherWarnings => 'Warnings';

  @override
  String get noWeatherWarningsForDay => 'No weather warnings for today';

  @override
  String get otherPageTitle => 'Other';

  @override
  String get settingsPageDescription =>
      'Configure app settings and preferences';

  @override
  String get weatherSymbolsPageDescription =>
      'View and learn about weather symbols used in the app';

  @override
  String get aboutPageDescription =>
      'Information about data sources and licenses';

  @override
  String get favouritesPageDescription =>
      'View and manage your saved locations';

  @override
  String get locating => 'Locating your position...';

  @override
  String get loadingForecasts => 'Loading forecasts...';

  @override
  String get geolocationTimeout =>
      'Geolocation request timed out. Please check your device settings.';

  @override
  String get retry => 'Retry';

  @override
  String get syncFavourites => 'Favourites';

  @override
  String get syncFavouritesDesc => 'Synchronize your favourites';

  @override
  String get syncToAppwrite => 'Sync';

  @override
  String get syncFavouritesSuccess => 'Favourites synchronized successfully.';

  @override
  String syncFavouritesError(String error) {
    return 'Error synchronizing favourites: $error';
  }

  @override
  String get addLocationsInFavourites =>
      'You can add locations on the Favourites page.';

  @override
  String get goToFavourites => 'Go to Favourites';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountConfirmationTitle => 'Delete Account?';

  @override
  String get deleteAccountConfirmationMessage =>
      'Are you sure you want to delete your account? This action cannot be undone and will remove all your data.';

  @override
  String get deleteAccountSuccess => 'Account deleted successfully.';

  @override
  String get deleteAccountError => 'Error deleting account.';

  @override
  String get locationServicesDisabled =>
      'Location services are disabled. Please enable location services in your device settings.';

  @override
  String get locationPermissionDenied =>
      'Location permission denied. Please allow the app to access your location.';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Location permission permanently denied. Please enable location access in app settings.';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String minutesAgo(Object minutes) {
    return '$minutes min ago';
  }

  @override
  String get resetMapPosition => 'Reset Map Position';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get ossLicenses => 'Open Source Licenses';

  @override
  String get amoledTheme => 'AMOLED Dark';

  @override
  String alertValidPeriod(String startDate, String endDate) {
    return 'Valid: $startDate - $endDate';
  }

  @override
  String areaCode(String code) {
    return 'Area Code: $code';
  }

  @override
  String get noActiveAlerts => 'No active alerts for the selected date';

  @override
  String get activeWeatherAlerts => 'Active Weather Alerts';

  @override
  String get nlfDataSource => 'National Land Survey of Finland';

  @override
  String nlfDescription(String month, String year) {
    return 'Contains data from the National Land Survey of Finland Geographic names Database $month/$year';
  }
}
