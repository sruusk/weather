import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:weather/l10n/app_localizations.g.dart';

// Import app state
import 'app_state.dart';
import 'pages/about_page.dart';
import 'pages/favourites_page.dart';
// Import pages
import 'pages/home_page.dart';
import 'pages/settings_page.dart';
import 'pages/warnings_page.dart';
import 'pages/weather_symbols_page.dart';

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    final availableVersion = await WebViewEnvironment.getAvailableVersion();
    assert(availableVersion != null,
        'Failed to find an installed WebView2 Runtime or non-stable Microsoft Edge installation.');

    webViewEnvironment = await WebViewEnvironment.create();
  }

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return MaterialApp(
          title: 'Weather App',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: appState.themeMode,
          locale: appState.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('fi'), // Finnish
          ],
          scrollBehavior: MyCustomScrollBehavior(),
          home: const MainScreen(),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(key: PageStorageKey('home_page')),
    const FavouritesPage(key: PageStorageKey('favourites_page')),
    const WarningsPage(key: PageStorageKey('warnings_page')),
    const WeatherSymbolsPage(key: PageStorageKey('weather_symbols_page')),
    const SettingsPage(key: PageStorageKey('settings_page')),
    const AboutPage(key: PageStorageKey('about_page')),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex != 0
          ? AppBar(title: Text(_getTitle(context, _selectedIndex)))
          : null,
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration:
            BoxDecoration(color: Theme.of(context).colorScheme.surfaceBright),
            child: Text(localizations.appTitle, style: TextStyle(fontSize: 24)),
          ),
          _buildTile(Icons.home, localizations.homePageTitle, 0),
          _buildTile(Icons.favorite, localizations.favouritesPageTitle, 1),
          _buildTile(Icons.warning, localizations.warningsPageTitle, 2),
          _buildTile(Icons.cloud, localizations.weatherSymbolsPageTitle, 3),
          _buildTile(Icons.settings, localizations.settingsPageTitle, 4),
          _buildTile(Icons.info, localizations.aboutPageTitle, 5),
        ],
      ),
    );
  }

  ListTile _buildTile(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index,
      onTap: () => _onItemTapped(index),
    );
  }

  String _getTitle(BuildContext context, int index) {
    final l = AppLocalizations.of(context)!;
    switch (index) {
      case 0:
        return l.homePageTitle;
      case 1:
        return l.favouritesPageTitle;
      case 2:
        return l.warningsPageTitle;
      case 3:
        return l.weatherSymbolsPageTitle;
      case 4:
        return l.settingsPageTitle;
      case 5:
        return l.aboutPageTitle;
      default:
        return l.appTitle;
    }
  }
}
