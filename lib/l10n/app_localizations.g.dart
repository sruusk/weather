import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.g.dart';
import 'app_localizations_fi.g.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.g.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fi')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get appTitle;

  /// Message shown when no location is selected
  ///
  /// In en, this message translates to:
  /// **'No location selected'**
  String get noLocationSelected;

  /// Error message with details
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String error(String error);

  /// Message shown when no observation stations are found
  ///
  /// In en, this message translates to:
  /// **'No observation stations found'**
  String get noObservationStationsFound;

  /// Distance to the observation station
  ///
  /// In en, this message translates to:
  /// **'Distance: {distance} km'**
  String distance(String distance);

  /// Label for temperature measurement
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// Label for humidity measurement
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// Label for dew point measurement
  ///
  /// In en, this message translates to:
  /// **'Dew Point'**
  String get dewPoint;

  /// Label for wind speed measurement
  ///
  /// In en, this message translates to:
  /// **'Wind Speed'**
  String get windSpeed;

  /// Label for wind direction measurement
  ///
  /// In en, this message translates to:
  /// **'Wind Direction'**
  String get windDirection;

  /// Label for wind gust measurement
  ///
  /// In en, this message translates to:
  /// **'Wind Gust'**
  String get windGust;

  /// Label for precipitation measurement
  ///
  /// In en, this message translates to:
  /// **'Precipitation'**
  String get precipitation;

  /// Label for snow depth measurement
  ///
  /// In en, this message translates to:
  /// **'Snow Depth'**
  String get snowDepth;

  /// Label for pressure measurement
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get pressure;

  /// Label for cloud base measurement
  ///
  /// In en, this message translates to:
  /// **'Cloud Base'**
  String get cloudBase;

  /// Label for visibility measurement
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get visibility;

  /// Message shown when no temperature history data is available
  ///
  /// In en, this message translates to:
  /// **'No temperature history data available'**
  String get noTemperatureHistoryData;

  /// Temperature in Celsius
  ///
  /// In en, this message translates to:
  /// **'°C'**
  String get temperatureCelsius;

  /// Title for the home page
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get homePageTitle;

  /// Title for the favourites page
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get favouritesPageTitle;

  /// Title for the warnings page
  ///
  /// In en, this message translates to:
  /// **'Weather Warnings'**
  String get warningsPageTitle;

  /// Title for the weather symbols page
  ///
  /// In en, this message translates to:
  /// **'Weather Symbols'**
  String get weatherSymbolsPageTitle;

  /// Title for the settings page
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsPageTitle;

  /// Title for the about page
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutPageTitle;

  /// Button to get current weather
  ///
  /// In en, this message translates to:
  /// **'Get Current Weather'**
  String get getCurrentWeather;

  /// Button to check for warnings
  ///
  /// In en, this message translates to:
  /// **'Check for Warnings'**
  String get checkForWarnings;

  /// Button to contact support
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// Label for language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Label for temperature unit setting
  ///
  /// In en, this message translates to:
  /// **'Temperature Unit'**
  String get temperatureUnit;

  /// Label for notifications setting
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Label for app version
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Description of the application
  ///
  /// In en, this message translates to:
  /// **'A simple weather application that provides current weather conditions, forecasts, and weather warnings.'**
  String get appDescription;

  /// Information about language support
  ///
  /// In en, this message translates to:
  /// **'This app supports both English and Finnish languages.'**
  String get languageSupport;

  /// Weather symbol title
  ///
  /// In en, this message translates to:
  /// **'Clear Day'**
  String get clearDay;

  /// Weather symbol title
  ///
  /// In en, this message translates to:
  /// **'Clear Night'**
  String get clearNight;

  /// Weather symbol title
  ///
  /// In en, this message translates to:
  /// **'Partly Cloudy Day'**
  String get partlyCloudyDay;

  /// Weather symbol title
  ///
  /// In en, this message translates to:
  /// **'Partly Cloudy Night'**
  String get partlyCloudyNight;

  /// Weather symbol title
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get cloudy;

  /// Weather symbol title
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get rain;

  /// Weather symbol title
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get thunderstorm;

  /// Weather symbol title
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm with Rain'**
  String get thunderstormWithRain;

  /// Weather symbol title
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get snow;

  /// Weather symbol title
  ///
  /// In en, this message translates to:
  /// **'Fog'**
  String get fog;

  /// Weather symbol title
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get wind;

  /// Weather symbol title
  ///
  /// In en, this message translates to:
  /// **'Tornado'**
  String get tornado;

  /// Weather symbol title
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm (Line)'**
  String get thunderstormLine;

  /// Weather symbol title
  ///
  /// In en, this message translates to:
  /// **'Wind (Line)'**
  String get windLine;

  /// Weather symbol description
  ///
  /// In en, this message translates to:
  /// **'Clear sky during daytime'**
  String get clearDayDesc;

  /// Weather symbol description
  ///
  /// In en, this message translates to:
  /// **'Clear sky during nighttime'**
  String get clearNightDesc;

  /// Weather symbol description
  ///
  /// In en, this message translates to:
  /// **'Some clouds during daytime'**
  String get partlyCloudyDayDesc;

  /// Weather symbol description
  ///
  /// In en, this message translates to:
  /// **'Some clouds during nighttime'**
  String get partlyCloudyNightDesc;

  /// Weather symbol description
  ///
  /// In en, this message translates to:
  /// **'Mostly or completely cloudy'**
  String get cloudyDesc;

  /// Weather symbol description
  ///
  /// In en, this message translates to:
  /// **'Rainfall'**
  String get rainDesc;

  /// Weather symbol description
  ///
  /// In en, this message translates to:
  /// **'Storm with thunder and lightning'**
  String get thunderstormDesc;

  /// Weather symbol description
  ///
  /// In en, this message translates to:
  /// **'Storm with thunder, lightning and rain'**
  String get thunderstormWithRainDesc;

  /// Weather symbol description
  ///
  /// In en, this message translates to:
  /// **'Snowfall'**
  String get snowDesc;

  /// Weather symbol description
  ///
  /// In en, this message translates to:
  /// **'Reduced visibility due to fog'**
  String get fogDesc;

  /// Weather symbol description
  ///
  /// In en, this message translates to:
  /// **'Strong winds'**
  String get windDesc;

  /// Weather symbol description
  ///
  /// In en, this message translates to:
  /// **'Violent rotating column of air'**
  String get tornadoDesc;

  /// Weather symbol description
  ///
  /// In en, this message translates to:
  /// **'Line style version'**
  String get lineStyleDesc;

  /// Label for weather radar
  ///
  /// In en, this message translates to:
  /// **'Weather Radar'**
  String get radar;

  /// Title for settings page
  ///
  /// In en, this message translates to:
  /// **'App settings and preferences'**
  String get appSettingsAndPreferences;

  /// English language name
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Finnish language name
  ///
  /// In en, this message translates to:
  /// **'Suomi'**
  String get finnish;

  /// Celsius temperature unit
  ///
  /// In en, this message translates to:
  /// **'Celsius'**
  String get celsius;

  /// Fahrenheit temperature unit
  ///
  /// In en, this message translates to:
  /// **'Fahrenheit'**
  String get fahrenheit;

  /// Enabled status
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// Label for geolocation setting
  ///
  /// In en, this message translates to:
  /// **'Geolocation'**
  String get geolocation;

  /// Disabled status
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// Header for data sources section
  ///
  /// In en, this message translates to:
  /// **'Data Sources'**
  String get dataSourcesHeader;

  /// Description for Open-Meteo data source
  ///
  /// In en, this message translates to:
  /// **'Weather data by Open-Meteo.com'**
  String get openMeteoDescription;

  /// Description for Finnish Meteorological Institute data source
  ///
  /// In en, this message translates to:
  /// **'Observations, alerts and radar images by \n the Finnish Meteorological Institute.'**
  String get fmiDescription;

  /// Description for OpenStreetMap data source
  ///
  /// In en, this message translates to:
  /// **'Map data by OpenStreetMap'**
  String get openStreetMapDescription;

  /// Label for a button to visit the data source website
  ///
  /// In en, this message translates to:
  /// **'Visit Website'**
  String get visitWebsite;

  /// Label for theme setting
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Dark theme
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// Light theme
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// Placeholder for location search
  ///
  /// In en, this message translates to:
  /// **'Search for location'**
  String get searchForLocation;

  /// Label for searching and adding to favourites
  ///
  /// In en, this message translates to:
  /// **'Search and add to favourites'**
  String get searchAndAddFavourites;

  /// Message indicating that support contact feature is not implemented
  ///
  /// In en, this message translates to:
  /// **'Support contact feature not implemented yet.'**
  String get supportContactNotImplemented;

  /// Message indicating that there are no saved locations
  ///
  /// In en, this message translates to:
  /// **'No saved locations'**
  String get noSavedLocations;

  /// Header for the licenses section
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licensesHeader;

  /// Name of the SmartMet alert client library
  ///
  /// In en, this message translates to:
  /// **'SmartMet Alert Client'**
  String get smartmetAlertClientName;

  /// License type for the SmartMet alert client
  ///
  /// In en, this message translates to:
  /// **'MIT License'**
  String get smartmetAlertClientLicense;

  /// Button text to view the license
  ///
  /// In en, this message translates to:
  /// **'View License'**
  String get viewLicense;

  /// Label for observations
  ///
  /// In en, this message translates to:
  /// **'Observations'**
  String get observations;

  /// Label for weather warnings
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get weatherWarnings;

  /// Message indicating no weather warnings for the current day
  ///
  /// In en, this message translates to:
  /// **'No weather warnings for today'**
  String get noWeatherWarningsForDay;

  /// Title for the other page
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherPageTitle;

  /// Description for the settings page in the other page
  ///
  /// In en, this message translates to:
  /// **'Configure app settings and preferences'**
  String get settingsPageDescription;

  /// Description for the weather symbols page in the other page
  ///
  /// In en, this message translates to:
  /// **'View and learn about weather symbols used in the app'**
  String get weatherSymbolsPageDescription;

  /// Description for the about page in the other page
  ///
  /// In en, this message translates to:
  /// **'Information about data sources and licenses'**
  String get aboutPageDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fi':
      return AppLocalizationsFi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
