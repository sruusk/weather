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
import 'pages/other_page.dart';
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
          debugShowCheckedModeBanner: true,
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

  // Main navigation pages
  final List<Widget> _mainPages = [
    const HomePage(key: PageStorageKey('home_page')),
    const FavouritesPage(key: PageStorageKey('favourites_page')),
    const WarningsPage(key: PageStorageKey('warnings_page')),
    const OtherPage(key: PageStorageKey('other_page')),
  ];

  void _onItemTapped(int index) {
    // Simply update the selected index to navigate to the new tab
    // No need to handle sub-page navigation as it's now handled in OtherPage
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail for wide screens
          if (isWideScreen) _buildNavigationRail(context),

          // Main content
          Expanded(
            child: SafeArea(
              child: IndexedStack(
                index: _selectedIndex,
                children: _mainPages,
              ),
            ),
          ),
        ],
      ),
      // Bottom Navigation Bar for narrow screens
      bottomNavigationBar: isWideScreen ? null : _buildBottomNavigationBar(context),
    );
  }

  Widget _buildNavigationRail(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onItemTapped,
      labelType: NavigationRailLabelType.all,
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.home),
          label: Text(localizations.homePageTitle),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.favorite),
          label: Text(localizations.favouritesPageTitle),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.warning),
          label: Text(localizations.warningsPageTitle),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.more_horiz),
          label: Text(localizations.otherPageTitle),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: localizations.homePageTitle,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.favorite),
          label: localizations.favouritesPageTitle,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.warning),
          label: localizations.warningsPageTitle,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.more_horiz),
          label: localizations.otherPageTitle,
        ),
      ],
    );
  }
}
