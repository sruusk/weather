// Helper class to store both path and name for a route
class AppRouteInfo {
  final String path;
  final String name;

  const AppRouteInfo({required this.path, required this.name});
}

class AppRoutes {
  static const AppRouteInfo home = AppRouteInfo(path: '/', name: 'home');
  static const AppRouteInfo login =
      AppRouteInfo(path: 'login', name: 'login'); // Added login route
  static const AppRouteInfo favourites = AppRouteInfo(path: '/favourites', name: 'favourites');
  static const AppRouteInfo weatherRadar =
      AppRouteInfo(path: '/weather_radar', name: 'weather_radar');
  static const AppRouteInfo warnings = AppRouteInfo(path: '/warnings', name: 'warnings');
  static const AppRouteInfo other = AppRouteInfo(path: '/other', name: 'other_root'); // Path for the list view, name for the root of this section
  static const AppRouteInfo settings = AppRouteInfo(path: 'settings', name: 'settings'); // Path is relative to 'other'
  static const AppRouteInfo weatherSymbols = AppRouteInfo(path: 'weather_symbols', name: 'weather_symbols'); // Path is relative to 'other'
  static const AppRouteInfo about = AppRouteInfo(path: 'about', name: 'about'); // Path is relative to 'other'
}
