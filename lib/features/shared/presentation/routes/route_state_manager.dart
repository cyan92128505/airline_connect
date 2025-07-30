class RouteStateManager {
  RouteStateManager._();

  static String? _currentRoute;
  static String? _previousRoute;

  static void updateRouteTransition(String newRoute) {
    _previousRoute = _currentRoute;
    _currentRoute = newRoute;
  }

  static String? getCurrentRoute() => _currentRoute;

  static String? getPreviousRoute() => _previousRoute;

  static void initialize(String initialRoute) {
    _currentRoute = initialRoute;
    _previousRoute = null;
  }

  static bool hasRouteHistory() => _previousRoute != null;

  static void reset() {
    _currentRoute = null;
    _previousRoute = null;
  }

  static Map<String, String?> getDebugState() {
    return {'current': _currentRoute, 'previous': _previousRoute};
  }
}
