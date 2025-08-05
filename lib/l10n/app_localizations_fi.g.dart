// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.g.dart';

// ignore_for_file: type=lint

/// The translations for Finnish (`fi`).
class AppLocalizationsFi extends AppLocalizations {
  AppLocalizationsFi([String locale = 'fi']) : super(locale);

  @override
  String get webPerformanceWarningTitle =>
      'Verkkosovelluksen suorituskykyvaroitus';

  @override
  String get webPerformanceWarningMessage =>
      'Verkkosovelluksella on rajoitettu suorituskyky verrattuna mobiilisovellukseen, ja on tarkoitettu vain demonstratiivisiin tarkoituksiin.';

  @override
  String get webMapDifferenceMessage =>
      'Verkkosovelluksessa käytetään eri karttoja kuin mobiilisovelluksessa, joten karttatoiminnot ovat visuaalisesti erilaisia.';

  @override
  String get acknowledge => 'Ymmärrän';

  @override
  String get signUp => 'Rekisteröidy';

  @override
  String get name => 'Nimi';

  @override
  String get enterYourName => 'Syötä nimesi';

  @override
  String get email => 'Sähköposti';

  @override
  String get enterYourEmail => 'Syötä sähköpostiosoitteesi';

  @override
  String get password => 'Salasana';

  @override
  String get enterYourPassword => 'Syötä salasanasi';

  @override
  String get createAccount => 'Luo tili';

  @override
  String get haveAccountLogin => 'Onko sinulla tili? Kirjaudu';

  @override
  String get or => 'Tai';

  @override
  String get signInWithGoogle => 'Kirjaudu Google-tilillä';

  @override
  String get unknownError => 'Tuntematon virhe tapahtui';

  @override
  String get appTitle => 'Sää';

  @override
  String get noLocationSelected => 'Sijaintia ei ole valittu';

  @override
  String error(String error) {
    return 'Virhe: $error';
  }

  @override
  String get noObservationStationsFound => 'Havaintoasemia ei löytynyt';

  @override
  String distance(String distance) {
    return 'Etäisyys: $distance km';
  }

  @override
  String get temperature => 'Lämpötila';

  @override
  String get humidity => 'Kosteus';

  @override
  String get dewPoint => 'Kastepiste';

  @override
  String get windSpeed => 'Tuulen nopeus';

  @override
  String get windDirection => 'Tuulen suunta';

  @override
  String get windGust => 'Tuulen puuska';

  @override
  String get precipitation => 'Sademäärä';

  @override
  String get snowDepth => 'Lumen syvyys';

  @override
  String get pressure => 'Ilmanpaine';

  @override
  String get cloudBase => 'Pilvien korkeus';

  @override
  String get visibility => 'Näkyvyys';

  @override
  String get noTemperatureHistoryData => 'Lämpötilahistoriaa ei saatavilla';

  @override
  String get noWindHistoryData => 'Tuulen historiaa ei saatavilla';

  @override
  String get temperatureCelsius => '°C';

  @override
  String get homePageTitle => 'Sää';

  @override
  String get favouritesPageTitle => 'Suosikit';

  @override
  String get warningsPageTitle => 'Varoitukset';

  @override
  String get weatherSymbolsPageTitle => 'Sääsymbolit';

  @override
  String get settingsPageTitle => 'Asetukset';

  @override
  String get aboutPageTitle => 'Tietoja';

  @override
  String get getCurrentWeather => 'Hae nykyinen sää';

  @override
  String get checkForWarnings => 'Tarkista hälytykset';

  @override
  String get contactSupport => 'Ota yhteyttä tukeen';

  @override
  String get language => 'Kieli';

  @override
  String get temperatureUnit => 'Lämpötilayksikkö';

  @override
  String get notifications => 'Ilmoitukset';

  @override
  String get version => 'Versio';

  @override
  String get appDescription =>
      'Yksinkertainen sääsovellus, joka tarjoaa nykyiset sääolosuhteet, ennusteet ja säävaroitukset.';

  @override
  String get languageSupport =>
      'Tämä sovellus tukee sekä englannin että suomen kieltä.';

  @override
  String get clearDay => 'Selkeä Päivä';

  @override
  String get clearNight => 'Selkeä Yö';

  @override
  String get partlyCloudyDay => 'Osittain Pilvinen Päivä';

  @override
  String get partlyCloudyNight => 'Osittain Pilvinen Yö';

  @override
  String get cloudy => 'Pilvinen';

  @override
  String get rain => 'Sade';

  @override
  String get thunderstorm => 'Ukkosmyrsky';

  @override
  String get thunderstormWithRain => 'Ukkosmyrsky Sateella';

  @override
  String get snow => 'Lumi';

  @override
  String get fog => 'Sumu';

  @override
  String get wind => 'Tuuli';

  @override
  String get tornado => 'Tornado';

  @override
  String get thunderstormLine => 'Ukkosmyrsky (Viiva)';

  @override
  String get windLine => 'Tuuli (Viiva)';

  @override
  String get clearDayDesc => 'Kirkas taivas päivällä';

  @override
  String get clearNightDesc => 'Kirkas taivas yöllä';

  @override
  String get partlyCloudyDayDesc => 'Joitakin pilviä päivällä';

  @override
  String get partlyCloudyNightDesc => 'Joitakin pilviä yöllä';

  @override
  String get cloudyDesc => 'Enimmäkseen tai täysin pilvinen';

  @override
  String get rainDesc => 'Sademäärä';

  @override
  String get thunderstormDesc => 'Myrsky ukkosella ja salamoinnilla';

  @override
  String get thunderstormWithRainDesc =>
      'Myrsky ukkosella, salamoinnilla ja sateella';

  @override
  String get snowDesc => 'Lumisade';

  @override
  String get fogDesc => 'Heikentynyt näkyvyys sumun vuoksi';

  @override
  String get windDesc => 'Voimakkaat tuulet';

  @override
  String get tornadoDesc => 'Voimakas pyörivä ilmapatsas';

  @override
  String get lineStyleDesc => 'Viivatyylinen versio';

  @override
  String get radar => 'Sadetutka';

  @override
  String get appSettingsAndPreferences =>
      'Sovelluksen asetukset ja määritykset';

  @override
  String get english => 'English';

  @override
  String get finnish => 'Suomi';

  @override
  String get celsius => 'Celsius';

  @override
  String get fahrenheit => 'Fahrenheit';

  @override
  String get enabled => 'Käytössä';

  @override
  String get geolocation => 'Sijainti';

  @override
  String get disabled => 'Pois käytöstä';

  @override
  String get settingsSync => 'Synkronointi';

  @override
  String get settingsSyncDesc =>
      'Synkronoi sovelluksen asetukset ja suosikit laitteiden välillä.';

  @override
  String get login => 'Kirjaudu sisään';

  @override
  String get logout => 'Kirjaudu ulos';

  @override
  String get logoutConfirmationTitle => 'Kirjaudu ulos?';

  @override
  String get logoutConfirmationMessage => 'Haluatko varmasti kirjautua ulos?';

  @override
  String get cancel => 'Peruuta';

  @override
  String get dataSourcesHeader => 'Tietolähteet';

  @override
  String get openMeteoDescription => 'Sääennusteet - Open-Meteo';

  @override
  String get fmiDescription =>
      'Havainnot, varoitukset, tutkakuvat ja HARMONIE sääennuste - Ilmatieteen laitos.';

  @override
  String get openStreetMapDescription => 'Karttadata';

  @override
  String get visitWebsite => 'Vieraile sivustolla';

  @override
  String get theme => 'Teema';

  @override
  String get dark => 'Tumma';

  @override
  String get light => 'Vaalea';

  @override
  String get system => 'Järjestelmä';

  @override
  String get searchForLocation => 'Etsi sijaintia';

  @override
  String get searchAndAddFavourites => 'Etsi ja lisää suosikkeihin';

  @override
  String get supportContactNotImplemented =>
      'Yhteydenotto ei ole vielä mahdollista.';

  @override
  String get noSavedLocations => 'Ei tallennettuja sijainteja';

  @override
  String get licensesHeader => 'Lisenssit';

  @override
  String get smartmetAlertClientName => 'SmartMet Alert Client';

  @override
  String get smartmetAlertClientLicense => 'MIT Lisenssi';

  @override
  String get viewLicense => 'Näytä lisenssi';

  @override
  String get observations => 'Havainnot';

  @override
  String get weatherWarnings => 'Varoitukset';

  @override
  String get noWeatherWarningsForDay => 'Ei säävaroituksia tälle päivälle';

  @override
  String get otherPageTitle => 'Muut';

  @override
  String get settingsPageDescription =>
      'Määritä sovelluksen asetukset ja määritykset';

  @override
  String get weatherSymbolsPageDescription =>
      'Katso ja opi sovelluksessa käytetyistä sääsymboleista';

  @override
  String get aboutPageDescription => 'Tietoa tietolähteistä ja lisensseistä';

  @override
  String get favouritesPageDescription =>
      'Tarkastele ja muokkaa tallennettuja sijainteja';

  @override
  String get locating => 'Paikannetaan...';

  @override
  String get loadingForecasts => 'Ladataan ennusteita...';

  @override
  String get geolocationTimeout => 'Sijainnin haku epäonnistui.';

  @override
  String get retry => 'Yritä uudelleen';

  @override
  String get syncFavourites => 'Suosikit';

  @override
  String get syncFavouritesDesc => 'Synkronoi suosikit laitteiden välillä.';

  @override
  String get syncToAppwrite => 'Synkronoi';

  @override
  String get syncFavouritesSuccess => 'Suosikkien synkronointi onnistui.';

  @override
  String syncFavouritesError(String error) {
    return 'Synkronointi epäonnistui: $error';
  }

  @override
  String get addLocationsInFavourites =>
      'Voit lisätä sijainteja siirtymällä suosikkeihin';

  @override
  String get goToFavourites => 'Siirry suosikkeihin';

  @override
  String get deleteAccount => 'Poista tili';

  @override
  String get deleteAccountConfirmationTitle => 'Vahvista tilin poisto';

  @override
  String get deleteAccountConfirmationMessage =>
      'Haluatko varmasti poistaa tilisi? Tämä poistaa kaikki tietosi pysyvästi.';

  @override
  String get deleteAccountSuccess => 'Tili poistettiin onnistuneesti.';

  @override
  String get deleteAccountError => 'Tilin poisto epäonnistui.';

  @override
  String get locationServicesDisabled =>
      'Sijaintipalvelut ovat pois käytöstä. Ota sijaintipalvelut käyttöön laitteen asetuksista.';

  @override
  String get locationPermissionDenied =>
      'Sijaintilupa evätty. Salli sovelluksen käyttää sijaintiasi.';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Sijaintilupa pysyvästi evätty. Ota sijainti käyttöön sovelluksen asetuksista.';

  @override
  String get play => 'Toista';

  @override
  String get pause => 'Pysäytä';

  @override
  String minutesAgo(Object minutes) {
    return '$minutes min. sitten';
  }

  @override
  String get resetMapPosition => 'Nollaa kartan sijainti';

  @override
  String get openSettings => 'Avaa asetukset';

  @override
  String get ossLicenses => 'Avoimen Lähdekoodin Lisenssit';

  @override
  String get amoledTheme => 'AMOLED Tumma';

  @override
  String alertValidPeriod(String startDate, String endDate) {
    return 'Voimassa: $startDate - $endDate';
  }

  @override
  String areaCode(String code) {
    return 'Aluekoodi: $code';
  }

  @override
  String get noActiveAlerts => 'Ei aktiivisia varoituksia valitulle päivälle';

  @override
  String get activeWeatherAlerts => 'Aktiiviset säävaroitukset';

  @override
  String get nlfDataSource => 'Maanmittauslaitos';

  @override
  String nlfDescription(String month, String year) {
    return 'Sisältää Maanmittauslaitoksen Nimistötietokannan $month/$year aineistoa';
  }
}
