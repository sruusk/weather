import 'dart:ui';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:weather/l10n/app_localizations.g.dart';

import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather/data/location.dart';
import 'package:weather/data/weather_data.dart';
import 'package:weather/data/widget_updater.dart';
import 'package:intl/intl.dart';

import 'app_state.dart';
import 'appwrite_client.dart';
import 'pages/about_page.dart';
// Import pages
import 'pages/favourites_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/other_page.dart';
import 'pages/settings_page.dart';
import 'pages/warnings_page.dart';
import 'pages/weather_radar_page.dart';
import 'pages/weather_symbols_page.dart';
import 'routes.dart';

// Global key for ScaffoldMessenger to show SnackBars across the app
final GlobalKey<ScaffoldMessengerState> globalScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

// Utility function to show SnackBars from anywhere in the app
void showGlobalSnackBar({
  required String message,
  Duration duration = const Duration(seconds: 5),
  SnackBarAction? action,
}) {
  globalScaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      action: action,
    ),
  );
}

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
StatefulShellBranch _buildStatefulBranch(
    AppRouteInfo routeInfo, Widget childWidget,
    {GlobalKey<NavigatorState>? navigatorKey}) {
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

const favouritesPage = FavouritesPage(key: PageStorageKey('favourites_page'));

final GoRouter _router = GoRouter(
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
            StatefulShellBranch(
              navigatorKey: GlobalKey<NavigatorState>(),
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoutes.home.path,
                  name: AppRoutes.home.name,
                  pageBuilder: (context, state) => NoTransitionPage(
                    key: state.pageKey,
                    child: const HomePage(key: PageStorageKey('home_page')),
                  ),
                  routes: <RouteBase>[
                    GoRoute(
                      path: AppRoutes.favourites.path,
                      name: AppRoutes.favourites.name,
                      pageBuilder: (context, state) => NoTransitionPage(
                        key: state.pageKey,
                        child: favouritesPage,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            _buildStatefulBranch(
                AppRoutes.weatherRadar,
                const WeatherRadarPage(
                    key: PageStorageKey('weather_radar_page'))),
            _buildStatefulBranch(AppRoutes.warnings,
                const WarningsPage(key: PageStorageKey('warnings_page'))),
            // _buildStatefulBranch(AppRoutes.login, const LoginPage(key: PageStorageKey('login_page'))),
            // Added 'Other' as a stateful branch with its nested children
            StatefulShellBranch(
              navigatorKey: GlobalKey<NavigatorState>(),
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoutes.other.path,
                  name: AppRoutes.other.name,
                  pageBuilder: (context, state) => NoTransitionPage(
                    key: state.pageKey,
                    child: const OtherPageListView(
                        key: PageStorageKey('other_links_page')),
                  ),
                  routes: <RouteBase>[
                    GoRoute(
                      path: AppRoutes.settings.path,
                      name: AppRoutes.settings.name,
                      pageBuilder: (context, state) => NoTransitionPage(
                        key: state.pageKey,
                        child: const SettingsPage(
                            key: PageStorageKey('settings_page')),
                      ),
                    ),
                    GoRoute(
                      path: AppRoutes.weatherSymbols.path,
                      name: AppRoutes.weatherSymbols.name,
                      pageBuilder: (context, state) => NoTransitionPage(
                        key: state.pageKey,
                        child: const WeatherSymbolsPage(
                            key: PageStorageKey('weather_symbols_page')),
                      ),
                    ),
                    GoRoute(
                      path: AppRoutes.about.path,
                      name: AppRoutes.about.name,
                      pageBuilder: (context, state) => NoTransitionPage(
                        key: state.pageKey,
                        child:
                            const AboutPage(key: PageStorageKey('about_page')),
                      ),
                    ),
                    GoRoute(
                      path: AppRoutes.login.path,
                      name: AppRoutes.login.name,
                      pageBuilder: (context, state) => NoTransitionPage(
                        key: state.pageKey,
                        child:
                            const LoginPage(key: PageStorageKey('login_page')),
                      ),
                    ),
                    GoRoute(
                      path: AppRoutes.favourites.path,
                      name: 'other-${AppRoutes.favourites.name}',
                      pageBuilder: (context, state) => NoTransitionPage(
                        key: state.pageKey,
                        child: favouritesPage,
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

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await updateWeatherWidget();
    return Future.value(true);
  });
}

@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  await updateWeatherWidget();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Workmanager
  Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);
  
  // Register periodic task (Android restricts this to minimum 15 minutes)
  Workmanager().registerPeriodicTask(
    "1",
    "weatherUpdate",
    frequency: const Duration(minutes: 15),
  );

  // Register HomeWidget background callback
  HomeWidget.registerBackgroundCallback(backgroundCallback);

  // Add meteocons to license registry
  LicenseRegistry.addLicense(() async* {
    final String license = await rootBundle.loadString(
      'assets/symbols/LICENSE',
    );
    yield LicenseEntryWithLineBreaks(['meteocons'], license);
  });

  // Initialize Appwrite Client
  AppwriteClient();
  
  // Force an immediate widget update when the app starts
  if (!kIsWeb) {
    updateWeatherWidget();
  }

  // Create AppState but don't use it yet
  final appState = AppState();

  // Wait for AppState to be initialized
  await appState.initialized;

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static ThemeData _buildModernTheme(ColorScheme scheme, {bool isDark = false, bool amoled = false}) {
    final colorScheme = scheme;

    final roundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );

    // In normal dark mode, use a deep navy tone inspired by the mockup. 
    // In light mode, use a very faint grey/white. 
    // In AMOLED, pitch black.
    final Color surfaceBaseColor = amoled 
        ? Colors.black 
        : (isDark ? const Color(0xFF111424) : Colors.white);
        
    // Scaffold background is the same as surface
    final Color scaffoldBgColor = surfaceBaseColor;
    
    // Divider and faint lines
    final Color outlineColor = isDark ? const Color(0xFF1E2235) : Colors.grey.shade200;
    
    // Segmented button background
    final Color segmentedBgColor = isDark ? const Color(0xFF1F2437) : Colors.grey.shade200;
    final Color segmentedActiveBg = isDark ? Colors.white : Colors.black;
    final Color segmentedActiveText = isDark ? Colors.black : Colors.white;
    final Color segmentedInactiveText = isDark ? const Color(0xFF8A8D9F) : Colors.grey.shade600;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme.copyWith(
        surface: surfaceBaseColor,
        errorContainer: Colors.red.shade500, // Bright red for delete buttons
        onSurfaceVariant: isDark ? const Color(0xFF8A8D9F) : Colors.grey.shade600, // Subtitles
        outlineVariant: outlineColor,
      ),
      brightness: colorScheme.brightness,
      scaffoldBackgroundColor: scaffoldBgColor,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBgColor,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 22,
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: surfaceBaseColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.all(8),
        shape: roundedShape.copyWith(
          side: BorderSide(color: outlineColor),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color.alphaBlend(colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.12), surfaceBaseColor),
        contentTextStyle: TextStyle(color: colorScheme.onSurface),
        actionTextColor: colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scaffoldBgColor,
        indicatorColor: colorScheme.primaryContainer.withValues(alpha: 0.35),
        labelTextStyle: WidgetStatePropertyAll(const TextStyle(fontWeight: FontWeight.w600)),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
          );
        }),
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: amoled ? Colors.black : (isDark ? const Color(0xFF06080F) : Colors.white),
        selectedItemColor: colorScheme.primary, // Uses Material You primary
        unselectedItemColor: isDark ? const Color(0xFF8A8D9F) : Colors.grey.shade500,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: IconThemeData(color: isDark ? const Color(0xFF8A8D9F) : Colors.grey.shade500),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Color.alphaBlend(colorScheme.primary.withValues(alpha: isDark ? 0.10 : 0.05), surfaceBaseColor),
        selectedColor: colorScheme.secondaryContainer,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: outlineColor),
      ),
      dividerTheme: DividerThemeData(
        color: outlineColor,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white; // White thumb when active
          }
          return isDark ? Colors.grey.shade400 : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary; // Dynamic blue/accent when active
          }
          return isDark ? const Color(0xFF2C324B) : Colors.grey.shade300;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return segmentedActiveBg;
            }
            return segmentedBgColor;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return segmentedActiveText;
            }
            return segmentedInactiveText;
          }),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w600),
          ),
          iconColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return segmentedActiveText;
            }
            return segmentedInactiveText;
          }),
          side: const WidgetStatePropertyAll(BorderSide.none),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Define fallback color schemes
        final lightColorScheme = ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        );

        final darkColorScheme = ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        );

        // Use DynamicColorBuilder to get dynamic color schemes if available
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            // Use dynamic color schemes if available, otherwise use fallback
            final lightScheme = lightDynamic ?? lightColorScheme;
            final darkScheme = darkDynamic ?? darkColorScheme;

            return MaterialApp.router(
              title: 'Weather App',
              debugShowCheckedModeBanner: true,
              scaffoldMessengerKey: globalScaffoldMessengerKey,
              theme: _buildModernTheme(lightScheme, isDark: false),
              darkTheme: appState.isAmoledTheme
                  ? _buildModernTheme(darkScheme, isDark: true, amoled: true)
                  : _buildModernTheme(darkScheme, isDark: true),
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
  // Flag to ensure _sync is only run once
  bool _syncComplete = false;

  void _sync(AppState appState) {
    final client = AppwriteClient();
    client.setAppState(appState);
    if (appState.syncFavouritesToAppwrite) {
      client.isLoggedIn().then((isLoggedIn) {
        if (isLoggedIn) {
          client.syncFavourites(appState,
              direction: SyncDirection.fromAppwrite);
          client.subscribe();
        }
      });
    }
  }

  bool wasDisplayed = false;

  // Show a dialog to inform users about web version limitations
  void _showWebPerformanceDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    const isRunningWithWasm = bool.fromEnvironment('dart.tool.dart2wasm');

    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.webPerformanceWarningTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text(localizations.webPerformanceWarningMessage),
              Text(localizations.webMapDifferenceMessage),
              isRunningWithWasm
                  ? Text(
                      localizations.webWasmPerformanceMessage,
                    )
                  : const SizedBox.shrink(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(localizations.acknowledge),
            ),
          ],
        );
      },
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();

    // Check if the location is the favourites page and return 0 (home tab)
    if (location.contains('/${AppRoutes.favourites.path}')) return 0;

    if (location.startsWith(AppRoutes.other.path)) return 3;
    if (location.startsWith(AppRoutes.warnings.path)) return 2;
    if (location.startsWith(AppRoutes.weatherRadar.path)) return 1;
    if (location.startsWith(AppRoutes.home.path)) return 0;

    return 0; // Default
  }

  void _onItemTapped(int index, BuildContext context) {
    final currentChild = widget.child;
    // Assuming Home, Favourites, Warnings, Other are the first 4 tabs (indices 0, 1, 2, 3)
    // and these are the ones managed by StatefulNavigationShell.
    const int statefulBranchCount = 4;

    if (currentChild is StatefulNavigationShell &&
        index >= 0 &&
        index < statefulBranchCount) {
      // We are on a stateful tab, and a stateful tab (0, 1, 2, or 3) was tapped.
      // Use goBranch to navigate, preserving state.
      currentChild.goBranch(index,
          initialLocation: index == currentChild.currentIndex);
    } else {
      // This block handles:
      // 1. currentChild is not StatefulNavigationShell (e.g., on "Other" page or its sub-routes).
      //    In this case, any tap (0, 1, 2, or 3) should use goNamed.
      switch (index) {
        case 0: // Home
          context.goNamed(AppRoutes.home.name);
          break;
        case 1: // Weather Radar
          context.goNamed(AppRoutes.weatherRadar.name);
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
    final AppState appState = Provider.of<AppState>(context);
    final bool isWideScreen = MediaQuery.of(context).size.width > 600;
    final int currentIndex = _calculateSelectedIndex(context);

    if (!_syncComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Perform the sync operation after the first frame is rendered
        _sync(appState);
      });
      _syncComplete = true;
    }

    if ((kIsWeb || kIsWasm) && !wasDisplayed) {
      wasDisplayed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showWebPerformanceDialog(context);
        } else {
          wasDisplayed = false;
        }
      });
    }

    return Scaffold(
      body: Row(
        children: [
          if (isWideScreen) _buildNavigationRail(context, currentIndex),
          Expanded(child: widget.child),
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
          icon: const Icon(Icons.radar),
          label: Text(localizations.radar),
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
          icon: const Icon(Icons.radar),
          label: localizations.radar,
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
