import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:weather/l10n/app_localizations.g.dart';
import 'package:go_router/go_router.dart';

// Import app state
import 'app_state.dart';
// Import pages
import 'pages/favourites_page.dart';
import 'pages/home_page.dart';
import 'pages/settings_page.dart';
import 'pages/weather_symbols_page.dart';
import 'pages/about_page.dart';
import 'pages/warnings_page.dart';
import 'pages/other_page.dart'; // Added import for OtherPageListView
import 'routes.dart'; // Added import for AppRoutes

class NoTransitionPage<T> extends CustomTransitionPage<T> {
  const NoTransitionPage({
    required super.child,
    super.name,
    super.arguments,
    super.restorationId,
    super.key,
  }) : super(
          transitionsBuilder: _transitionsBuilder,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        );

  static Widget _transitionsBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

// Helper for creating branches for StatefulShellRoute
StatefulShellBranch _buildStatefulBranch(AppRouteInfo routeInfo, Widget childWidget, {GlobalKey<NavigatorState>? navigatorKey}) {
  return StatefulShellBranch(
    navigatorKey: navigatorKey,
    routes: <RouteBase>[
      GoRoute(
        path: routeInfo.path,
        name: routeInfo.name,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: childWidget,
        ),
      ),
    ],
  );
}

late final GoRouter _router = GoRouter(
  initialLocation: AppRoutes.home.path,
  routes: <RouteBase>[
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        // This child is either the StatefulNavigationShell (for Home/Fav/Warn/Other)
        // or the actual page widget for 'Other' routes.
        return MainScreen(child: child);
      },
      routes: <RouteBase>[
        // StatefulShellRoute for Home, Favourites, Warnings, Other
        StatefulShellRoute.indexedStack(
          builder: (BuildContext context, GoRouterState state,
              StatefulNavigationShell navigationShell) {
            // This navigationShell is the widget that manages and displays
            // the current active branch (Home, Favourites, Warnings, or Other).
            // It becomes the 'child' for the parent ShellRoute's builder (MainScreen).
            return navigationShell;
          },
          branches: <StatefulShellBranch>[
            _buildStatefulBranch(AppRoutes.home, const HomePage(key: PageStorageKey('home_page'))),
            _buildStatefulBranch(AppRoutes.favourites, const FavouritesPage(key: PageStorageKey('favourites_page'))),
            _buildStatefulBranch(AppRoutes.warnings, const WarningsPage(key: PageStorageKey('warnings_page'))),
            // Added 'Other' as a stateful branch with its nested children
            StatefulShellBranch(
              navigatorKey: GlobalKey<NavigatorState>(),
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoutes.other.path,
                  name: AppRoutes.other.name,
                  pageBuilder: (context, state) => NoTransitionPage(
                    key: state.pageKey,
                    child: const OtherPageListView(key: PageStorageKey('other_links_page')),
                  ),
                  routes: <RouteBase>[
                    GoRoute(
                      path: AppRoutes.settings.path,
                      name: AppRoutes.settings.name,
                      pageBuilder: (context, state) => NoTransitionPage(
                        key: state.pageKey,
                        child: const SettingsPage(key: PageStorageKey('settings_page')),
                      ),
                    ),
                    GoRoute(
                      path: AppRoutes.weatherSymbols.path,
                      name: AppRoutes.weatherSymbols.name,
                      pageBuilder: (context, state) => NoTransitionPage(
                        key: state.pageKey,
                        child: const WeatherSymbolsPage(key: PageStorageKey('weather_symbols_page')),
                      ),
                    ),
                    GoRoute(
                      path: AppRoutes.about.path,
                      name: AppRoutes.about.name,
                      pageBuilder: (context, state) => NoTransitionPage(
                        key: state.pageKey,
                        child: const AboutPage(key: PageStorageKey('about_page')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Error')),
    body: Center(child: Text('Page not found: ${state.error}')),
  ),
);

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
        return MaterialApp.router(
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
            Locale('en'),
            Locale('fi'),
          ],
          scrollBehavior: MyCustomScrollBehavior(),
          routerConfig: _router,
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final Widget child;

  const MainScreen({super.key, required this.child});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();

    if (location.startsWith(AppRoutes.other.path)) return 3;
    if (location.startsWith(AppRoutes.warnings.path)) return 2;
    if (location.startsWith(AppRoutes.favourites.path)) return 1;
    if (location.startsWith(AppRoutes.home.path)) return 0;

    return 0; // Default
  }

  void _onItemTapped(int index, BuildContext context) {
    final currentChild = widget.child;
    // Assuming Home, Favourites, Warnings, Other are the first 4 tabs (indices 0, 1, 2, 3)
    // and these are the ones managed by StatefulNavigationShell.
    const int statefulBranchCount = 4;

    if (currentChild is StatefulNavigationShell && index >= 0 && index < statefulBranchCount) {
      // We are on a stateful tab, and a stateful tab (0, 1, 2, or 3) was tapped.
      // Use goBranch to navigate, preserving state.
      currentChild.goBranch(index, initialLocation: index == currentChild.currentIndex);
    } else {
      // This block handles:
      // 1. currentChild is not StatefulNavigationShell (e.g., on "Other" page or its sub-routes).
      //    In this case, any tap (0, 1, 2, or 3) should use goNamed.
      switch (index) {
        case 0: // Home
          context.goNamed(AppRoutes.home.name);
          break;
        case 1: // Favourites
          context.goNamed(AppRoutes.favourites.name);
          break;
        case 2: // Warnings
          context.goNamed(AppRoutes.warnings.name);
          break;
        case 3: // Other
          context.goNamed(AppRoutes.other.name);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    final int currentIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: Row(
        children: [
          if (isWideScreen) _buildNavigationRail(context, currentIndex),
          Expanded(
            child: SafeArea(
              child: widget.child,
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWideScreen
          ? null
          : _buildBottomNavigationBar(context, currentIndex),
    );
  }

  Widget _buildNavigationRail(BuildContext context, int selectedIndex) {
    final localizations = AppLocalizations.of(context)!;

    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => _onItemTapped(index, context),
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
      onTap: (index) => _onItemTapped(index, context),
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

