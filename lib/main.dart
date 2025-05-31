import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:weather/l10n/app_localizations.g.dart';

// Import app state
import 'app_state.dart';
import 'pages/favourites_page.dart';
// Import pages
import 'pages/home_page.dart';
import 'pages/other_page.dart';
import 'pages/warnings_page.dart';

// Define route names
class MainRoutes {
  static const String home = '/';
  static const String favourites = '/favourites';
  static const String warnings = '/warnings';
  static const String other = '/other';
  // Routes for pages under 'OtherPage'
  static const String settings = '/other/settings';
  static const String weatherSymbols = '/other/weather_symbols';
  static const String about = '/other/about';
}

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
          initialRoute: MainRoutes.home,
          onGenerateRoute: (settings) {
            Widget page;
            // For main routes, always show MainScreen.
            // MainScreen's internal Navigator will handle displaying the correct page.
            switch (settings.name) {
              case MainRoutes.home:
              case MainRoutes.favourites:
              case MainRoutes.warnings:
              case MainRoutes.other:
                page =
                    const MainScreen(); // MainScreen will use the route from 'settings'
                break;
              // Sub-routes like MainRoutes.settings, .weatherSymbols, .about
              // are handled by the Navigator within OtherPage, so they are not cased here.
              default:
                // Fallback to MainScreen, which will likely show its default page (e.g., home)
                page = const MainScreen();
            }
            return MaterialPageRoute(builder: (_) => page, settings: settings);
          },
          routes: {
            // Routes are handled by onGenerateRoute
          },
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
  PageController? _pageController; // Changed to nullable
  int _currentDisplayIndex = 0;
  bool _dependenciesInitialized = false; // Flag to run initialization once
  final GlobalKey<NavigatorState> _otherPageNavigatorKey =
      GlobalKey<NavigatorState>(); // Key for OtherPage's Navigator

  // Define the main pages directly in a list for PageView
  late final List<Widget> _mainPages; // Make it late final

  @override
  void initState() {
    super.initState();
    _mainPages = [
      const HomePage(key: PageStorageKey('home_page')),
      const FavouritesPage(key: PageStorageKey('favourites_page')),
      const WarningsPage(key: PageStorageKey('warnings_page')),
      OtherPage(
          key: PageStorageKey('other_page'),
          navigatorKey: _otherPageNavigatorKey), // Pass the key
    ];
    // _pageController will be initialized in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dependenciesInitialized) {
      final String? initialRouteName = ModalRoute.of(context)?.settings.name;
      _currentDisplayIndex = _getSelectedIndex(initialRouteName);
      _pageController = PageController(initialPage: _currentDisplayIndex);
      _dependenciesInitialized = true;
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_currentDisplayIndex != index) {
      _pageController?.jumpToPage(index);
      // If we are moving away from the 'Other' page, reset its navigator
      if (_currentDisplayIndex == 3 && index != 3) {
        _otherPageNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
    } else if (index == 3 && _currentDisplayIndex == 3) {
      // If we are on the 'Other' page and tap it again, reset its navigator
      _otherPageNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
  }

  int _getSelectedIndex(String? currentRouteName) {
    if (currentRouteName == MainRoutes.home) return 0;
    if (currentRouteName == MainRoutes.favourites) return 1;
    if (currentRouteName == MainRoutes.warnings) return 2;
    if (currentRouteName == MainRoutes.other) return 3;
    // If MainScreen is loaded via a sub-route of OtherPage initially (e.g. deep link)
    // we might want to default to the 'Other' tab.
    if (currentRouteName == MainRoutes.settings ||
        currentRouteName == MainRoutes.weatherSymbols ||
        currentRouteName == MainRoutes.about) {
      return 3;
    }
    return 0; // Default to home
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    if (!_dependenciesInitialized || _pageController == null) {
      // Return a loading indicator or an empty container if not initialized yet
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Row(
        children: [
          if (isWideScreen) _buildNavigationRail(context, _currentDisplayIndex),
          Expanded(
            child: SafeArea(
              child: PageView.builder(
                controller:
                    _pageController!, // Use null assertion as it's checked
                itemCount: _mainPages.length,
                itemBuilder: (context, index) {
                  return _mainPages[index];
                },
                onPageChanged: (index) {
                  int previousIndex = _currentDisplayIndex;
                  setState(() {
                    _currentDisplayIndex = index;
                  });
                  // If we swiped away from the 'Other' page, reset its navigator
                  if (previousIndex == 3 && index != 3) {
                    _otherPageNavigatorKey.currentState
                        ?.popUntil((route) => route.isFirst);
                  }
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWideScreen
          ? null
          : _buildBottomNavigationBar(context, _currentDisplayIndex),
    );
  }

  Widget _buildNavigationRail(BuildContext context, int selectedIndex) {
    final localizations = AppLocalizations.of(context)!;

    return NavigationRail(
      selectedIndex: selectedIndex,
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

  Widget _buildBottomNavigationBar(BuildContext context, int selectedIndex) {
    final localizations = AppLocalizations.of(context)!;

    return BottomNavigationBar(
      currentIndex: selectedIndex,
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
